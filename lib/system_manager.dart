import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

import 'constants.dart';

class SystemManager {
  static bool isInit = true;

  static Future<void> init() async {
    final box = Hive.box(settings);
    final bool alwaysOnTopResult = box.get(alwaysOnTop, defaultValue: true);
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
          box.get(windowPositionMemory, defaultValue: true);

      if (eventName == 'leftMouseUp') {
        final bool isFocused = await windowManager.isFocused();
        if (isFocused) {
          windowManager.close();
        } else {
          windowManager.show();

          if (isInit || !windowPositionMemoryResult) {
            windowManager.setSize(const Size(400, 600));
            windowManager.setPosition(
              await screenRetriever.getCursorScreenPoint() -
                  const Offset(200, 0),
            );
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
}
