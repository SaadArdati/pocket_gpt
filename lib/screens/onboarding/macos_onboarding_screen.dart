import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/adapters.dart';

import '../../constants.dart';
import '../../ui/theme_extensions.dart';
import '../settings_screen.dart';

class MacOSOnboarding extends StatelessWidget {
  const MacOSOnboarding({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: Hive.box(Constants.settings).listenable(),
        builder: (context, box, child) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'One more thing...',
                        textAlign: TextAlign.center,
                        style: context.textTheme.headlineLarge,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The menu bar icon in your system will open the options menu by left-clicking. Right-clicking it will open the app.',
                      textAlign: TextAlign.left,
                      style: context.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You can optionally flip this behavior so that left-clicking opens the app and right-clicking opens the menu.',
                      textAlign: TextAlign.left,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SettingsTile(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: CheckboxListTile(
                        value: box.get(
                          Constants.macOSLeftClickOpensApp,
                          defaultValue: false,
                        ),
                        title: Text(
                          'Left-click opens app',
                          style: context.textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          'Left-clicking on the menu bar icon will open the app, right-clicking will open the options menu.',
                          style: context.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color:
                                context.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        onChanged: (bool? value) {
                          box.put(
                            Constants.macOSLeftClickOpensApp,
                            value ??
                                !box.get(
                                  Constants.macOSLeftClickOpensApp,
                                  defaultValue: false,
                                ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Material(
                        color: context.colorScheme.primaryContainer,
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'Finish',
                          onPressed: () {
                            context.go('/home', extra: {'from': 'onboarding'});
                          },
                          iconSize: 32,
                          icon: const Icon(Icons.navigate_next),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
