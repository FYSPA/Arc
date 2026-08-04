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
          ),
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double intensity;

  const _GlowBlob({required this.color, required this.intensity});

  @override
  Widget build(BuildContext context) {
    final alpha = (intensity * 60).round().clamp(5, 60);

    return Container(
      width: 350.0,
      height: 350.0,
      margin: const EdgeInsets.only(
        top: -120.0,
        right: -120.0,
        bottom: -120.0,
        left: -120.0,
      ),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withAlpha(alpha), color.withAlpha(0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}
