import 'dart:async';
import 'dart:io';

import 'package:arc_engine/arc_engine.dart';
import 'package:flutter/foundation.dart';

import '../data/models/track.dart';

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

  bool _streamsInitialized = false;
  StreamSubscription<PlaybackState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<String>? _nameSub;
  StreamSubscription<String>? _abortSub;
  StreamSubscription<FlacMetadataData?>? _metaSub;

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
        _position = Duration.zero;
        notifyListeners();
      }
    });

    _posSub = _player.onPositionChanged.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _nameSub = _player.onNameChanged.listen((name) {
      _onGaplessTransition(name);
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
    debugPrint('[ARC] gapless aborted: $failedName');
    _skipToNextOnFailure();
  }

  void _skipToNextOnFailure() {
    if (_queue.isEmpty) {
      _isPlaying = false;
      notifyListeners();
      return;
    }

    final nextIndex = _queueIndex + 1;
    if (nextIndex < _queue.length) {
      final next = _queue[nextIndex];
      if (next.filePath != null && File(next.filePath!).existsSync()) {
        debugPrint('[ARC] skipping failed track, playing: ${next.title}');
        playTrack(next, index: nextIndex);
      } else {
        _queueIndex = nextIndex;
        _skipToNextOnFailure();
      }
    } else if (_repeatMode == ArcRepeatMode.all) {
      final first = _queue.first;
      if (first.filePath != null && File(first.filePath!).existsSync()) {
        debugPrint('[ARC] skipping failed track, looping to: ${first.title}');
        playTrack(first, index: 0);
      } else {
        _isPlaying = false;
        _position = Duration.zero;
        _duration = Duration.zero;
        _metadata = null;
        _currentTrack = null;
        notifyListeners();
      }
    } else {
      _isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      _metadata = null;
      _currentTrack = null;
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
      debugPrint('[ARC] track has no filePath: ${track.title}');
      _skipToNextOnFailure();
      return;
    }

    if (!File(track.filePath!).existsSync()) {
      debugPrint('[ARC] file not found on disk: ${track.filePath}');
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

    final result = _player.play(track.filePath!);
    if (result == 0) {
      _duration = _player.duration;
      _metadata = _player.metadata;
      _isPlaying = true;
      _queueNext();
    } else {
      debugPrint('[ARC] play() failed for: ${track.title} (${track.filePath})');
      _isPlaying = false;
      _skipToNextOnFailure();
      return;
    }

    _updateMediaSession();
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
    _queue.add(track);
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
    notifyListeners();
  }

  Future<void> _updateMediaSession() async {
    if (_currentTrack == null) return;
    try {
      await MediaSession.requestPermission();
      await MediaSession.ensureService();
      await MediaSession.setMetadata(
        title: title,
        artist: artist,
        album: album,
        durationMs: _duration.inMilliseconds,
      );
      await MediaSession.setPlaybackState(
        isPlaying: _isPlaying,
        positionMs: _position.inMilliseconds,
      );
      await MediaSession.show(
        title: title,
        artist: artist,
        isPlaying: _isPlaying,
      );
    } catch (_) {}
  }

  Future<void> _hideMediaSession() async {
    try {
      await MediaSession.hide();
    } catch (_) {}
  }

  void initMediaSessionCommands() {
    _ensureStreams();
    MediaSession.onCommand.listen((cmd) {
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
    super.dispose();
  }
}
