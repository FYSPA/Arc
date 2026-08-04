import 'package:flutter/material.dart';

import '../../core/broken_icons.dart';

class AnimatedCheckMark extends StatefulWidget {
  final double size;
  final bool active;

  const AnimatedCheckMark({
    super.key,
    required this.size,
    required this.active,
  });

  @override
  State<AnimatedCheckMark> createState() => _AnimatedCheckMarkState();
}

class _AnimatedCheckMarkState extends State<AnimatedCheckMark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.fastLinearToSlowEaseIn),
    );
    if (widget.active) _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCheckMark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.forward(from: 0.0);
    } else if (!widget.active && oldWidget.active) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            Broken.tick_circle,
            size: widget.size,
            color: widget.active ? Colors.green : Colors.grey,
          ),
        );
      },
    );
  }
}
