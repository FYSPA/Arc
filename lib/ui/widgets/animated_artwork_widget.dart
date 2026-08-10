import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:arx_canvas/arx_canvas.dart';

import '../../core/broken_icons.dart';
import '../../data/models/track.dart';
import '../../services/animated_artwork_service.dart';
import '../../services/artwork_service.dart' as local;

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
    _loadArtwork();
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
    if (c != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        c.dispose();
      });
    }
  }

  Future<void> _loadArtwork() async {
    final key = widget.track.filePath ?? '${widget.track.id}';
    if (_currentTrackKey == key) return;
    _currentTrackKey = key;
    debugPrint(
      '[AnimatedArtwork] _loadArtwork for ${widget.track.title} (${widget.track.artist}) key=$key',
    );

    _disposeController();
    _artwork = null;
    _staticImage = null;
    _videoReady = false;
    if (mounted) setState(() {});

    try {
      // Check ImageProvider cache first (instant, from miniplayer)
      final cached = local.ArtworkService.inst.getCachedImageProvider(
        widget.track.id,
      );
      if (cached != null) {
        _staticImage = cached;
        debugPrint('[AnimatedArtwork] static artwork from ImageProvider cache');
      }

      // Run both fetches in parallel (for cache miss or fallback)
      final localFuture = cached == null
          ? local.ArtworkService.inst.getLocalArtwork(widget.track)
          : Future.value(null);
      final animatedFuture = AnimatedArtworkService.inst.fetchForTrack(
        widget.track,
        null,
      );

      // Animated artwork first — it's what matters for the visual
      final artwork = await animatedFuture;

      if (_disposed || !mounted || _currentTrackKey != key) return;

      _artwork = artwork;
      debugPrint(
        '[AnimatedArtwork] animated result: ${artwork != null ? "hasAnimation=${artwork.hasAnimation}, url=${artwork.preferredAnimationUrl}" : "NULL"}',
      );

      // Static artwork as fallback (from MediaStore only, fast)
      final bytes = await localFuture;
      if (bytes != null && bytes.isNotEmpty) {
        _staticImage = MemoryImage(bytes);
      }

      // Fallback: use staticImageUrl from animated artwork if MediaStore has no artwork
      if (_staticImage == null && artwork?.staticImageUrl != null) {
        debugPrint('[AnimatedArtwork] using staticImageUrl fallback');
        _staticImage = NetworkImage(artwork!.staticImageUrl!);
      }

      debugPrint(
        '[AnimatedArtwork] static artwork loaded: ${_staticImage != null}',
      );

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
      debugPrint('[AnimatedArtwork] _loadArtwork error: $e');
      if (mounted) setState(() {});
    }
  }

  Future<void> _openMedia(String url, String expectedKey) async {
    try {
      debugPrint('[AnimatedArtwork] _openMedia: $url');

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

      controller.play();

      debugPrint(
        '[AnimatedArtwork] initialized: ${controller.value.size.width}x${controller.value.size.height}',
      );

      // Video is ready - start crossfade to animated
      if (!_disposed && mounted) {
        debugPrint('[AnimatedArtwork] video ready, crossfading to animated');
        _videoReady = true;
        setState(() {});
      }
    } catch (e) {
      debugPrint('[AnimatedArtwork] _openMedia error: $e');
      if (_disposed || !mounted || _currentTrackKey != expectedKey) return;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox.expand(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_controller != null && _controller!.value.isInitialized)
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
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _videoReady ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeInOut,
                child: _buildStaticArtwork(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticArtwork(ThemeData theme) {
    if (_staticImage != null) {
      return Image(image: _staticImage!, fit: BoxFit.cover);
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
