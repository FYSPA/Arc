import 'package:flutter/material.dart';

import '../../core/broken_icons.dart';
import '../../core/extensions.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      children: [
        _SectionTitle(title: 'Recently Added', theme: theme),
        const SizedBox(height: 8.0),
        _EmptyState(
          icon: Broken.musicnote,
          message: 'No tracks yet',
          theme: theme,
        ),
        const SizedBox(height: 24.0),
        _SectionTitle(title: 'Recently Played', theme: theme),
        const SizedBox(height: 8.0),
        _EmptyState(
          icon: Broken.play_circle,
          message: 'Nothing played yet',
          theme: theme,
        ),
        const SizedBox(height: 24.0),
        _SectionTitle(title: 'Top Artists', theme: theme),
        const SizedBox(height: 8.0),
        _EmptyState(
          icon: Broken.user,
          message: 'No artists found',
          theme: theme,
        ),
        const SizedBox(height: 24.0),
        _SectionTitle(title: 'Top Albums', theme: theme),
        const SizedBox(height: 8.0),
        _EmptyState(
          icon: Broken.music_dashboard,
          message: 'No albums found',
          theme: theme,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final ThemeData theme;

  const _SectionTitle({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final ThemeData theme;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100.0,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14.0),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28.0,
              color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.4),
            ),
            const SizedBox(height: 8.0),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
