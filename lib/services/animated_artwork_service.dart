import 'dart:async';
import 'dart:io';

import 'package:arx_canvas/arx_canvas.dart';
import 'package:path_provider/path_provider.dart';

import '../core/utils.dart';

import '../controller/settings_controller.dart';
import '../data/models/track.dart';

class AnimatedArtworkService {
  AnimatedArtworkService._();
  static final inst = AnimatedArtworkService._();

  AppleMusicArtworkService? _service;
  CacheManager? _cacheManager;

  final _memoryCache = <String, AnimatedArtwork>{};
  final _memoryCacheOrder = <String>[];
  static const _maxMemoryCache = 50;

  final _failedTracks = <int>{};

  static const _maxConcurrent = 2;
  int _activeLoads = 0;
  final _pendingQueue = <Completer<void>>[];

  Future<void> _acquire() async {
    if (_activeLoads < _maxConcurrent) {
      _activeLoads++;
      return;
    }
    final completer = Completer<void>();
    _pendingQueue.add(completer);
    await completer.future;
  }

  void _release() {
    _activeLoads--;
    if (_pendingQueue.isNotEmpty) {
      _activeLoads++;
      _pendingQueue.removeAt(0).complete();
    }
  }

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
      musiclinkApiKeys: s.allMusiclinkApiKeys,
    );

    logD(
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
    logD(
      '[AnimatedArtworkService] fetchForTrack START key=$key '
      'title="${track.title}" artist="${track.artist}" album="${track.album}"',
    );

    if (_memoryCache.containsKey(key)) {
      logD('[AnimatedArtworkService] memory cache HIT for "${track.title}"');
      return _memoryCache[key];
    }

    if (_failedTracks.contains(track.id)) {
      logD(
        '[AnimatedArtworkService] known failure for "${track.title}", skipping',
      );
      return null;
    }

    try {
      logD('[AnimatedArtworkService] checking disk cache...');
      final cm = await _getCacheManager();
      logD('[AnimatedArtworkService] disk cache manager ready');
      final cached = await cm.getAnimatedArtwork(key);
      if (cached != null) {
        logD('[AnimatedArtworkService] disk cache HIT for "${track.title}"');
        _memoryCache[key] = cached;
        return cached;
      }
      logD('[AnimatedArtworkService] disk cache MISS');
    } catch (e) {
      logD('[AnimatedArtworkService] cacheManager error: $e');
    }

    try {
      logD('[AnimatedArtworkService] creating service...');
      final service = _getOrCreate();
      logD(
        '[AnimatedArtworkService] service ready, fetching for '
        '"${track.title}" by ${track.artist} (album: ${track.album})...',
      );

      final albumName = (track.album.isEmpty || track.album == 'Unknown Album')
          ? track.title
          : track.album;

      await _acquire();
      try {
        logD('[AnimatedArtworkService] calling getAnimatedArtwork...');
        final result = await service
            .getAnimatedArtwork(
              albumName: albumName,
              artistName: track.artist,
              trackName: track.title,
            )
            .timeout(const Duration(seconds: 15));

        logD(
          '[AnimatedArtworkService] result: '
          'hasAnimation=${result.hasAnimation}, '
          'hasVideo=${result.hasVideo}, '
          'url=${result.preferredAnimationUrl}, '
          'staticUrl=${result.staticImageUrl}',
        );

        _memoryCache[key] = result;
        _memoryCacheOrder.remove(key);
        _memoryCacheOrder.add(key);
        if (_memoryCacheOrder.length > _maxMemoryCache) {
          final evict = _memoryCacheOrder.removeAt(0);
          _memoryCache.remove(evict);
        }

        try {
          final cm = await _getCacheManager();
          await cm.saveAnimatedArtwork(key, result);
          logD(
            '[AnimatedArtworkService] saved to disk cache for "${track.title}"',
          );
        } catch (e) {
          logD('[AnimatedArtworkService] disk cache save error: $e');
        }

        logD('[AnimatedArtworkService] fetchForTrack END (success)');
        return result;
      } finally {
        _release();
      }
    } catch (e) {
      logD(
        '[AnimatedArtworkService] FETCH FAILED for "${track.title}": '
        '${e.runtimeType}: $e',
      );
      _failedTracks.add(track.id);
      if (_failedTracks.length > 500) {
        final toRemove = _failedTracks.take(250).toList();
        _failedTracks.removeAll(toRemove);
      }
      return null;
    }
  }

  bool isKnownFailure(int trackId) => _failedTracks.contains(trackId);

  AnimatedArtwork? getCached(String trackPath) => _memoryCache[trackPath];

  Future<void> clearCache() async {
    _memoryCache.clear();
    _memoryCacheOrder.clear();
    _failedTracks.clear();
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
