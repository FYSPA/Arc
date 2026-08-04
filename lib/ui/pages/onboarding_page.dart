import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controller/settings_controller.dart';
import '../../core/broken_icons.dart';
import '../../core/dimensions.dart';
import '../dialogs/backup_restore_dialog.dart';
import '../dialogs/color_picker_dialog.dart';
import '../dialogs/performance_dialog.dart';
import '../dialogs/theme_dialog.dart';
import '../widgets/section_header.dart';
import '../widgets/settings/onboarding_bottom_bar.dart';
import '../widgets/settings_card.dart';
import '../widgets/settings_tile.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

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
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.settingsHorizontalMargin,
            ),
            child: SettingsCard(
              icon: Broken.moon,
              title: 'Configurar',
              subtitle: 'Preparar para el primer inicio',
              trailing: IconButton(
                tooltip: 'Restaurar backup',
                icon: const Icon(Broken.document_upload, size: 18.0),
                onPressed: () => showBackupRestoreDialog(context),
              ),
              child: Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 2.0,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            const SectionHeader(title: 'Appearance'),
                            SettingsTile(
                              icon: Broken.paintbucket,
                              title: 'Accent Color',
                              subtitle: 'Customize',
                              onTap: () =>
                                  showColorPickerDialog(context, settings),
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
                              icon: Broken.global,
                              title: 'Language',
                              subtitle: settings.languageCode == 'es'
                                  ? 'Español'
                                  : 'English',
                            ),
                            const SectionHeader(title: 'Performance'),
                            SettingsTile(
                              icon: Broken.speedometer,
                              title: 'Performance Mode',
                              subtitle: _performanceModeText(
                                settings.performanceMode,
                              ),
                              onTap: () =>
                                  showPerformanceDialog(context, settings),
                            ),
                            SettingsTile(
                              icon: Broken.element_plus,
                              title: 'Library Tabs',
                              subtitle: '${settings.libraryTabs.length} tabs',
                            ),
                            const SectionHeader(title: 'Library'),
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
                              subtitle:
                                  '${settings.foldersToScan.length} folders',
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
                              subtitle:
                                  '${settings.foldersToExclude.length} folders',
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
                            const SectionHeader(title: 'Cache'),
                            SettingsTile(
                              icon: Broken.image,
                              title: 'Artwork Cache',
                              subtitle: '${settings.artworkCacheSize}px',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      OnboardingBottomBar(
                        settings: settings,
                        onGrantPermission: () =>
                            settings.setStoragePermission(true),
                        onContinue: () {
                          settings.completeOnboarding();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

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
        return 'Limit 80%';
    }
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
}
