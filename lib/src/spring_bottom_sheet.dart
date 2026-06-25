import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';

enum _SheetMotion { idle, opening, dragging, snapping, dismissing }

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

/// Exposes the scroll controller that coordinates a scrollable child with the
/// surrounding [SpringBottomSheet].
///
/// Most vertical scroll views without an explicit controller will pick this up
/// automatically through [PrimaryScrollController]. Use [of] or [maybeOf] when
/// a child needs to pass the controller explicitly.
class SpringBottomSheetScrollController extends InheritedWidget {
  const SpringBottomSheetScrollController._({
    required this.controller,
    required super.child,
  });

  /// The controller descendants can attach to their primary scrollable.
  final ScrollController controller;

  /// Returns the nearest coordinated scroll controller, or null when the
  /// context is not inside a [SpringBottomSheet].
  static ScrollController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SpringBottomSheetScrollController>()
        ?.controller;
  }

  /// Returns the nearest coordinated scroll controller.
  static ScrollController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(() {
      if (controller == null) {
        throw FlutterError(
          'SpringBottomSheetScrollController.of() was called with a context '
          'that does not contain a SpringBottomSheetScrollController.\n'
          'Make sure the context is below a SpringBottomSheet body.',
        );
      }
      return true;
    }());
    return controller!;
  }

  @override
  bool updateShouldNotify(SpringBottomSheetScrollController oldWidget) {
    return controller != oldWidget.controller;
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
    this.enableContentDrag = true,
    this.enableDrag = true,
    this.header,
    this.initialSnapIndex = 0,
    this.isDismissible = true,
    this.maxTopGap = 14,
    this.onDismissed,
    this.rubberBandConstant = 0.55,
    this.shadowColor = const Color(0x33111827),
    this.showDragHandle = true,
    this.snapSizes,
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

  /// Whether vertical drags that start in a scrollable body can resize the
  /// sheet before the body scrolls.
  final bool enableContentDrag;

  /// Whether the sheet can be dragged by its surface.
  final bool enableDrag;

  /// Optional header above the body and below the drag handle.
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
  ///
  /// When omitted, the sheet measures its rendered content and uses that
  /// height as a single snap point, capped by the available viewport height.
  final List<double>? snapSizes;

  /// Spring physics used for open, close, and snap animations.
  final SpringDescription spring;

  /// Tolerance used by the spring simulation.
  final Tolerance springTolerance;

  @override
  State<SpringBottomSheet> createState() => _SpringBottomSheetState();
}

class _SpringBottomSheetState extends State<SpringBottomSheet>
    with SingleTickerProviderStateMixin {
  static final Set<TargetPlatform> _allTargetPlatforms = Set.unmodifiable(
    TargetPlatform.values,
  );

  late final AnimationController _heightController;
  late final _SpringBottomSheetScrollCoordinator _scrollCoordinator;
  late final _SpringBottomSheetScrollController _contentScrollController;

  List<double> _snapPoints = const [];
  double _dragStartHeight = 0;
  double _dragOffset = 0;
  double? _pendingAutoHeight;
  Future<void>? _dismissFuture;
  _SheetMotion _motion = _SheetMotion.idle;
  bool _autoSizeUpdateScheduled = false;
  bool _dismissNotified = false;
  int _animationGeneration = 0;
  int _layoutVersion = 0;

  double get _minSnap => _snapPoints.first;
  double get _maxSnap => _snapPoints.last;

  @override
  void initState() {
    super.initState();
    _heightController = AnimationController.unbounded(vsync: this, value: 0);
    _scrollCoordinator = _SpringBottomSheetScrollCoordinator(this);
    _contentScrollController = _SpringBottomSheetScrollController(
      coordinator: _scrollCoordinator,
    );
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(covariant SpringBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }

    if ((oldWidget.snapSizes == null) != (widget.snapSizes == null)) {
      _pendingAutoHeight = null;
      _layoutVersion++;
    }

    if (oldWidget.open != widget.open) {
      if (widget.open) {
        _dismissNotified = false;
        if (_motion == _SheetMotion.dismissing && _dismissFuture == null) {
          _animationGeneration++;
          _heightController.stop();
          _motion = _SheetMotion.idle;
        }
        if (_snapPoints.isNotEmpty) {
          // Defer by one frame so build() has updated _snapPoints via
          // _syncSnapPoints before the animation target is resolved.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && widget.open && _snapPoints.isNotEmpty) {
              unawaited(
                _animateTo(
                  _snapPoints[widget.initialSnapIndex
                      .clamp(0, _snapPoints.length - 1)
                      .toInt()],
                  velocity: 0,
                  motion: _SheetMotion.opening,
                ),
              );
            }
          });
        }
      } else {
        if (_heightController.value <= 0.6) {
          _animationGeneration++;
          _heightController.stop();
          _heightController.value = 0;
          _motion = _SheetMotion.idle;
        } else {
          unawaited(
            _animateTo(0, velocity: 0, motion: _SheetMotion.dismissing),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _contentScrollController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> snapToIndex(int index, {double velocity = 0}) async {
    if (_snapPoints.isEmpty || _motion == _SheetMotion.dismissing) {
      return;
    }

    final safeIndex = index.clamp(0, _snapPoints.length - 1).toInt();
    await _animateTo(
      _snapPoints[safeIndex],
      velocity: velocity,
      motion: _SheetMotion.snapping,
    );
  }

  Future<void> snapToNearest({double velocity = 0}) async {
    if (_snapPoints.isEmpty || _motion == _SheetMotion.dismissing) {
      return;
    }

    final projected = _heightController.value + (velocity * 0.16);
    await _animateTo(
      _nearestSnap(projected),
      velocity: velocity,
      motion: _SheetMotion.snapping,
    );
  }

  Future<void> dismiss({double velocity = 0}) {
    if (widget.onDismissed == null) {
      return Future<void>.value();
    }

    final activeDismiss = _dismissFuture;
    if (activeDismiss != null) {
      return activeDismiss;
    }

    late final Future<void> operation;
    operation = _runDismiss(velocity).whenComplete(() {
      if (identical(_dismissFuture, operation)) {
        _dismissFuture = null;
      }
    });
    _dismissFuture = operation;
    return operation;
  }

  Future<void> _runDismiss(double velocity) async {
    final completed = await _animateTo(
      0,
      velocity: velocity,
      motion: _SheetMotion.dismissing,
    );

    if (completed && mounted && !_dismissNotified) {
      _dismissNotified = true;
      widget.onDismissed?.call();
    }
  }

  Future<bool> _animateTo(
    double target, {
    required double velocity,
    required _SheetMotion motion,
  }) async {
    if (_snapPoints.isEmpty && target != 0) {
      return false;
    }

    if (_motion == _SheetMotion.dismissing &&
        motion != _SheetMotion.dismissing) {
      return false;
    }

    final safeTarget = target == 0 ? 0.0 : target.clamp(_minSnap, _maxSnap);
    final generation = ++_animationGeneration;
    _heightController.stop();

    if ((_heightController.value - safeTarget).abs() <= 0.1) {
      _heightController.value = safeTarget;
      _motion = _SheetMotion.idle;
      return true;
    }

    _motion = motion;

    final simulation = SpringSimulation(
      widget.spring,
      _heightController.value,
      safeTarget,
      velocity,
      tolerance: widget.springTolerance,
    );

    try {
      await _heightController.animateWith(simulation).orCancel;
    } on TickerCanceled {
      return false;
    }

    if (!mounted || generation != _animationGeneration) {
      return false;
    }

    final completed =
        (_heightController.value - safeTarget).abs() <=
        math.max(0.6, widget.springTolerance.distance);
    _motion = _SheetMotion.idle;

    if (completed) {
      final settledTarget =
          motion != _SheetMotion.dismissing &&
              widget.open &&
              widget.snapSizes == null &&
              _snapPoints.isNotEmpty
          ? _maxSnap
          : safeTarget;
      _heightController.value = settledTarget;
    }

    return completed;
  }

  void _handleDragStart(DragStartDetails details) {
    _beginDrag();
  }

  void _beginDrag() {
    if (_snapPoints.isEmpty || _motion == _SheetMotion.dismissing) {
      return;
    }

    _animationGeneration++;
    _heightController.stop();
    _motion = _SheetMotion.dragging;
    _dragStartHeight = _heightController.value;
    _dragOffset = 0;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _updateDrag(details.delta.dy);
  }

  void _updateDrag(double userOffsetDelta) {
    if (_snapPoints.isEmpty || _motion != _SheetMotion.dragging) {
      return;
    }

    _dragOffset += userOffsetDelta;

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
    _settleDrag(velocity: velocity);
  }

  void _settleDrag({required double velocity}) {
    if (_snapPoints.isEmpty) {
      return;
    }

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

    unawaited(
      _animateTo(
        _nearestSnap(projected),
        velocity: velocity,
        motion: _SheetMotion.snapping,
      ),
    );
  }

  bool _shouldResizeFromContentDrag(
    double userOffsetDelta, {
    required bool listCanScroll,
  }) {
    if (!widget.enableContentDrag || _snapPoints.isEmpty) {
      return false;
    }

    final height = _heightController.value;
    final isAtMax = height >= _maxSnap - 0.6;
    final lowerBound = widget.onDismissed == null || !widget.isDismissible
        ? _minSnap
        : 0.0;
    final isAtLowerBound = height <= lowerBound + 0.6;
    final isAtMinSnap = height <= _minSnap + 0.6;

    if (!isAtLowerBound && !isAtMax) {
      return true;
    }

    if (isAtMax) {
      return !listCanScroll;
    }

    if (isAtLowerBound && userOffsetDelta < 0) {
      return true;
    }

    // Keep the existing rubber-band/dismiss feel when the sheet is already at
    // the compact snap and the user pulls the content downward from the top.
    return isAtMinSnap && userOffsetDelta > 0;
  }

  void _handleDragCancel() {
    if (_motion == _SheetMotion.dragging) {
      unawaited(snapToNearest());
    }
  }

  void _syncSnapPoints(List<double> nextSnapPoints) {
    if (_sameSnapPoints(_snapPoints, nextSnapPoints)) {
      return;
    }

    if (nextSnapPoints.isEmpty) {
      final previousHeight = _heightController.value;
      _snapPoints = const [];
      final version = ++_layoutVersion;

      if (previousHeight > 0.6) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              version == _layoutVersion &&
              _motion != _SheetMotion.dragging &&
              _motion != _SheetMotion.dismissing) {
            unawaited(
              _animateTo(0, velocity: 0, motion: _SheetMotion.snapping),
            );
          }
        });
      }
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
        _motion = _SheetMotion.idle;
        return;
      }

      if (_motion == _SheetMotion.dragging ||
          _motion == _SheetMotion.dismissing) {
        return;
      }

      if (wasEmpty || previousHeight <= 0.6) {
        final safeIndex = widget.initialSnapIndex
            .clamp(0, _snapPoints.length - 1)
            .toInt();
        unawaited(
          _animateTo(
            _snapPoints[safeIndex],
            velocity: 0,
            motion: _SheetMotion.opening,
          ),
        );
        return;
      }

      final target = _nearestSnap(previousHeight);
      if ((target - previousHeight).abs() > 0.6) {
        unawaited(
          _animateTo(target, velocity: 0, motion: _SheetMotion.snapping),
        );
      }
    });
  }

  void _handleAutoSurfaceSizeChanged(Size size) {
    if (!mounted || widget.snapSizes != null || !size.height.isFinite) {
      return;
    }

    _pendingAutoHeight = math.max(0.0, size.height);
    if (_autoSizeUpdateScheduled) {
      return;
    }

    _autoSizeUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSizeUpdateScheduled = false;
      if (!mounted || widget.snapSizes != null) {
        _pendingAutoHeight = null;
        return;
      }

      final nextHeight = _pendingAutoHeight;
      _pendingAutoHeight = null;
      if (nextHeight != null) {
        _applyAutoHeight(nextHeight);
      }
    });
  }

  void _applyAutoHeight(double nextHeight) {
    final nextSnapPoints = nextHeight > 0 ? [nextHeight] : const <double>[];
    if (_sameSnapPoints(_snapPoints, nextSnapPoints)) {
      return;
    }

    final wasEmpty = _snapPoints.isEmpty;
    final previousHeight = _heightController.value;
    _snapPoints = nextSnapPoints;
    _layoutVersion++;

    if (!widget.open) {
      _heightController.value = 0;
      _motion = _SheetMotion.idle;
      return;
    }

    if (_snapPoints.isEmpty) {
      if (_motion == _SheetMotion.idle) {
        _heightController.value = 0;
      }
      return;
    }

    if (wasEmpty || previousHeight <= 0.6) {
      if (_motion != _SheetMotion.dismissing) {
        unawaited(
          _animateTo(_maxSnap, velocity: 0, motion: _SheetMotion.opening),
        );
      }
      return;
    }

    // During a gesture or spring, only update the destination/bounds. The
    // active interaction keeps control of the visible height and aligns with
    // the latest auto snap when it finishes.
    if (_motion != _SheetMotion.idle) {
      return;
    }

    // Flutter's standard bottom sheet follows its laid-out child directly.
    // Updating the unbounded controller here repaints/repositions the surface
    // without creating a new spring for every content-size animation frame.
    _heightController.value = _maxSnap;
  }

  List<double> _resolveSnapPoints(double availableHeight) {
    final points =
        widget.snapSizes!
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
      if (a[i] != b[i]) {
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
        final usesAutoSnapSize = widget.snapSizes == null;

        if (!usesAutoSnapSize) {
          _syncSnapPoints(_resolveSnapPoints(availableHeight));
        }

        final sheetSurface = _SheetSurface(
          backgroundColor: widget.backgroundColor,
          borderRadius: widget.borderRadius,
          clipBehavior: widget.clipBehavior,
          contentScrollController: widget.enableContentDrag
              ? _contentScrollController
              : null,
          elevation: widget.elevation,
          enableDrag: widget.enableDrag,
          expandBody: !usesAutoSnapSize,
          header: widget.header,
          onSizeChanged: usesAutoSnapSize
              ? _handleAutoSurfaceSizeChanged
              : null,
          primaryScrollPlatforms: _allTargetPlatforms,
          onVerticalDragCancel: _handleDragCancel,
          onVerticalDragEnd: _handleDragEnd,
          onVerticalDragStart: _handleDragStart,
          onVerticalDragUpdate: _handleDragUpdate,
          shadowColor: widget.shadowColor,
          showDragHandle: widget.showDragHandle,
          child: widget.child,
        );

        return AnimatedBuilder(
          animation: _heightController,
          // _SheetSurface is passed as child so it is built once per
          // LayoutBuilder rebuild, not on every animation tick.
          child: sheetSurface,
          builder: (context, sheetSurface) {
            final maxSnap = _snapPoints.isEmpty ? 0.0 : _maxSnap;
            final rawHeight = _heightController.value;
            final sheetHeight = rawHeight.clamp(0.0, availableHeight);
            final surfaceHeight = math.max(maxSnap, sheetHeight);
            final autoSurfaceHeight = availableHeight;
            final progress = maxSnap == 0
                ? 0.0
                : (sheetHeight / maxSnap).clamp(0.0, 1.0);
            final backdropColor = Color.lerp(
              Colors.transparent,
              widget.backdropColor,
              progress,
            )!;

            return IgnorePointer(
              ignoring:
                  sheetHeight <= 0.6 || _motion == _SheetMotion.dismissing,
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
                  if (usesAutoSnapSize)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: autoSurfaceHeight,
                      child: Transform.translate(
                        offset: Offset(0, autoSurfaceHeight - sheetHeight),
                        child: sheetSurface,
                      ),
                    )
                  else
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
    required this.contentScrollController,
    required this.elevation,
    required this.enableDrag,
    required this.expandBody,
    required this.header,
    required this.onSizeChanged,
    required this.onVerticalDragCancel,
    required this.onVerticalDragEnd,
    required this.onVerticalDragStart,
    required this.onVerticalDragUpdate,
    required this.primaryScrollPlatforms,
    required this.shadowColor,
    required this.showDragHandle,
  });

  final Color backgroundColor;
  final BorderRadiusGeometry borderRadius;
  final Widget child;
  final Clip clipBehavior;
  final ScrollController? contentScrollController;
  final double elevation;
  final bool enableDrag;
  final bool expandBody;
  final Widget? header;
  final ValueChanged<Size>? onSizeChanged;
  final GestureDragCancelCallback onVerticalDragCancel;
  final GestureDragEndCallback onVerticalDragEnd;
  final GestureDragStartCallback onVerticalDragStart;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final Set<TargetPlatform> primaryScrollPlatforms;
  final Color shadowColor;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      mainAxisSize: expandBody ? MainAxisSize.max : MainAxisSize.min,
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
        if (expandBody)
          Expanded(child: _buildBody())
        else
          Flexible(fit: FlexFit.loose, child: _buildBody()),
      ],
    );

    final onSizeChanged = this.onSizeChanged;
    if (!expandBody) {
      if (onSizeChanged != null) {
        content = _MeasureSize(onChange: onSizeChanged, child: content);
      }

      content = Align(alignment: Alignment.topCenter, child: content);
    }

    final surface = Material(
      clipBehavior: clipBehavior,
      color: backgroundColor,
      elevation: elevation,
      shadowColor: shadowColor,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: content,
    );

    if (!enableDrag) {
      return surface;
    }

    return _SheetDragDetector(
      onVerticalDragCancel: onVerticalDragCancel,
      onVerticalDragEnd: onVerticalDragEnd,
      onVerticalDragStart: onVerticalDragStart,
      onVerticalDragUpdate: onVerticalDragUpdate,
      child: surface,
    );
  }

  Widget _buildBody() {
    final controller = contentScrollController;
    if (controller == null) {
      return child;
    }

    return SpringBottomSheetScrollController._(
      controller: controller,
      child: PrimaryScrollController(
        automaticallyInheritForPlatforms: primaryScrollPlatforms,
        controller: controller,
        child: child,
      ),
    );
  }
}

class _SheetDragDetector extends StatelessWidget {
  const _SheetDragDetector({
    required this.child,
    required this.onVerticalDragCancel,
    required this.onVerticalDragEnd,
    required this.onVerticalDragStart,
    required this.onVerticalDragUpdate,
  });

  final Widget child;
  final GestureDragCancelCallback onVerticalDragCancel;
  final GestureDragEndCallback onVerticalDragEnd;
  final GestureDragStartCallback onVerticalDragStart;
  final GestureDragUpdateCallback onVerticalDragUpdate;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      gestures: <Type, GestureRecognizerFactory<GestureRecognizer>>{
        VerticalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
              () => VerticalDragGestureRecognizer(debugOwner: this),
              (instance) {
                instance
                  ..onCancel = onVerticalDragCancel
                  ..onEnd = onVerticalDragEnd
                  ..onStart = onVerticalDragStart
                  ..onUpdate = onVerticalDragUpdate
                  ..onlyAcceptDragOnThreshold = true;
              },
            ),
      },
      child: child,
    );
  }
}

class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, required super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderObject(onChange);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _MeasureSizeRenderObject renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRenderObject extends RenderProxyBox {
  _MeasureSizeRenderObject(this._onChange);

  ValueChanged<Size> _onChange;
  Size? _oldSize;

  set onChange(ValueChanged<Size> value) {
    _onChange = value;
  }

  @override
  void performLayout() {
    super.performLayout();

    final newSize = size;
    if (_oldSize == newSize) {
      return;
    }

    _oldSize = newSize;
    _onChange(newSize);
  }
}

class _SpringBottomSheetScrollCoordinator {
  _SpringBottomSheetScrollCoordinator(this._state);

  final _SpringBottomSheetState _state;
  bool _isResizingSheet = false;

  bool shouldResize(double userOffsetDelta, {required bool listCanScroll}) {
    if (_isResizingSheet) {
      return true;
    }

    final shouldResize = _state._shouldResizeFromContentDrag(
      userOffsetDelta,
      listCanScroll: listCanScroll,
    );
    if (shouldResize) {
      _isResizingSheet = true;
      _state._beginDrag();
    }
    return shouldResize;
  }

  void applyUserOffset(double userOffsetDelta) {
    _state._updateDrag(userOffsetDelta);
  }

  bool get shouldSettle => _isResizingSheet;

  void settle(double velocity) {
    _isResizingSheet = false;
    _state._settleDrag(velocity: velocity);
  }

  void forgetDrag() {
    _isResizingSheet = false;
  }
}

class _SpringBottomSheetScrollController extends ScrollController {
  _SpringBottomSheetScrollController({required this.coordinator});

  final _SpringBottomSheetScrollCoordinator coordinator;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _SpringBottomSheetScrollPosition(
      coordinator: coordinator,
      context: context,
      oldPosition: oldPosition,
      physics: physics.applyTo(const AlwaysScrollableScrollPhysics()),
    );
  }
}

class _SpringBottomSheetScrollPosition extends ScrollPositionWithSingleContext {
  _SpringBottomSheetScrollPosition({
    required this.coordinator,
    required super.context,
    required super.physics,
    super.oldPosition,
  });

  final _SpringBottomSheetScrollCoordinator coordinator;
  VoidCallback? _dragCancelCallback;

  bool get _isScrolledAwayFromTop => pixels > minScrollExtent;

  bool _canScrollInDragDirection(double userOffsetDelta) {
    if (userOffsetDelta < 0) {
      return pixels < maxScrollExtent;
    }

    if (userOffsetDelta > 0) {
      return pixels > minScrollExtent;
    }

    return false;
  }

  @override
  void applyUserOffset(double delta) {
    final listCanScroll = _canScrollInDragDirection(delta);
    if (!_isScrolledAwayFromTop &&
        coordinator.shouldResize(delta, listCanScroll: listCanScroll)) {
      coordinator.applyUserOffset(delta);
      return;
    }

    super.applyUserOffset(delta);
  }

  @override
  void goBallistic(double velocity) {
    if (!coordinator.shouldSettle) {
      coordinator.forgetDrag();
      super.goBallistic(velocity);
      return;
    }

    _dragCancelCallback?.call();
    _dragCancelCallback = null;
    coordinator.settle(velocity);
    super.goBallistic(0);
  }

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    _dragCancelCallback = dragCancelCallback;
    return super.drag(details, dragCancelCallback);
  }
}
