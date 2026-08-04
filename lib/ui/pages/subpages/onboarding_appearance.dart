import 'package:flutter/material.dart';

import '../../../controller/settings_controller.dart';
import '../../../core/broken_icons.dart';
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
