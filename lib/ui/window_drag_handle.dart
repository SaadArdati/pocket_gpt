import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WindowDragHandle extends StatelessWidget {
  final Widget? child;

  const WindowDragHandle({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = defaultTargetPlatform;
    final bool isDesktop = !kIsWeb &&
        (platform == TargetPlatform.windows ||
            platform == TargetPlatform.linux ||
            platform == TargetPlatform.macOS);

    if (!isDesktop) {
      return child ?? const SizedBox();
    }
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (details) => appWindow.startDragging(),
      child: child,
    );
  }
}
