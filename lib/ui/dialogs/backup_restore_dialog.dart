import 'package:flutter/material.dart';

import '../../core/broken_icons.dart';

void showBackupRestoreDialog(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 0.0),
      contentPadding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 20.0),
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withAlpha(100),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Broken.document_upload,
              size: 24.0,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            'Backup & Restore',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: Text(
        'Create and restore backups of your library, playlists, and settings.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        FilledButton.tonal(
          onPressed: () => Navigator.pop(context),
          child: const Text('Create Backup'),
        ),
      ],
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
    ),
  );
}
