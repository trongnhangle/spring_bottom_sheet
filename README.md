<div align="center">
  <h1>Spring Bottom Sheet</h1>
  <p>A dependency-free Flutter bottom sheet with spring physics, content-based sizing, snap points, coordinated scrolling, and rubber-band gestures.</p>
</div>

<p align="center">
  <a href="https://pub.dev/packages/spring_bottom_sheet">
    <img src="https://img.shields.io/pub/v/spring_bottom_sheet.svg" alt="pub package">
  </a>
  <a href="https://pub.dev/packages/spring_bottom_sheet/score">
    <img src="https://img.shields.io/pub/likes/spring_bottom_sheet" alt="pub likes">
  </a>
  <a href="https://pub.dev/packages/spring_bottom_sheet/score">
    <img src="https://img.shields.io/pub/popularity/spring_bottom_sheet" alt="pub popularity">
  </a>
</p>

<p align="center">
  <img width="368" height="720" alt="Spring Bottom Sheet demo" src="https://github.com/user-attachments/assets/917d6c8f-716b-4a02-b32a-d45722b03d68">
</p>

## Features

- Content-height sizing by default, similar to Flutter's standard bottom sheet.
- Optional fractional snap points for compact, medium, and expanded states.
- Consistent dragging from the header, body, or drag handle.
- Coordinated sheet resizing and content scrolling.
- Spring settling powered by Flutter's `SpringSimulation`.
- Rubber-band resistance beyond the sheet bounds.
- Modal route API with `Future<T?>` result support.
- Imperative controller for snapping and dismissal.
- Optional dependency-free staggered content animations.
- No third-party runtime dependencies.

## Installation

```bash
flutter pub add spring_bottom_sheet
```

Or add the package manually:

```yaml
dependencies:
  spring_bottom_sheet: ^1.0.1
```

Then import it:

```dart
import 'package:spring_bottom_sheet/spring_bottom_sheet.dart';
```

## Quick start

`snapSizes` is optional. When omitted, the sheet measures its rendered content
and opens to that height, capped by the available viewport.

```dart
FilledButton(
  onPressed: () {
    showSpringBottomSheet<void>(
      context: context,
      builder: (context) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Text('Hello from Spring Bottom Sheet!'),
        );
      },
    );
  },
  child: const Text('Open sheet'),
)
```

## Content-sized sheets

The default behavior is best for menus, forms, action panels, and other content
with a natural finite height:

```dart
showSpringBottomSheet<void>(
  context: context,
  headerBuilder: (context) => const Padding(
    padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
    child: Text(
      'Choose an action',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    ),
  ),
  builder: (context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: Text('Edit')),
          ListTile(title: Text('Share')),
          ListTile(title: Text('Delete')),
        ],
      ),
    );
  },
);
```

If the content changes after the sheet opens, the sheet tracks its latest
rendered height without starting a new spring on every layout frame.

### Content-sized scroll views

A regular `ListView` expands to the maximum available height. For a short,
finite menu, use `shrinkWrap: true` to size the sheet to the list content:

```dart
showSpringBottomSheet<void>(
  context: context,
  builder: (context) {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: const [
        ListTile(title: Text('Profile')),
        ListTile(title: Text('Settings')),
        ListTile(title: Text('Sign out')),
      ],
    );
  },
);
```

Keep `shrinkWrap: false` (the default) for long or lazily-built lists.
Shrink-wrapping requires Flutter to recompute the scroll view's extent as it
scrolls and is significantly more expensive for large collections. Long
content is automatically capped by the available viewport and continues
scrolling inside the sheet.

## Custom snap points

Pass `snapSizes` when the sheet should have one or more predefined heights.
Each value is a fraction of the available height:

```dart
showSpringBottomSheet<void>(
  context: context,
  initialSnapIndex: 1,
  snapSizes: const [0.32, 0.62, 0.92],
  builder: (context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 40,
      itemBuilder: (context, index) {
        return ListTile(title: Text('Row $index'));
      },
    );
  },
);
```

The available height excludes the top safe-area padding and `maxTopGap`.
Values are clamped to `0.0...1.0`, sorted, and de-duplicated. If no valid
positive snap remains, the sheet falls back to a single 60% snap point.

## Drag and scroll behavior

Dragging the header, handle, non-scrollable body, or scrollable body uses the
same sheet drag curve and rubber-band behavior.

For coordinated scrollable content:

1. An upward gesture expands the sheet toward its largest snap point.
2. A gesture that starts as a sheet resize remains a sheet resize until it ends.
3. After the sheet reaches its largest snap, the next upward gesture scrolls
   the content.
4. When the content is back at its top, a downward gesture collapses or
   dismisses the sheet.

Primary vertical scroll views inherit the coordinated controller automatically.
If a scroll view requires an explicit controller, obtain it from the sheet body
context:

```dart
builder: (context) {
  return ListView(
    controller: SpringBottomSheetScrollController.of(context),
    padding: const EdgeInsets.all(20),
    children: const [
      ListTile(title: Text('First')),
      ListTile(title: Text('Second')),
    ],
  );
}
```

Set `enableContentDrag: false` to let scrollable content handle its gestures
independently. Set `enableDrag: false` to disable direct surface dragging.

## Returning a result

`showSpringBottomSheet` returns a `Future<T?>`, just like Flutter's modal route
helpers:

```dart
final result = await showSpringBottomSheet<String>(
  context: context,
  builder: (context) {
    return ListTile(
      title: const Text('Select this value'),
      onTap: () => Navigator.of(context).pop('selected'),
    );
  },
);
```

## Controller

Use `SpringBottomSheetController` for imperative actions:

```dart
final sheetController = SpringBottomSheetController();

showSpringBottomSheet<void>(
  context: context,
  controller: sheetController,
  snapSizes: const [0.35, 0.65, 0.92],
  headerBuilder: (context) {
    return Row(
      children: [
        TextButton(
          onPressed: () => sheetController.snapToIndex(0),
          child: const Text('Compact'),
        ),
        TextButton(
          onPressed: () => sheetController.snapToIndex(2),
          child: const Text('Expand'),
        ),
        IconButton(
          onPressed: () => sheetController.dismiss(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  },
  builder: (context) => const Center(child: Text('Controlled sheet')),
);
```

| Member | Description |
| --- | --- |
| `height` | Current sheet height in logical pixels. |
| `snapToIndex(index, velocity: 0)` | Animates to a snap point. The index is safely clamped. |
| `snapToNearest(velocity: 0)` | Animates to the nearest snap point. |
| `dismiss(velocity: 0)` | Animates to the closed position when dismissal is configured. |

## Using the widget directly

Use `SpringBottomSheet` directly when the sheet belongs inside your own
`Stack`:

```dart
class SheetHost extends StatefulWidget {
  const SheetHost({super.key});

  @override
  State<SheetHost> createState() => _SheetHostState();
}

class _SheetHostState extends State<SheetHost> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: FilledButton(
            onPressed: () => setState(() => _open = true),
            child: const Text('Open sheet'),
          ),
        ),
        SpringBottomSheet(
          open: _open,
          onDismissed: () => setState(() => _open = false),
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Content-sized sheet'),
          ),
        ),
      ],
    );
  }
}
```

Provide `onDismissed` if backdrop taps, swipe-down gestures, or controller
dismissal should update the host state.

## Staggered content

`SpringStaggeredListView` fades and slides each direct child:

```dart
SpringStaggeredListView(
  shrinkWrap: true,
  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
  initialDelay: const Duration(milliseconds: 120),
  staggerDelay: const Duration(milliseconds: 60),
  children: const [
    ListTile(title: Text('Profile')),
    ListTile(title: Text('Settings')),
    ListTile(title: Text('Sign out')),
  ],
)
```

When `controller` and `primary` are both unset, the list automatically inherits
the sheet's coordinated scroll controller. An explicit `controller` or
`primary: false` is respected.

Use `SpringStaggeredItem` to animate an individual widget:

```dart
SpringStaggeredItem(
  delay: const Duration(milliseconds: 180),
  child: FilledButton(
    onPressed: () {},
    child: const Text('Continue'),
  ),
)
```

## API reference

### `showSpringBottomSheet`

| Parameter | Default | Description |
| --- | --- | --- |
| `context` | required | Context used to find the target `Navigator`. |
| `builder` | required | Builds the sheet body. |
| `backdropColor` | `Color(0x990F172A)` | Backdrop color at full progress. |
| `backgroundColor` | `Colors.white` | Sheet surface color. |
| `borderRadius` | `28 px` top radius | Sheet surface shape. |
| `clipBehavior` | `Clip.antiAlias` | Surface clipping behavior. |
| `controller` | `null` | Optional imperative controller. |
| `elevation` | `22` | Material elevation. |
| `enableContentDrag` | `true` | Coordinates body scrolling with sheet resizing. |
| `enableDrag` | `true` | Enables dragging from the sheet surface. |
| `headerBuilder` | `null` | Builds content above the body and below the handle. |
| `initialSnapIndex` | `0` | Initial snap index. |
| `isDismissible` | `true` | Enables backdrop and swipe-down dismissal. |
| `maxTopGap` | `14` | Gap below the top safe area at maximum height. |
| `routeSettings` | `null` | Optional Navigator route settings. |
| `rubberBandConstant` | `0.55` | Resistance beyond snap bounds. |
| `shadowColor` | `Color(0x33111827)` | Material shadow color. |
| `showDragHandle` | `true` | Shows the default drag handle. |
| `snapSizes` | `null` | Uses content height. Pass fractions for custom snaps. |
| `spring` | `mass: 1, stiffness: 210, damping: 20` | Spring physics. |
| `springTolerance` | `distance: 0.6, velocity: 0.6` | Simulation tolerance. |
| `useRootNavigator` | `false` | Pushes the route on the root Navigator. |

### `SpringBottomSheet`

`SpringBottomSheet` supports the same visual, gesture, snap, and spring options,
plus:

| Property | Description |
| --- | --- |
| `child` | Required body content. |
| `open` | Required visibility state. |
| `header` | Optional widget above the body. |
| `onDismissed` | Called after a dismiss action reaches the closed position. |

## Example

```bash
cd example
flutter run
```

The example app demonstrates content sizing, custom snap points, coordinated
scrolling, dismissal, and staggered content.

## Testing

```bash
flutter analyze
flutter test
```

## Requirements

- Dart SDK `>=3.8.0 <4.0.0`
- Flutter SDK compatible with the package environment

## Contributing

Issues and pull requests are welcome. Behavioral changes should include a
focused test or an example update.

## Support

If this package saves you time, you can support continued development through
[Ko-fi](https://ko-fi.com/trongnhangle) or
[PayPal](https://www.paypal.me/trongnhangle).

## License

Released under the [MIT License](LICENSE).
