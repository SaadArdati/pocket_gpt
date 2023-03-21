import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
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
          icon: const Icon(Icons.arrow_downward),
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
          final ThemeMode mode = getThemeMode();
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
                                    mode == ThemeMode.light
                                        ? Icons.light_mode_outlined
                                        : mode == ThemeMode.dark
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
                              selected: {mode},
                              onSelectionChanged: (Set<ThemeMode> selected) {
                                final ThemeMode newThemeMode = selected.first;
                                box.put(themeMode, newThemeMode.name);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const SettingsTile(
                        padding: EdgeInsets.all(16),
                        child: OpenAIKeyTile(),
                      ),
                      const SizedBox(height: 16),
                      buildInfoTile(context),
                      const SizedBox(height: 32),
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

  SettingsTile buildInfoTile(BuildContext context) {
    return SettingsTile(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                Text(
                  'Pocket GPT',
                  style: context.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder(
            future: PackageInfo.fromPlatform(),
            builder:
                (BuildContext context, AsyncSnapshot<PackageInfo> snapshot) {
              final String version;
              if (snapshot.hasError) {
                version = snapshot.error.toString();
              } else if (snapshot.hasData) {
                version = snapshot.data!.version;
              } else {
                version = 'Checking...';
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildContactTile(
                    title: 'Website',
                    icon: 'assets/profile_256x.png',
                    url: 'https://saad-ardati.web.app/',
                    avatar: true,
                  ),
                  const SizedBox(height: 8),
                  buildContactTile(
                    title: 'Twitter',
                    icon: 'assets/twitter_256x.png',
                    url: 'https://twitter.com/SaadArdati',
                  ),
                  const SizedBox(height: 8),
                  buildContactTile(
                    title: 'Github',
                    icon: Theme.of(context).brightness == Brightness.dark
                        ? 'assets/github_black_256x.png'
                        : 'assets/github_white_256x.png',
                    url: 'https://github.com/SwissCheese5',
                  ),
                  const SizedBox(height: 8),
                  buildContactTile(
                    title: 'Discord',
                    icon: 'assets/discord_256x.png',
                    url: 'https://discord.gg/3Z2Z5Z5',
                  ),
                  const SizedBox(height: 8),
                  buildContactTile(
                    title: 'LinkedIn',
                    icon: 'assets/linked_in_256x.png',
                    url: 'https://www.linkedin.com/in/saad-ardati',
                  ),
                  const SizedBox(height: 16),
                  Text('Version: $version'),
                  const SizedBox(height: 8),
                  Text(
                    'Copyright © 2020-2021. All Rights Reserved',
                    style: context.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          showLicensePage(context: context);
                        },
                        child: const Text('View Licenses'),
                      )
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Row buildContactTile({
    required String icon,
    required String title,
    required String url,
    bool avatar = false,
  }) {
    return Row(
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.colorScheme.inverseSurface,
            shape: BoxShape.circle,
          ),
          padding: avatar ? EdgeInsets.zero : const EdgeInsets.all(8),
          child: Image.asset(
            icon,
            width: avatar ? 32 : 18,
            height: avatar ? 32 : 18,
            fit: avatar ? BoxFit.cover : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium,
            TextSpan(
              text: '$title: ',
              children: [
                TextSpan(
                  text: url,
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      launchUrlString('https://discord.gg/ARxJzxU');
                    },
                ),
              ],
            ),
          ),
        ),
      ],
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
