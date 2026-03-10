import 'package:flutter/material.dart';

/// A wrapper for list items that provides a smooth fade-in and slide-up animation.
class BourraqListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;

  const BourraqListItem({
    super.key,
    required this.child,
    required this.index,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<BourraqListItem> createState() => _BourraqListItemState();
}

class _BourraqListItemState extends State<BourraqListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    // Delayed start based on index
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        (0.05 * widget.index).clamp(0, 0.5),
        1.0,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      ),
    );
  }
}
