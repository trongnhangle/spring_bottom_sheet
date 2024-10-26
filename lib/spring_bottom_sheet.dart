/// A Flutter package that provides a bottom sheet with spring animation effect
library spring_bottom_sheet;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// A widget that displays its child with a spring animation effect when shown from bottom
///
/// Example usage:
/// ```dart
/// SpringBottomSheet(
///   child: Container(
///     child: Text('Bottom Sheet Content'),
///   ),
/// )
/// ```
class SpringBottomSheet extends StatefulWidget {
  /// The widget to be displayed inside the bottom sheet
  final Widget child;

  /// Creates a SpringBottomSheet widget
  ///
  /// The [child] parameter must not be null and will be displayed
  /// with a spring animation effect
  const SpringBottomSheet({super.key, required this.child});

  @override
  _SpringBottomSheetState createState() => _SpringBottomSheetState();
}

class _SpringBottomSheetState extends State<SpringBottomSheet>
    with SingleTickerProviderStateMixin {
  /// Controller for the spring animation
  late AnimationController _controller;

  /// Key to measure the child widget's height
  final GlobalKey _childKey = GlobalKey();

  /// Notifier to track changes in child height
  final ValueNotifier<double> _childHeight = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();

    // Initialize animation controller with 500ms duration
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Measure child height after first frame and start animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureChildHeight();
      _startAnimation();
    });
  }

  /// Measures the height of the child widget using RenderBox
  void _measureChildHeight() {
    final RenderBox? renderBox =
        _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      _childHeight.value = renderBox.size.height;
    }
  }

  /// Starts the spring animation with custom spring parameters
  ///
  /// Uses SpringSimulation with:
  /// - mass: 1
  /// - stiffness: 500 (controls spring force)
  /// - damping: 25 (controls bounce reduction)
  void _startAnimation() {
    _controller.animateWith(
      SpringSimulation(
        const SpringDescription(
          mass: 1,
          stiffness: 500,
          damping: 25,
        ),
        0, // Start value
        1, // End value
        0, // Initial velocity
      ),
    );
  }

  @override
  void dispose() {
    // Clean up resources
    _controller.dispose();
    _childHeight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Stack(
          children: [
            // Hidden widget to measure true height
            Offstage(
              child: Container(
                key: _childKey,
                child: widget.child,
              ),
            ),
            // Animated visible widget
            ValueListenableBuilder<double>(
              valueListenable: _childHeight,
              builder: (context, height, _) {
                return SizedBox(
                  height: height * _controller.value,
                  child: widget.child,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
