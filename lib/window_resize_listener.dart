import 'dart:developer';
import 'dart:ui';

import 'package:hive/hive.dart';
import 'package:window_manager/window_manager.dart';

import 'constants.dart';

class WindowResizeListener extends WindowListener {
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
}

Offset? getSavedWindowPosition() {
  final double? left = Hive.box(Constants.settings).get(Constants.windowX);
  final double? top = Hive.box(Constants.settings).get(Constants.windowY);
  return top != null && left != null ? Offset(left, top) : null;
}

Size getSavedWindowSize({required Size defaultSize}) {
  final double width = Hive.box(Constants.settings)
      .get(Constants.windowWidth, defaultValue: defaultSize.width);
  final double height = Hive.box(Constants.settings)
      .get(Constants.windowHeight, defaultValue: defaultSize.height);

  return Size(width, height);
}

Offset? getSavedTrayPosition() {
  log('getSavedTrayPosition');
  final double? top = Hive.box(Constants.settings).get(Constants.trayPositionX);
  final double? left =
      Hive.box(Constants.settings).get(Constants.trayPositionY);
  return top != null && left != null ? Offset(left, top) : null;
}

void saveTrayPosition(Offset position) {
  log('saveTrayPosition');
  Hive.box(Constants.settings).put(Constants.trayPositionX, position.dx);
  Hive.box(Constants.settings).put(Constants.trayPositionY, position.dy);
}
