import 'package:flutter/material.dart';

import '../../controller/settings_controller.dart';
import '../../core/broken_icons.dart';
import '../pages/library_tabs.dart';

void showLibraryTabsDialog(BuildContext context, SettingsController settings) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  // El set completo de pestañas se deriva de kLibraryTabs para no desincronizar
  // si se añade alguna en el futuro.
  final allTabs = kLibraryTabs.keys.toList();
  // Respeta el orden ya guardado por el usuario (no el orden canónico).
  final activeTabs = List<String>.from(settings.libraryTabs);
  final dialogWidth = (MediaQuery.of(context).size.width - 80).clamp(
    280.0,
    400.0,
  );

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Arrastra el asidero para reordenar. Toca el ojo para ocultar.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(
              width: dialogWidth,
              height: activeTabs.length * 56.0,
              child: ReorderableListView(
                buildDefaultDragHandles: false,
                onReorderItem: (oldIndex, newIndex) {
                  final item = activeTabs.removeAt(oldIndex);
                  activeTabs.insert(newIndex, item);
                  setDialogState(() {});
                },
                children: [
                  for (int i = 0; i < activeTabs.length; i++)
                    ListTile(
                      key: ValueKey(activeTabs[i]),
                      leading: ReorderableDragStartListener(
                        index: i,
                        child: Icon(
                          Icons.drag_handle,
                          size: 18.0,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      title: Text(
                        activeTabs[i],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Broken.eye_slash,
                          size: 18.0,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: activeTabs.length > 2
                            ? () {
                                activeTabs.removeAt(i);
                                setDialogState(() {});
                              }
                            : null,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Ocultas (toca para mostrar):',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                for (final tab in allTabs.where((t) => !activeTabs.contains(t)))
                  ActionChip(
                    label: Text(tab),
                    onPressed: () {
                      activeTabs.add(tab);
                      setDialogState(() {});
                    },
                  ),
              ],
            ),
          ],
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
