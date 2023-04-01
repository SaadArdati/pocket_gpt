import 'dart:developer';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:system_tray/system_tray.dart';
import 'package:universal_io/io.dart';
import 'package:window_manager/window_manager.dart';

import '../constants.dart';

class SystemManager with WindowListener {
  bool isInitializing = true;
  late Offset trayPosition;
  Size defaultWindowSize = const Size(400, 600);
  final ValueNotifier<bool> windowFocus = ValueNotifier(true);

  SystemManager._();

  static final SystemManager _instance = SystemManager._();

  static SystemManager get instance => _instance;

  factory SystemManager() => _instance;

  Future<void> init() async {
    final box = Hive.box(Constants.settings);
    final bool alwaysOnTop = box.get(Constants.alwaysOnTop, defaultValue: true);
    final bool showInTaskbar =
        box.get(Constants.moveToSystemDock, defaultValue: false);
    final bool showTitleBar =
        box.get(Constants.showTitleBar, defaultValue: false);

    WidgetsFlutterBinding.ensureInitialized();

    await windowManager.ensureInitialized();

    trayPosition = getSavedTrayPosition() ?? Offset.zero;
    final Offset? position = getSavedWindowPosition();
    final Size size = getSavedWindowSize(defaultSize: defaultWindowSize);

    if (!showTitleBar) {
      await windowManager.setAsFrameless();
    }

    final windowOptions = WindowOptions(
      alwaysOnTop: alwaysOnTop,
      backgroundColor: Colors.transparent,
      skipTaskbar: !showInTaskbar,
      titleBarStyle: showTitleBar ? TitleBarStyle.normal : TitleBarStyle.hidden,
      title: 'PocketGPT',
    );

    windowManager.waitUntilReadyToShow(windowOptions);

    doWhenWindowReady(() async {
      appWindow.minSize = defaultWindowSize;
      appWindow.size = size;

      if (position != null) appWindow.position = position;

      windowManager.addListener(this);
      appWindow.hide();
    });

    if (Platform.isMacOS) windowManager.setMovable(true);

    final String path =
        Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png';

    final SystemTray systemTray = SystemTray();

    await systemTray.initSystemTray(
      title: '',
      toolTip: 'PocketGPT',
      iconPath: path,
    );

    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(
        label: 'Toggle Window',
        onClicked: (menuItem) => onSystemTrayClick(),
      ),
      MenuItemLabel(
        label: 'Quit',
        onClicked: (menuItem) => quitApp(),
      ),
    ]);
    await systemTray.setContextMenu(menu);

    // handle system tray event
    systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        onSystemTrayClick();
      } else if (eventName == kSystemTrayEventRightClick) {
        systemTray.popUpContextMenu();
      }
    });
  }

  Future<void> onSystemTrayClick() async {
    final box = Hive.box(Constants.settings);
    final bool shouldPreserveWindowPosition =
        box.get(Constants.shouldPreserveWindowPosition, defaultValue: true);
    final bool isFirstTime = box.get(Constants.isFirstTime, defaultValue: true);

    final bool isVisible = await windowManager.isVisible();

    if (isVisible) {
      minimizeWindow();
    } else {
      revealWindow();
      final AxisDirection dockPosition = await findSystemDockPosition();
      saveDockPosition(dockPosition);

      trayPosition = await findBestTrayWindowPosition(dockPosition);

      if (isInitializing || !shouldPreserveWindowPosition) {
        saveTrayPosition(trayPosition);

        if (isFirstTime) {
          await windowManager.center(animate: false);
        } else {
          await windowManager.setBounds(
            Rect.fromLTWH(
              trayPosition.dx,
              trayPosition.dy,
              defaultWindowSize.width,
              defaultWindowSize.height,
            ),
            animate: false,
          );
        }
        trayPosition = await windowManager.getPosition();
      }
      isInitializing = false;
    }
  }

  /// From: https://stackoverflow.com/a/20861130/4327834
  static bool _pointInTriangle(Offset p, Offset p0, Offset p1, Offset p2) {
    var s = (p0.dx - p2.dx) * (p.dy - p2.dy) - (p0.dy - p2.dy) * (p.dx - p2.dx);
    var t = (p1.dx - p0.dx) * (p.dy - p0.dy) - (p1.dy - p0.dy) * (p.dx - p0.dx);

    if ((s < 0) != (t < 0) && s != 0 && t != 0) {
      return false;
    }

    var d = (p2.dx - p1.dx) * (p.dy - p1.dy) - (p2.dy - p1.dy) * (p.dx - p1.dx);
    return d == 0 || (d < 0) == (s + t <= 0);
  }

  static const Offset _center = Offset(0.5, 0.5);
  static const Map<AxisDirection, List<Offset>> _triangles = {
    AxisDirection.left: [
      Offset.zero,
      _center,
      Offset(0, 1),
    ],
    AxisDirection.up: [
      Offset.zero,
      _center,
      Offset(1, 0),
    ],
    AxisDirection.right: [
      Offset(1, 0),
      _center,
      Offset(1, 1),
    ],
    AxisDirection.down: [
      Offset(0, 1),
      _center,
      Offset(1, 1),
    ],
  };

  Future<AxisDirection> findSystemDockPosition() async {
    final Display primaryDisplay = await screenRetriever.getPrimaryDisplay();
    final Size displaySize = primaryDisplay.size;
    final Offset pointerPos = await screenRetriever.getCursorScreenPoint();

    AxisDirection dockPosition = AxisDirection.down;
    for (final AxisDirection section in AxisDirection.values) {
      if (_pointInTriangle(
        pointerPos,
        _triangles[section]![0].scale(displaySize.width, displaySize.height),
        _triangles[section]![1].scale(displaySize.width, displaySize.height),
        _triangles[section]![2].scale(displaySize.width, displaySize.height),
      )) {
        dockPosition = section;
        break;
      }
    }

    return dockPosition;
  }

  Future<Offset> findBestTrayWindowPosition(
      AxisDirection systemDockPosition) async {
    final Offset pointerPos = await screenRetriever.getCursorScreenPoint();
    final Display primaryDisplay = await screenRetriever.getPrimaryDisplay();
    final Size displaySize = primaryDisplay.size;
    final double scaleFactor = primaryDisplay.scaleFactor?.toDouble() ?? 1;

    final bool isHorizontalDock = systemDockPosition == AxisDirection.left ||
        systemDockPosition == AxisDirection.right;
    final double dockSize;
    if (Platform.isWindows) {
      if (isHorizontalDock) {
        dockSize = 50 * scaleFactor;
      } else {
        dockSize = 40 * scaleFactor;
      }
    } else {
      dockSize = 0;
    }

    final Size windowSize = defaultWindowSize;
    late Offset windowPosition;
    switch (systemDockPosition) {
      case AxisDirection.left:
        windowPosition = Offset(0, pointerPos.dy - windowSize.height / 2);
        break;
      case AxisDirection.up:
        windowPosition = Offset(pointerPos.dx - windowSize.width / 2, 0);
        break;
      case AxisDirection.right:
        windowPosition = Offset(displaySize.width - windowSize.width,
            pointerPos.dy - windowSize.height / 2);
        break;
      case AxisDirection.down:
        windowPosition = Offset(pointerPos.dx - windowSize.width / 2,
            displaySize.height - windowSize.height);
        break;
    }

    // apply padding.
    switch (systemDockPosition) {
      case AxisDirection.left:
        windowPosition += Offset(dockSize, 0);
        break;
      case AxisDirection.up:
        windowPosition += Offset(0, dockSize);
        break;
      case AxisDirection.right:
        windowPosition -= Offset(dockSize, 0);
        break;
      case AxisDirection.down:
        windowPosition -= Offset(0, dockSize);
        break;
    }

    return windowPosition;
  }

  void dispose() {
    windowManager.removeListener(this);
  }

  void toggleTitleBar({required bool show}) {
    // Requires restart for borderless frame to be disabled.
    // if (show) {
    //   windowManager.setTitleBarStyle(TitleBarStyle.normal);
    // } else {
    //   windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    // }

    final box = Hive.box(Constants.settings);
    box.put(Constants.showTitleBar, show);
  }

  void toggleSystemDock({required bool show}) {
    windowManager.setSkipTaskbar(!show);
    final box = Hive.box(Constants.settings);
    box.put(Constants.moveToSystemDock, show);
  }

  Future<void> setAlwaysOnTop(bool isAlwaysOnTop) {
    return windowManager.setAlwaysOnTop(isAlwaysOnTop);
  }

  Future<void> minimizeWindow() async {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return appWindow.hide();
    } else {
      return windowManager.hide();
    }
  }

  Future<void> revealWindow() async {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      appWindow.restore();
      // TODO: maybe appWindow.show();
    } else {
      windowManager.show();
    }
  }

  Future<void> quitApp() async {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      appWindow.close();
    } else {
      return SystemNavigator.pop();
    }
  }

  @override
  Future<void> onWindowResized() async {
    final Size size = await windowManager.getSize();
    Hive.box(Constants.settings).put(Constants.windowWidth, size.width);
    Hive.box(Constants.settings).put(Constants.windowHeight, size.height);
  }

  @override
  Future<void> onWindowMoved() async {
    final pos = await windowManager.getPosition();
    Hive.box(Constants.settings).put(Constants.windowX, pos.dx);
    Hive.box(Constants.settings).put(Constants.windowY, pos.dy);
  }

  @override
  Future<void> onWindowBlur() async {
    log('window unfocused');
    final box = Hive.box(Constants.settings);
    final bool alwaysOnTop = box.get(Constants.alwaysOnTop, defaultValue: true);

    if (alwaysOnTop) return;

    if (Platform.isWindows) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (Platform.isWindows && isInitializing) return;
    await minimizeWindow();
    windowFocus.value = false;
  }

  @override
  void onWindowFocus() {
    log('window focused');
    windowFocus.value = true;
  }

  Future<void> toggleWindowMemory() async {
    final box = Hive.box(Constants.settings);

    final Size windowSize = await windowManager.getSize();
    final Offset windowPosition = await windowManager.getPosition();
    double threshold = 20;
    double thresholdY = 60;
    if (isInitializing &&
            (windowSize.width - defaultWindowSize.width).abs() > threshold ||
        (windowSize.height - defaultWindowSize.height).abs() > threshold ||
        (windowPosition.dx - trayPosition.dx).abs() > threshold ||
        (windowPosition.dy - trayPosition.dy).abs() > thresholdY) {
      // store in hive before changing.
      box.put(Constants.retainedWindowWidth, windowSize.width);
      box.put(Constants.retainedWindowHeight, windowSize.height);
      box.put(Constants.retainedWindowX, windowPosition.dx);
      box.put(Constants.retainedWindowY, windowPosition.dy);

      final savedDockPosition = getSavedDockPosition();
      final currentDockPosition = await findSystemDockPosition();
      if (savedDockPosition != currentDockPosition) {
        // dock position changed.
        box.put(Constants.systemDockPosition, currentDockPosition);

        trayPosition = await findBestTrayWindowPosition(currentDockPosition);
        saveTrayPosition(trayPosition);
      }
      await windowManager.setBounds(
        Rect.fromLTWH(
          trayPosition.dx,
          trayPosition.dy,
          defaultWindowSize.width,
          defaultWindowSize.height,
        ),
        animate: true,
      );
    } else {
      // restore from hive.
      final double? restoredWidth = box.get(Constants.retainedWindowWidth);
      final double? restoredHeight = box.get(Constants.retainedWindowHeight);
      final double? restoredX = box.get(Constants.retainedWindowX);
      final double? restoredY = box.get(Constants.retainedWindowY);

      if (restoredWidth != null &&
          restoredHeight != null &&
          restoredX != null &&
          restoredY != null) {
        await windowManager.setBounds(
          Rect.fromLTWH(
            restoredX,
            restoredY,
            restoredWidth,
            restoredHeight,
          ),
          animate: true,
        );
      }
    }
  }
}

Offset? getSavedWindowPosition() {
  final double? x = Hive.box(Constants.settings).get(Constants.windowX);
  final double? y = Hive.box(Constants.settings).get(Constants.windowY);
  return y != null && x != null ? Offset(x, y) : null;
}

Size getSavedWindowSize({required Size defaultSize}) {
  final double width = Hive.box(Constants.settings)
      .get(Constants.windowWidth, defaultValue: defaultSize.width);
  final double height = Hive.box(Constants.settings)
      .get(Constants.windowHeight, defaultValue: defaultSize.height);

  return Size(width, height);
}

Offset? getSavedTrayPosition() {
  final double? y = Hive.box(Constants.settings).get(Constants.trayPositionY);
  final double? x = Hive.box(Constants.settings).get(Constants.trayPositionX);
  return y != null && x != null ? Offset(x, y) : null;
}

void saveTrayPosition(Offset position) {
  Hive.box(Constants.settings).put(Constants.trayPositionX, position.dx);
  Hive.box(Constants.settings).put(Constants.trayPositionY, position.dy);
}

void saveDockPosition(AxisDirection position) {
  Hive.box(Constants.settings)
      .put(Constants.systemDockPosition, position.index);
}

AxisDirection getSavedDockPosition() {
  final int? index = Hive.box(Constants.settings).get(
      Constants.systemDockPosition,
      defaultValue: AxisDirection.down.index);
  return AxisDirection.values[index!];
}
