import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

import 'constants.dart';
import 'window_resize_listener.dart';

class SystemManager {
  static bool isInit = true;
  static late Offset trayPosition;
  static Size defaultWindowSize = const Size(400, 600);

  static Future<void> init() async {
    final box = Hive.box(Constants.settings);
    final bool alwaysOnTop =
        box.get(Constants.alwaysOnTop, defaultValue: true);
    WidgetsFlutterBinding.ensureInitialized();

    await windowManager.ensureInitialized();

    trayPosition = getSavedTrayPosition() ?? Offset.zero;
    final Offset? position = getSavedWindowPosition();
    final Size size = getSavedWindowSize(defaultSize: defaultWindowSize);

    // final WindowOptions windowOptions = WindowOptions(
    //   size: const Size(400, 600),
    //   backgroundColor: Colors.transparent,
    //   skipTaskbar: true,
    //   titleBarStyle: TitleBarStyle.hidden,
    //   alwaysOnTop: alwaysOnTopResult,
    // );
    //
    // await windowManager.waitUntilReadyToShow(windowOptions);

    doWhenWindowReady(() async {
      appWindow.minSize = defaultWindowSize;
      appWindow.size = size;

      if (position != null) appWindow.position = position;

      windowManager.setSkipTaskbar(true);
      windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      windowManager.setAlwaysOnTop(alwaysOnTop);
      windowManager.setBackgroundColor(Colors.transparent);
      windowManager.setAsFrameless();
      windowManager.addListener(WindowResizeListener());
    });

    if (Platform.isMacOS) windowManager.setMovable(true);

    final String path =
        Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png';

    final SystemTray systemTray = SystemTray();

    await systemTray.initSystemTray(
      title: '',
      toolTip: 'Pocket GPT',
      iconPath: path,
    );

    // handle system tray event
    systemTray.registerSystemTrayEventHandler((eventName) async {
      final bool windowPositionMemory =
          box.get(Constants.windowPositionMemory, defaultValue: true);

      if (eventName == 'click') {
        final bool isVisible = await windowManager.isVisible();
        if (isVisible) {
          windowManager.close();
        } else {
          windowManager.show();

          trayPosition = await screenRetriever.getCursorScreenPoint() -
              Offset(defaultWindowSize.width / 2, 0);

          if (isInit || !windowPositionMemory) {
            saveTrayPosition(trayPosition);

            await windowManager.setBounds(
              Rect.fromLTWH(
                trayPosition.dx,
                trayPosition.dy,
                defaultWindowSize.width,
                defaultWindowSize.height,
              ),
              animate: false,
            );
            trayPosition = await windowManager.getPosition();
          }
          isInit = false;
        }
      }
    });
  }

  static void dispose() {
    isInit = true;
  }

  static Future<void> setAlwaysOnTop(bool isAlwaysOnTop) {
    return windowManager.setAlwaysOnTop(isAlwaysOnTop);
  }

  static Future<void> closeWindow() {
    return windowManager.close();
  }

  static Future<void> toggleWindowMemory() async {
    final box = Hive.box(Constants.settings);

    final Size windowSize = await windowManager.getSize();
    final Offset windowPosition = await windowManager.getPosition();
    double threshold = 20;
    double thresholdY = 60;
    if ((windowSize.width - defaultWindowSize.width).abs() > threshold ||
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
