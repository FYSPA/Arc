import 'package:flutter/material.dart';

class OnboardingPageHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const OnboardingPageHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: 24.0),
        Container(
          width: 64.0,
          height: 64.0,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withAlpha(60),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32.0, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 16.0),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
