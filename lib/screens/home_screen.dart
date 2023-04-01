import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../constants.dart';
import '../managers/version_manager.dart';
import '../models/chat_type.dart';
import '../ui/theme_extensions.dart';
import '../ui/window_controls.dart';

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
    final Version? latestVersion =
        await VersionManager.instance.getLatestRelease();

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
                'https://github.com/SaadArdati/pocketgpt/releases/$latestVersion');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PocketGPT',
          style: context.textTheme.titleMedium,
        ),
        centerTitle: false,
        leading: IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings),
          onPressed: () {
            context.go('/settings', extra: {'from': 'home'});
          },
        ),
        actions: const [WindowControls()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: LayoutBuilder(builder: (context, constraints) {
              final int crossAxisCount;

              if (constraints.maxWidth <= 500) {
                crossAxisCount = 2;
              } else if (constraints.maxWidth <= 700) {
                crossAxisCount = 3;
              } else {
                crossAxisCount = 4;
              }

              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                ),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: ChatType.values.length,
                itemBuilder: (context, index) {
                  final type = ChatType.values[index];
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
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GPTCard(
                      type: type,
                      isComingSoon: isComingSoon,
                    ),
                  );
                },
              );
            }),
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
