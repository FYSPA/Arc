import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../controller/settings_controller.dart';

void showColorPickerDialog(BuildContext context, SettingsController settings) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  final presetColors = [
    _ColorOption(Color(0xFFB89D7D), 'Beige'),
    _ColorOption(Color(0xFF7C4DFF), 'Purple'),
    _ColorOption(Color(0xFF00BFA5), 'Teal'),
    _ColorOption(Color(0xFFFF5252), 'Red'),
    _ColorOption(Color(0xFFFF6D00), 'Orange'),
    _ColorOption(Color(0xFFFFD600), 'Yellow'),
    _ColorOption(Color(0xFF00E676), 'Green'),
    _ColorOption(Color(0xFF2979FF), 'Blue'),
    _ColorOption(Color(0xFFE040FB), 'Pink'),
    _ColorOption(Color(0xFF78909C), 'Blue Grey'),
  ];

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Accent Color',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 1.0,
        ),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
      contentPadding: const EdgeInsets.all(20.0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: presetColors.map((preset) {
              final isSelected = settings.mainColor == preset.color;
              return GestureDetector(
                onTap: () {
                  settings.setMainColor(preset.color);
                  Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48.0,
                  height: 48.0,
                  decoration: BoxDecoration(
                    color: preset.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? colorScheme.onSurface : Colors.transparent,
                      width: 2.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: preset.color.withAlpha(80),
                              blurRadius: 8.0,
                              spreadRadius: 2.0,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 20.0,
                          color: _contrastColor(preset.color),
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16.0),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showCustomColorPicker(context, settings),
              icon: Icon(Icons.colorize, size: 18.0),
              label: Text('Custom Color'),
            ),
          ),
        ],
      ),
    ),
  );
}

void _showCustomColorPicker(BuildContext context, SettingsController settings) {
  Navigator.pop(context);
  Color pickerColor = settings.mainColor;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Pick a color',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1.0,
            ),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
      contentPadding: const EdgeInsets.all(20.0),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: pickerColor,
          onColorChanged: (color) => pickerColor = color,
          enableAlpha: false,
          labelTypes: const [],
          pickerAreaHeightPercent: 0.8,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        FilledButton.tonal(
          onPressed: () {
            settings.setMainColor(pickerColor);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
    ),
  );
}

Color _contrastColor(Color color) {
  final luminance = color.computeLuminance();
  return luminance > 0.5 ? Colors.black : Colors.white;
}

class _ColorOption {
  final Color color;
  final String name;

  const _ColorOption(this.color, this.name);
}
