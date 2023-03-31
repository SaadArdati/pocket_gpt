import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../constants.dart';
import '../managers/system_manager.dart';

class WindowControls extends StatelessWidget {
  const WindowControls({super.key});

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = defaultTargetPlatform;
    final bool isDesktop = !kIsWeb &&
        (platform == TargetPlatform.windows ||
            platform == TargetPlatform.linux ||
            platform == TargetPlatform.macOS);
    final bool isMacOS = isDesktop && platform == TargetPlatform.macOS;

    final box = Hive.box(Constants.settings);
    final bool showTitleBar =
        box.get(Constants.showTitleBar, defaultValue: false);

    final double? buttonSize = isDesktop ? 20 : null;
    return Row(
      children: [
        if (isDesktop) ...[
          IconButton(
            iconSize: buttonSize,
            tooltip: 'Toggle window bounds',
            icon: const Icon(Icons.photo_size_select_small),
            onPressed: SystemManager.instance.toggleWindowMemory,
          ),
          if (!showTitleBar) ...[
            IconButton(
              iconSize: buttonSize,
              tooltip: 'Close',
              icon: const Icon(Icons.close),
              onPressed: SystemManager.instance.minimizeWindow,
            ),
            // IconButton(
            //   iconSize: buttonSize,
            //   tooltip: isMacOS ? 'Close' : 'Minimize',
            //   icon: const Icon(Icons.minimize),
            //   onPressed: SystemManager.instance.minimizeWindow,
            // ),
            // IconButton(
            //   iconSize: buttonSize,
            //   tooltip: 'Quit',
            //   icon: const Icon(Icons.close),
            //   onPressed: SystemManager.instance.quitApp,
            // ),
          ],
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}
