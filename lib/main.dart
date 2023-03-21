import 'dart:io';
import 'dart:math';

import 'package:dart_openai/openai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_strategy/url_strategy.dart';
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
  await Hive.initFlutter();
  await Hive.openBox(history);
  await Hive.openBox(settings);

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await SystemManager.init();
  }
  setPathUrlStrategy();

  OpenAI.apiKey = Hive.box(settings).get(openAIKey, defaultValue: '');

  runApp(const PocketGPT());
}

Widget defaultPageTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child, {
  required GoRouterState state,
  required AxisDirection comesFrom,
}) {
  return SlideTransition(
    position: CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.linearToEaseOut,
      reverseCurve: Curves.easeInToLinear,
    ).drive(
      Tween<Offset>(
        begin: Offset.zero,
        end: comesFrom == AxisDirection.up || comesFrom == AxisDirection.down
            ? Offset(0.0, comesFrom == AxisDirection.up ? -1 : 1)
            : Offset(comesFrom == AxisDirection.left ? -1 : 1, 0.0),
      ),
    ),
    transformHitTests: false,
    child: SlideTransition(
      position: CurvedAnimation(
        parent: animation,
        curve: Curves.linearToEaseOut,
        reverseCurve: Curves.easeInToLinear,
      ).drive(
        Tween<Offset>(
          begin:
              comesFrom == AxisDirection.up || comesFrom == AxisDirection.down
                  ? Offset(0.0, comesFrom == AxisDirection.up ? -1 : 1)
                  : Offset(comesFrom == AxisDirection.left ? -1 : 1, 0.0),
          end: Offset.zero,
        ),
      ),
      child: child,
    ),
  );
}

ThemeMode getThemeMode() {
  final box = Hive.box(settings);
  switch (box.get(themeMode, defaultValue: 'system')) {
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
    // initialLocation: '/onboarding',
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
                    pageBuilder: (context, state) {
                      return CustomTransitionPage(
                        key: state.pageKey,
                        child: const OnboardingWelcome(),
                        opaque: false,
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          return defaultPageTransition(
                            context,
                            animation,
                            secondaryAnimation,
                            child,
                            state: state,
                            comesFrom: AxisDirection.right,
                          );
                        },
                      );
                    },
                  ),
                  GoRoute(
                    path: 'two',
                    pageBuilder: (context, state) {
                      return CustomTransitionPage(
                        key: state.pageKey,
                        child: const OpenAIKeyScreen(),
                        opaque: false,
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          return defaultPageTransition(
                            context,
                            animation,
                            secondaryAnimation,
                            child,
                            state: state,
                            comesFrom: AxisDirection.right,
                          );
                        },
                      );
                    },
                  ),
                  GoRoute(
                    path: 'three',
                    pageBuilder: (context, state) {
                      return CustomTransitionPage(
                        key: state.pageKey,
                        child: const OnboardingDone(),
                        opaque: false,
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          return defaultPageTransition(
                            context,
                            animation,
                            secondaryAnimation,
                            child,
                            state: state,
                            comesFrom: AxisDirection.right,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
            pageBuilder: (context, state) {
              final extra = state.extra;
              AxisDirection comesFrom = AxisDirection.down;
              if (extra != null && extra is Map) {
                final String? fromParam = extra['from'];
                if (fromParam == '/chat') {
                  comesFrom = AxisDirection.up;
                }
              }

              return CustomTransitionPage(
                key: state.pageKey,
                child: const HomeScreen(),
                opaque: false,
                transitionDuration: const Duration(milliseconds: 600),
                reverseTransitionDuration: const Duration(milliseconds: 600),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return defaultPageTransition(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                    state: state,
                    comesFrom: comesFrom,
                  );
                },
              );
            },
          ),
          GoRoute(
            path: '/chat',
            pageBuilder: (context, state) {
              final Widget child;
              final extra = state.extra;
              if (extra == null || extra is! Map) {
                child = const ChatScreenWrapper();
              } else {
                final String typeParam = extra['type'] ?? ChatType.general.name;
                final ChatType type = ChatType.values.firstWhere(
                  (chatType) => chatType.name == typeParam,
                );
                child = ChatScreenWrapper(type: type);
              }

              return CustomTransitionPage(
                key: state.pageKey,
                child: child,
                opaque: false,
                transitionDuration: const Duration(milliseconds: 600),
                reverseTransitionDuration: const Duration(milliseconds: 600),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return defaultPageTransition(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                    state: state,
                    comesFrom: AxisDirection.down,
                  );
                },
              );
            },
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
            pageBuilder: (context, state) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: const SettingsScreen(),
                opaque: false,
                transitionDuration: const Duration(milliseconds: 600),
                reverseTransitionDuration: const Duration(milliseconds: 600),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return defaultPageTransition(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                    state: state,
                    comesFrom: AxisDirection.up,
                  );
                },
              );
            },
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top]);
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
              systemOverlayStyle: SystemUiOverlayStyle(
                systemStatusBarContrastEnforced: false,
                systemNavigationBarContrastEnforced: false,
                systemNavigationBarColor: Colors.transparent,
                statusBarColor: Colors.transparent,
                systemNavigationBarIconBrightness: Brightness.dark,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkColorScheme,
            scaffoldBackgroundColor: Colors.transparent,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              systemOverlayStyle: SystemUiOverlayStyle(
                systemStatusBarContrastEnforced: false,
                systemNavigationBarContrastEnforced: false,
                systemNavigationBarColor: Colors.transparent,
                statusBarColor: Colors.transparent,
                systemNavigationBarIconBrightness: Brightness.dark,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
              ),
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
