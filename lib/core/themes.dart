import 'package:flutter/material.dart';

import 'constans.dart';
import 'dimensions.dart';

class AppThemes {
  static ThemeData light(Color color) {
    return _buildTheme(color, Brightness.light);
  }

  static ThemeData dark(Color color, {bool isAmoled = false}) {
    return _buildTheme(color, Brightness.dark, isAmoled: isAmoled);
  }

  static ThemeData fromColor(
    Color color,
    Brightness brightness, {
    bool isAmoled = false,
  }) {
    return _buildTheme(color, brightness, isAmoled: isAmoled);
  }

  static ThemeData _buildTheme(
    Color color,
    Brightness brightness, {
    bool isAmoled = false,
  }) {
    final isLight = brightness == Brightness.light;

    final scaffoldBg = isLight
        ? Color.alphaBlend(color.withAlpha(60), Colors.white)
        : isAmoled
        ? pitchBlack
        : darkGrey;

    final cardColor = isLight
        ? Color.alphaBlend(color.withAlpha(45), Colors.white)
        : isAmoled
        ? const Color(0xFF0A0A0A)
        : const Color(0xFF1A1A1A);

    final dialogBg = isLight
        ? null
        : isAmoled
        ? const Color(0xFF141414)
        : const Color(0xFF1E1E1E);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'LexendDeca',
      fontFamilyFallback: ['sans-serif', 'Roboto'],
      colorScheme: ColorScheme.fromSeed(
        seedColor: color,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      splashColor: Colors.transparent,
      highlightColor: isLight
          ? Colors.black.withAlpha(20)
          : Colors.white.withAlpha(15),
      disabledColor: isLight
          ? const Color(0xC8A0A0A0)
          : const Color(0xC83C3C3C),
      dividerColor: isLight ? const Color(0x64646464) : const Color(0x32FFFFFF),
      cardTheme: CardThemeData(
        elevation: isLight ? 12.0 : 0.0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.0.multipliedRadius),
          side: isLight
              ? BorderSide.none
              : BorderSide(
                  color: Colors.white.withAlpha(isAmoled ? 15 : 25),
                  width: 0.5,
                ),
        ),
      ),
      dialogTheme: DialogThemeData(
        surfaceTintColor: Colors.transparent,
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0.multipliedRadius),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        surfaceTintColor: Colors.transparent,
        elevation: 12.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0.multipliedRadius),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        margin: const EdgeInsets.symmetric(horizontal: 24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0.multipliedRadius),
          boxShadow: [
            BoxShadow(
              color: const Color(0x460C0C0C),
              blurRadius: 6.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        waitDuration: const Duration(seconds: 1),
      ),
    );
  }
}
