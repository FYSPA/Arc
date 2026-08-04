import 'package:flutter/material.dart';

import '../../controller/settings_controller.dart';
import '../../core/broken_icons.dart';

void showLanguageDialog(BuildContext context, SettingsController settings) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  final languages = [
    _LanguageOption(code: 'en', name: 'English', flag: '🇺🇸'),
    _LanguageOption(code: 'es', name: 'Español', flag: '🇪🇸'),
  ];

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Language',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 1.0,
        ),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
      contentPadding: const EdgeInsets.all(20.0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: languages.map((lang) {
          final isSelected = settings.languageCode == lang.code;
          return ListTile(
            leading: Text(lang.flag, style: const TextStyle(fontSize: 24.0)),
            title: Text(
              lang.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            trailing: isSelected
                ? Icon(
                    Broken.tick_circle,
                    size: 18.0,
                    color: colorScheme.primary,
                  )
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            onTap: () {
              settings.setLanguageCode(lang.code);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    ),
  );
}

class _LanguageOption {
  final String code;
  final String name;
  final String flag;

  const _LanguageOption({
    required this.code,
    required this.name,
    required this.flag,
  });
}
