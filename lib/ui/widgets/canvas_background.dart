import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/utils.dart';
import '../../data/models/track.dart';
import '../../services/canvas_service.dart';
import '../../services/toast_service.dart';

/// Full-screen looping Spotify Canvas video shown as the bottom layer of the
/// full player. Fetches the canvas URL only when the track changes (not on every
/// rebuild) and degrades to an empty widget when no canvas is available.
class CanvasBackground extends StatefulWidget {
  final ArcTrack? track;

  const CanvasBackground({super.key, this.track});

  @override
  State<CanvasBackground> createState() => _CanvasBackgroundState();
}

class _CanvasBackgroundState extends State<CanvasBackground> {
  VideoPlayerController? _controller;
  bool _hasCanvas = false;
  int? _loadingTrackId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CanvasBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track?.id != widget.track?.id) _load();
  }

  Future<void> _load() async {
    _disposeController();
    final track = widget.track;
    if (track == null) {
      if (mounted) setState(() => _hasCanvas = false);
      return;
    }

    // Evita dos fetches del mismo track si el widget se remonta rápido (el
    // CanvasService ya cachea el resultado, pero esto corta el in-flight).
    if (_loadingTrackId == track.id) return;
    _loadingTrackId = track.id;
    try {
      final url = await CanvasService.inst.getCanvasUrl(track);
      if (!mounted) return;

      if (url == null || url.isEmpty) {
        ToastService.inst.showNoCanvas(track);
        setState(() => _hasCanvas = false);
        return;
      }

      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      controller.setLooping(true);
      controller.setVolume(0);
      controller.play();
      _controller = controller;
      logD('[Canvas] video initialized for "${track.title}"');
      setState(() => _hasCanvas = true);
    } catch (e) {
      logD('[Canvas] video init failed: $e');
      setState(() => _hasCanvas = false);
    } finally {
      if (_loadingTrackId == track.id) _loadingTrackId = null;
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCanvas ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}
