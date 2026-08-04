import 'dart:ui';

extension ColorExtensions on Color {
  Color withOpacityExt(double opacity) {
    return withValues(alpha: opacity);
  }

  Color alphaBlendWith(Color other) {
    return Color.alphaBlend(this, other);
  }
}
