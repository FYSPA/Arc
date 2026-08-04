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

    final alpha = (settings.amoledGlowIntensity * 40).round().clamp(3, 40);

    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: visible ? 1.0 : 0.0,
        child: Stack(
          children: [
            for (final pos in settings.amoledGlowPositions)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: pos.alignment,
                      radius: 0.8,
                      colors: [
                        settings.mainColor.withAlpha(alpha),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
