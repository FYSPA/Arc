import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:arx_canvas/arx_canvas.dart' as arx;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../controller/settings_controller.dart';
import '../data/models/track.dart';
import 'animated_artwork_service.dart';
import 'artist_photo_service.dart';
import 'media_store_service.dart';

import '../core/utils.dart';

class ArtworkService {
  ArtworkService._();
  static final inst = ArtworkService._();

  final _cache = <int, Uint8List>{};
  final _imageProviderCache = <String, ImageProvider?>{};
  final _cacheOrder = <int>[];
  static const _maxCache = 300;
  final _nullCache = <int, Set<MediaType>>{};
  final _loggedNulls = <int>{};
  int _preloadToken = 0;
  Directory? _cacheDir;

  arx.ArtworkService? _onlineService;

  static const _maxConcurrent = 5;
  int _activeLoads = 0;
  final _pendingQueue = <Completer<void>>[];

  final _pendingArtworks = <int, Completer<Uint8List?>>{};

  static const _maxOnlineConcurrent = 3;
  int _activeOnline = 0;
  final _onlinePendingQueue = <Completer<void>>[];

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

  Future<void> _acquireOnline() async {
    if (_activeOnline < _maxOnlineConcurrent) {
      _activeOnline++;
      return;
    }
    final completer = Completer<void>();
    _onlinePendingQueue.add(completer);
    await completer.future;
  }

  void _releaseOnline() {
    _activeOnline--;
    if (_onlinePendingQueue.isNotEmpty) {
      _activeOnline++;
      _onlinePendingQueue.removeAt(0).complete();
    }
  }

  void _cacheHit(int id) {
    _cacheOrder.remove(id);
    _cacheOrder.add(id);
  }

  void _evictIfNeeded() {
    while (_cacheOrder.length > _maxCache) {
      final evictId = _cacheOrder.removeAt(0);
      _cache.remove(evictId);
      _imageProviderCache.removeWhere(
        (k, _) => k == '$evictId' || k.endsWith(':$evictId'),
      );
    }
  }

  /// Proactively evict the oldest files from the on-disk artwork cache when
  /// it exceeds the configured limit (see docs/OPTIMIZACIONES.md §2.10).
  void _trimDiskIfNeeded() {
    try {
      final dir = _cacheDir;
      if (dir == null || !dir.existsSync()) return;
      final maxFiles = SettingsController.inst.artworkCacheSize;
      final files = dir.listSync().whereType<File>().toList();
      if (files.length <= maxFiles) return;
      files.sort(
        (a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()),
      );
      final excess = files.length - maxFiles;
      for (var i = 0; i < excess; i++) {
        try {
          files[i].deleteSync();
        } catch (_) {}
      }
    } catch (_) {}
  }

  arx.ArtworkService _getOnlineService() {
    if (_onlineService != null) return _onlineService!;
    final s = SettingsController.inst;
    _onlineService = arx.ArtworkService(
      spotifyClientId: s.spotifyClientId,
      spotifyClientSecret: s.spotifyClientSecret,
    );
    return _onlineService!;
  }

  Future<Directory> get _directory async {
    if (_cacheDir != null) return _cacheDir!;
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${appDir.path}/artwork_cache');
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    return _cacheDir!;
  }

  Future<Uint8List?> getArtwork(int id, MediaType type) async {
    if (_cache.containsKey(id)) return _cache[id];
    if (_nullCache[id]?.contains(type) == true) return null;

    // Dedupe: if a load for this id is already in flight, wait for it
    // instead of launching a second (expensive) MediaStore query.
    final pending = _pendingArtworks[id];
    if (pending != null) return pending.future;

    final completer = Completer<Uint8List?>();
    _pendingArtworks[id] = completer;
    Uint8List? result;
    try {
      final dir = await _directory;
      final file = File('${dir.path}/$id.jpg');

      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        _cache[id] = bytes;
        _cacheHit(id);
        _evictIfNeeded();
        result = bytes;
        return bytes;
      }

      // Skip the expensive cross-process MediaStore query when we already know
      // this id has no art of this type. The marker persists across app
      // restarts so we don't re-query MediaStore on every launch.
      final nullMarker = File('${dir.path}/$id._null_${type.index}');
      if (await nullMarker.exists()) {
        _nullCache.putIfAbsent(id, () => {}).add(type);
        result = null;
        return null;
      }

      await _acquire();
      try {
        final artwork = await MediaStoreService.inst.queryArtwork(id, type);

        if (artwork != null && artwork.isNotEmpty) {
          await file.writeAsBytes(artwork);
          _cache[id] = artwork;
          _cacheHit(id);
          _evictIfNeeded();
          _trimDiskIfNeeded();
        } else {
          _nullCache.putIfAbsent(id, () => {}).add(type);
          try {
            await nullMarker.create();
          } catch (_) {}
        }

        result = artwork;
        return artwork;
      } finally {
        _release();
      }
    } catch (e) {
      result = null;
      rethrow;
    } finally {
      completer.complete(result);
      _pendingArtworks.remove(id);
    }
  }

  Future<Uint8List?> _fetchOnlineArtwork(String? album, String? artist) async {
    if (album == null || album.isEmpty || artist == null || artist.isEmpty) {
      return null;
    }

    await _acquireOnline();
    try {
      final result = await _getOnlineService().fetchArtwork(
        albumName: album,
        artistName: artist,
      );
      if (result == null || result.url.isEmpty) {
        logD('[ArtworkService] online: no result for "$album" by "$artist"');
        return null;
      }

      logD(
        '[ArtworkService] online: found from ${result.source} for "$album" by "$artist"',
      );
      final response = await http
          .get(Uri.parse(result.url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        logD(
          '[ArtworkService] online: HTTP ${response.statusCode} for "$album" by "$artist"',
        );
        return null;
      }

      final bytes = response.bodyBytes;
      if (bytes.isEmpty) return null;

      return bytes;
    } catch (e) {
      logD(
        '[ArtworkService] _fetchOnlineArtwork failed for "$album" by "$artist": $e',
      );
      return null;
    } finally {
      _releaseOnline();
    }
  }

  Future<Uint8List?> getLocalArtwork(ArcTrack track) async {
    // Album art is the cover source for the vast majority of tracks. Check it
    // FIRST so we avoid a slow per-track MediaStore query when only album art
    // exists (see docs/OPTIMIZACIONES.md — "carátulas ya cacheadas lentas").
    if (track.albumId != null) {
      final albumBytes = await getArtwork(track.albumId!, MediaType.album);
      if (albumBytes != null && albumBytes.isNotEmpty) return albumBytes;
    }

    final bytes = await getArtwork(track.id, MediaType.audio);
    if (bytes != null && bytes.isNotEmpty) return bytes;

    return null;
  }

  Future<Uint8List?> getLocalOnlyArtwork(ArcTrack track) async {
    final bytes = await getArtwork(track.id, MediaType.audio);
    if (bytes != null && bytes.isNotEmpty) return bytes;

    if (track.albumId != null) {
      final albumBytes = await getArtwork(track.albumId!, MediaType.album);
      if (albumBytes != null && albumBytes.isNotEmpty) return albumBytes;
    }

    return null;
  }

  Future<Uint8List?> _fetchHighResOnline(ArcTrack track) async {
    final albumQuery = (track.album.isEmpty || track.album == 'Unknown Album')
        ? track.title
        : track.album;
    final onlineBytes = await _fetchOnlineArtwork(albumQuery, track.artist);
    if (onlineBytes == null || onlineBytes.isEmpty) return null;

    final dir = await _directory;
    final cacheId = track.albumId ?? track.id;
    final file = File('${dir.path}/$cacheId.jpg');
    await file.writeAsBytes(onlineBytes);
    _trimDiskIfNeeded();
    _cache[cacheId] = onlineBytes;
    _cacheHit(cacheId);
    _evictIfNeeded();
    return onlineBytes;
  }

  Future<Uint8List?> _fetchAnimatedStatic(ArcTrack track) async {
    try {
      final animated = await AnimatedArtworkService.inst.fetchForTrack(
        track,
        null,
      );
      if (animated?.staticImageUrl != null &&
          animated!.staticImageUrl!.isNotEmpty) {
        await _acquireOnline();
        try {
          final response = await http
              .get(Uri.parse(animated.staticImageUrl!))
              .timeout(const Duration(seconds: 10));
          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            final dir = await _directory;
            final cacheId = track.albumId ?? track.id;
            final file = File('${dir.path}/$cacheId.jpg');
            await file.writeAsBytes(response.bodyBytes);
            _trimDiskIfNeeded();
            _cache[cacheId] = response.bodyBytes;
            _cacheHit(cacheId);
            _evictIfNeeded();
            return response.bodyBytes;
          }
        } catch (_) {
        } finally {
          _releaseOnline();
        }
      }
    } catch (_) {}

    return null;
  }

  Future<Uint8List?> getTrackArtwork(ArcTrack track) async {
    final bytes = await getLocalArtwork(track);
    if (bytes != null && bytes.isNotEmpty) return bytes;

    final online = await _fetchHighResOnline(track);
    if (online != null && online.isNotEmpty) return online;

    return _fetchAnimatedStatic(track);
  }

  /// Loads artwork for [track], showing the embedded/local bytes instantly
  /// (when available) and upgrading to a high-resolution online source
  /// (arx_canvas ArtworkService: iTunes → Apple → Deezer → Spotify) when it
  /// arrives. The full player uses [onUpgrade] to swap to the high-res image;
  /// the high-res online fetch runs in the background so the UI never blocks.
  ///
  /// When the local art is missing, the online fetch runs synchronously so
  /// missing artwork (that the user knows exists) gets filled in.
  Future<Uint8List?> getHighResArtwork(
    ArcTrack track, {
    void Function(Uint8List bytes)? onUpgrade,
    bool preferHighRes = false,
  }) async {
    // When the caller wants the highest quality up front (e.g. the full
    // player), prefer the album-level / online high-res artwork that is
    // already cached on disk over the low-resolution per-track embedded art.
    // This avoids the "low quality first, then upgrade" flash.
    if (preferHighRes && track.albumId != null) {
      final album = await getArtwork(track.albumId!, MediaType.album);
      if (album != null && album.isNotEmpty) {
        if (onUpgrade != null) {
          unawaited(
            _fetchHighResOnline(track).then((bytes) {
              if (bytes != null && bytes.isNotEmpty) onUpgrade(bytes);
            }),
          );
        }
        return album;
      }
    }

    final local = await getLocalArtwork(track);
    if (local != null && local.isNotEmpty) {
      if (onUpgrade != null) {
        unawaited(
          _fetchHighResOnline(track).then((bytes) {
            if (bytes != null && bytes.isNotEmpty) onUpgrade(bytes);
          }),
        );
      }
      return local;
    }

    final online = await _fetchHighResOnline(track);
    if (online != null && online.isNotEmpty) return online;

    return _fetchAnimatedStatic(track);
  }

  /// Cache for named (album/artist) lookups that have no numeric MediaStore id.
  final Map<String, Uint8List> _namedCache = {};

  Future<Uint8List?> _fetchHighResOnlineNames(
    String album,
    String artist, {
    required String cacheKey,
    int? idForDisk,
  }) async {
    final bytes = await _fetchOnlineArtwork(album, artist);
    if (bytes == null || bytes.isEmpty) return null;
    _namedCache[cacheKey] = bytes;
    if (idForDisk != null) {
      try {
        final dir = await _directory;
        await File('${dir.path}/$idForDisk.jpg').writeAsBytes(bytes);
        _trimDiskIfNeeded();
        _cache[idForDisk] = bytes;
        _cacheHit(idForDisk);
        _evictIfNeeded();
      } catch (_) {}
    }
    return bytes;
  }

  /// Embedded-or-online album artwork. Uses the embedded bytes when present
  /// (keyed by [id]) and falls back to the arx_canvas ArtworkService by
  /// [album]+[artist] so albums that MediaStore failed to index still show art.
  Future<Uint8List?> getHighResAlbumArt(
    String album,
    String artist, {
    int? id,
  }) async {
    if (id != null) {
      final local = await getArtwork(id, MediaType.album);
      if (local != null && local.isNotEmpty) return local;
    }
    final cacheKey = id != null ? 'a$id' : 'a_${album}_$artist';
    if (_namedCache.containsKey(cacheKey)) return _namedCache[cacheKey];
    return _fetchHighResOnlineNames(
      album,
      artist,
      cacheKey: cacheKey,
      idForDisk: id,
    );
  }

  /// Artist portrait with online fallback (Deezer/Apple/Spotify via
  /// [ArtistPhotoServiceWrapper]).
  Future<Uint8List?> getHighResArtistArt(String artist, {int? id}) =>
      fetchArtistPhoto(artist, id ?? artist.hashCode);

  Future<ImageProvider?> getArtworkImage(ArcTrack track) async {
    final cached = getCachedImageProvider(track.id);
    if (cached != null) return cached;

    final bytes = await getTrackArtwork(track);
    if (bytes == null || bytes.isEmpty) {
      if (_loggedNulls.add(track.id)) {
        logD(
          '[ArtworkService] no artwork for "${track.title}" (albumId=${track.albumId})',
        );
      }
      return null;
    }

    if (_loggedNulls.remove(track.id)) {
      logD(
        '[ArtworkService] loaded artwork for "${track.title}" (${bytes.length} bytes)',
      );
    }
    final image = MemoryImage(bytes);
    cacheImageProvider(track.id, image);
    return image;
  }

  /// Reads (or generates + persists) a resized PNG thumbnail for [id] at
  /// [size] px. Thumbnails are tiny on disk (~30-60KB) so list covers load
  /// without reading/decoding the full-res artwork (OPTIMIZACIONES.md §2.3,
  /// Opción B).
  Future<Uint8List?> getThumbnailBytes(int id, MediaType type, int size) async {
    final dir = await _directory;
    final file = File('${dir.path}/$id._t$size.png');
    if (await file.exists()) return file.readAsBytes();

    final full = await getArtwork(id, type);
    if (full == null || full.isEmpty) return null;

    Uint8List? png;
    try {
      png = await _encodeThumbnail(full, size);
    } catch (_) {
      return full;
    }
    if (png == null || png.isEmpty) return full;

    try {
      await file.writeAsBytes(png);
      _trimDiskIfNeeded();
    } catch (_) {}
    return png;
  }

  Future<Uint8List?> _encodeThumbnail(Uint8List bytes, int size) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final ui.Image image = frame.image;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final w = image.width;
    final h = image.height;
    final side = w < h ? w : h;
    final src = ui.Rect.fromLTWH(
      (w - side) / 2.0,
      (h - side) / 2.0,
      side.toDouble(),
      side.toDouble(),
    );
    final dst = ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
    canvas.drawImageRect(image, src, dst, ui.Paint());
    final picture = recorder.endRecording();
    final resized = await picture.toImage(size, size);
    final data = await resized.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    resized.dispose();
    return data?.buffer.asUint8List();
  }

  /// Best-effort background generation of list thumbnails for [ids] so the
  /// first navigation after a scan is instant (Opción B / §2.3). Yields between
  /// items to keep the UI responsive. A newer call (or [cancelPreload])
  /// supersedes an in-flight preload.
  Future<void> preloadAlbumThumbnails(List<int> ids, int size) async {
    final myToken = ++_preloadToken;
    for (final id in ids) {
      if (myToken != _preloadToken) return;
      try {
        await getThumbnailBytes(id, MediaType.album, size);
      } catch (_) {}
      await Future.delayed(Duration.zero);
    }
  }

  void cancelPreload() => _preloadToken++;

  /// Returns a cached [ImageProvider] for [track] decoded at [pixelSize].
  /// Reuses a single provider instance per `id:size` so Flutter's ImageCache
  /// does not re-decode artwork on every list cell / scroll. When [onlineFallback]
  /// is true and no local art exists, an online fetch fills the missing art
  /// (once) — but already-cached local art never hits the network.
  Future<ImageProvider?> getArtworkProvider(
    ArcTrack track,
    int pixelSize, {
    bool onlineFallback = false,
  }) async {
    final key = 'list:$pixelSize:${track.id}';
    final cached = _imageProviderCache[key];
    if (cached != null) return cached;

    Uint8List? bytes;
    final albumId = track.albumId;
    if (albumId != null) {
      bytes = await getThumbnailBytes(albumId, MediaType.album, pixelSize);
    }
    if (bytes == null || bytes.isEmpty) {
      bytes = await getLocalArtwork(track);
      if (bytes == null || bytes.isEmpty) {
        if (!onlineFallback) return null;
        bytes = await getTrackArtwork(track);
        if (bytes == null || bytes.isEmpty) return null;
      }
    }

    final provider = ResizeImage(
      MemoryImage(bytes),
      width: pixelSize,
      height: pixelSize,
    );
    _imageProviderCache[key] = provider;
    return provider;
  }

  ImageProvider? getCachedImageProvider(int trackId, {String? namespace}) {
    return _imageProviderCache['${namespace ?? 'def'}:$trackId'];
  }

  void cacheImageProvider(
    int trackId,
    ImageProvider provider, {
    String? namespace,
  }) {
    _imageProviderCache['${namespace ?? 'def'}:$trackId'] = provider;
  }

  String? getCachedPath(int id) {
    if (_cacheDir == null) return null;
    final file = File('${_cacheDir!.path}/$id.jpg');
    return file.existsSync() ? file.path : null;
  }

  Future<Uint8List?> fetchArtistPhoto(String artistName, int artistId) async {
    if (_cache.containsKey(artistId)) return _cache[artistId];

    final dir = await _directory;
    final file = File('${dir.path}/$artistId.jpg');
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      _cache[artistId] = bytes;
      _cacheHit(artistId);
      _evictIfNeeded();
      return bytes;
    }

    final url = await ArtistPhotoServiceWrapper.inst.getArtistPhotoUrl(
      artistName,
    );
    if (url == null || url.isEmpty) return null;

    await _acquireOnline();
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final bytes = response.bodyBytes;
      if (bytes.isEmpty) return null;

      await file.writeAsBytes(bytes);
      _trimDiskIfNeeded();
      _cache[artistId] = bytes;
      _cacheHit(artistId);
      _evictIfNeeded();
      return bytes;
    } catch (_) {
      return null;
    } finally {
      _releaseOnline();
    }
  }

  Future<void> clearCache() async {
    _cache.clear();
    _imageProviderCache.clear();
    _cacheOrder.clear();
    _nullCache.clear();
    _loggedNulls.clear();
    final dir = await _directory;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
