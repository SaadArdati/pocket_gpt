import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:window_manager/window_manager.dart';

import '../gpt_manager.dart';
import '../system_manager.dart';
import '../theme_extensions.dart';
import '../versioning.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    checkForUpdates();
  }

  Future<void> checkForUpdates() async {
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
                'https://github.com/SwissCheese5/pocket_gpt/releases/$latestVersion');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = Theme.of(context).platform;
    final bool isDesktop = platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux ||
        platform == TargetPlatform.macOS;
    return Scaffold(
      appBar: AppBar(
        title: const Text('System GPT'),
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings),
          onPressed: () {
            context.go('/settings');
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
      body: Center(
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          runAlignment: WrapAlignment.center,
          alignment: WrapAlignment.center,
          children: [...ChatType.values.map((type) => GPTCard(type: type))],
        ),
      ),
    );
  }
}

class GPTCard extends StatelessWidget {
  final ChatType type;

  const GPTCard({
    super.key,
    required this.type,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: context.colorScheme.tertiaryContainer,
          highlightColor: context.colorScheme.secondaryContainer,
          onTap: () => context.go('/chat', extra: {'type': type.name}),
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
    );
  }
}
