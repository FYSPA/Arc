import 'package:flutter/material.dart';

import '../../controller/settings_controller.dart';
import '../../core/broken_icons.dart';

void showLibraryTabsDialog(BuildContext context, SettingsController settings) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  final allTabs = ['Songs', 'Artists', 'Albums', 'Folders', 'Genres'];
  final activeTabs = List<String>.from(settings.libraryTabs);

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(
          'Library Tabs',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 1.0,
          ),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
        contentPadding: const EdgeInsets.all(20.0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: allTabs.map((tab) {
            final isActive = activeTabs.contains(tab);
            return ListTile(
              leading: Icon(
                isActive ? Broken.tick_circle : Broken.eye_slash,
                size: 18.0,
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              title: Text(
                tab,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isActive
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Icon(
                isActive ? Icons.drag_handle : null,
                size: 18.0,
                color: colorScheme.onSurfaceVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              onTap: () {
                if (isActive && activeTabs.length > 2) {
                  activeTabs.remove(tab);
                } else if (!isActive) {
                  activeTabs.add(tab);
                }
                setDialogState(() {});
              },
            );
          }).toList(),
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
            onPressed: () {
              settings.setLibraryTabs(activeTabs);
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
      ),
    ),
  );
}
