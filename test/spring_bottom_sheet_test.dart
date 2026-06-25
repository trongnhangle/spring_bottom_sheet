import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spring_bottom_sheet/spring_bottom_sheet.dart';

void main() {
  testWidgets('renders a spring bottom sheet with staggered content', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _Harness(
        open: true,
        child: SpringStaggeredListView(
          children: [Text('First item'), Text('Second item')],
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Header'), findsOneWidget);
    expect(find.text('First item'), findsOneWidget);
    expect(find.text('Second item'), findsOneWidget);
  });

  testWidgets('dismiss animation does not overflow on a narrow viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(415, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = SpringBottomSheetController();

    await tester.pumpWidget(
      _Harness(
        controller: controller,
        open: true,
        child: const Center(child: Text('Body')),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    unawaited(controller.dismiss());

    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('content scroll gestures expand and collapse the sheet', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = SpringBottomSheetController();

    await tester.pumpWidget(
      _Harness(
        controller: controller,
        initialSnapIndex: 0,
        open: true,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 40,
          itemBuilder: (context, index) =>
              SizedBox(height: 56, child: Text('Item $index')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    final compactHeight = controller.height;

    await tester.timedDrag(
      find.text('Item 1'),
      const Offset(0, -180),
      const Duration(milliseconds: 600),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    final expandedHeight = controller.height;
    expect(expandedHeight, greaterThan(compactHeight + 120));

    await tester.timedDrag(
      find.text('Item 1'),
      const Offset(0, 180),
      const Duration(milliseconds: 600),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(controller.height, lessThan(expandedHeight - 120));
  });

  testWidgets('header and body use the same sheet drag curve', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = SpringBottomSheetController();

    await tester.pumpWidget(
      _Harness(
        controller: controller,
        initialSnapIndex: 0,
        open: true,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 40,
          itemBuilder: (context, index) =>
              SizedBox(height: 56, child: Text('Curve item $index')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    final headerDrag = await tester.startGesture(
      tester.getCenter(find.text('Header')),
    );
    await headerDrag.moveBy(const Offset(0, -24));
    await tester.pump();
    await headerDrag.moveBy(const Offset(0, -96));
    await tester.pump();
    final headerHeight = controller.height;
    await headerDrag.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    unawaited(controller.snapToIndex(0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    final bodyDrag = await tester.startGesture(
      tester.getCenter(find.text('Curve item 1')),
    );
    await bodyDrag.moveBy(const Offset(0, -24));
    await tester.pump();
    await bodyDrag.moveBy(const Offset(0, -96));
    await tester.pump();
    final bodyHeight = controller.height;
    await bodyDrag.up();

    expect(bodyHeight, closeTo(headerHeight, 1));
  });

  testWidgets('body finishes resizing before handing off to content scroll', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = SpringBottomSheetController();

    await tester.pumpWidget(
      _Harness(
        controller: controller,
        initialSnapIndex: 0,
        open: true,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 40,
          itemBuilder: (context, index) =>
              SizedBox(height: 56, child: Text('Handoff item $index')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(SpringBottomSheet),
        matching: find.byType(Scrollable),
      ),
    );

    final resizeDrag = await tester.startGesture(
      tester.getCenter(find.text('Handoff item 1')),
    );
    await resizeDrag.moveBy(const Offset(0, -24));
    await tester.pump();
    await resizeDrag.moveBy(const Offset(0, -500));
    await tester.pump();

    expect(controller.height, greaterThan(700));
    expect(scrollable.position.pixels, closeTo(0, 0.1));

    await resizeDrag.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    final expandedHeight = controller.height;

    await tester.timedDrag(
      find.text('Handoff item 1'),
      const Offset(0, -180),
      const Duration(milliseconds: 600),
    );
    await tester.pump();

    expect(scrollable.position.pixels, greaterThan(0));
    expect(controller.height, closeTo(expandedHeight, 1));
  });

  testWidgets('non-scrollable body drags the sheet surface', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = SpringBottomSheetController();

    await tester.pumpWidget(
      _Harness(
        controller: controller,
        initialSnapIndex: 1,
        open: true,
        child: const Center(child: Text('Plain body')),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    final balancedHeight = controller.height;

    await tester.timedDrag(
      find.text('Plain body'),
      const Offset(0, -180),
      const Duration(milliseconds: 600),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    final expandedHeight = controller.height;
    expect(expandedHeight, greaterThan(balancedHeight + 120));

    await tester.timedDrag(
      find.text('Plain body'),
      const Offset(0, 180),
      const Duration(milliseconds: 600),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(controller.height, lessThan(expandedHeight - 120));
  });

  testWidgets('shrink-wrapped package list inherits sheet drag coordination', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = SpringBottomSheetController();

    await tester.pumpWidget(
      _Harness(
        controller: controller,
        initialSnapIndex: 0,
        open: true,
        child: SpringStaggeredListView(
          shrinkWrap: true,
          children: [
            for (var index = 0; index < 12; index++)
              SizedBox(height: 56, child: Text('Shrink item $index')),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    final compactHeight = controller.height;

    await tester.timedDragFrom(
      const Offset(200, 720),
      const Offset(0, -180),
      const Duration(milliseconds: 600),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(controller.height, greaterThan(compactHeight + 120));
  });

  testWidgets('omitted snapSizes snaps to the rendered content height', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = SpringBottomSheetController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              SpringBottomSheet(
                controller: controller,
                header: const SizedBox(height: 48, child: Text('Header')),
                onDismissed: () {},
                open: true,
                showDragHandle: false,
                child: const SizedBox(height: 120, child: Text('Body')),
              ),
            ],
          ),
        ),
      ),
    );

    expect(controller.height, 0);
    expect(tester.getTopLeft(find.text('Body')).dy, greaterThan(800));

    await tester.pump(const Duration(milliseconds: 16));
    expect(controller.height, 0);
    await tester.pump(const Duration(milliseconds: 16));
    expect(controller.height, greaterThan(0));

    await tester.pump(const Duration(milliseconds: 700));

    expect(controller.height, closeTo(168, 2));
  });

  testWidgets('auto sizing caps a long scrollable at the available height', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = SpringBottomSheetController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              SpringBottomSheet(
                controller: controller,
                onDismissed: () {},
                open: true,
                showDragHandle: false,
                child: ListView.builder(
                  itemCount: 40,
                  itemBuilder: (context, index) =>
                      SizedBox(height: 56, child: Text('Long item $index')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 700));

    expect(controller.height, closeTo(786, 2));

    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(SpringBottomSheet),
        matching: find.byType(Scrollable),
      ),
    );

    await tester.timedDrag(
      find.text('Long item 1'),
      const Offset(0, -180),
      const Duration(milliseconds: 600),
    );
    await tester.pump();

    expect(scrollable.position.pixels, greaterThan(0));
    expect(controller.height, closeTo(786, 2));
  });

  testWidgets('package list respects an explicit primary false', (
    tester,
  ) async {
    late ScrollController sheetScrollController;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              SpringBottomSheet(
                onDismissed: () {},
                open: true,
                snapSizes: const [0.5],
                child: Builder(
                  builder: (context) {
                    sheetScrollController =
                        SpringBottomSheetScrollController.of(context);
                    return const SpringStaggeredListView(
                      animate: false,
                      primary: false,
                      shrinkWrap: true,
                      children: [SizedBox(height: 80)],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(sheetScrollController.hasClients, isFalse);
  });

  testWidgets('auto snap size follows content height changes', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = SpringBottomSheetController();
    late StateSetter setHarnessState;
    var expanded = false;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            setHarnessState = setState;

            return Scaffold(
              body: Stack(
                children: [
                  SpringBottomSheet(
                    controller: controller,
                    header: const SizedBox(height: 48, child: Text('Header')),
                    onDismissed: () {},
                    open: true,
                    showDragHandle: false,
                    child: SizedBox(
                      height: expanded ? 240 : 120,
                      child: const Text('Body'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(controller.height, closeTo(168, 2));

    setHarnessState(() {
      expanded = true;
    });
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 700));

    expect(controller.height, closeTo(288, 2));
  });

  testWidgets('auto snap body drag rubber-bands in both directions', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = SpringBottomSheetController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              SpringBottomSheet(
                controller: controller,
                header: const SizedBox(height: 48, child: Text('Header')),
                onDismissed: () {},
                open: true,
                showDragHandle: false,
                child: const SpringStaggeredListView(
                  animate: false,
                  shrinkWrap: true,
                  children: [
                    SizedBox(height: 56, child: Text('Auto item 0')),
                    SizedBox(height: 56, child: Text('Auto item 1')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    final settledHeight = controller.height;

    final upDrag = await tester.startGesture(
      tester.getCenter(find.text('Auto item 1')),
    );
    await upDrag.moveBy(const Offset(0, -20));
    await tester.pump();
    await upDrag.moveBy(const Offset(0, -40));
    await tester.pump();

    expect(controller.height, greaterThan(settledHeight));

    await upDrag.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    final downDrag = await tester.startGesture(
      tester.getCenter(find.text('Auto item 1')),
    );
    await downDrag.moveBy(const Offset(0, 20));
    await tester.pump();
    await downDrag.moveBy(const Offset(0, 40));
    await tester.pump();

    expect(controller.height, lessThan(settledHeight));

    await downDrag.up();
  });

  testWidgets('can switch from snapSizes to auto content sizing', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = SpringBottomSheetController();
    late StateSetter setHarnessState;
    var useAutoSnapSize = false;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            setHarnessState = setState;

            return Scaffold(
              body: Stack(
                children: [
                  SpringBottomSheet(
                    controller: controller,
                    header: const SizedBox(height: 48, child: Text('Header')),
                    onDismissed: () {},
                    open: true,
                    showDragHandle: false,
                    snapSizes: useAutoSnapSize ? null : const [0.5],
                    child: const SizedBox(height: 120, child: Text('Body')),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(controller.height, greaterThan(300));

    setHarnessState(() {
      useAutoSnapSize = true;
    });
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 700));

    expect(controller.height, closeTo(168, 2));
  });

  testWidgets('showSpringBottomSheet completes with Navigator.pop result', (
    tester,
  ) async {
    String? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    result = await showSpringBottomSheet<String>(
                      context: context,
                      initialSnapIndex: 1,
                      snapSizes: const [0.32, 0.62, 0.92],
                      headerBuilder: (context) => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Route header'),
                      ),
                      builder: (context) {
                        return Center(
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop('done'),
                            child: const Text('Return result'),
                          ),
                        );
                      },
                    );
                  },
                  child: const Text('Show sheet'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Show sheet'));
    await tester.pump();
    await tester.pumpAndSettle(
      const Duration(milliseconds: 16),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 3),
    );

    expect(find.text('Route header'), findsOneWidget);
    expect(find.text('Return result'), findsOneWidget);

    await tester.tap(find.text('Return result'));
    await tester.pump();
    await tester.pumpAndSettle(
      const Duration(milliseconds: 16),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 3),
    );
    await tester.pump();

    expect(result, 'done');
    expect(find.text('Return result'), findsNothing);
  });
}

class _Harness extends StatelessWidget {
  const _Harness({
    required this.child,
    required this.open,
    this.controller,
    this.initialSnapIndex = 1,
  });

  final Widget child;
  final SpringBottomSheetController? controller;
  final int initialSnapIndex;
  final bool open;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            const Center(child: Text('Background')),
            SpringBottomSheet(
              controller: controller,
              header: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Header'),
              ),
              onDismissed: () {},
              open: open,
              snapSizes: const [0.32, 0.62, 0.92],
              initialSnapIndex: initialSnapIndex,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
