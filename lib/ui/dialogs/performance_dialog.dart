import 'package:flutter/material.dart';

import '../../core/broken_icons.dart';
import '../../controller/settings_controller.dart';

void showPerformanceDialog(BuildContext context, SettingsController settings) {
  final theme = Theme.of(context);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Performance',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
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
              _PerformanceOption(
                icon: Broken.flash,
                label: 'Off',
                isSelected: settings.performanceMode == PerformanceMode.off,
                onTap: () {
                  settings.setPerformanceMode(PerformanceMode.off);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(width: 8.0),
              _PerformanceOption(
                icon: Broken.tree,
                label: 'Power\nSaving',
                isSelected: settings.performanceMode == PerformanceMode.powerSaving,
                onTap: () {
                  settings.setPerformanceMode(PerformanceMode.powerSaving);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(width: 8.0),
              _PerformanceOption(
                icon: Broken.speedometer,
                label: 'Limit\n80%',
                isSelected: settings.performanceMode == PerformanceMode.limit80,
                onTap: () {
                  settings.setPerformanceMode(PerformanceMode.limit80);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _PerformanceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PerformanceOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
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
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8.0),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
