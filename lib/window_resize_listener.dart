import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:universal_io/io.dart';
import 'package:window_manager/window_manager.dart';

import 'constants.dart';

final ValueNotifier<bool> windowFocus = ValueNotifier(true);

class WindowEventsListener extends WindowListener {
  WindowEventsListener._();

  static final WindowEventsListener _instance = WindowEventsListener._();

  factory WindowEventsListener() => _instance;

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
    print('hiding window from onWindowBlur');
    await windowManager.hide();
    windowFocus.value = false;
  }

  @override
  void onWindowFocus() {
    log('window focused');
    windowFocus.value = true;
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
