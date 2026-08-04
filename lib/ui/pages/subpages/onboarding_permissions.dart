import 'package:flutter/material.dart';

import '../../../controller/settings_controller.dart';
import '../../../core/broken_icons.dart';
import '../../widgets/animated_check_mark.dart';
import '../../widgets/onboarding_page_header.dart';

class OnboardingPermissionsPage extends StatelessWidget {
  final SettingsController settings;
  const OnboardingPermissionsPage({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasPermission = settings.hasStoragePermission;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      children: [
        const OnboardingPageHeader(
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
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: AnimatedCheckMark(size: 20.0, active: hasPermission),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4.0,
            vertical: 2.0,
          ),
          visualDensity: const VisualDensity(vertical: -4),
        ),
        const SizedBox(height: 12.0),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(128),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Row(
            children: [
              Icon(Broken.info_circle, size: 20.0, color: colorScheme.primary),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why do we need this?',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Arc needs storage access to scan your device for FLAC, WAV, and MP3 files, read metadata, and display album artwork.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
