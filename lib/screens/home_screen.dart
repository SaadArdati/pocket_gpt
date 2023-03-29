import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../constants.dart';
import '../gpt_manager.dart';
import '../system_manager.dart';
import '../theme_extensions.dart';
import '../versioning.dart';

bool didCheckForUpdates = false;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    runUpdateCheck();
  }

  Future<void> runUpdateCheck() async {
    final box = Hive.box(Constants.settings);
    if (!box.get(Constants.checkForUpdates, defaultValue: true)) return;

    if (!didCheckForUpdates) {
      didCheckForUpdates = true;
    } else {
      return;
    }
    final Version? latestVersion = await getLatestRelease();

    if (latestVersion == null) return;

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = Version.parse(packageInfo.version);

    // enable this for testing update UI.
    // final latestVersion = Version(1, 0, 1);

    if (latestVersion > currentVersion) {
      showUpdateAvailableUI(latestVersion);
    }
  }

  void showUpdateAvailableUI(Version latestVersion) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'A new version is available!',
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onInverseSurface,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 34),
        showCloseIcon: true,
        duration: const Duration(days: 1),
        backgroundColor: context.colorScheme.inverseSurface,
        action: SnackBarAction(
          label: 'Download',
          textColor: context.colorScheme.inversePrimary,
          onPressed: () {
            launchUrlString(
                'https://github.com/SaadArdati/pocket_gpt/releases/$latestVersion');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = defaultTargetPlatform;
    final bool isDesktop = !kIsWeb &&
        (platform == TargetPlatform.windows ||
            platform == TargetPlatform.linux ||
            platform == TargetPlatform.macOS);
    return Scaffold(
      appBar: AppBar(
        title: const Text('PocketGPT'),
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings),
          onPressed: () {
            context.go('/settings', extra: {'from': 'home'});
          },
        ),
        actions: [
          if (isDesktop) ...[
            IconButton(
              tooltip: 'Toggle window bounds',
              icon: const Icon(Icons.photo_size_select_small),
              onPressed: SystemManager.instance.toggleWindowMemory,
            ),
            IconButton(
              tooltip: 'Minimize',
              icon: const Icon(Icons.minimize),
              onPressed: SystemManager.instance.closeWindow,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              runAlignment: WrapAlignment.center,
              alignment: WrapAlignment.center,
              children: [
                ...ChatType.values.map((type) {
                  final bool isComingSoon;
                  switch (type) {
                    case ChatType.general:
                    case ChatType.email:
                    case ChatType.documentCode:
                      isComingSoon = false;
                      break;
                    case ChatType.scientific:
                    case ChatType.analyze:
                    case ChatType.readMe:
                      isComingSoon = true;
                      break;
                  }
                  return GPTCard(
                    type: type,
                    isComingSoon: isComingSoon,
                  );
                })
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GPTCard extends StatelessWidget {
  final ChatType type;
  final bool isComingSoon;

  const GPTCard({
    super.key,
    required this.type,
    this.isComingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,
      height: 175,
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
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              splashColor: context.colorScheme.tertiaryContainer,
              highlightColor: context.colorScheme.secondaryContainer,
              onTap: isComingSoon
                  ? null
                  : () => context
                      .go('/chat', extra: {'type': type.name, 'from': '/home'}),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      type.icon,
                      color: context.colorScheme.tertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      type.label,
                      style: context.textTheme.bodyMedium!.copyWith(
                        color: context.colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type.caption,
                      style: context.textTheme.bodySmall!.copyWith(
                        color: context.colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isComingSoon)
            Center(
              child: Transform.rotate(
                angle: -35 * pi / 180,
                child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: context.colorScheme.inverseSurface,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Coming Soon',
                      style: context.textTheme.bodyMedium!.copyWith(
                        color: context.colorScheme.onInverseSurface,
                      ),
                    )),
              ),
            )
        ],
      ),
    );
  }
}
