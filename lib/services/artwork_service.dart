import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:arx_canvas/arx_canvas.dart' as arx;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../controller/settings_controller.dart';
import '../data/models/track.dart';
import 'animated_artwork_service.dart';
import 'artist_photo_service.dart';
import 'media_store_service.dart';

class ArtworkService {
  ArtworkService._();
  static final inst = ArtworkService._();

  final _cache = <int, Uint8List>{};
  final _imageProviderCache = <int, ImageProvider?>{};
  final _nullCache = <int, Set<MediaType>>{};
  final _loggedNulls = <int>{};
  Directory? _cacheDir;

  arx.ArtworkService? _onlineService;

  static const _maxConcurrent = 5;
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

    final dir = await _directory;
    final file = File('${dir.path}/$id.jpg');

    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      _cache[id] = bytes;
      return bytes;
    }

    await _acquire();
    try {
      final artwork = await MediaStoreService.inst.queryArtwork(id, type);

      if (artwork != null && artwork.isNotEmpty) {
        await file.writeAsBytes(artwork);
        _cache[id] = artwork;
      } else {
        _nullCache.putIfAbsent(id, () => {}).add(type);
      }

      return artwork;
    } finally {
      _release();
    }
  }

  Future<Uint8List?> _fetchOnlineArtwork(String? album, String? artist) async {
    if (album == null || album.isEmpty || artist == null || artist.isEmpty) {
      return null;
    }

    try {
      final result = await _getOnlineService().fetchArtwork(
        albumName: album,
        artistName: artist,
      );
      if (result == null || result.url.isEmpty) return null;

      final response = await http
          .get(Uri.parse(result.url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final bytes = response.bodyBytes;
      if (bytes.isEmpty) return null;

      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> getLocalArtwork(ArcTrack track) async {
    final bytes = await getArtwork(track.id, MediaType.audio);
    if (bytes != null && bytes.isNotEmpty) return bytes;

    if (track.albumId != null) {
      final albumBytes = await getArtwork(track.albumId!, MediaType.album);
      if (albumBytes != null && albumBytes.isNotEmpty) return albumBytes;
    }

    return null;
  }

  Future<Uint8List?> getTrackArtwork(ArcTrack track) async {
    final bytes = await getArtwork(track.id, MediaType.audio);
    if (bytes != null && bytes.isNotEmpty) return bytes;

    if (track.albumId != null) {
      final albumBytes = await getArtwork(track.albumId!, MediaType.album);
      if (albumBytes != null && albumBytes.isNotEmpty) return albumBytes;
    }

    final onlineBytes = await _fetchOnlineArtwork(track.album, track.artist);
    if (onlineBytes != null && onlineBytes.isNotEmpty) {
      final dir = await _directory;
      final cacheId = track.albumId ?? track.id;
      final file = File('${dir.path}/$cacheId.jpg');
      await file.writeAsBytes(onlineBytes);
      _cache[cacheId] = onlineBytes;
      return onlineBytes;
    }

    final animated = await AnimatedArtworkService.inst.fetchForTrack(
      track,
      null,
    );
    if (animated?.staticImageUrl != null &&
        animated!.staticImageUrl!.isNotEmpty) {
      try {
        final response = await http
            .get(Uri.parse(animated.staticImageUrl!))
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          final dir = await _directory;
          final cacheId = track.albumId ?? track.id;
          final file = File('${dir.path}/$cacheId.jpg');
          await file.writeAsBytes(response.bodyBytes);
          _cache[cacheId] = response.bodyBytes;
          return response.bodyBytes;
        }
      } catch (_) {}
    }

    return null;
  }

  Future<ImageProvider?> getArtworkImage(ArcTrack track) async {
    final cached = _imageProviderCache[track.id];
    if (cached != null) return cached;

    final bytes = await getTrackArtwork(track);
    if (bytes == null || bytes.isEmpty) {
      if (_loggedNulls.add(track.id)) {
        debugPrint(
          '[ArtworkService] no artwork for "${track.title}" (albumId=${track.albumId})',
        );
      }
      return null;
    }

    if (_loggedNulls.remove(track.id)) {
      debugPrint(
        '[ArtworkService] loaded artwork for "${track.title}" (${bytes.length} bytes)',
      );
    }
    final image = MemoryImage(bytes);
    _imageProviderCache[track.id] = image;
    return image;
  }

  ImageProvider? getCachedImageProvider(int trackId) {
    return _imageProviderCache[trackId];
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
      return bytes;
    }

    final url = await ArtistPhotoServiceWrapper.inst.getArtistPhotoUrl(
      artistName,
    );
    if (url == null || url.isEmpty) return null;

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final bytes = response.bodyBytes;
      if (bytes.isEmpty) return null;

      await file.writeAsBytes(bytes);
      _cache[artistId] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCache() async {
    _cache.clear();
    _imageProviderCache.clear();
    _nullCache.clear();
    _loggedNulls.clear();
    final dir = await _directory;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
