import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:dart_openai/openai.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:universal_io/io.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:window_manager/window_manager.dart';

import 'constants.dart';
import 'managers/navigation_manager.dart';
import 'managers/system_manager.dart';
import 'ui/color_schemes.g.dart';
import 'ui/theme_extensions.dart';
import 'ui/wave_background.dart';

void main() async {
  await initPocketGPT();
  final mode = await AdaptiveTheme.getThemeMode() ?? AdaptiveThemeMode.system;
  runApp(PocketGPT(mode: mode));
}

Future<bool> initPocketGPT() async {
  await Hive.initFlutter('PocketGPT');
  await Hive.openBox(Constants.history);

  final EncryptedSharedPreferences encryptedPrefs =
      EncryptedSharedPreferences();
  String key = await encryptedPrefs.getString(Constants.encryptionKey);
  final List<int> encryptionKeyData;
  if (key.isEmpty) {
    log('Generating a new encryption key');
    encryptionKeyData = Hive.generateSecureKey();
    log('Saving the encryption key');
    await encryptedPrefs.setString(
      Constants.encryptionKey,
      base64UrlEncode(encryptionKeyData),
    );
  } else {
    log('Found an existing encryption key');
    encryptionKeyData = base64Url.decode(key);
  }
  log('Encryption key: $key');

  await Hive.openBox(
    Constants.settings,
    encryptionCipher: HiveAesCipher(encryptionKeyData),
  );

  if (!kIsWeb) {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await SystemManager.instance.init();

      final box = Hive.box(Constants.settings);
      if (box.get(Constants.launchOnStartup, defaultValue: true)) {
        final packageInfo = await PackageInfo.fromPlatform();
        LaunchAtStartup.instance.setup(
          appName: packageInfo.appName,
          appPath: Platform.resolvedExecutable,
        );
        await LaunchAtStartup.instance.enable();
      }
    }
    setPathUrlStrategy();
  }

  OpenAI.apiKey =
      Hive.box(Constants.settings).get(Constants.openAIKey, defaultValue: '');

  return true;
}

class PocketGPT extends StatefulWidget {
  final AdaptiveThemeMode mode;

  const PocketGPT({super.key, required this.mode});

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
    SystemManager.instance.dispose();
    super.dispose();
  }

  @override
  void onWindowFocus() {
    // Make sure to call once.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top]);
    return AdaptiveTheme(
      light: ThemeData(
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
      dark: ThemeData(
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
      initial: widget.mode,
      builder: (theme, darkTheme) {
        return MaterialApp.router(
          title: 'PocketGPT',
          debugShowCheckedModeBanner: false,
          theme: theme,
          darkTheme: darkTheme,
          routerConfig: NavigationManager.instance.router,
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

  late final AnimationController logoController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..forward();

  late final Animation<double> transitionAnimation = CurvedAnimation(
    parent: transitionController,
    curve: Curves.easeInOutQuart,
  );

  late final Animation<double> waveAnimation = CurvedAnimation(
    parent: waveController,
    curve: Curves.linear,
  );

  late final Animation<double> logoAnimation = CurvedAnimation(
    parent: logoController,
    curve: Curves.easeInOutQuart,
  );

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
    logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorScheme.background,
      child: LayoutBuilder(builder: (context, constraints) {
        final double bestFit = constraints.biggest.shortestSide;
        return Stack(
          children: [
            AnimatedBuilder(
              animation: logoAnimation,
              builder: (context, child) {
                return Positioned(
                  top: (constraints.biggest.height / 2) *
                          (1 - logoAnimation.value) +
                      -bestFit / 2 * logoAnimation.value,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    'assets/app_logo_1000x.png',
                    width: 56 + (bestFit - 56) * logoAnimation.value,
                    height: 56 + (bestFit - 56) * logoAnimation.value,
                    color: Color.lerp(
                      context.colorScheme.onBackground,
                      context.colorScheme.surfaceVariant.withOpacity(0.5),
                      logoAnimation.value,
                    ),
                  ),
                );
              },
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
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.fastOutSlowIn,
                color: context.colorScheme.background.withOpacity(
                  isChatPage ? 0.8 : 0.5,
                ),
              ),
            ),
            widget.child,
          ],
        );
      }),
    );
  }
}
