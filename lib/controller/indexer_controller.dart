import 'package:flutter/foundation.dart';

import '../data/models/track.dart';
import '../data/models/album.dart';
import '../data/models/artist.dart';
import '../services/media_store_service.dart';
import '../services/permission_service.dart';
import 'settings_controller.dart';

enum SortType { name, date, duration, artist, album }

class IndexerController extends ChangeNotifier {
  IndexerController._();
  static final inst = IndexerController._();

  List<ArcTrack> _allTracks = [];
  List<ArcTrack> _trackList = [];
  List<ArcAlbum> _albumList = [];
  List<ArcArtist> _artistList = [];

  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  SortType _currentSort = SortType.name;
  bool _sortReverse = false;

  int _loadedCount = 0;
  bool _hasMoreTracks = true;
  bool _isLoadingMore = false;
  static const _chunkSize = 50;

  List<ArcTrack> get trackList => _sortedTracks;
  List<ArcAlbum> get albumList => _albumList;
  List<ArcArtist> get artistList => _artistList;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  SortType get currentSort => _currentSort;
  bool get sortReverse => _sortReverse;
  bool get hasMoreTracks => _hasMoreTracks;
  bool get isLoadingMore => _isLoadingMore;

  List<ArcTrack> get _sortedTracks {
    final list = List<ArcTrack>.from(_trackList);
    switch (_currentSort) {
      case SortType.name:
        list.sort((a, b) => a.title.compareTo(b.title));
      case SortType.date:
        list.sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));
      case SortType.duration:
        list.sort((a, b) => (a.duration ?? 0).compareTo(b.duration ?? 0));
      case SortType.artist:
        list.sort((a, b) => a.artist.compareTo(b.artist));
      case SortType.album:
        list.sort((a, b) => a.album.compareTo(b.album));
    }
    if (_sortReverse) return list.reversed.toList();
    return list;
  }

  List<ArcTrack> recentlyAdded({int limit = 5}) {
    final sorted = List<ArcTrack>.from(_trackList);
    sorted.sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));
    return sorted.take(limit).toList();
  }

  void setSortType(SortType type) {
    if (_currentSort == type) {
      _sortReverse = !_sortReverse;
    } else {
      _currentSort = type;
      _sortReverse = false;
    }
    notifyListeners();
  }

  bool _hasPermission = false;
  bool get hasPermission => _hasPermission;
  bool _isRequestingPermission = false;

  Future<bool> checkPermission() async {
    final result = await PermissionService.inst.check();
    _hasPermission = result;
    notifyListeners();
    return _hasPermission;
  }

  Future<bool> requestPermission() async {
    if (_isRequestingPermission) return _hasPermission;
    _isRequestingPermission = true;
    try {
      _hasPermission = await PermissionService.inst.request();
      SettingsController.inst.setStoragePermission(_hasPermission);
      notifyListeners();
      return _hasPermission;
    } catch (e) {
      return _hasPermission;
    } finally {
      _isRequestingPermission = false;
    }
  }

  Future<void> scanDevice() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    _loadedCount = 0;
    _hasMoreTracks = true;
    _trackList = [];
    notifyListeners();

    try {
      if (!_hasPermission) {
        final granted = await checkPermission();
        if (!granted) {
          _hasError = true;
          _errorMessage = 'Storage permission denied';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      final media = MediaStoreService.inst;

      try {
        final songMaps = await media.querySongs();
        final folders = SettingsController.inst.foldersToScan;
        _allTracks = songMaps
            .map(ArcTrack.fromMap)
            .where((s) => (s.duration ?? 0) > 1000)
            .where((s) {
              if (folders.isEmpty || s.filePath == null) return true;
              return folders.any((f) => s.filePath!.startsWith(f));
            })
            .toList();
        await _loadNextChunk();
      } catch (e) {
        debugPrint('[ARC] scanDevice: querySongs ERROR $e');
      }

      try {
        final albumMaps = await media.queryAlbums();
        _albumList = albumMaps.map(ArcAlbum.fromMap).toList();
      } catch (e) {
        debugPrint('[ARC] scanDevice: queryAlbums ERROR $e');
      }

      try {
        final artistMaps = await media.queryArtists();
        _artistList = artistMaps.map(ArcArtist.fromMap).toList();
      } catch (e) {
        debugPrint('[ARC] scanDevice: queryArtists ERROR $e');
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadNextChunk() async {
    if (_loadedCount >= _allTracks.length) {
      _hasMoreTracks = false;
      return;
    }

    final end = (_loadedCount + _chunkSize).clamp(0, _allTracks.length);
    final chunk = _allTracks.sublist(_loadedCount, end);
    _trackList.addAll(chunk);
    _loadedCount = end;
    _hasMoreTracks = _loadedCount < _allTracks.length;
    notifyListeners();

    if (_hasMoreTracks) {
      await Future.delayed(const Duration(milliseconds: 30));
      await _loadNextChunk();
    }
  }

  Future<void> loadMoreTracks() async {
    if (_isLoadingMore || !_hasMoreTracks) return;

    _isLoadingMore = true;
    notifyListeners();

    await _loadNextChunk();

    _isLoadingMore = false;
    notifyListeners();
  }
}
