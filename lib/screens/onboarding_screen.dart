import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/adapters.dart';

import '../constants.dart';
import '../ui/theme_extensions.dart';
import '../ui/window_controls.dart';

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
  final box = Hive.box(Constants.settings);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: const [WindowControls()],
      ),
      resizeToAvoidBottomInset: true,
      body: WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: widget.child,
            ),
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
          const SizedBox(height: 8),
          Text(
            "The app will naturally live in your system's tray.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Material(
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
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
