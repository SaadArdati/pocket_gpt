import 'dart:math';

import 'package:dart_openai/openai.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'gpt_manager.dart';
import 'screens/open_ai_key_screen.dart';
import 'constants.dart';
import 'screens/chat_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/settings_screen.dart';
import 'system_manager.dart';
import 'theme_extensions.dart';

import 'color_schemes.g.dart';
import 'wave_background.dart';

void main() async {
  await SystemManager().init();

  await Hive.initFlutter();
  await Hive.openBox(history);
  await Hive.openBox(settings);

  OpenAI.apiKey = Hive.box(settings).get(openAIKey, defaultValue: '');

  runApp(const PocketGPT());
}

AnimatedWidget defaultPageTransition(
  BuildContext context,
  Animation<double> animation,
  Widget child, {
  required bool reverse,
}) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: Offset(0, reverse ? -1 : 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutQuart,
      ),
    ),
    child: child,
  );
}

ThemeMode getThemeMode() {
  final box = Hive.box(settings);
  switch (box.get('theme_mode', defaultValue: 'system')) {
    case 'dark':
      return ThemeMode.dark;
    case 'light':
      return ThemeMode.light;
    default:
      return ThemeMode.system;
  }
}

class PocketGPT extends StatefulWidget {
  const PocketGPT({super.key});

  @override
  State<PocketGPT> createState() => _PocketGPTState();
}

class _PocketGPTState extends State<PocketGPT> with WindowListener {

  @override
  void initState() {
    windowManager.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowFocus() {
    // Make sure to call once.
    setState(() {});
  }

  final box = Hive.box(settings);

  late final _router = GoRouter(
    initialLocation:
        box.get(isFirstTime, defaultValue: true) ? '/onboarding' : '/home',
    routes: [
      ShellRoute(
        builder: (context, GoRouterState state, child) {
          return NavigationBackground(state: state, child: child);
        },
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (state, context) => const SizedBox.shrink(),
            redirect: (BuildContext context, GoRouterState state) {
              if (state.location == '/onboarding') {
                return '/onboarding/one';
              }
              return null;
            },
            routes: [
              ShellRoute(
                builder: (context, GoRouterState state, child) {
                  return OnboardingScreen(child: child);
                },
                routes: [
                  GoRoute(
                    path: 'one',
                    builder: (context, state) => const OnboardingWelcome(),
                  ),
                  GoRoute(
                    path: 'two',
                    builder: (context, state) => const OpenAIKeyScreen(),
                  ),
                  GoRoute(
                    path: 'three',
                    builder: (context, state) => const OnboardingDone(),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
            // pageBuilder: (context, state) {
            //   return CustomTransitionPage(
            //     key: state.pageKey,
            //     child: const HomeScreen(),
            //     opaque: false,
            //     transitionsBuilder:
            //         (context, animation, secondaryAnimation, child) {
            //       return defaultPageTransition(
            //         context,
            //         animation,
            //         child,
            //         reverse: true,
            //       );
            //     },
            //   );
            // },
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) {
              final extra = state.extra;
              if (extra == null || extra is! Map) {
                return const ChatScreenWrapper();
              }

              final String typeParam = extra['type'] ?? ChatType.general.name;
              final ChatType type = ChatType.values.firstWhere(
                (chatType) => chatType.name == typeParam,
              );

              return ChatScreenWrapper(type: type);
            },
            // pageBuilder: (context, state) {
            //   return CustomTransitionPage(
            //     key: state.pageKey,
            //     child: const ChatScreenWrapper(),
            //     opaque: false,
            //     transitionsBuilder:
            //         (context, animation, secondaryAnimation, child) {
            //       return defaultPageTransition(
            //         context,
            //         animation,
            //         child,
            //         reverse: false,
            //       );
            //     },
            //   );
            // },
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
            //   pageBuilder: (context, state) {
            //     return CustomTransitionPage(
            //       key: state.pageKey,
            //       child: const SettingsScreen(),
            //       opaque: false,
            //       transitionsBuilder:
            //           (context, animation, secondaryAnimation, child) {
            //         return SlideTransition(
            //           position: Tween<Offset>(
            //             begin: const Offset(1, 0),
            //             end: Offset.zero,
            //           ).animate(
            //             CurvedAnimation(
            //               parent: animation,
            //               curve: Curves.easeOutQuart,
            //             ),
            //           ),
            //           child: child,
            //         );
            //       },
            //     );
            //   },
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box(settings).listenable(),
      builder: (context, Box box, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightColorScheme,
            scaffoldBackgroundColor: Colors.transparent,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkColorScheme,
            scaffoldBackgroundColor: Colors.transparent,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
            ),
          ),
          themeMode: getThemeMode(),
          routerConfig: _router,
        );
      },
    );
  }
}

class NavigationBackground extends StatefulWidget {
  final Widget child;
  final GoRouterState state;

  const NavigationBackground({
    super.key,
    required this.state,
    required this.child,
  });

  @override
  State<NavigationBackground> createState() => _NavigationBackgroundState();
}

class _NavigationBackgroundState extends State<NavigationBackground>
    with TickerProviderStateMixin {
  late final AnimationController transitionController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );
  late final AnimationController waveController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 100),
  )..repeat(reverse: true);

  late final AnimationController rotationController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
    upperBound: 360,
    value: isOnboardingPage ? 150 : 130,
  );

  late final Animation<double> transitionAnimation = CurvedAnimation(
    parent: transitionController,
    curve: Curves.easeInOutQuart,
  );

  late final Animation<double> waveAnimation = CurvedAnimation(
    parent: waveController,
    curve: Curves.linear,
  );

  bool transitionDirection = false;

  bool get isHomePage => widget.state.location == '/home';

  bool get isChatPage => widget.state.location == '/chat';

  bool get isOnboardingPage => widget.state.location.startsWith('/onboarding');

  bool get isSettingsPage => widget.state.location == '/settings';

  bool isTransitioning() =>
      transitionController.status != AnimationStatus.completed &&
      transitionController.status != AnimationStatus.dismissed;

  @override
  void didUpdateWidget(covariant NavigationBackground oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.state == oldWidget.state) return;

    transitionController
      ..reset()
      ..forward();

    if (isChatPage) {
      rotationController.animateTo(
        230,
        curve: Curves.easeInOutQuart,
        duration: const Duration(seconds: 1),
      );
    } else if (isSettingsPage) {
      rotationController.animateTo(
        20,
        curve: Curves.easeInOutQuart,
        duration: const Duration(seconds: 1),
      );
    } else if (isOnboardingPage) {
      final bool isStep1 = widget.state.location == '/onboarding/one';
      final bool isStep2 = widget.state.location == '/onboarding/two';
      rotationController.animateTo(
        isStep1
            ? 150
            : isStep2
                ? 230
                : 300,
        curve: Curves.easeInOutQuart,
        duration: const Duration(seconds: 1),
      );
    } else {
      rotationController.animateTo(
        130,
        curve: Curves.easeInOutQuart,
        duration: const Duration(seconds: 1),
      );
    }
  }

  void transitionListener() {
    if (isTransitioning()) {
      // [0, 1]
      final time = transitionAnimation.value;

      // [-1, 0, 1]
      final normalizedTime = time * 2 - 1;

      // [1, 0, 1]
      final vTime = normalizedTime.abs();

      // [0, 1, 0]
      final reversedTime = 1 - vTime;

      waveController.value = (waveController.value + (reversedTime / 90)) % 1;
    } else {
      waveController.repeat(reverse: true);
    }
  }

  @override
  void initState() {
    super.initState();

    transitionAnimation.addListener(transitionListener);
  }

  @override
  void dispose() {
    transitionAnimation.removeListener(transitionListener);
    transitionController.dispose();
    waveController.dispose();
    rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorScheme.background,
      child: Stack(
        children: [
          Positioned(
            top: -500,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/app_logo.png',
              width: 1000,
              height: 1000,
              color: context.colorScheme.surfaceVariant.withOpacity(0.1),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: rotationController,
              builder: (BuildContext context, Widget? child) {
                return AnimatedBuilder(
                  animation: waveAnimation,
                  builder: (context, child) {
                    final primary = context.colorScheme.primary;
                    final secondary = context.colorScheme.primaryContainer;
                    final overlay = context.colorScheme.background;
                    final double rot = rotationController.value;
                    return WaveBackground(
                      duration: const Duration(milliseconds: 10),
                      waves: [
                        Wave(
                          intensity: 10,
                          frequency: 50,
                          gravity: 65,
                          rotation: (pi / 180) * (rot + 20),
                          startColor: primary,
                          endColor: secondary,
                        ),
                        Wave(
                          intensity: 20,
                          frequency: 20,
                          gravity: 60,
                          rotation: (pi / 180) * (rot),
                          startColor: secondary,
                          endColor: primary,
                          reverseDirection: true,
                        ),
                        Wave(
                          intensity: 15,
                          frequency: 30,
                          gravity: 30,
                          rotation: (pi / 180) * (rot + 15),
                          startColor: primary,
                          endColor: secondary,
                        ),
                        Wave(
                          intensity: 20,
                          frequency: 40,
                          gravity: 10,
                          rotation: (pi / 180) * (rot + 20),
                          startColor: secondary,
                          endColor: overlay,
                          reverseDirection: true,
                        ),
                      ],
                      waveMotion: waveAnimation.value * 2 - 1,
                    );
                  },
                );
              },
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}
