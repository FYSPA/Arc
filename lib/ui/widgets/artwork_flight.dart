import 'package:flutter/material.dart';

/// A shared-element "flight" that animates an artwork image from one on-screen
/// rect to another (e.g. the miniplayer thumbnail lifting into the full
/// player). Rendered in the root Overlay so it floats above both the chrome
/// and the player route.
class ArtworkFlight extends StatefulWidget {
  final Rect sourceRect;
  final Rect targetRect;
  final ImageProvider? image;
  final double radiusStart;
  final double radiusEnd;
  final int durationMs;
  final Curve curve;
  final VoidCallback? onCompleted;

  const ArtworkFlight({
    super.key,
    required this.sourceRect,
    required this.targetRect,
    required this.image,
    this.radiusStart = 8.0,
    this.radiusEnd = 24.0,
    this.durationMs = 200,
    this.curve = Curves.easeOutCubic,
    this.onCompleted,
  });

  @override
  State<ArtworkFlight> createState() => _ArtworkFlightState();
}

class _ArtworkFlightState extends State<ArtworkFlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Rect?> _rect;
  late final Animation<double> _radius;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );
    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    _rect = RectTween(
      begin: widget.sourceRect,
      end: widget.targetRect,
    ).animate(curved);
    _radius = Tween<double>(
      begin: widget.radiusStart,
      end: widget.radiusEnd,
    ).animate(curved);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted?.call();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.image;
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final rect = _rect.value ?? widget.targetRect;
            final radius = _radius.value;
            final child = image != null
                ? Image(image: image, fit: BoxFit.cover)
                : Container(color: Colors.grey.shade800);
            return Positioned(
              left: rect.left,
              top: rect.top,
              width: rect.width,
              height: rect.height,
              child: RepaintBoundary(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: child,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Inserts an [ArtworkFlight] overlay entry (in the root Overlay, above the
/// chrome) and removes it when the flight finishes. Calls [onCompleted] right
/// after the entry is removed.
OverlayEntry startArtworkFlight({
  required BuildContext context,
  required Rect sourceRect,
  required Rect targetRect,
  required ImageProvider? image,
  double radiusStart = 8.0,
  double radiusEnd = 24.0,
  int durationMs = 200,
  Curve curve = Curves.easeOutCubic,
  VoidCallback? onCompleted,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned.fill(
      child: ArtworkFlight(
        sourceRect: sourceRect,
        targetRect: targetRect,
        image: image,
        radiusStart: radiusStart,
        radiusEnd: radiusEnd,
        durationMs: durationMs,
        curve: curve,
        onCompleted: () {
          entry.remove();
          onCompleted?.call();
        },
      ),
    ),
  );
  overlay.insert(entry);
  return entry;
}
