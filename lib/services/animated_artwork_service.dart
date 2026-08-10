import 'dart:io';

import 'package:arx_canvas/arx_canvas.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../controller/settings_controller.dart';
import '../data/models/track.dart';

class AnimatedArtworkService {
  AnimatedArtworkService._();
  static final inst = AnimatedArtworkService._();

  AppleMusicArtworkService? _service;
  CacheManager? _cacheManager;

  final _memoryCache = <String, AnimatedArtwork>{};

  AppleMusicArtworkService _getOrCreate() {
    if (_service != null) return _service!;

    final s = SettingsController.inst;
    final config = ArcCanvasConfig(
      spotifyClientId: s.spotifyClientId,
      spotifyClientSecret: s.spotifyClientSecret,
      spotifySpDcCookie: s.spotifySpDcCookie,
      geniusAccessToken: s.geniusAccessToken,
      musixmatchApiKey: s.musixmatchApiKey,
      m8tecBaseUrl: s.m8tecBaseUrl,
      appleMusicStorefront: s.appleMusicStorefront,
      appleMusicAmpToken: s.appleMusicAmpToken,
      musiclinkApiKey: s.musiclinkApiKey,
    );

    debugPrint(
      '[AnimatedArtworkService] creating service — '
      'm8tec=${config.hasM8tecBaseUrl}, '
      'spotify=${config.hasSpotifyCanvasCredentials}, '
      'storefront=${config.appleStorefront}',
    );

    SpotifyCanvasClient? spotifyCanvas;
    if (config.hasSpotifyCanvasCredentials) {
      spotifyCanvas = SpotifyCanvasClient();
      if (s.spotifySpDcCookie != null) {
        spotifyCanvas.setSpDcCookie(s.spotifySpDcCookie!);
      }
    }

    _service = AppleMusicArtworkService(
      m8tecClient: M8tecClient(baseUrl: config.m8tecBaseUrl),
      ampProvider: AmpAppleMusicProvider(
        storefront: config.appleMusicStorefront,
      ),
      spotifyCanvas: spotifyCanvas,
      storefront: config.appleMusicStorefront,
    );

    return _service!;
  }

  Future<CacheManager> _getCacheManager() async {
    if (_cacheManager != null) return _cacheManager!;
    final appDir = await getApplicationCacheDirectory();
    _cacheManager = CacheManager(
      baseDir: Directory('${appDir.path}/arx_canvas'),
    );
    await _cacheManager!.init();
    return _cacheManager!;
  }

  String _buildKey(ArcTrack track) {
    return CacheManager.buildCacheKey(
      title: track.title,
      artist: track.artist,
      album: track.album,
    );
  }

  Future<AnimatedArtwork?> fetchForTrack(
    ArcTrack track,
    dynamic metadata,
  ) async {
    final key = _buildKey(track);
    debugPrint(
      '[AnimatedArtworkService] fetchForTrack START key=$key '
      'title="${track.title}" artist="${track.artist}" album="${track.album}"',
    );

    if (_memoryCache.containsKey(key)) {
      debugPrint(
        '[AnimatedArtworkService] memory cache HIT for "${track.title}"',
      );
      return _memoryCache[key];
    }

    try {
      debugPrint('[AnimatedArtworkService] checking disk cache...');
      final cm = await _getCacheManager();
      debugPrint('[AnimatedArtworkService] disk cache manager ready');
      final cached = await cm.getAnimatedArtwork(key);
      if (cached != null) {
        debugPrint(
          '[AnimatedArtworkService] disk cache HIT for "${track.title}"',
        );
        _memoryCache[key] = cached;
        return cached;
      }
      debugPrint('[AnimatedArtworkService] disk cache MISS');
    } catch (e) {
      debugPrint('[AnimatedArtworkService] cacheManager error: $e');
    }

    try {
      debugPrint('[AnimatedArtworkService] creating service...');
      final service = _getOrCreate();
      debugPrint(
        '[AnimatedArtworkService] service ready, fetching for '
        '"${track.title}" by ${track.artist} (album: ${track.album})...',
      );

      debugPrint('[AnimatedArtworkService] calling getAnimatedArtwork...');
      final result = await service
          .getAnimatedArtwork(
            albumName: track.album,
            artistName: track.artist,
            trackName: track.title,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint(
        '[AnimatedArtworkService] result: '
        'hasAnimation=${result.hasAnimation}, '
        'hasVideo=${result.hasVideo}, '
        'url=${result.preferredAnimationUrl}, '
        'staticUrl=${result.staticImageUrl}',
      );

      _memoryCache[key] = result;

      try {
        final cm = await _getCacheManager();
        await cm.saveAnimatedArtwork(key, result);
        debugPrint(
          '[AnimatedArtworkService] saved to disk cache for "${track.title}"',
        );
      } catch (e) {
        debugPrint('[AnimatedArtworkService] disk cache save error: $e');
      }

      debugPrint('[AnimatedArtworkService] fetchForTrack END (success)');
      return result;
    } catch (e) {
      debugPrint(
        '[AnimatedArtworkService] FETCH FAILED for "${track.title}": '
        '${e.runtimeType}: $e',
      );
      return null;
    }
  }

  AnimatedArtwork? getCached(String trackPath) => _memoryCache[trackPath];

  Future<void> clearCache() async {
    _memoryCache.clear();
    try {
      final cm = await _getCacheManager();
      await cm.clearCache();
    } catch (_) {}
  }

  void dispose() {
    _service?.dispose();
    _service = null;
    _cacheManager?.dispose();
    _cacheManager = null;
    _memoryCache.clear();
  }
}
