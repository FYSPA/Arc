import 'package:flutter/material.dart';

import '../../../controller/settings_controller.dart';
import '../../../core/broken_icons.dart';
import '../../dialogs/library_tabs_dialog.dart';
import '../../dialogs/performance_dialog.dart';
import '../../widgets/onboarding_page_header.dart';
import '../../widgets/settings_tile.dart';

class OnboardingLibraryPage extends StatelessWidget {
  final SettingsController settings;
  const OnboardingLibraryPage({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      children: [
        const OnboardingPageHeader(
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
