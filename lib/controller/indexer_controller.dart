import 'package:flutter/foundation.dart';

import '../data/models/track.dart';
import '../data/models/album.dart';
import '../data/models/artist.dart';
import '../services/media_store_service.dart';
import '../services/permission_service.dart';
import 'settings_controller.dart';

import '../core/utils.dart';

enum SortType { name, date, duration, artist, album }

class _ArtistInfo {
  String name;
  int trackCount = 0;
  final albumIds = <int?>{};
  _ArtistInfo({required this.name});
}

class IndexerController extends ChangeNotifier {
  IndexerController._();
  static final inst = IndexerController._();

  List<ArcTrack> _allTracks = [];
  List<ArcTrack> _trackList = [];
  List<ArcAlbum> _albumList = [];
  List<ArcArtist> _artistList = [];

  bool _isLoading = false;
  bool _pendingRescan = false;
  bool _hasError = false;
  String _errorMessage = '';
  SortType _currentSort = SortType.name;
  bool _sortReverse = false;
  List<ArcTrack>? _sortedTracksCache;
  bool _sortedTracksDirty = true;

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

  static String _normalizeName(String name) {
    return name
        .replaceAll(RegExp(r'[\u00A0\u2000-\u200B\u202F\u205F\u3000]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
  }

  static final _collabSep = RegExp(
    r',\s*|&\s*|\s+feat\.?\s+|\s+ft\.?\s+|\s+vs\.?\s+|\s+x\s+',
    caseSensitive: false,
  );

  static List<ArcArtist> _buildArtistsFromTracks(List<ArcTrack> tracks) {
    final map = <String, _ArtistInfo>{};
    for (final track in tracks) {
      final names = track.artist.split(_collabSep);
      for (final name in names) {
        final key = _normalizeName(name);
        if (key.isEmpty) continue;
        map.putIfAbsent(key, () => _ArtistInfo(name: name.trim()));
        map[key]!.trackCount++;
        map[key]!.albumIds.add(track.albumId);
      }
    }
    return map.entries
        .map(
          (e) => ArcArtist(
            id: e.value.name.toLowerCase().hashCode,
            artist: e.value.name,
            numOfAlbums: e.value.albumIds.length,
            numOfSongs: e.value.trackCount,
          ),
        )
        .toList()
      ..sort((a, b) => a.artist.compareTo(b.artist));
  }

  List<ArcTrack> getTracksByArtist(String artistName) {
    final key = _normalizeName(artistName);
    return _trackList.where((t) {
      return t.artist.split(_collabSep).any((n) => _normalizeName(n) == key);
    }).toList();
  }

  List<ArcTrack> getTracksByAlbum(String albumName) {
    final normalized = _normalizeName(albumName);
    return _trackList
        .where((t) => _normalizeName(t.album) == normalized)
        .toList();
  }

  List<ArcTrack> getTracksByFolder(String folderPath) {
    return _trackList
        .where((t) => t.filePath?.startsWith(folderPath) == true)
        .toList();
  }

  List<ArcTrack> get _sortedTracks {
    if (_sortedTracksCache != null && !_sortedTracksDirty) {
      return _sortedTracksCache!;
    }
    final sw = Stopwatch()..start();
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
    if (_sortReverse) {
      _sortedTracksCache = list.reversed.toList();
    } else {
      _sortedTracksCache = list;
    }
    _sortedTracksDirty = false;
    sw.stop();
    if (sw.elapsedMilliseconds > 5) {
      logD(
        '[ARC] _sortedTracks: ${sw.elapsedMilliseconds}ms '
        '(${list.length} items, sort=${_currentSort.name})',
      );
    }
    return _sortedTracksCache!;
  }

  void _invalidateSortCache() {
    _sortedTracksDirty = true;
    _sortedTracksCache = null;
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
    _invalidateSortCache();
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
    if (_isLoading) {
      // A newer scan was requested while one is in flight: remember it and
      // run it once the current one finishes, so a folder-aware re-scan is
      // never silently dropped by the _isLoading guard.
      _pendingRescan = true;
      return;
    }
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    _loadedCount = 0;
    _hasMoreTracks = true;
    _trackList = [];
    _albumList = [];
    _artistList = [];
    _invalidateSortCache();
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
        logD('[ARC] scanDevice: querySongs ERROR $e');
      }

      try {
        final albumMaps = await media.queryAlbums();
        final rawAlbums = albumMaps.map(ArcAlbum.fromMap).toList();
        final albumByName = <String, ArcAlbum>{};
        for (final album in rawAlbums) {
          final key = _normalizeName(album.album);
          final existing = albumByName[key];
          if (existing == null ||
              (album.numOfSongs ?? 0) > (existing.numOfSongs ?? 0)) {
            albumByName[key] = album;
          }
        }
        _albumList = albumByName.values.toList()
          ..sort((a, b) => a.album.compareTo(b.album));
      } catch (e) {
        logD('[ARC] scanDevice: queryAlbums ERROR $e');
      }

      _artistList = _buildArtistsFromTracks(_trackList);
    } catch (e) {
      _hasError = true;
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();

    if (_pendingRescan) {
      _pendingRescan = false;
      scanDevice();
    }
  }

  Future<void> _loadNextChunk() async {
    if (_loadedCount >= _allTracks.length) {
      _hasMoreTracks = false;
      return;
    }

    final end = (_loadedCount + _chunkSize).clamp(0, _allTracks.length);
    final chunk = _allTracks.sublist(_loadedCount, end);
    _trackList.addAll(chunk);
    _invalidateSortCache();
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
