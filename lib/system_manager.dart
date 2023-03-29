import 'dart:developer';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:system_tray/system_tray.dart';
import 'package:universal_io/io.dart';
import 'package:window_manager/window_manager.dart';

import 'constants.dart';

class SystemManager with WindowListener {
  bool isInit = true;
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
        onClicked: (menuItem) => SystemNavigator.pop(),
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
      windowManager.hide();
    } else {
      windowManager.show();

      trayPosition = await screenRetriever.getCursorScreenPoint() -
          Offset(defaultWindowSize.width / 2, 0);

      if (isInit || !shouldPreserveWindowPosition) {
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
      isInit = false;
    }
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

  Future<void> closeWindow() {
    return windowManager.hide();
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
    if (Platform.isWindows && isInit) return;
    await windowManager.hide();
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
    if (isInit &&
            (windowSize.width - defaultWindowSize.width).abs() > threshold ||
        (windowSize.height - defaultWindowSize.height).abs() > threshold ||
        (windowPosition.dx - trayPosition.dx).abs() > threshold ||
        (windowPosition.dy - trayPosition.dy).abs() > thresholdY) {
      // store in hive before changing.
      box.put(Constants.settingWindowWidth, windowSize.width);
      box.put(Constants.settingWindowHeight, windowSize.height);
      box.put(Constants.settingWindowX, windowPosition.dx);
      box.put(Constants.settingWindowY, windowPosition.dy);

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
      final double? restoredWidth = box.get(Constants.settingWindowWidth);
      final double? restoredHeight = box.get(Constants.settingWindowHeight);
      final double? restoredX = box.get(Constants.settingWindowX);
      final double? restoredY = box.get(Constants.settingWindowY);

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
