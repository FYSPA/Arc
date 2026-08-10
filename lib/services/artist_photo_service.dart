import 'package:arx_canvas/arx_canvas.dart' as arx;

import '../controller/settings_controller.dart';

class ArtistPhotoServiceWrapper {
  ArtistPhotoServiceWrapper._();
  static final inst = ArtistPhotoServiceWrapper._();

  arx.ArtistPhotoService? _service;
  final _memoryCache = <String, String?>{};

  arx.ArtistPhotoService _getOrCreate() {
    if (_service != null) return _service!;
    final s = SettingsController.inst;

    arx.SpotifyAuth? spotifyAuth;
    if (s.spotifySpDcCookie != null) {
      spotifyAuth = arx.SpotifyAuth();
      spotifyAuth.setSpDcCookie(s.spotifySpDcCookie!);
    }

    _service = arx.ArtistPhotoService(
      spotifyClientId: s.spotifyClientId,
      spotifyClientSecret: s.spotifyClientSecret,
      spotifyAuth: spotifyAuth,
    );
    return _service!;
  }

  Future<String?> getArtistPhotoUrl(String artistName) async {
    if (artistName.isEmpty) return null;

    final cacheKey = artistName.toLowerCase().trim();
    if (_memoryCache.containsKey(cacheKey)) return _memoryCache[cacheKey];

    try {
      final result = await _getOrCreate().fetchArtistPhoto(
        artistName: artistName,
      );
      final url = result?.url;
      _memoryCache[cacheKey] = url;
      return url;
    } catch (_) {
      _memoryCache[cacheKey] = null;
      return null;
    }
  }

  void clearCache() => _memoryCache.clear();

  void dispose() {
    _service?.dispose();
    _service = null;
    _memoryCache.clear();
  }
}
