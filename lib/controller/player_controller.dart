import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arc_engine/arc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/track.dart';

import '../core/utils.dart';

enum ArcRepeatMode { off, all, one }

class PlayerController extends ChangeNotifier {
  PlayerController._();
  static final inst = PlayerController._();

  final TrackPlayer _player = AudioEngine.instance.tracks[0];

  ArcTrack? _currentTrack;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  ArcRepeatMode _repeatMode = ArcRepeatMode.off;
  bool _shuffleMode = false;
  FlacMetadataData? _metadata;

  List<ArcTrack> _queue = [];
  int _queueIndex = -1;

  DateTime _lastPlayCall = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastSaveTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastNotifyTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastNotifyLogTime = DateTime.fromMillisecondsSinceEpoch(0);
  int _notifyCount = 0;
  int _consecutiveSkips = 0;
  static const _maxConsecutiveSkips = 5;
  bool _isRestoring = false;
  bool _streamsInitialized = false;
  StreamSubscription<PlaybackState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<String>? _nameSub;
  StreamSubscription<String>? _abortSub;
  StreamSubscription<FlacMetadataData?>? _metaSub;
  StreamSubscription<MediaCommand>? _commandSub;

  ArcTrack? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  ArcRepeatMode get repeatMode => _repeatMode;
  bool get shuffleMode => _shuffleMode;
  FlacMetadataData? get metadata => _metadata;
  List<ArcTrack> get queue => List.unmodifiable(_queue);
  int get queueIndex => _queueIndex;
  bool get hasTrack => _currentTrack != null;
  bool get hasQueue => _queue.isNotEmpty;

  @override
  void notifyListeners() {
    _notifyCount++;
    final now = DateTime.now();
    if (now.difference(_lastNotifyLogTime).inSeconds >= 3) {
      logD(
        '[PERF] PlayerController.notifyListeners — $_notifyCount calls in last ${now.difference(_lastNotifyLogTime).inSeconds}s',
      );
      _notifyCount = 0;
      _lastNotifyLogTime = now;
    }
    super.notifyListeners();
  }

  String get title {
    if (_metadata != null && _metadata!.title.isNotEmpty) {
      return _metadata!.titleClean.isNotEmpty
          ? _metadata!.titleClean
          : _metadata!.title;
    }
    return _currentTrack?.title ?? '';
  }

  String get artist {
    if (_metadata != null && _metadata!.artist.isNotEmpty) {
      return _metadata!.artist;
    }
    return _currentTrack?.artist ?? '';
  }

  String get album {
    if (_metadata != null && _metadata!.album.isNotEmpty) {
      return _metadata!.album;
    }
    return _currentTrack?.album ?? '';
  }

  void _ensureStreams() {
    if (_streamsInitialized) return;
    _streamsInitialized = true;

    _stateSub = _player.onStateChanged.listen((state) {
      if (state == PlaybackState.stopped && _currentTrack != null) {
        final elapsed = DateTime.now().difference(_lastPlayCall).inMilliseconds;
        if (elapsed > 500) {
          _skipToNextOnFailure();
        }
      }
    });

    _posSub = _player.onPositionChanged.listen((pos) {
      _position = pos;
      final now = DateTime.now();
      if (now.difference(_lastNotifyTime).inMilliseconds >= 500) {
        _lastNotifyTime = now;
        notifyListeners();
      }
      if (!_isRestoring &&
          _currentTrack != null &&
          DateTime.now().difference(_lastSaveTime).inSeconds >= 5) {
        _lastSaveTime = DateTime.now();
        _savePlaybackState();
      }
    });

    _nameSub = _player.onNameChanged.listen((name) {
      if (_player.isGaplessTransition) {
        _onGaplessTransition(name);
      }
    });

    _abortSub = _player.onGaplessAborted.listen((name) {
      _onGaplessAborted(name);
    });

    _metaSub = _player.onMetadataLoaded.listen((meta) {
      _metadata = meta;
      notifyListeners();
    });
  }

  void _onGaplessTransition(String newName) {
    if (_queue.isNotEmpty && _queueIndex < _queue.length - 1) {
      _queueIndex++;
      _currentTrack = _queue[_queueIndex];
      _metadata = _player.metadata;
      _duration = _player.duration;
      _position = Duration.zero;
      _isPlaying = true;
      _queueNext();
      _savePlaybackState();
      notifyListeners();
    } else {
      _currentTrack = null;
      _isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      _metadata = null;
      notifyListeners();
    }
  }

  void _onGaplessAborted(String failedName) {
    logD('[ARC] gapless aborted: $failedName');
    _skipToNextOnFailure();
  }

  void _skipToNextOnFailure() {
    _consecutiveSkips++;
    if (_consecutiveSkips > _maxConsecutiveSkips) {
      logD('[ARC] too many consecutive skips ($_consecutiveSkips), stopping');
      _isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      _metadata = null;
      _currentTrack = null;
      _consecutiveSkips = 0;
      notifyListeners();
      return;
    }

    if (_queue.isEmpty) {
      _isPlaying = false;
      _consecutiveSkips = 0;
      notifyListeners();
      return;
    }

    final nextIndex = _queueIndex + 1;
    if (nextIndex < _queue.length) {
      final next = _queue[nextIndex];
      if (next.filePath != null && File(next.filePath!).existsSync()) {
        logD(
          '[ARC] skipping failed track (#$_consecutiveSkips), playing: ${next.title}',
        );
        playTrack(next, index: nextIndex);
      } else {
        _queueIndex = nextIndex;
        _skipToNextOnFailure();
      }
    } else if (_repeatMode == ArcRepeatMode.all) {
      final first = _queue.first;
      if (first.filePath != null && File(first.filePath!).existsSync()) {
        logD('[ARC] skipping failed track, looping to: ${first.title}');
        playTrack(first, index: 0);
      } else {
        _isPlaying = false;
        _position = Duration.zero;
        _duration = Duration.zero;
        _metadata = null;
        _currentTrack = null;
        _consecutiveSkips = 0;
        notifyListeners();
      }
    } else {
      _isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      _metadata = null;
      _currentTrack = null;
      _consecutiveSkips = 0;
      notifyListeners();
    }
  }

  void _queueNext() {
    if (_repeatMode == ArcRepeatMode.one) {
      if (_currentTrack?.filePath != null) {
        _player.setNextTrack(
          _currentTrack!.filePath,
          name: _currentTrack!.title,
        );
      }
      return;
    }

    if (_queue.isEmpty) {
      _player.clearNextTrack();
      return;
    }

    final nextIndex = _queueIndex + 1;
    if (nextIndex < _queue.length) {
      final next = _queue[nextIndex];
      if (next.filePath != null) {
        _player.setNextTrack(next.filePath, name: next.title);
      }
    } else if (_repeatMode == ArcRepeatMode.all) {
      _queueIndex = -1;
      final first = _queue.first;
      if (first.filePath != null) {
        _player.setNextTrack(first.filePath, name: first.title);
      }
    } else {
      _player.clearNextTrack();
    }
  }

  Future<void> playTrack(
    ArcTrack track, {
    List<ArcTrack>? queue,
    int? index,
  }) async {
    _ensureStreams();

    if (track.filePath == null || track.filePath!.isEmpty) {
      logD('[ARC] track has no filePath: ${track.title}');
      _skipToNextOnFailure();
      return;
    }

    if (!File(track.filePath!).existsSync()) {
      logD('[ARC] file not found on disk: ${track.filePath}');
      _skipToNextOnFailure();
      return;
    }

    _currentTrack = track;
    _position = Duration.zero;
    _metadata = null;

    if (queue != null) {
      _queue = List.from(queue);
      _queueIndex = index ?? _queue.indexOf(track);
    } else if (!_queue.contains(track)) {
      _queue = [track];
      _queueIndex = 0;
    } else {
      _queueIndex = _queue.indexOf(track);
    }

    _lastPlayCall = DateTime.now();
    final result = _player.play(track.filePath!);
    if (result == 0) {
      _consecutiveSkips = 0;
      _duration = _player.duration;
      if (_duration.inMilliseconds <= 0 &&
          track.duration != null &&
          track.duration! > 0) {
        _duration = Duration(milliseconds: track.duration!);
      }
      _metadata = _player.metadata;
      _isPlaying = true;
      _queueNext();
    } else {
      logD('[ARC] play() failed for: ${track.title} (${track.filePath})');
      _isPlaying = false;
      _skipToNextOnFailure();
      return;
    }

    _updateMediaSession();
    _savePlaybackState();
    notifyListeners();
  }

  void playPause() {
    if (_currentTrack == null) return;

    if (_isPlaying) {
      _player.pause();
    } else {
      _player.resume();
    }
    _isPlaying = !_isPlaying;
    if (!_isPlaying) _savePlaybackState();
    _updateMediaSession();
    notifyListeners();
  }

  void skipNext() {
    if (_queue.isEmpty) return;

    int nextIndex;
    if (_shuffleMode) {
      nextIndex = _getRandomIndex();
    } else {
      nextIndex = _queueIndex + 1;
      if (nextIndex >= _queue.length) {
        if (_repeatMode == ArcRepeatMode.all) {
          nextIndex = 0;
        } else {
          return;
        }
      }
    }

    if (nextIndex >= 0 && nextIndex < _queue.length) {
      playTrack(_queue[nextIndex], index: nextIndex);
    }
  }

  void skipPrevious() {
    if (_queue.isEmpty) return;

    if (_position.inSeconds > 3) {
      seek(Duration.zero);
      return;
    }

    int prevIndex = _queueIndex - 1;
    if (prevIndex < 0) {
      if (_repeatMode == ArcRepeatMode.all) {
        prevIndex = _queue.length - 1;
      } else {
        prevIndex = 0;
      }
    }

    playTrack(_queue[prevIndex], index: prevIndex);
  }

  void seek(Duration position) {
    _player.seek(position);
  }

  void setArcRepeatMode(ArcRepeatMode mode) {
    _repeatMode = mode;
    if (mode == ArcRepeatMode.one) {
      _player.repeatCount = -1;
    } else {
      _player.repeatCount = 0;
    }
    notifyListeners();
  }

  void toggleArcRepeatMode() {
    switch (_repeatMode) {
      case ArcRepeatMode.off:
        setArcRepeatMode(ArcRepeatMode.all);
        break;
      case ArcRepeatMode.all:
        setArcRepeatMode(ArcRepeatMode.one);
        break;
      case ArcRepeatMode.one:
        setArcRepeatMode(ArcRepeatMode.off);
        break;
    }
  }

  void toggleShuffleMode() {
    _shuffleMode = !_shuffleMode;
    notifyListeners();
  }

  void addToQueue(ArcTrack track) {
    if (_queue.isEmpty && _currentTrack == null) {
      playTrack(track);
      return;
    }
    _queue.add(track);
    notifyListeners();
  }

  void playNext(ArcTrack track) {
    if (_queue.isEmpty) {
      addToQueue(track);
      return;
    }
    final insertAt = (_queueIndex + 1).clamp(0, _queue.length);
    _queue.insert(insertAt, track);
    _queueNext();
    notifyListeners();
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    if (index < _queueIndex) {
      _queueIndex--;
    } else if (index == _queueIndex && _queueIndex >= _queue.length) {
      _queueIndex = _queue.length - 1;
    }
    _queueNext();
    notifyListeners();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    if (oldIndex < 0 || oldIndex >= _queue.length) return;
    if (newIndex < 0 || newIndex >= _queue.length) return;

    final track = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, track);

    if (oldIndex == _queueIndex) {
      _queueIndex = newIndex;
    } else if (oldIndex < _queueIndex && newIndex >= _queueIndex) {
      _queueIndex--;
    } else if (oldIndex > _queueIndex && newIndex <= _queueIndex) {
      _queueIndex++;
    }

    _queueNext();
    notifyListeners();
  }

  void clearQueue() {
    _player.clearNextTrack();
    _queue.clear();
    _queueIndex = -1;
    notifyListeners();
  }

  int _getRandomIndex() {
    if (_queue.length <= 1) return 0;
    int next;
    do {
      next = DateTime.now().microsecondsSinceEpoch % _queue.length;
    } while (next == _queueIndex);
    return next;
  }

  void stop() {
    _player.stop();
    _isPlaying = false;
    _position = Duration.zero;
    _currentTrack = null;
    _metadata = null;
    _duration = Duration.zero;
    _queue.clear();
    _queueIndex = -1;
    _hideMediaSession();
    _clearPlaybackState();
    notifyListeners();
  }

  // ──────────────────── Playback persistence ────────────────────

  Future<void> _savePlaybackState() async {
    if (_currentTrack == null) return;
    try {
      logD(
        '[ARC] saving state: ${_currentTrack!.title} @ ${_position.inMilliseconds}ms',
      );
      final queueJson = _queue
          .map(
            (t) => {
              'id': t.id,
              'filePath': t.filePath ?? '',
              'title': t.title,
              'artist': t.artist,
              'album': t.album,
              'duration': t.duration ?? 0,
              'fileSize': t.fileSize ?? 0,
              'albumId': t.albumId ?? 0,
              'genre': t.genre ?? '',
              'track': t.track ?? 0,
            },
          )
          .toList();
      final state = {
        'track_id': _currentTrack!.id,
        'file_path': _currentTrack!.filePath ?? '',
        'title': _currentTrack!.title,
        'artist': _currentTrack!.artist,
        'album': _currentTrack!.album,
        'duration_ms': _currentTrack!.duration ?? 0,
        'file_size': _currentTrack!.fileSize ?? 0,
        'album_id': _currentTrack!.albumId ?? 0,
        'genre': _currentTrack!.genre ?? '',
        'track_number': _currentTrack!.track ?? 0,
        'position_ms': _position.inMilliseconds,
        'queue_index': _queueIndex,
        'repeat_mode': _repeatMode.index,
        'queue': queueJson,
      };
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pb_state', jsonEncode(state));
    } catch (e) {
      logD('[ARC] _savePlaybackState failed: $e');
    }
  }

  void _clearPlaybackState() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('pb_state');
    });
  }

  Future<bool> restorePlaybackState() async {
    final sw = Stopwatch()..start();
    _isRestoring = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString('pb_state');
      if (stateJson == null || stateJson.isEmpty) {
        _isRestoring = false;
        sw.stop();
        logD(
          '[PERF] restorePlaybackState: no saved state (${sw.elapsedMilliseconds}ms)',
        );
        return false;
      }
      final state = jsonDecode(stateJson) as Map<String, dynamic>;
      final filePath = state['file_path'] as String? ?? '';
      if (filePath.isEmpty || !File(filePath).existsSync()) {
        _clearPlaybackState();
        _isRestoring = false;
        sw.stop();
        logD(
          '[PERF] restorePlaybackState: file missing (${sw.elapsedMilliseconds}ms)',
        );
        return false;
      }

      final trackId = state['track_id'] as int? ?? 0;
      final title = state['title'] as String? ?? 'Unknown';
      final artist = state['artist'] as String? ?? 'Unknown Artist';
      final album = state['album'] as String? ?? 'Unknown Album';
      final duration = state['duration_ms'] as int?;
      final fileSize = state['file_size'] as int?;
      final albumId = state['album_id'] as int?;
      final genre = state['genre'] as String?;
      final trackNumber = state['track_number'] as int?;
      final positionMs = state['position_ms'] as int? ?? 0;
      final queueIndex = state['queue_index'] as int? ?? 0;
      final repeatIndex = state['repeat_mode'] as int? ?? 0;

      logD('[ARC] restoring: $title @ ${positionMs}ms');

      final track = ArcTrack(
        id: trackId,
        title: title,
        artist: artist,
        album: album,
        filePath: filePath,
        duration: duration,
        fileSize: fileSize,
        albumId: albumId,
        genre: genre,
        track: trackNumber,
      );

      List<ArcTrack> queue = [track];
      final queueList = state['queue'] as List?;
      if (queueList != null && queueList.isNotEmpty) {
        final restored = queueList
            .map((m) {
              final map = Map<String, dynamic>.from(m as Map);
              final path = map['filePath'] as String? ?? '';
              if (path.isEmpty || !File(path).existsSync()) return null;
              final fileName = path.split('/').last;
              if (fileName.isEmpty ||
                  !fileName[0].contains(RegExp(r'[a-zA-Z0-9\u00C0-\u024F]'))) {
                return null;
              }
              final f = File(path);
              final size = f.existsSync() ? f.lengthSync() : 0;
              if (size < 1024) return null;
              return ArcTrack.fromMap(map);
            })
            .whereType<ArcTrack>()
            .toList();
        if (restored.isNotEmpty) queue = restored;
      }

      final safeIndex = queueIndex.clamp(0, queue.length - 1);

      final curFile = File(filePath);
      final curSize = curFile.existsSync() ? curFile.lengthSync() : 0;
      if (curSize < 1024) {
        _clearPlaybackState();
        _isRestoring = false;
        sw.stop();
        logD(
          '[PERF] restorePlaybackState: current track too small (${sw.elapsedMilliseconds}ms)',
        );
        return false;
      }

      _ensureStreams();
      _lastPlayCall = DateTime.now();
      _lastSaveTime = DateTime.now();
      _currentTrack = track;
      _queue = queue;
      _queueIndex = safeIndex;
      _position = Duration(milliseconds: positionMs);
      _repeatMode = ArcRepeatMode
          .values[repeatIndex.clamp(0, ArcRepeatMode.values.length - 1)];
      _metadata = null;

      final playSw = Stopwatch()..start();
      final result = _player.play(filePath);
      playSw.stop();
      logD(
        '[PERF] restorePlaybackState _player.play(): ${playSw.elapsedMilliseconds}ms',
      );

      if (result == 0) {
        final seekSw = Stopwatch()..start();
        _player.pause();
        _player.seek(_position);
        seekSw.stop();
        logD(
          '[PERF] restorePlaybackState pause+seek: ${seekSw.elapsedMilliseconds}ms',
        );

        _duration = _player.duration;
        if (_duration.inMilliseconds <= 0 && duration != null && duration > 0) {
          _duration = Duration(milliseconds: duration);
        }
        _isPlaying = false;
        _queueNext();
        _isRestoring = false;
        sw.stop();
        logD(
          '[PERF] restorePlaybackState TOTAL: ${sw.elapsedMilliseconds}ms — pos=${_position.inMilliseconds}ms',
        );
        notifyListeners();
        return true;
      }

      _currentTrack = null;
      _queue = [];
      _queueIndex = -1;
      _isRestoring = false;
      sw.stop();
      logD(
        '[PERF] restorePlaybackState: play() failed (${sw.elapsedMilliseconds}ms)',
      );
      return false;
    } catch (e) {
      logD('[ARC] restorePlaybackState failed: $e');
      _isRestoring = false;
      sw.stop();
      logD(
        '[PERF] restorePlaybackState EXCEPTION: ${sw.elapsedMilliseconds}ms',
      );
      return false;
    }
  }

  void _updateMediaSession() {
    if (_currentTrack == null) return;
    MediaSession.requestPermission().then((_) {
      MediaSession.ensureService().then((_) {
        MediaSession.setMetadata(
          title: title,
          artist: artist,
          album: album,
          durationMs: _duration.inMilliseconds,
        );
        MediaSession.setPlaybackState(
          isPlaying: _isPlaying,
          positionMs: _position.inMilliseconds,
        );
        MediaSession.show(title: title, artist: artist, isPlaying: _isPlaying);
      });
    });
  }

  void _hideMediaSession() {
    MediaSession.hide();
  }

  void initMediaSessionCommands() {
    _ensureStreams();
    _commandSub?.cancel();
    _commandSub = MediaSession.onCommand.listen((cmd) {
      switch (cmd) {
        case MediaCommandPlay():
          playPause();
          break;
        case MediaCommandPause():
          playPause();
          break;
        case MediaCommandStop():
          stop();
          break;
        case MediaCommandNext():
          skipNext();
          break;
        case MediaCommandPrevious():
          skipPrevious();
          break;
        case MediaCommandSeekTo(:final positionMs):
          seek(Duration(milliseconds: positionMs));
          break;
      }
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _nameSub?.cancel();
    _abortSub?.cancel();
    _metaSub?.cancel();
    _commandSub?.cancel();
    super.dispose();
  }
}
