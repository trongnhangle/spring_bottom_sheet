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
