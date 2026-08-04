import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 4.0, right: 4.0, top: 16.0, bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4.0),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant,
          ),
        ],
      ),
    );
  }
}
