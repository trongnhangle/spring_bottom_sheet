// ignore_for_file: library_private_types_in_public_api

library spring_bottom_sheet;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Displays a modal bottom sheet with spring-like animation effect.
///
/// This function wraps the `showModalBottomSheet` with added customization
/// for a spring animation and provides various options for configuration.
///
/// Parameters:
/// - [context]: The BuildContext where the bottom sheet is displayed.
/// - [builder]: A builder to create the content of the bottom sheet.
/// - [backgroundColor]: The background color of the sheet (defaults to transparent).
/// - [barrierLabel]: The semantic label for the barrier (optional).
/// - [elevation]: The z-coordinate at which to place this material relative to its parent.
/// - [shape]: The shape of the modal bottom sheet (optional).
/// - [clipBehavior]: How to handle child content that overflows its bounds.
/// - [constraints]: Optional constraints for the size of the sheet.
/// - [barrierColor]: The color of the barrier behind the sheet.
/// - [isScrollControlled]: Determines if the bottom sheet should expand to fill available space.
/// - [scrollControlDisabledMaxHeightRatio]: The maximum height ratio when scroll control is disabled.
/// - [useRootNavigator]: Whether to use the root navigator instead of a nested one.
/// - [isDismissible]: Controls whether the sheet can be dismissed by tapping outside it.
/// - [enableDrag]: Allows the sheet to be draggable.
/// - [showDragHandle]: If true, shows a handle to drag the sheet.
/// - [useSafeArea]: Whether to avoid system UI padding.
/// - [routeSettings]: Custom route settings for the bottom sheet.
/// - [transitionAnimationController]: Optional controller for the transition animation.
/// - [anchorPoint]: Optional anchor point to which the sheet is anchored.
/// - [sheetAnimationStyle]: Custom animation style for the sheet.
void showSpringBottomSheet({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  String? barrierLabel,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  Color? barrierColor,
  bool isScrollControlled = false,
  double scrollControlDisabledMaxHeightRatio = 9.0 / 16.0,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool? showDragHandle,
  bool useSafeArea = false,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
  Offset? anchorPoint,
  AnimationStyle? sheetAnimationStyle,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: backgroundColor ?? Colors.white,
    shape: shape,
    clipBehavior: clipBehavior,
    constraints: constraints,
    barrierColor: barrierColor,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
    builder: (BuildContext context) {
      return SpringBottomSheet(child: builder(context));
    },
  );
}

/// A custom widget that creates a bottom sheet with a spring animation effect.
///
/// The widget uses an `AnimationController` and a `SpringSimulation` to animate
/// the appearance of the sheet with a spring-like effect.
class SpringBottomSheet extends StatefulWidget {
  final Widget child;

  const SpringBottomSheet({super.key, required this.child});

  @override
  _SpringBottomSheetState createState() => _SpringBottomSheetState();
}

class _SpringBottomSheetState extends State<SpringBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  /// Initializes the animation controller and starts the spring animation.
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Apply a spring simulation to the animation.
    _controller.animateWith(
      SpringSimulation(
        const SpringDescription(
          mass: 1,
          stiffness: 500,
          damping: 25,
        ),
        0,
        1,
        0,
      ),
    );
  }

  /// Disposes of the animation controller when the widget is no longer used.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Builds the animated bottom sheet with a spring effect and rounded top corners.
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20 * _controller.value),
          ),
          child: SizedBox(
            height: height * 0.5 * _controller.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}
