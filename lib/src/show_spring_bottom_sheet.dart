import 'dart:async';

import 'package:flutter/material.dart';

import 'spring_bottom_sheet.dart';

/// Shows a spring-animated modal bottom sheet.
///
/// This mirrors Flutter's `showModalBottomSheet` style of use while keeping the
/// spring physics, snap points, rubber-banding, and optional header from this
/// package.
Future<T?> showSpringBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color backdropColor = const Color(0x990F172A),
  Color backgroundColor = Colors.white,
  BorderRadiusGeometry borderRadius = const BorderRadius.vertical(
    top: Radius.circular(28),
  ),
  Clip clipBehavior = Clip.antiAlias,
  SpringBottomSheetController? controller,
  double elevation = 22,
  bool enableContentDrag = true,
  bool enableDrag = true,
  WidgetBuilder? headerBuilder,
  int initialSnapIndex = 0,
  bool isDismissible = true,
  double maxTopGap = 14,
  RouteSettings? routeSettings,
  double rubberBandConstant = 0.55,
  Color shadowColor = const Color(0x33111827),
  bool showDragHandle = true,
  List<double>? snapSizes,
  SpringDescription spring = const SpringDescription(
    mass: 1,
    stiffness: 210,
    damping: 20,
  ),
  Tolerance springTolerance = const Tolerance(distance: 0.6, velocity: 0.6),
  bool useRootNavigator = false,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);

  return navigator.push(
    _SpringBottomSheetRoute<T>(
      capturedThemes: themes,
      config: _SheetConfig(
        backdropColor: backdropColor,
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
        builder: builder,
        clipBehavior: clipBehavior,
        elevation: elevation,
        enableContentDrag: enableContentDrag,
        enableDrag: enableDrag,
        headerBuilder: headerBuilder,
        initialSnapIndex: initialSnapIndex,
        isDismissible: isDismissible,
        maxTopGap: maxTopGap,
        rubberBandConstant: rubberBandConstant,
        shadowColor: shadowColor,
        showDragHandle: showDragHandle,
        snapSizes: snapSizes,
        spring: spring,
        springTolerance: springTolerance,
      ),
      routeSettings: routeSettings,
      sheetController: controller,
    ),
  );
}

// All sheet-level parameters gathered in one place. Threading this single
// object through the route avoids a parallel set of 17 fields at every layer —
// adding a new parameter requires one change here, not four.
class _SheetConfig {
  const _SheetConfig({
    required this.backdropColor,
    required this.backgroundColor,
    required this.borderRadius,
    required this.builder,
    required this.clipBehavior,
    required this.elevation,
    required this.enableContentDrag,
    required this.enableDrag,
    required this.headerBuilder,
    required this.initialSnapIndex,
    required this.isDismissible,
    required this.maxTopGap,
    required this.rubberBandConstant,
    required this.shadowColor,
    required this.showDragHandle,
    required this.snapSizes,
    required this.spring,
    required this.springTolerance,
  });

  final Color backdropColor;
  final Color backgroundColor;
  final BorderRadiusGeometry borderRadius;
  final WidgetBuilder builder;
  final Clip clipBehavior;
  final double elevation;
  final bool enableContentDrag;
  final bool enableDrag;
  final WidgetBuilder? headerBuilder;
  final int initialSnapIndex;
  final bool isDismissible;
  final double maxTopGap;
  final double rubberBandConstant;
  final Color shadowColor;
  final bool showDragHandle;
  final List<double>? snapSizes;
  final SpringDescription spring;
  final Tolerance springTolerance;
}

class _SpringBottomSheetRoute<T> extends PageRoute<T> {
  _SpringBottomSheetRoute({
    required this.capturedThemes,
    required this.config,
    required RouteSettings? routeSettings,
    required this.sheetController,
  }) : super(settings: routeSettings);

  final CapturedThemes capturedThemes;
  final _SheetConfig config;
  final SpringBottomSheetController? sheetController;

  final GlobalKey<_SpringBottomSheetRoutePageState<T>> _pageKey =
      GlobalKey<_SpringBottomSheetRoutePageState<T>>();
  bool _popStarted = false;
  bool _completed = false;

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;

  @override
  Widget buildModalBarrier() {
    return const IgnorePointer(child: SizedBox.expand());
  }

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  // Not calling super keeps the Navigator from removing the route immediately,
  // letting the spring animation play to completion first. The trade-off is
  // that NavigatorObserver.didPop is never fired for this route; observers
  // receive didRemove instead when _complete() calls removeRoute().
  // ignore: must_call_super
  bool didPop(T? result) {
    if (config.isDismissible) {
      _beginPop(result);
    }
    return false;
  }

  @override
  void didComplete(T? result) {
    _completed = true;
    super.didComplete(result);
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return capturedThemes.wrap(
      _SpringBottomSheetRoutePage<T>(key: _pageKey, route: this),
    );
  }

  void _beginPop(T? result) {
    if (_popStarted) return;
    _popStarted = true;
    final pageState = _pageKey.currentState;
    if (pageState == null) {
      _complete(result);
      return;
    }
    pageState.close(result);
  }

  void _complete(T? result) {
    if (_completed) return;
    _completed = true;
    navigator?.removeRoute(this, result);
  }
}

class _SpringBottomSheetRoutePage<T> extends StatefulWidget {
  const _SpringBottomSheetRoutePage({required this.route, super.key});

  final _SpringBottomSheetRoute<T> route;

  @override
  State<_SpringBottomSheetRoutePage<T>> createState() =>
      _SpringBottomSheetRoutePageState<T>();
}

class _SpringBottomSheetRoutePageState<T>
    extends State<_SpringBottomSheetRoutePage<T>> {
  late final SpringBottomSheetController _controller =
      widget.route.sheetController ?? SpringBottomSheetController();
  T? _result;
  bool _closing = false;

  void close(T? result) {
    if (_closing) return;
    _closing = true;
    _result = result;
    unawaited(_controller.dismiss());
  }

  @override
  void dispose() {
    // Fallback: if this state is disposed while the dismiss animation is still
    // in flight (e.g. the navigator was reset mid-animation), ensure the route
    // future always resolves. _complete is idempotent.
    widget.route._complete(_result);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.route.config;

    return SpringBottomSheet(
      backdropColor: config.backdropColor,
      backgroundColor: config.backgroundColor,
      borderRadius: config.borderRadius,
      clipBehavior: config.clipBehavior,
      controller: _controller,
      elevation: config.elevation,
      enableContentDrag: config.enableContentDrag,
      enableDrag: config.enableDrag,
      header: config.headerBuilder != null
          ? Builder(builder: config.headerBuilder!)
          : null,
      initialSnapIndex: config.initialSnapIndex,
      isDismissible: config.isDismissible,
      maxTopGap: config.maxTopGap,
      onDismissed: () => widget.route._complete(_result),
      open: true,
      rubberBandConstant: config.rubberBandConstant,
      shadowColor: config.shadowColor,
      showDragHandle: config.showDragHandle,
      snapSizes: config.snapSizes,
      spring: config.spring,
      springTolerance: config.springTolerance,
      child: Builder(builder: config.builder),
    );
  }
}
