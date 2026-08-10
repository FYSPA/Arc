import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import '../core/constans.dart';

class _PaletteInput {
  final Uint8List rgbaBytes;
  final int width;
  final int height;
  _PaletteInput(this.rgbaBytes, this.width, this.height);
}

Future<PaletteGenerator> _extractPalette(_PaletteInput input) async {
  final byteData = ByteData.view(input.rgbaBytes.buffer);
  final encodedImage = EncodedImage(
    byteData,
    width: input.width,
    height: input.height,
  );
  return PaletteGenerator.fromByteData(encodedImage);
}

class CurrentColorController extends ChangeNotifier {
  CurrentColorController._();
  static final inst = CurrentColorController._();

  Color _accentColor = kMainColorDark;
  Color _accentColorLight = kMainColorLight;
  bool _isExtracting = false;

  Color get accentColor => _accentColor;
  Color get accentColorLight => _accentColorLight;
  bool get isExtracting => _isExtracting;

  Future<void> extractFromImage(ImageProvider? imageProvider) async {
    if (imageProvider == null) {
      _resetToDefault();
      return;
    }

    _isExtracting = true;
    notifyListeners();

    try {
      final imageStream = imageProvider.resolve(
        const ImageConfiguration(devicePixelRatio: 1.0),
      );

      final completer = Completer<ui.Image?>();
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (ImageInfo info, bool _) {
          completer.complete(info.image);
          imageStream.removeListener(listener);
        },
        onError: (error, stackTrace) {
          completer.complete(null);
          imageStream.removeListener(listener);
        },
      );
      imageStream.addListener(listener);

      final image = await completer.future;
      if (image == null) {
        _resetToDefault();
        return;
      }

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      if (byteData == null) {
        _resetToDefault();
        return;
      }

      final rgbaBytes = byteData.buffer.asUint8List();
      final w = image.width;
      final h = image.height;

      final palette = await compute(
        _extractPalette,
        _PaletteInput(rgbaBytes, w, h),
      );

      final dominant = palette.dominantColor?.color;
      final vibrant = palette.vibrantColor?.color;
      final lightVibrant = palette.lightVibrantColor?.color;

      final newAccent = vibrant ?? dominant ?? lightVibrant ?? kMainColorDark;
      final newAccentLight = lightVibrant ?? dominant ?? kMainColorLight;

      if (_accentColor != newAccent || _accentColorLight != newAccentLight) {
        _accentColor = newAccent;
        _accentColorLight = newAccentLight;
        notifyListeners();
      }
    } catch (_) {
      _resetToDefault();
    } finally {
      _isExtracting = false;
      notifyListeners();
    }
  }

  void _resetToDefault() {
    if (_accentColor != kMainColorDark) {
      _accentColor = kMainColorDark;
      _accentColorLight = kMainColorLight;
      notifyListeners();
    }
  }

  void setAccentColor(Color color) {
    _accentColor = color;
    _accentColorLight = color;
    notifyListeners();
  }
}
