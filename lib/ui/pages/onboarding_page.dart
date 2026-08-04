import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controller/settings_controller.dart';
import '../../core/broken_icons.dart';
import '../dialogs/color_picker_dialog.dart';
import '../dialogs/language_dialog.dart';
import '../dialogs/library_tabs_dialog.dart';
import '../dialogs/performance_dialog.dart';
import '../dialogs/theme_dialog.dart';
import '../widgets/animated_check_mark.dart';
import '../widgets/settings_tile.dart';
import 'main_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding(SettingsController settings) {
    settings.completeOnboarding();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const MainPage(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [
                    _AppearancePage(settings: settings),
                    _PermissionsPage(settings: settings),
                    _LibraryPage(settings: settings),
                  ],
                ),
              ),
              _DotIndicators(current: _currentPage, total: 3),
              const SizedBox(height: 8.0),
              _ActionBottomBar(
                currentPage: _currentPage,
                hasPermission: settings.hasStoragePermission,
                onContinue: _nextPage,
                onGrantPermission: () => settings.setStoragePermission(true),
                onDone: () => _completeOnboarding(settings),
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 1: Appearance
// ---------------------------------------------------------------------------

class _AppearancePage extends StatelessWidget {
  final SettingsController settings;
  const _AppearancePage({required this.settings});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      children: [
        const _PageHeader(
          icon: Broken.brush,
          title: 'Appearance',
          subtitle: 'Customize your experience',
        ),
        const SizedBox(height: 16.0),
        SettingsTile(
          icon: Broken.paintbucket,
          title: 'Accent Color',
          subtitle: 'Customize',
          onTap: () => showColorPickerDialog(context, settings),
        ),
        SettingsTile(
          icon: Broken.brush,
          title: 'Theme',
          subtitle: _themeModeText(settings.themeMode),
          onTap: () => showThemeDialog(context, settings),
        ),
        SettingsTile(
          icon: Broken.moon,
          title: 'AMOLED Black',
          subtitle: 'Pure black background',
          type: SettingsTileType.toggle,
          value: settings.useAmoledBlack,
          onChanged: settings.setUseAmoledBlack,
        ),
        SettingsTile(
          icon: Broken.language_square,
          title: 'Language',
          subtitle: settings.languageCode == 'es' ? 'Español' : 'English',
          onTap: () => showLanguageDialog(context, settings),
        ),
        SettingsTile(
          icon: Broken.command_square,
          title: 'Border Radius',
          subtitle: '${settings.borderRadiusMultiplier.toStringAsFixed(1)}x',
          trailing: SizedBox(
            width: 120.0,
            child: Slider(
              value: settings.borderRadiusMultiplier,
              min: 0.0,
              max: 2.0,
              divisions: 20,
              onChanged: settings.setBorderRadiusMultiplier,
            ),
          ),
        ),
        SettingsTile(
          icon: Broken.color_swatch,
          title: 'Library Tabs',
          subtitle: '${settings.libraryTabs.length} active',
          onTap: () => showLibraryTabsDialog(context, settings),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Page 2: Permissions
// ---------------------------------------------------------------------------

class _PermissionsPage extends StatelessWidget {
  final SettingsController settings;
  const _PermissionsPage({required this.settings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPermission = settings.hasStoragePermission;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      children: [
        const _PageHeader(
          icon: Broken.shield_cross,
          title: 'Permissions',
          subtitle: 'Grant access to your music',
        ),
        const SizedBox(height: 16.0),
        ListTile(
          leading: Icon(
            hasPermission ? Broken.tick_circle : Broken.folder_open,
            size: 18.0,
          ),
          title: Text(
            hasPermission ? 'Storage Granted' : 'Grant Storage Access',
            style: theme.textTheme.bodyMedium,
          ),
          subtitle: Text(
            hasPermission
                ? 'Arc can access your music files'
                : 'Required to scan and play music',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: AnimatedCheckMark(size: 20.0, active: hasPermission),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4.0,
            vertical: 2.0,
          ),
          visualDensity: const VisualDensity(vertical: -4),
        ),
        SettingsTile(
          icon: Broken.global,
          title: 'Language',
          subtitle: settings.languageCode == 'es' ? 'Español' : 'English',
          onTap: () => showLanguageDialog(context, settings),
        ),
        SettingsTile(
          icon: Broken.speedometer,
          title: 'Performance Mode',
          subtitle: _performanceModeText(settings.performanceMode),
          onTap: () => showPerformanceDialog(context, settings),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Page 3: Library
// ---------------------------------------------------------------------------

class _LibraryPage extends StatelessWidget {
  final SettingsController settings;
  const _LibraryPage({required this.settings});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      children: [
        const _PageHeader(
          icon: Broken.folder,
          title: 'Library',
          subtitle: 'Configure your music folders',
        ),
        const SizedBox(height: 16.0),
        SettingsTile(
          icon: Broken.video,
          title: 'Include Videos',
          subtitle: 'Index video files too',
          type: SettingsTileType.toggle,
          value: settings.includeVideos,
          onChanged: settings.setIncludeVideos,
        ),
        SettingsTile(
          icon: Broken.folder_open,
          title: 'Add Folder',
          subtitle: 'Select music folders',
        ),
        SettingsTile(
          icon: Broken.folder,
          title: 'Folders to Scan',
          subtitle: '${settings.foldersToScan.length} folders',
          type: SettingsTileType.expansion,
          expandedChild: _buildFolderList(
            context,
            settings.foldersToScan,
            settings.removeFolderToScan,
          ),
        ),
        SettingsTile(
          icon: Broken.folder_cross,
          title: 'Excluded Folders',
          subtitle: '${settings.foldersToExclude.length} folders',
          type: SettingsTileType.expansion,
          expandedChild: _buildFolderList(
            context,
            settings.foldersToExclude,
            settings.removeFolderToExclude,
          ),
        ),
        SettingsTile(
          icon: Broken.mobile,
          title: 'Media Store',
          subtitle: 'Use Android MediaStore',
          type: SettingsTileType.toggle,
          value: settings.useMediaStore,
          onChanged: settings.setUseMediaStore,
        ),
        SettingsTile(
          icon: Broken.image,
          title: 'Artwork Cache',
          subtitle: '${settings.artworkCacheSize}px',
        ),
        SettingsTile(
          icon: Broken.cpu_setting,
          title: 'Performance Mode',
          subtitle: _performanceModeText(settings.performanceMode),
          onTap: () => showPerformanceDialog(context, settings),
        ),
        SettingsTile(
          icon: Broken.color_swatch,
          title: 'Library Tabs',
          subtitle: settings.libraryTabs.join(', '),
          onTap: () => showLibraryTabsDialog(context, settings),
        ),
        SettingsTile(
          icon: Broken.search_normal,
          title: 'FAB Type',
          subtitle: _fabTypeText(settings.fabType),
          onTap: () => _showFabTypeDialog(context, settings),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _PageHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PageHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: 24.0),
        Container(
          width: 64.0,
          height: 64.0,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withAlpha(60),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32.0, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 16.0),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DotIndicators extends StatelessWidget {
  final int current;
  final int total;

  const _DotIndicators({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          width: isActive ? 8.0 : 6.0,
          height: isActive ? 8.0 : 6.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant.withAlpha(100),
          ),
        );
      }),
    );
  }
}

class _ActionBottomBar extends StatelessWidget {
  final int currentPage;
  final bool hasPermission;
  final VoidCallback onContinue;
  final VoidCallback onGrantPermission;
  final VoidCallback onDone;

  const _ActionBottomBar({
    required this.currentPage,
    required this.hasPermission,
    required this.onContinue,
    required this.onGrantPermission,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (currentPage == 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          child: InkWell(
            borderRadius: BorderRadius.circular(12.0),
            onTap: onDone,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 14.0,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Broken.tick_circle,
                    size: 18.0,
                    color: theme.colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'Done',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (currentPage == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.0),
                  onTap: hasPermission ? null : onGrantPermission,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: hasPermission
                          ? Colors.green.withAlpha(20)
                          : theme.colorScheme.primaryContainer.withAlpha(100),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        width: 1.0,
                        color: hasPermission
                            ? Colors.green.withAlpha(60)
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedCheckMark(size: 16.0, active: hasPermission),
                        const SizedBox(width: 8.0),
                        Text(
                          hasPermission ? 'Granted' : 'Grant Access',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: hasPermission ? 1.0 : 0.4,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.0),
                  onTap: hasPermission ? onContinue : null,
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: hasPermission
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(
                      Broken.arrow_right,
                      size: 18.0,
                      color: hasPermission
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Page 0: simple Continue button
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: onContinue,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 14.0,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8.0),
                Icon(
                  Broken.arrow_right,
                  size: 18.0,
                  color: theme.colorScheme.onPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _themeModeText(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return 'System';
    case ThemeMode.light:
      return 'Light';
    case ThemeMode.dark:
      return 'Dark';
  }
}

String _performanceModeText(PerformanceMode mode) {
  switch (mode) {
    case PerformanceMode.off:
      return 'Off';
    case PerformanceMode.powerSaving:
      return 'Power Saving';
    case PerformanceMode.limit80:
      return 'Balanced (80%)';
  }
}

String _fabTypeText(String type) {
  switch (type) {
    case 'search':
      return 'Search';
    case 'play':
      return 'Play';
    case 'shuffle':
      return 'Shuffle';
    default:
      return 'Search';
  }
}

void _showFabTypeDialog(BuildContext context, SettingsController settings) {
  final theme = Theme.of(context);
  final options = [
    _FabOption('search', Broken.search_normal, 'Search'),
    _FabOption('play', Broken.play, 'Play'),
    _FabOption('shuffle', Broken.shuffle, 'Shuffle'),
  ];

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'FAB Type',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1.0,
        ),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
      contentPadding: const EdgeInsets.all(20.0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = settings.fabType == opt.type;
          return ListTile(
            leading: Icon(
              opt.icon,
              size: 18.0,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(
              opt.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            trailing: isSelected
                ? Icon(
                    Broken.tick_circle,
                    size: 18.0,
                    color: theme.colorScheme.primary,
                  )
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            onTap: () {
              settings.setFabType(opt.type);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    ),
  );
}

class _FabOption {
  final String type;
  final IconData icon;
  final String label;

  const _FabOption(this.type, this.icon, this.label);
}

Widget _buildFolderList(
  BuildContext context,
  List<String> folders,
  Function(String) onRemove,
) {
  final theme = Theme.of(context);

  if (folders.isEmpty) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        'No folders configured',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  return Column(
    children: folders
        .map(
          (folder) => ListTile(
            leading: Icon(
              Broken.folder,
              size: 16.0,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(
              folder.split('/').last,
              style: theme.textTheme.bodySmall,
            ),
            subtitle: Text(
              folder,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Broken.close_square,
                size: 14.0,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: () => onRemove(folder),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            dense: true,
            visualDensity: const VisualDensity(vertical: -4),
          ),
        )
        .toList(),
  );
}
