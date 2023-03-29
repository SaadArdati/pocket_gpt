import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../constants.dart';
import '../system_manager.dart';

class WindowControls extends StatelessWidget {
  const WindowControls({super.key});

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = defaultTargetPlatform;
    final bool isDesktop = !kIsWeb &&
        (platform == TargetPlatform.windows ||
            platform == TargetPlatform.linux ||
            platform == TargetPlatform.macOS);

    final box = Hive.box(Constants.settings);
    final bool showTitleBar =
        box.get(Constants.showTitleBar, defaultValue: false);

    const double buttonSize = 20;
    return Row(
      children: [
        if (isDesktop && !showTitleBar) ...[
          IconButton(
            iconSize: buttonSize,
            tooltip: 'Toggle window bounds',
            icon: const Icon(Icons.photo_size_select_small),
            onPressed: SystemManager.instance.toggleWindowMemory,
          ),
          IconButton(
            iconSize: buttonSize,
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: SystemManager.instance.closeWindow,
          ),
        ],
      ],
    );
  }
}
