import 'dart:ui';

import 'package:hive/hive.dart';
import 'package:window_manager/window_manager.dart';

import 'constants.dart';

class WindowResizeListener extends WindowListener {
  @override
  Future<void> onWindowResized() async {
    final Size size = await windowManager.getSize();
    Hive.box(settings).put('width', size.width);
    Hive.box(settings).put('height', size.height);
  }

  @override
  Future<void> onWindowMoved() async {
    final pos = await windowManager.getPosition();
    Hive.box(settings).put('left', pos.dx);
    Hive.box(settings).put('top', pos.dy);
  }
}

Offset? getSavedWindowPosition() {
  final double? top = Hive.box(settings).get('top');
  final double? left = Hive.box(settings).get('left');
  return top != null && left != null ? Offset(left, top) : null;
}

Size getSavedWindowSize({required Size defaultSize}) {
  final double width =
  Hive.box(settings).get('width', defaultValue: defaultSize.width);
  final double height =
  Hive.box(settings).get('height', defaultValue: defaultSize.height);

  return Size(width, height);
}
