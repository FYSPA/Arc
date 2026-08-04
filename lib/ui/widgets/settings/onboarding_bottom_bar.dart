import 'package:flutter/material.dart';

import '../../../controller/settings_controller.dart';
import '../../../core/broken_icons.dart';
import '../animated_check_mark.dart';

class OnboardingBottomBar extends StatelessWidget {
  final SettingsController settings;
  final VoidCallback onGrantPermission;
  final VoidCallback onContinue;

  const OnboardingBottomBar({
    super.key,
    required this.settings,
    required this.onGrantPermission,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPermission = settings.hasStoragePermission;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12.0),
              onTap: hasPermission ? null : onGrantPermission,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: hasPermission
                      ? Colors.green.withAlpha(20)
                      : theme.colorScheme.primaryContainer.withAlpha(100),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    width: 1.0,
                    color: hasPermission
                        ? Colors.green.withAlpha(60)
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedCheckMark(
                      size: 16.0,
                      active: hasPermission,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      hasPermission ? 'Granted' : 'Grant Access',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: hasPermission ? 1.0 : 0.4,
            child: InkWell(
              borderRadius: BorderRadius.circular(12.0),
              onTap: hasPermission ? onContinue : null,
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: hasPermission
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(
                  Broken.arrow_right,
                  size: 18.0,
                  color: hasPermission
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
