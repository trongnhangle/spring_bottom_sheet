/// A customizable bottom sheet widget that animates into view with a spring effect.
///
/// This widget provides a bottom sheet that slides up from the bottom of the screen
/// with a natural spring animation, making it feel more dynamic and interactive.
/// The sheet also features rounded corners that animate as the sheet appears.
library spring_bottom_sheet;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// A stateful widget that implements a bottom sheet with spring animation.
///
/// Example usage:
/// ```dart
/// SpringBottomSheet(
///   child: Container(
///     color: Colors.white,
///     child: YourContent(),
///   ),
/// )
/// ```
class SpringBottomSheet extends StatefulWidget {
  /// The widget to be displayed inside the bottom sheet.
  ///
  /// This will be wrapped with the necessary animation and styling widgets
  /// to create the bottom sheet effect.
  final Widget child;

  /// Creates a new [SpringBottomSheet] instance.
  ///
  /// The [child] parameter must not be null and represents the content
  /// to be displayed within the bottom sheet.
  const SpringBottomSheet({super.key, required this.child});

  @override
  _SpringBottomSheetState createState() => _SpringBottomSheetState();
}

/// The state class for [SpringBottomSheet].
///
/// Handles the animation logic and builds the animated bottom sheet interface.
class _SpringBottomSheetState extends State<SpringBottomSheet>
    with SingleTickerProviderStateMixin {
  /// Controller for managing the spring animation.
  ///
  /// This controls both the height animation and the border radius animation
  /// of the bottom sheet.
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller with a medium duration
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Configure and start the spring animation
    // The spring simulation parameters are tuned for a natural feel:
    // - mass: affects the weight feeling of the animation
    // - stiffness: affects how quickly the animation moves
    // - damping: affects how quickly the animation settles
    _controller.animateWith(
      SpringSimulation(
        const SpringDescription(
          mass: 1, // The mass of the spring
          stiffness: 500, // How rigid the spring is
          damping: 25, // How quickly the spring's oscillations decrease
        ),
        0, // Start value
        1, // End value
        0, // Initial velocity
      ),
    );
  }

  @override
  void dispose() {
    // Clean up the animation controller when the widget is disposed
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen height to calculate the bottom sheet's height
    final height = MediaQuery.sizeOf(context).height;

    // Build the animated bottom sheet using AnimatedBuilder for efficiency
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ClipRRect(
          // Animate the top border radius based on the animation value
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20 * _controller.value),
          ),
          child: SizedBox(
            // Animate the height to be half of the screen height
            height: height * 0.5 * _controller.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}
