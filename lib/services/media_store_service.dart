import 'package:flutter/services.dart';

enum MediaType { audio, album, artist }

class MediaStoreService {
  MediaStoreService._();
  static final inst = MediaStoreService._();
  static const _channel = MethodChannel('arc_app/media');

  Future<List<Map<String, dynamic>>> querySongs() async {
    try {
      final result = await _channel.invokeMethod<List>('querySongs');
      if (result == null) return [];
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> queryAlbums() async {
    try {
      final result = await _channel.invokeMethod<List>('queryAlbums');
      if (result == null) return [];
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> queryArtists() async {
    try {
      final result = await _channel.invokeMethod<List>('queryArtists');
      if (result == null) return [];
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> queryFolders() async {
    try {
      final result = await _channel.invokeMethod<List>('queryFolders');
      if (result == null) return [];
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Uint8List?> queryArtwork(int id, MediaType type) async {
    try {
      final result = await _channel.invokeMethod<Uint8List>('queryArtwork', {
        'id': id,
        'type': type.index,
      });
      return result;
    } catch (e) {
      return null;
    }
  }
}
