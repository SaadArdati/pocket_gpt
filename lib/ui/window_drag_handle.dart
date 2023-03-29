import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

class WindowDragHandle extends StatelessWidget {
  final Widget? child;

  const WindowDragHandle({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (details) => appWindow.startDragging(),
      child: child,
    );
  }
}
