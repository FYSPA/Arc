import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../data/models/track.dart';
import 'media_store_service.dart';

class ArtworkService {
  ArtworkService._();
  static final inst = ArtworkService._();

  final _cache = <int, Uint8List>{};
  final _nullCache = <int>{};
  Directory? _cacheDir;

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
    if (_nullCache.contains(id)) return null;

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
        _nullCache.add(id);
      }

      return artwork;
    } finally {
      _release();
    }
  }

  Future<ImageProvider?> getArtworkImage(ArcTrack track) async {
    final albumId = track.albumId;
    if (albumId == null) return null;

    final bytes = await getArtwork(albumId, MediaType.album);
    if (bytes == null || bytes.isEmpty) return null;

    return MemoryImage(bytes);
  }

  String? getCachedPath(int id) {
    if (_cacheDir == null) return null;
    final file = File('${_cacheDir!.path}/$id.jpg');
    return file.existsSync() ? file.path : null;
  }

  Future<void> clearCache() async {
    _cache.clear();
    _nullCache.clear();
    final dir = await _directory;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
