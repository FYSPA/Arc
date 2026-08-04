import 'package:flutter/material.dart';

import '../../core/broken_icons.dart';

enum SettingsTileType { tap, toggle, expansion }

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final SettingsTileType type;
  final VoidCallback? onTap;
  final bool? value;
  final ValueChanged<bool>? onChanged;
  final Widget? expandedChild;
  final Widget? trailing;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.type = SettingsTileType.tap,
    this.onTap,
    this.value,
    this.onChanged,
    this.expandedChild,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (type) {
      case SettingsTileType.toggle:
        return ListTile(
          leading: Icon(icon, size: 18.0),
          title: Text(title, style: theme.textTheme.bodyMedium),
          subtitle: Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          )),
          trailing: Switch(
            value: value ?? false,
            onChanged: onChanged,
          ),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
          visualDensity: const VisualDensity(vertical: -4),
        );

      case SettingsTileType.expansion:
        return _ExpansionSettingsTile(
          icon: icon,
          title: title,
          subtitle: subtitle,
          child: expandedChild ?? const SizedBox.shrink(),
        );

      case SettingsTileType.tap:
        return ListTile(
          leading: Icon(icon, size: 18.0),
          title: Text(title, style: theme.textTheme.bodyMedium),
          subtitle: Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          )),
          trailing: trailing ?? Icon(
            Broken.arrow_right_1,
            size: 12.0,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
          visualDensity: const VisualDensity(vertical: -4),
        );
    }
  }
}

class _ExpansionSettingsTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _ExpansionSettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  State<_ExpansionSettingsTile> createState() => _ExpansionSettingsTileState();
}

class _ExpansionSettingsTileState extends State<_ExpansionSettingsTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        ListTile(
          leading: Icon(widget.icon, size: 18.0),
          title: Text(widget.title, style: theme.textTheme.bodyMedium),
          subtitle: Text(widget.subtitle, style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          )),
          trailing: AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastEaseInToSlowEaseOut,
            child: Icon(
              Broken.arrow_down_2,
              size: 18.0,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          contentPadding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
          visualDensity: const VisualDensity(vertical: -4),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: widget.child,
          crossFadeState:
              _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }
}
