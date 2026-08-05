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
  Directory? _cacheDir;

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

    final dir = await _directory;
    final file = File('${dir.path}/$id.jpg');

    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      _cache[id] = bytes;
      return bytes;
    }

    final artwork = await MediaStoreService.inst.queryArtwork(id, type);

    if (artwork != null && artwork.isNotEmpty) {
      await file.writeAsBytes(artwork);
      _cache[id] = artwork;
    }

    return artwork;
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
    final dir = await _directory;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
