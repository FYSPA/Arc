import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controller/settings_controller.dart';
import '../../core/broken_icons.dart';
import '../../core/enums.dart';
import '../../services/animated_artwork_service.dart';
import '../../services/artist_photo_service.dart';
import '../../services/artwork_service.dart';
import '../dialogs/color_picker_dialog.dart';
import '../dialogs/language_dialog.dart';
import '../dialogs/library_tabs_dialog.dart';
import '../dialogs/performance_dialog.dart';
import '../dialogs/theme_dialog.dart';
import '../widgets/settings_card.dart';
import '../widgets/settings_tile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ──── Apariencia ────
          _SectionHeader(icon: Broken.brush, label: 'Appearance'),
          const SizedBox(height: 8.0),
          SettingsCard(
            icon: Broken.brush,
            title: 'Appearance',
            subtitle: 'Theme, colors and visual style',
            child: Column(
              children: [
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
                if (settings.useAmoledBlack) ...[
                  SettingsTile(
                    icon: Broken.drop,
                    title: 'Glow Effect',
                    subtitle: 'Accent color ambient glow',
                    type: SettingsTileType.toggle,
                    value: settings.enableAmoledGlow,
                    onChanged: settings.setEnableAmoledGlow,
                  ),
                  if (settings.enableAmoledGlow) ...[
                    SettingsTile(
                      icon: Broken.sidebar_bottom,
                      title: 'Glow Position',
                      subtitle: _glowPositionsText(
                        settings.amoledGlowPositions,
                      ),
                      onTap: () => _showGlowPositionDialog(context, settings),
                    ),
                    SettingsTile(
                      icon: Broken.speedometer,
                      title: 'Glow Intensity',
                      subtitle:
                          '${(settings.amoledGlowIntensity * 100).round()}%',
                      trailing: SizedBox(
                        width: 120.0,
                        child: Slider(
                          value: settings.amoledGlowIntensity,
                          min: 0.0,
                          max: 1.0,
                          divisions: 20,
                          onChanged: settings.setAmoledGlowIntensity,
                        ),
                      ),
                    ),
                  ],
                ],
                SettingsTile(
                  icon: Broken.language_square,
                  title: 'Language',
                  subtitle: settings.languageCode == 'es'
                      ? 'Español'
                      : 'English',
                  onTap: () => showLanguageDialog(context, settings),
                ),
                SettingsTile(
                  icon: Broken.command_square,
                  title: 'Border Radius',
                  subtitle:
                      '${settings.borderRadiusMultiplier.toStringAsFixed(1)}x',
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
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // ──── Biblioteca ────
          _SectionHeader(icon: Broken.music_dashboard, label: 'Library'),
          const SizedBox(height: 8.0),
          SettingsCard(
            icon: Broken.music_dashboard,
            title: 'Library',
            subtitle: 'Tabs, folders and indexing',
            child: Column(
              children: [
                SettingsTile(
                  icon: Broken.color_swatch,
                  title: 'Library Tabs',
                  subtitle: '${settings.libraryTabs.length} active',
                  onTap: () => showLibraryTabsDialog(context, settings),
                ),
                SettingsTile(
                  icon: Broken.musicnote,
                  title: 'Default Tab',
                  subtitle: settings.defaultLibraryTab,
                  onTap: () => _showDefaultTabDialog(context, settings),
                ),
                SettingsTile(
                  icon: Broken.folder,
                  title: 'Folders to Scan',
                  subtitle: '${settings.foldersToScan.length} folders',
                  type: SettingsTileType.expansion,
                  expandedChild: _folderList(
                    context,
                    settings.foldersToScan,
                    settings.removeFolderToScan,
                  ),
                ),
                SettingsTile(
                  icon: Broken.eye_slash,
                  title: 'Folders to Exclude',
                  subtitle: '${settings.foldersToExclude.length} folders',
                  type: SettingsTileType.expansion,
                  expandedChild: _folderList(
                    context,
                    settings.foldersToExclude,
                    settings.removeFolderToExclude,
                  ),
                ),
                SettingsTile(
                  icon: Broken.eye,
                  title: 'Include Videos',
                  subtitle: 'Index video files',
                  type: SettingsTileType.toggle,
                  value: settings.includeVideos,
                  onChanged: settings.setIncludeVideos,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // ──── Audio ────
          _SectionHeader(icon: Broken.music_library_2, label: 'Audio'),
          const SizedBox(height: 8.0),
          SettingsCard(
            icon: Broken.music_library_2,
            title: 'Audio',
            subtitle: 'Performance and playback',
            child: Column(
              children: [
                SettingsTile(
                  icon: Broken.flash,
                  title: 'Performance Mode',
                  subtitle: _performanceModeText(settings.performanceMode),
                  onTap: () => showPerformanceDialog(context, settings),
                ),
                SettingsTile(
                  icon: Broken.image,
                  title: 'Clear Artwork Cache',
                  subtitle: 'Refresh artwork from source',
                  onTap: () => _clearArtworkCache(context),
                ),
                SettingsTile(
                  icon: Broken.play_circle,
                  title: 'Animated Artwork',
                  subtitle: 'Auto-play animated covers in player',
                  type: SettingsTileType.toggle,
                  value: settings.enableAnimatedArtwork,
                  onChanged: settings.setEnableAnimatedArtwork,
                ),
                SettingsTile(
                  icon: Broken.video,
                  title: 'Spotify Canvas (fondo)',
                  subtitle: 'Video de Spotify de fondo en el player completo',
                  type: SettingsTileType.toggle,
                  value: settings.enableSpotifyCanvas,
                  onChanged: settings.setEnableSpotifyCanvas,
                ),
                SettingsTile(
                  icon: Broken.brush,
                  title: 'Tinte del cristal',
                  subtitle: settings.canvasGlassTint == CanvasGlassTint.neutral
                      ? 'Gris neutro'
                      : 'Color de la carátula',
                  trailing: SegmentedButton<CanvasGlassTint>(
                    selected: {settings.canvasGlassTint},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) =>
                        settings.setCanvasGlassTint(selection.first),
                    segments: const [
                      ButtonSegment(
                        value: CanvasGlassTint.neutral,
                        label: Text('Neutro'),
                      ),
                      ButtonSegment(
                        value: CanvasGlassTint.accent,
                        label: Text('Carátula'),
                      ),
                    ],
                  ),
                ),
                SettingsTile(
                  icon: Broken.command_square,
                  title: 'Artwork Size',
                  subtitle: '${settings.artworkSize.round()}px',
                  trailing: SizedBox(
                    width: 210.0,
                    child: Slider(
                      value: settings.artworkSize,
                      min: 280.0,
                      max: 460.0,
                      divisions: 14,
                      onChanged: settings.setArtworkSize,
                    ),
                  ),
                ),
                SettingsTile(
                  icon: Broken.image,
                  title: 'Calidad de carátula',
                  subtitle: 'Resolución en listas (player usa alta siempre)',
                  trailing: SegmentedButton<ArtworkQuality>(
                    selected: {settings.artworkQuality},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) =>
                        settings.setArtworkQuality(selection.first),
                    segments: const [
                      ButtonSegment(
                        value: ArtworkQuality.low,
                        label: Text('Baja'),
                      ),
                      ButtonSegment(
                        value: ArtworkQuality.medium,
                        label: Text('Media'),
                      ),
                      ButtonSegment(
                        value: ArtworkQuality.high,
                        label: Text('Alta'),
                      ),
                    ],
                  ),
                ),
                SettingsTile(
                  icon: Broken.command,
                  title: 'FAB Action',
                  subtitle: _fabTypeText(settings.fabType),
                  onTap: () => _showFabTypeDialog(context, settings),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // ──── Secrets Keys ────
          _SectionHeader(icon: Broken.key, label: 'Secrets Keys'),
          const SizedBox(height: 8.0),
          SettingsCard(
            icon: Broken.key,
            title: 'API Keys',
            subtitle: 'Configure Arx Canvas providers',
            child: Column(
              children: [
                SettingsTile(
                  icon: Broken.music_dashboard,
                  title: 'Spotify',
                  subtitle: settings.spotifyClientId != null
                      ? 'Configured'
                      : 'Not configured',
                  onTap: () => _showSpotifyKeysDialog(context, settings),
                ),
                SettingsTile(
                  icon: Broken.document_code,
                  title: 'Genius',
                  subtitle: settings.geniusAccessToken != null
                      ? 'Configured'
                      : 'Not configured',
                  onTap: () => _showSingleKeyDialog(
                    context,
                    title: 'Genius Access Token',
                    value: settings.geniusAccessToken,
                    onChanged: settings.setGeniusAccessToken,
                  ),
                ),
                SettingsTile(
                  icon: Broken.musicnote,
                  title: 'Musixmatch',
                  subtitle: settings.musixmatchApiKey != null
                      ? 'Configured'
                      : 'Not configured',
                  onTap: () => _showSingleKeyDialog(
                    context,
                    title: 'Musixmatch API Key',
                    value: settings.musixmatchApiKey,
                    onChanged: settings.setMusixmatchApiKey,
                  ),
                ),
                SettingsTile(
                  icon: Broken.link,
                  title: 'MusicLink 1',
                  subtitle: settings.musiclinkApiKey != null
                      ? 'Key 1 configured'
                      : 'Not configured',
                  onTap: () => _showSingleKeyDialog(
                    context,
                    title: 'MusicLink API Key 1',
                    value: settings.musiclinkApiKey,
                    onChanged: settings.setMusiclinkApiKey,
                  ),
                ),
                SettingsTile(
                  icon: Broken.link,
                  title: 'MusicLink 2',
                  subtitle: settings.musiclinkApiKey2 != null
                      ? 'Key 2 configured'
                      : 'Not configured',
                  onTap: () => _showSingleKeyDialog(
                    context,
                    title: 'MusicLink API Key 2',
                    value: settings.musiclinkApiKey2,
                    onChanged: settings.setMusiclinkApiKey2,
                  ),
                ),
                SettingsTile(
                  icon: Broken.global,
                  title: 'M8tec Base URL',
                  subtitle: settings.m8tecBaseUrl ?? 'Default',
                  onTap: () => _showSingleKeyDialog(
                    context,
                    title: 'M8tec Base URL',
                    value: settings.m8tecBaseUrl,
                    onChanged: settings.setM8tecBaseUrl,
                  ),
                ),
                SettingsTile(
                  icon: Broken.global,
                  title: 'Apple Music Storefront',
                  subtitle: settings.appleMusicStorefront.toUpperCase(),
                  onTap: () => _showSingleKeyDialog(
                    context,
                    title: 'Apple Music Storefront',
                    value: settings.appleMusicStorefront,
                    onChanged: (v) =>
                        settings.setAppleMusicStorefront(v ?? 'us'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // ──── Acerca de ────
          _SectionHeader(icon: Broken.info_circle, label: 'About'),
          const SizedBox(height: 8.0),
          SettingsCard(
            icon: Broken.info_circle,
            title: 'About Arc',
            subtitle: 'Version 1.0.0',
            child: Column(
              children: [
                SettingsTile(
                  icon: Broken.cpu,
                  title: 'Arc Engine',
                  subtitle: 'Native audio playback engine',
                ),
                SettingsTile(
                  icon: Broken.pen_tool,
                  title: 'Arx Canvas',
                  subtitle: 'Lyrics and visual effects',
                ),
                SettingsTile(
                  icon: Broken.document,
                  title: 'Licenses',
                  subtitle: 'Open source licenses',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Arc',
                    applicationVersion: '1.0.0',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32.0),
        ],
      ),
    );
  }
}

// ──── Helpers ────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14.0, color: theme.colorScheme.primary),
        const SizedBox(width: 8.0),
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

Widget _folderList(
  BuildContext context,
  List<String> folders,
  ValueChanged<String> onRemove,
) {
  final theme = Theme.of(context);
  if (folders.isEmpty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        'None',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
  return Column(
    children: folders.map((path) {
      final name = path.split('/').last;
      return ListTile(
        dense: true,
        title: Text(name, style: theme.textTheme.bodySmall),
        subtitle: Text(
          path,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10.0,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: Icon(
            Broken.close_circle,
            size: 16.0,
            color: theme.colorScheme.error,
          ),
          onPressed: () => onRemove(path),
        ),
        contentPadding: EdgeInsets.zero,
        visualDensity: const VisualDensity(vertical: -4),
      );
    }).toList(),
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

String _glowPositionsText(Set<GlowPosition> positions) {
  if (positions.isEmpty) return 'None';
  if (positions.length == 1) return positions.first.label;
  return positions.map((p) => p.label).join(', ');
}

String _performanceModeText(PerformanceMode mode) {
  switch (mode) {
    case PerformanceMode.off:
      return 'Off';
    case PerformanceMode.powerSaving:
      return 'Power Saving';
    case PerformanceMode.limit80:
      return 'Balanced 80%';
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
      return type;
  }
}

Future<void> _clearArtworkCache(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Clear Artwork Cache'),
      content: const Text(
        'All cached artwork will be re-fetched on next load. Continue?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton.tonal(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Clear'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  await ArtworkService.inst.clearCache();
  await AnimatedArtworkService.inst.clearCache();
  ArtistPhotoServiceWrapper.inst.clearCache();

  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Artwork cache cleared')));
}

void _showGlowPositionDialog(
  BuildContext context,
  SettingsController settings,
) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final selected = Set<GlowPosition>.from(settings.amoledGlowPositions);

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(
          'Glow Position',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 1.0,
          ),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
        contentPadding: const EdgeInsets.all(20.0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 180.0,
              height: 140.0,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(128),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: colorScheme.outlineVariant,
                        width: 0.5,
                      ),
                    ),
                  ),
                  for (final position in GlowPosition.values)
                    Positioned(
                      top:
                          position == GlowPosition.topLeft ||
                              position == GlowPosition.topRight
                          ? 8.0
                          : null,
                      bottom:
                          position == GlowPosition.bottomLeft ||
                              position == GlowPosition.bottomRight
                          ? 8.0
                          : null,
                      left:
                          position == GlowPosition.topLeft ||
                              position == GlowPosition.bottomLeft
                          ? 8.0
                          : null,
                      right:
                          position == GlowPosition.topRight ||
                              position == GlowPosition.bottomRight
                          ? 8.0
                          : null,
                      child: GestureDetector(
                        onTap: () {
                          final isActive = selected.contains(position);
                          if (isActive) {
                            selected.remove(position);
                          } else if (selected.length < 2) {
                            selected.add(position);
                          }
                          setDialogState(() {});
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 28.0,
                          height: 28.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected.contains(position)
                                ? colorScheme.primary.withAlpha(80)
                                : colorScheme.surfaceContainerHighest,
                            border: Border.all(
                              color: selected.contains(position)
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                              width: selected.contains(position) ? 1.5 : 0.5,
                            ),
                            boxShadow: selected.contains(position)
                                ? [
                                    BoxShadow(
                                      color: settings.mainColor.withAlpha(60),
                                      blurRadius: 12.0,
                                      spreadRadius: 2.0,
                                    ),
                                  ]
                                : null,
                          ),
                          child: selected.contains(position)
                              ? Icon(
                                  Broken.tick_circle,
                                  size: 14.0,
                                  color: colorScheme.primary,
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'Tap corners to toggle (max 2)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton.tonal(
            onPressed: () {
              settings.setAmoledGlowPositions(selected);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
      ),
    ),
  );
}

void _showDefaultTabDialog(BuildContext context, SettingsController settings) {
  final tabs = ['Songs', 'Artists', 'Albums', 'Folders', 'Genres'];
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Default Tab',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.0,
        ),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
      contentPadding: const EdgeInsets.all(20.0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: tabs.map((tab) {
          final isSelected = settings.defaultLibraryTab == tab;
          return ListTile(
            dense: true,
            title: Text(tab),
            trailing: isSelected
                ? Icon(
                    Broken.tick_circle,
                    size: 18.0,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              settings.setDefaultLibraryTab(tab);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    ),
  );
}

void _showFabTypeDialog(BuildContext context, SettingsController settings) {
  final options = [
    ('search', 'Search', Broken.search_normal_1),
    ('play', 'Play', Broken.play),
    ('shuffle', 'Shuffle', Broken.shuffle),
  ];
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'FAB Action',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.0,
        ),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
      contentPadding: const EdgeInsets.all(20.0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = settings.fabType == opt.$1;
          return ListTile(
            dense: true,
            leading: Icon(opt.$3, size: 18.0),
            title: Text(opt.$2),
            trailing: isSelected
                ? Icon(
                    Broken.tick_circle,
                    size: 18.0,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              settings.setFabType(opt.$1);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    ),
  );
}

void _showSpotifyKeysDialog(BuildContext context, SettingsController settings) {
  final clientIdController = TextEditingController(
    text: settings.spotifyClientId ?? '',
  );
  final clientSecretController = TextEditingController(
    text: settings.spotifyClientSecret ?? '',
  );
  final spDcController = TextEditingController(
    text: settings.spotifySpDcCookie ?? '',
  );

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Spotify Keys',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.0,
        ),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
      contentPadding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 0.0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: clientIdController,
              decoration: const InputDecoration(
                labelText: 'Client ID',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: clientSecretController,
              decoration: const InputDecoration(
                labelText: 'Client Secret',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: spDcController,
              decoration: const InputDecoration(
                labelText: 'sp_dc Cookie',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.tonal(
          onPressed: () {
            settings.setSpotifyClientId(clientIdController.text);
            settings.setSpotifyClientSecret(clientSecretController.text);
            settings.setSpotifySpDcCookie(spDcController.text);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 12.0),
    ),
  );
}

void _showSingleKeyDialog(
  BuildContext context, {
  required String title,
  required String? value,
  required ValueChanged<String?> onChanged,
}) {
  final controller = TextEditingController(text: value ?? '');

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.0,
        ),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
      contentPadding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 0.0),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.tonal(
          onPressed: () {
            onChanged(controller.text);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 12.0),
    ),
  );
}
