import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Controls a [SpringBottomSheet] without exposing a [GlobalKey].
class SpringBottomSheetController {
  _SpringBottomSheetState? _state;

  /// The current sheet height in logical pixels.
  double get height => _state?._heightController.value ?? 0;

  /// Snaps to the snap point at [index].
  Future<void> snapToIndex(int index, {double velocity = 0}) async {
    await _state?.snapToIndex(index, velocity: velocity);
  }

  /// Snaps to the nearest snap point from the current height.
  Future<void> snapToNearest({double velocity = 0}) async {
    await _state?.snapToNearest(velocity: velocity);
  }

  /// Dismisses the sheet when [SpringBottomSheet.onDismissed] is configured.
  Future<void> dismiss({double velocity = 0}) async {
    await _state?.dismiss(velocity: velocity);
  }

  void _attach(_SpringBottomSheetState state) {
    _state = state;
  }

  void _detach(_SpringBottomSheetState state) {
    if (_state == state) {
      _state = null;
    }
  }
}

/// A dependency-free bottom sheet with spring physics, snap points, dragging,
/// rubber-banding, and a dimmed backdrop.
class SpringBottomSheet extends StatefulWidget {
  const SpringBottomSheet({
    required this.child,
    required this.open,
    this.backdropColor = const Color(0x990F172A),
    this.backgroundColor = Colors.white,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(28)),
    this.clipBehavior = Clip.antiAlias,
    this.controller,
    this.elevation = 22,
    this.enableDrag = true,
    this.header,
    this.initialSnapIndex = 0,
    this.isDismissible = true,
    this.maxTopGap = 14,
    this.onDismissed,
    this.rubberBandConstant = 0.55,
    this.shadowColor = const Color(0x33111827),
    this.showDragHandle = true,
    this.snapSizes = const [0.35, 0.65, 0.92],
    this.spring = const SpringDescription(mass: 1, stiffness: 210, damping: 20),
    this.springTolerance = const Tolerance(distance: 0.6, velocity: 0.6),
    super.key,
  });

  /// The sheet body.
  final Widget child;

  /// Whether the sheet is open.
  final bool open;

  /// Color used for the backdrop at full progress.
  final Color backdropColor;

  /// Color of the sheet surface.
  final Color backgroundColor;

  /// Border radius for the sheet surface.
  final BorderRadiusGeometry borderRadius;

  /// Clip behavior for the sheet surface.
  final Clip clipBehavior;

  /// Optional imperative controller.
  final SpringBottomSheetController? controller;

  /// Elevation for the sheet surface.
  final double elevation;

  /// Whether the sheet can be dragged by the handle/header area.
  final bool enableDrag;

  /// Optional header. Dragging is attached to the handle/header area.
  final Widget? header;

  /// Initial snap index when opening from closed state.
  final int initialSnapIndex;

  /// Whether backdrop taps and swipe-down gestures can dismiss the sheet.
  final bool isDismissible;

  /// Distance left between the top of the screen and the tallest snap point.
  final double maxTopGap;

  /// Called after the sheet has animated to the closed position.
  final VoidCallback? onDismissed;

  /// Resistance applied when dragging beyond the snap bounds.
  final double rubberBandConstant;

  /// Shadow color for the sheet surface.
  final Color shadowColor;

  /// Whether to show the default drag handle above [header].
  final bool showDragHandle;

  /// Snap sizes as fractions of the available viewport height.
  final List<double> snapSizes;

  /// Spring physics used for open, close, and snap animations.
  final SpringDescription spring;

  /// Tolerance used by the spring simulation.
  final Tolerance springTolerance;

  @override
  State<SpringBottomSheet> createState() => _SpringBottomSheetState();
}

class _SpringBottomSheetState extends State<SpringBottomSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heightController;

  List<double> _snapPoints = const [];
  double _dragStartHeight = 0;
  double _dragOffset = 0;
  int _layoutVersion = 0;

  double get _minSnap => _snapPoints.first;
  double get _maxSnap => _snapPoints.last;

  @override
  void initState() {
    super.initState();
    _heightController = AnimationController.unbounded(vsync: this, value: 0);
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(covariant SpringBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }

    if (oldWidget.open != widget.open && _snapPoints.isNotEmpty) {
      if (widget.open) {
        // Defer by one frame so build() has updated _snapPoints via
        // _syncSnapPoints before the animation target is resolved.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.open) unawaited(snapToIndex(widget.initialSnapIndex));
        });
      } else {
        unawaited(_animateTo(0, velocity: 0));
      }
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _heightController.dispose();
    super.dispose();
  }

  Future<void> snapToIndex(int index, {double velocity = 0}) async {
    if (_snapPoints.isEmpty) {
      return;
    }

    final safeIndex = index.clamp(0, _snapPoints.length - 1).toInt();
    await _animateTo(_snapPoints[safeIndex], velocity: velocity);
  }

  Future<void> snapToNearest({double velocity = 0}) async {
    if (_snapPoints.isEmpty) {
      return;
    }

    final projected = _heightController.value + (velocity * 0.16);
    await _animateTo(_nearestSnap(projected), velocity: velocity);
  }

  Future<void> dismiss({double velocity = 0}) async {
    if (widget.onDismissed == null) {
      return;
    }

    await _animateTo(0, velocity: velocity);

    if (mounted) {
      widget.onDismissed?.call();
    }
  }

  Future<void> _animateTo(double target, {required double velocity}) async {
    if (_snapPoints.isEmpty && target != 0) {
      return;
    }

    final safeTarget = target == 0 ? 0.0 : target.clamp(_minSnap, _maxSnap);

    _heightController.stop();

    final simulation = SpringSimulation(
      widget.spring,
      _heightController.value,
      safeTarget,
      velocity,
      tolerance: widget.springTolerance,
    );

    await _heightController.animateWith(simulation);
  }

  void _handleDragStart(DragStartDetails details) {
    if (_snapPoints.isEmpty) {
      return;
    }

    _heightController.stop();
    _dragStartHeight = _heightController.value;
    _dragOffset = 0;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_snapPoints.isEmpty) {
      return;
    }

    _dragOffset += details.delta.dy;

    final rawHeight = _dragStartHeight - _dragOffset;
    final lowerBound = widget.onDismissed == null || !widget.isDismissible
        ? _minSnap
        : 0.0;
    final nextHeight = _rubberBandIfOutOfBounds(
      rawHeight,
      min: lowerBound,
      max: _maxSnap,
      constant: widget.rubberBandConstant,
    );

    _heightController.value = nextHeight;
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_snapPoints.isEmpty) {
      return;
    }

    final velocity = -details.velocity.pixelsPerSecond.dy;
    final projected = _heightController.value + (velocity * 0.16);
    final shouldDismiss =
        widget.onDismissed != null &&
        widget.isDismissible &&
        (projected < _minSnap * 0.5 ||
            (velocity < -1200 && _heightController.value < _minSnap + 90));

    if (shouldDismiss) {
      unawaited(dismiss(velocity: velocity));
      return;
    }

    unawaited(_animateTo(_nearestSnap(projected), velocity: velocity));
  }

  void _handleDragCancel() {
    unawaited(snapToNearest());
  }

  void _syncSnapPoints(List<double> nextSnapPoints) {
    if (_sameSnapPoints(_snapPoints, nextSnapPoints)) {
      return;
    }

    final wasEmpty = _snapPoints.isEmpty;
    final previousHeight = _heightController.value;
    _snapPoints = nextSnapPoints;
    final version = ++_layoutVersion;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || version != _layoutVersion) {
        return;
      }

      if (!widget.open) {
        _heightController.value = 0;
        return;
      }

      if (wasEmpty || previousHeight <= 0.6) {
        unawaited(snapToIndex(widget.initialSnapIndex));
        return;
      }

      final target = _nearestSnap(previousHeight);
      if ((target - previousHeight).abs() > 0.6) {
        unawaited(_animateTo(target, velocity: 0));
      }
    });
  }

  List<double> _resolveSnapPoints(double availableHeight) {
    final points =
        widget.snapSizes
            .map(
              (size) =>
                  (size.clamp(0.0, 1.0) * availableHeight).roundToDouble(),
            )
            .where((height) => height > 0)
            .toSet()
            .toList()
          ..sort();

    if (points.isEmpty) {
      return [(availableHeight * 0.6).roundToDouble()];
    }

    return points;
  }

  double _nearestSnap(double value) {
    return _snapPoints.reduce((best, snap) {
      final bestDistance = (best - value).abs();
      final snapDistance = (snap - value).abs();
      return snapDistance < bestDistance ? snap : best;
    });
  }

  bool _sameSnapPoints(List<double> a, List<double> b) {
    if (a.length != b.length) {
      return false;
    }

    for (var i = 0; i < a.length; i++) {
      if ((a[i] - b[i]).abs() > 0.1) {
        return false;
      }
    }

    return true;
  }

  double _rubberBandIfOutOfBounds(
    double value, {
    required double min,
    required double max,
    required double constant,
  }) {
    if (value >= min && value <= max) return value;

    final dimension = max - min;
    final overflow = value < min ? min - value : value - max;
    final compressed = dimension <= 0
        ? overflow * constant
        : (1 - (1 / ((overflow * constant / dimension) + 1))) * dimension;

    return value < min ? min - compressed : max + compressed;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final topPadding = MediaQuery.paddingOf(context).top;
        final availableHeight = math.max(
          0.0,
          constraints.maxHeight - topPadding - widget.maxTopGap,
        );
        final snapPoints = _resolveSnapPoints(availableHeight);

        _syncSnapPoints(snapPoints);

        return AnimatedBuilder(
          animation: _heightController,
          // _SheetSurface is passed as child so it is built once per
          // LayoutBuilder rebuild, not on every animation tick.
          child: _SheetSurface(
            backgroundColor: widget.backgroundColor,
            borderRadius: widget.borderRadius,
            clipBehavior: widget.clipBehavior,
            elevation: widget.elevation,
            enableDrag: widget.enableDrag,
            header: widget.header,
            onVerticalDragCancel: _handleDragCancel,
            onVerticalDragEnd: _handleDragEnd,
            onVerticalDragStart: _handleDragStart,
            onVerticalDragUpdate: _handleDragUpdate,
            shadowColor: widget.shadowColor,
            showDragHandle: widget.showDragHandle,
            child: widget.child,
          ),
          builder: (context, sheetSurface) {
            final maxSnap = snapPoints.last;
            final rawHeight = _heightController.value;
            final sheetHeight = rawHeight.clamp(0.0, availableHeight);
            final surfaceHeight = math.max(maxSnap, sheetHeight);
            final progress = maxSnap == 0
                ? 0.0
                : (sheetHeight / maxSnap).clamp(0.0, 1.0);
            final backdropColor = Color.lerp(
              Colors.transparent,
              widget.backdropColor,
              progress,
            )!;

            return IgnorePointer(
              ignoring: sheetHeight <= 0.6,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.isDismissible
                          ? () => unawaited(dismiss())
                          : null,
                      child: ColoredBox(color: backdropColor),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: surfaceHeight,
                    child: Transform.translate(
                      offset: Offset(0, surfaceHeight - sheetHeight),
                      child: sheetSurface,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SheetSurface extends StatelessWidget {
  const _SheetSurface({
    required this.backgroundColor,
    required this.borderRadius,
    required this.child,
    required this.clipBehavior,
    required this.elevation,
    required this.enableDrag,
    required this.header,
    required this.onVerticalDragCancel,
    required this.onVerticalDragEnd,
    required this.onVerticalDragStart,
    required this.onVerticalDragUpdate,
    required this.shadowColor,
    required this.showDragHandle,
  });

  final Color backgroundColor;
  final BorderRadiusGeometry borderRadius;
  final Widget child;
  final Clip clipBehavior;
  final double elevation;
  final bool enableDrag;
  final Widget? header;
  final GestureDragCancelCallback onVerticalDragCancel;
  final GestureDragEndCallback onVerticalDragEnd;
  final GestureDragStartCallback onVerticalDragStart;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final Color shadowColor;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    return Material(
      clipBehavior: clipBehavior,
      color: backgroundColor,
      elevation: elevation,
      shadowColor: shadowColor,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragCancel: enableDrag ? onVerticalDragCancel : null,
            onVerticalDragEnd: enableDrag ? onVerticalDragEnd : null,
            onVerticalDragStart: enableDrag ? onVerticalDragStart : null,
            onVerticalDragUpdate: enableDrag ? onVerticalDragUpdate : null,
            child: Column(
              children: [
                if (showDragHandle) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
                ?header,
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
