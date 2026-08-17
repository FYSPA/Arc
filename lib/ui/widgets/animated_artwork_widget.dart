import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:video_player/video_player.dart';
import 'package:arx_canvas/arx_canvas.dart';

import '../../core/broken_icons.dart';
import '../../data/models/track.dart';
import '../../services/animated_artwork_service.dart';
import '../../services/artwork_service.dart' as local;

import '../../core/utils.dart';

class AnimatedArtworkWidget extends StatefulWidget {
  final ArcTrack track;
  final bool isPlaying;
  final double size;
  final double borderRadius;

  const AnimatedArtworkWidget({
    super.key,
    required this.track,
    this.isPlaying = true,
    this.size = 280,
    this.borderRadius = 24,
  });

  @override
  State<AnimatedArtworkWidget> createState() => _AnimatedArtworkWidgetState();
}

class _AnimatedArtworkWidgetState extends State<AnimatedArtworkWidget> {
  VideoPlayerController? _controller;
  AnimatedArtwork? _artwork;
  ImageProvider? _staticImage;
  bool _videoReady = false;
  bool _disposed = false;
  String? _currentTrackKey;

  bool get _hasVideo =>
      _artwork != null &&
      _artwork!.hasAnimation &&
      _artwork!.preferredAnimationUrl != null &&
      _controller != null &&
      _controller!.value.isInitialized;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (!_disposed && mounted) _loadArtwork();
      });
    });
  }

  @override
  void didUpdateWidget(covariant AnimatedArtworkWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track.id != widget.track.id) {
      _loadArtwork();
    } else if (oldWidget.isPlaying != widget.isPlaying) {
      final c = _controller;
      if (c != null && _hasVideo) {
        widget.isPlaying ? c.play() : c.pause();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    final c = _controller;
    _controller = null;
    _videoReady = false;
    try {
      c?.dispose();
    } catch (e) {
      logD('[AnimatedArtwork] dispose error: $e');
    }
  }

  Future<void> _loadArtwork() async {
    final key = widget.track.filePath ?? '${widget.track.id}';
    if (_currentTrackKey == key) return;
    _currentTrackKey = key;
    logD(
      '[AnimatedArtwork] _loadArtwork for ${widget.track.title} (${widget.track.artist}) key=$key',
    );

    _disposeController();
    _artwork = null;
    _staticImage = null;
    _videoReady = false;
    if (mounted) setState(() {});

    try {
      // Show the cached LOCAL high-res artwork immediately as the static
      // frame. Don't reuse the miniplayer's low-res thumbnail cache, and don't
      // fetch online for art that already exists locally (no baja→alta flash).
      final localBytes = await local.ArtworkService.inst.getLocalArtwork(
        widget.track,
      );
      if (_disposed || !mounted || _currentTrackKey != key) return;
      if (localBytes != null && localBytes.isNotEmpty) {
        _staticImage = MemoryImage(localBytes);
        logD('[AnimatedArtwork] static artwork from local cache');
        setState(() {});
      } else {
        // Local art missing: fill from online in the background (no flash).
        local.ArtworkService.inst.getTrackArtwork(widget.track).then((online) {
          if (_disposed || !mounted || _currentTrackKey != key) return;
          if (online != null && online.isNotEmpty) {
            _staticImage = MemoryImage(online);
            logD('[AnimatedArtwork] static artwork filled from online');
            setState(() {});
          }
        });
      }

      // Animated artwork — runs independently, takes seconds
      final artwork = await AnimatedArtworkService.inst.fetchForTrack(
        widget.track,
        null,
      );

      if (_disposed || !mounted || _currentTrackKey != key) return;

      _artwork = artwork;
      logD(
        '[AnimatedArtwork] animated result: ${artwork != null ? "hasAnimation=${artwork.hasAnimation}, url=${artwork.preferredAnimationUrl}" : "NULL"}',
      );

      // Fallback: use staticImageUrl from animated artwork if MediaStore has no artwork
      if (_staticImage == null && artwork?.staticImageUrl != null) {
        logD('[AnimatedArtwork] using staticImageUrl fallback');
        _staticImage = NetworkImage(artwork!.staticImageUrl!);
      }

      logD('[AnimatedArtwork] static artwork loaded: ${_staticImage != null}');

      if (mounted) setState(() {});

      if (artwork != null && artwork.hasAnimation) {
        final url = artwork.preferredAnimationUrl;
        if (url != null && url.isNotEmpty) {
          await _openMedia(url, key);
          return;
        }
      }
    } catch (e) {
      if (_disposed || !mounted || _currentTrackKey != key) return;
      logD('[AnimatedArtwork] _loadArtwork error: $e');
      if (mounted) setState(() {});
    }
  }

  Future<void> _openMedia(String url, String expectedKey) async {
    try {
      logD('[AnimatedArtwork] _openMedia: $url');

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: const {'User-Agent': 'Arc/1.0'},
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      if (_disposed || !mounted || _currentTrackKey != expectedKey) {
        controller.dispose();
        return;
      }

      _controller = controller;

      await controller.initialize();
      if (_disposed || !mounted || _currentTrackKey != expectedKey) return;

      await controller.setLooping(true);
      await controller.setVolume(0.0);

      if (_disposed || !mounted || _currentTrackKey != expectedKey) return;

      if (widget.isPlaying) {
        controller.play();
      }

      logD(
        '[AnimatedArtwork] initialized: ${controller.value.size.width}x${controller.value.size.height}',
      );

      // Video is ready - start crossfade to animated
      if (!_disposed && mounted) {
        logD('[AnimatedArtwork] video ready, crossfading to animated');
        _videoReady = true;
        setState(() {});
      }
    } catch (e) {
      logD('[AnimatedArtwork] _openMedia error: $e');
      if (_disposed || !mounted || _currentTrackKey != expectedKey) return;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasVideo = _controller != null && _controller!.value.isInitialized;

    return SizedBox.expand(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasVideo)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              ),
            if (!_videoReady)
              Positioned.fill(child: _buildStaticArtwork(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticArtwork(ThemeData theme) {
    if (_staticImage != null) {
      return Image(
        image: _staticImage!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }
    return Container(
      color: theme.cardColor,
      child: Icon(
        Broken.musicnote,
        size: 48,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
