import 'package:flutter/material.dart';

import '../../core/broken_icons.dart';
import '../../controller/settings_controller.dart';

void showThemeDialog(BuildContext context, SettingsController settings) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  final isDark = settings.themeMode == ThemeMode.dark ||
      (settings.themeMode == ThemeMode.system &&
          MediaQuery.platformBrightnessOf(context) == Brightness.dark);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Theme',
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
          Row(
            children: [
              _ThemeOption(
                icon: Broken.sun,
                label: 'Light',
                isSelected: settings.themeMode == ThemeMode.light,
                onTap: () {
                  settings.setThemeMode(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(width: 8.0),
              _ThemeOption(
                icon: Broken.moon,
                label: 'Dark',
                isSelected: settings.themeMode == ThemeMode.dark,
                onTap: () {
                  settings.setThemeMode(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              _ThemeOption(
                icon: Broken.autobrightness,
                label: 'System',
                isSelected: settings.themeMode == ThemeMode.system,
                onTap: () {
                  settings.setThemeMode(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(width: 8.0),
              _ThemeOption(
                icon: Broken.square,
                label: 'AMOLED',
                isSelected: isDark && settings.useAmoledBlack,
                enabled: isDark,
                onTap: isDark
                    ? () {
                        settings.setUseAmoledBlack(!settings.useAmoledBlack);
                        Navigator.pop(context);
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withAlpha(30)
                : colorScheme.surfaceContainerHighest.withAlpha(128),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20.0,
                color: isSelected
                    ? colorScheme.primary
                    : enabled
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurfaceVariant.withAlpha(100),
              ),
              const SizedBox(height: 8.0),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? colorScheme.onSurface
                      : enabled
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurfaceVariant.withAlpha(100),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
