import 'dart:async';

import 'package:flutter/material.dart';

/// A small dependency-free staggered list that fades and slides every direct
/// child from the bottom.
class SpringStaggeredListView extends StatelessWidget {
  const SpringStaggeredListView({
    required this.children,
    this.animate = true,
    this.clipBehavior = Clip.hardEdge,
    this.controller,
    this.duration = const Duration(milliseconds: 420),
    this.initialDelay = const Duration(milliseconds: 160),
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.padding,
    this.physics,
    this.primary,
    this.reverse = false,
    this.shrinkWrap = false,
    this.staggerDelay = const Duration(milliseconds: 80),
    this.verticalOffset = 40,
    super.key,
  });

  /// Children to display and animate. Every direct child is automatically
  /// wrapped with the stagger effect.
  final List<Widget> children;

  /// Whether to animate children with a staggered fade-and-slide effect.
  /// Defaults to true.
  final bool animate;

  final Clip clipBehavior;
  final ScrollController? controller;
  final Duration duration;
  final Duration initialDelay;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool? primary;
  final bool reverse;
  final bool shrinkWrap;
  final Duration staggerDelay;
  final double verticalOffset;

  @override
  Widget build(BuildContext context) {
    return ListView(
      clipBehavior: clipBehavior,
      controller: controller,
      keyboardDismissBehavior: keyboardDismissBehavior,
      padding: padding,
      physics: physics,
      primary: primary,
      reverse: reverse,
      shrinkWrap: shrinkWrap,
      children: [
        for (var index = 0; index < children.length; index++)
          SpringStaggeredItem(
            key: children[index].key,
            animate: animate,
            delay: initialDelay + (staggerDelay * index),
            duration: duration,
            verticalOffset: verticalOffset,
            child: children[index],
          ),
      ],
    );
  }
}

/// A dependency-free fade and slide animation used by
/// [SpringStaggeredListView].
class SpringStaggeredItem extends StatefulWidget {
  const SpringStaggeredItem({
    required this.child,
    this.animate = true,
    this.curve = Curves.easeOutCubic,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.verticalOffset = 40,
    super.key,
  });

  final Widget child;

  /// Whether to apply the fade-and-slide animation. Defaults to true.
  final bool animate;

  final Curve curve;
  final Duration delay;
  final Duration duration;
  final double verticalOffset;

  @override
  State<SpringStaggeredItem> createState() => _SpringStaggeredItemState();
}

class _SpringStaggeredItemState extends State<SpringStaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late CurvedAnimation _animation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    _start();
  }

  @override
  void didUpdateWidget(covariant SpringStaggeredItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.delay != widget.delay ||
        oldWidget.duration != widget.duration ||
        oldWidget.curve != widget.curve) {
      _timer?.cancel();
      _animation.dispose();
      _controller
        ..duration = widget.duration
        ..reset();
      _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
      _start();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    _timer = Timer(widget.delay, () {
      if (mounted) {
        unawaited(_controller.forward());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) return widget.child;

    return FadeTransition(
      opacity: _animation,
      child: AnimatedBuilder(
        animation: _animation,
        child: widget.child,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, (1 - _animation.value) * widget.verticalOffset),
            child: child,
          );
        },
      ),
    );
  }
}
