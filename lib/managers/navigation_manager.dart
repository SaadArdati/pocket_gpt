import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../constants.dart';
import '../main.dart';
import '../models/chat_type.dart';
import '../screens/chat_screen.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/open_ai_key_screen.dart';
import '../screens/settings_screen.dart';
import '../ui/window_drag_handle.dart';

class NavigationManager {
  NavigationManager._();

  static final NavigationManager _instance = NavigationManager._();

  static NavigationManager get instance => _instance;

  factory NavigationManager() => _instance;

  final box = Hive.box(Constants.settings);

  late final router = GoRouter(
    // initialLocation: '/onboarding',
    initialLocation: box.get(Constants.isFirstTime, defaultValue: true)
        ? '/onboarding'
        : '/home',
    routes: [baseRoute],
  );

  late final baseRoute = ShellRoute(
    builder: (context, GoRouterState state, child) {
      return WindowDragHandle(
          child: NavigationBackground(state: state, child: child));
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
                      return pocketGPTTransition(
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
                      return pocketGPTTransition(
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
                      return pocketGPTTransition(
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
                routes: [
                  GoRoute(
                    path: 'tray_position',
                    builder: (context, state) {
                      final extras = state.extra;
                      final String id = extras != null && extras is Map
                          ? extras['instructionID']
                          : '';

                      return InstructionView(instructionID: id);
                    },
                  ),
                ],
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
            if (fromParam == 'chat') {
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
              return pocketGPTTransition(
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
              return pocketGPTTransition(
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
              return pocketGPTTransition(
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
  );

  Widget pocketGPTTransition(
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
}
