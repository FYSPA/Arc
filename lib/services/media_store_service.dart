import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

enum MediaType { audio, album, artist }

class MediaStoreService {
  MediaStoreService._();
  static final inst = MediaStoreService._();
  static const _channel = MethodChannel('arc_app/media');

  static bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  Future<List<Map<String, dynamic>>> querySongs() async {
    if (!_isMobile) return [];
    try {
      final result = await _channel.invokeMethod<List>('querySongs');
      if (result == null) return [];
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> queryAlbums() async {
    if (!_isMobile) return [];
    try {
      final result = await _channel.invokeMethod<List>('queryAlbums');
      if (result == null) return [];
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> queryArtists() async {
    if (!_isMobile) return [];
    try {
      final result = await _channel.invokeMethod<List>('queryArtists');
      if (result == null) return [];
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> queryFolders() async {
    if (!_isMobile) return [];
    try {
      final result = await _channel.invokeMethod<List>('queryFolders');
      if (result == null) return [];
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Uint8List?> queryArtwork(int id, MediaType type) async {
    if (!_isMobile) return null;
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
