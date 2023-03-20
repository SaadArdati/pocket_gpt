import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:window_manager/window_manager.dart';

import '../constants.dart';
import '../system_manager.dart';
import '../theme_extensions.dart';

class OnboardingScreen extends StatefulWidget {
  final Widget child;

  const OnboardingScreen({
    super.key,
    required this.child,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final box = Hive.box(settings);

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = Theme.of(context).platform;
    final bool isDesktop = platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux ||
        platform == TargetPlatform.macOS;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          ValueListenableBuilder(
            valueListenable: box.listenable(),
            builder: (context, Box box, child) {
              final Brightness brightness = Theme.of(context).brightness;
              return IconButton(
                tooltip:
                    brightness == Brightness.light ? 'Dark Mode' : 'Light Mode',
                icon: Icon(
                  brightness == Brightness.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                onPressed: () {
                  box.put(
                    'theme_mode',
                    brightness == Brightness.light
                        ? ThemeMode.dark.name
                        : ThemeMode.light.name,
                  );
                },
              );
            },
          ),
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class OnboardingWelcome extends StatelessWidget {
  const OnboardingWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          Text(
            'Welcome',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 16),
          Text(
            "Let's get you set up",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          Material(
            color: context.colorScheme.primaryContainer,
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Next',
              onPressed: () {
                context.go('/onboarding/two');
              },
              iconSize: 32,
              icon: const Icon(Icons.navigate_next),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class OnboardingDone extends StatelessWidget {
  const OnboardingDone({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          Text(
            "You're all set!",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 16),
          Material(
            color: context.colorScheme.primaryContainer,
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Finish',
              onPressed: () {
                context.go('/home');
              },
              iconSize: 32,
              icon: const Icon(Icons.navigate_next),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
