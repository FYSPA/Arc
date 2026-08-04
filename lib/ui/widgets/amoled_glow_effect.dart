import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controller/settings_controller.dart';
import '../../core/enums.dart';

class AmoledGlowEffect extends StatelessWidget {
  const AmoledGlowEffect({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final visible =
        settings.useAmoledBlack &&
        isDark &&
        settings.enableAmoledGlow &&
        settings.amoledGlowIntensity > 0;

    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: visible ? 1.0 : 0.0,
        child: Align(
          alignment: settings.amoledGlowPosition.alignment,
          child: _GlowBlob(
            color: settings.mainColor,
            intensity: settings.amoledGlowIntensity,
            position: settings.amoledGlowPosition,
          ),
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double intensity;
  final GlowPosition position;

  const _GlowBlob({
    required this.color,
    required this.intensity,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final alpha = (intensity * 35).round().clamp(3, 35);

    return Transform.translate(
      offset: position.translateOffset,
      child: Container(
        width: 600.0,
        height: 600.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withAlpha(alpha),
              color.withAlpha((alpha * 0.5).round()),
              color.withAlpha((alpha * 0.15).round()),
              color.withAlpha(0),
            ],
            stops: const [0.0, 0.25, 0.6, 1.0],
          ),
        ),
      ),
    );
  }
}
