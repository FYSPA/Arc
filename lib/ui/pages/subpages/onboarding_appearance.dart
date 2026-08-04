import 'package:flutter/material.dart';

import '../../../controller/settings_controller.dart';
import '../../../core/broken_icons.dart';
import '../../../core/enums.dart';
import '../../dialogs/color_picker_dialog.dart';
import '../../dialogs/language_dialog.dart';
import '../../dialogs/library_tabs_dialog.dart';
import '../../dialogs/theme_dialog.dart';
import '../../widgets/onboarding_page_header.dart';
import '../../widgets/settings_tile.dart';

class OnboardingAppearancePage extends StatelessWidget {
  final SettingsController settings;
  const OnboardingAppearancePage({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      children: [
        const OnboardingPageHeader(
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
              subtitle: _glowPositionsText(settings.amoledGlowPositions),
              onTap: () => _showGlowPositionDialog(context, settings),
            ),
            SettingsTile(
              icon: Broken.speedometer,
              title: 'Glow Intensity',
              subtitle: '${(settings.amoledGlowIntensity * 100).round()}%',
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
