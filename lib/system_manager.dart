import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

import 'constants.dart';

class SystemManager {
  static bool isInit = true;
  static late Offset trayPosition;
  static Size defaultWindowSize = const Size(400, 600);

  static Future<void> init() async {
    final box = Hive.box(settings);
    final bool alwaysOnTopResult =
        box.get(settingAlwaysOnTop, defaultValue: true);
    WidgetsFlutterBinding.ensureInitialized();

    await windowManager.ensureInitialized();

    final WindowOptions windowOptions = WindowOptions(
      size: const Size(400, 600),
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
      alwaysOnTop: alwaysOnTopResult,
    );
    await windowManager.waitUntilReadyToShow(windowOptions);
    await windowManager.setMovable(true);
    await windowManager.setAsFrameless();

    final String path =
        Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png';

    final SystemTray systemTray = SystemTray();

    await systemTray.initSystemTray(
      title: '',
      toolTip: 'System GPT',
      iconPath: path,
    );

    // handle system tray event
    systemTray.registerSystemTrayEventHandler((eventName) async {
      final bool windowPositionMemoryResult =
          box.get(settingWindowPositionMemory, defaultValue: true);

      if (eventName == 'leftMouseUp') {
        final bool isFocused = await windowManager.isFocused();
        if (isFocused) {
          windowManager.close();
        } else {
          windowManager.show();

          trayPosition = await screenRetriever.getCursorScreenPoint() -
              Offset(defaultWindowSize.width / 2, 0);

          if (isInit || !windowPositionMemoryResult) {
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

  static Future<void> setAlwaysOnTop(bool isAlwaysOnTop) {
    return windowManager.setAlwaysOnTop(isAlwaysOnTop);
  }

  static Future<void> closeWindow() {
    return windowManager.close();
  }

  static Future<void> toggleWindowMemory() async {
    final box = Hive.box(settings);

    final Size windowSize = await windowManager.getSize();
    final Offset windowPosition = await windowManager.getPosition();
    double threshold = 20;
    double thresholdY = 60;
    if ((windowSize.width - defaultWindowSize.width).abs() > threshold ||
        (windowSize.height - defaultWindowSize.height).abs() > threshold ||
        (windowPosition.dx - trayPosition.dx).abs() > threshold ||
        (windowPosition.dy - trayPosition.dy).abs() > thresholdY) {
      // store in hive before changing.
      box.put(settingsWindowWidth, windowSize.width);
      box.put(settingsWindowHeight, windowSize.height);
      box.put(settingsWindowX, windowPosition.dx);
      box.put(settingsWindowY, windowPosition.dy);

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
      final double? restoredWidth = box.get(settingsWindowWidth);
      final double? restoredHeight = box.get(settingsWindowHeight);
      final double? restoredX = box.get(settingsWindowX);
      final double? restoredY = box.get(settingsWindowY);

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
