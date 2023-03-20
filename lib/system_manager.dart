import 'dart:io';

import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

class SystemManager {
  static bool isOpen = false;
  static bool isInit = true;

  Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    await windowManager.ensureInitialized();

    const WindowOptions windowOptions = WindowOptions(
      size: Size(400, 600),
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
      alwaysOnTop: true,
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
      if (eventName == 'leftMouseUp') {
        if (isOpen) {
          windowManager.close();
          isOpen = false;
        } else {
          windowManager.show();

          // get cursor of system.
          if (isInit) {
            windowManager.setPosition(
              await screenRetriever.getCursorScreenPoint() -
                  const Offset(200, 0),
            );
          }
          isInit = false;
          isOpen = true;
        }
      }
    });
  }
}
