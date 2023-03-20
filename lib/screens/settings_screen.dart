import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:window_manager/window_manager.dart';

import '../constants.dart';
import '../main.dart';
import '../system_manager.dart';
import '../theme_extensions.dart';
import 'open_ai_key_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final box = Hive.box(settings);

  late final AnimationController animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  late final Animation<double> blurAnimation = CurvedAnimation(
    parent: animationController,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = Theme.of(context).platform;
    final bool isDesktop = platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux ||
        platform == TargetPlatform.macOS;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
          },
        ),
        actions: [
          if (isDesktop)
            IconButton(
              tooltip: 'Minimize',
              icon: const Icon(Icons.minimize),
              onPressed: () {
                windowManager.close();
                SystemManager.isOpen = false;
              },
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box box, child) {
          final ThemeMode themeMode = getThemeMode();
          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 350),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      SizedBox(
                          height: (Scaffold.of(context).appBarMaxHeight ?? 48) +
                              16),
                      SettingsTile(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    themeMode == ThemeMode.light
                                        ? Icons.light_mode_outlined
                                        : themeMode == ThemeMode.dark
                                            ? Icons.dark_mode_outlined
                                            : Icons.brightness_4,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Theme Mode',
                                    style: context.textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SegmentedButton<ThemeMode>(
                              segments: const [
                                ButtonSegment<ThemeMode>(
                                  value: ThemeMode.light,
                                  label: Text('Light'),
                                ),
                                ButtonSegment<ThemeMode>(
                                  value: ThemeMode.dark,
                                  label: Text('Dark'),
                                ),
                                ButtonSegment<ThemeMode>(
                                  value: ThemeMode.system,
                                  label: Text('System'),
                                ),
                              ],
                              selected: {themeMode},
                              onSelectionChanged: (Set<ThemeMode> selected) {
                                final ThemeMode newThemeMode = selected.first;
                                box.put('theme_mode', newThemeMode.name);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const SettingsTile(
                        padding: EdgeInsets.all(8),
                        child: OpenAIKeyTile(),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Builder(builder: (context) {
                  return ClipRect(
                    child: AnimatedBuilder(
                      animation: blurAnimation,
                      builder: (context, child) {
                        return BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: blurAnimation.value * 5,
                            sigmaY: blurAnimation.value * 5,
                          ),
                          child: child!,
                        );
                      },
                      child: Container(
                        color: Colors.transparent,
                        height: Scaffold.of(context).appBarMaxHeight ?? 48 + 16,
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const SettingsTile({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: padding,
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: context.colorScheme.tertiaryContainer,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colorScheme.tertiaryContainer,
              context.colorScheme.background,
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: child,
        ),
      ),
    );
  }
}
