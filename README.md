<div align="center" style="font-size: 70px; font-weight: bold;">
    Spring Bottom Sheet 🌟
</div>

### Hey Awesome Developer! ☕️

If `spring_bottom_sheet` saves you time, makes your UI feel smoother, or helps you ship faster, please consider supporting its development.

I have never received any sponsorship or financial support for this work before. Even a small contribution — just $1 — would mean more than you can imagine. It helps me keep maintaining this package, improving the documentation, fixing issues, and building more useful Flutter tools for the community.

```
⭐️ "Open-source code grows stronger when kind developers support the people behind it." ⭐️
```

<img width="720" height="330" alt="support-open-source" src="https://github.com/user-attachments/assets/2d8905a8-f089-4e87-a0fa-e40c09b16d30" />

<p align="center">
  <a href="https://ko-fi.com/trongnhangle">
    <img src="assets/support-open-source.gif" alt="Support this project - even $1 helps" width="430">
  </a>
</p>

<div align="center">
  <h2>Support this project and help me keep building:</h2>
  <p style="font-size: 18px;">
    🎯 Support me on <a href="https://ko-fi.com/trongnhangle" style="font-size: 22px; font-weight: bold;">Ko-fi</a><br>
    💖 Send a small contribution via <a href="https://www.paypal.me/trongnhangle" style="font-size: 22px; font-weight: bold;">PayPal</a>
  </p>
</div>

*Every contribution, even $1, gives me more motivation to keep creating and improving open-source Flutter packages.* 🙏

---

# spring_bottom_sheet ✨

A dependency-free Flutter bottom sheet with spring physics, snap points,
dragging, rubber-band resistance, backdrop dismissal, coordinated scrolling, and
optional staggered content animations.

[![pub package](https://img.shields.io/pub/v/spring_bottom_sheet.svg)](https://pub.dev/packages/spring_bottom_sheet)
[![likes](https://img.shields.io/pub/likes/spring_bottom_sheet)](https://pub.dev/packages/spring_bottom_sheet/score)
[![popularity](https://img.shields.io/pub/popularity/spring_bottom_sheet)](https://pub.dev/packages/spring_bottom_sheet/score)

<figure>
  <img width="368" height="720" alt="Spring Bottom Sheet demo — smooth spring animation with snap points, drag handle, and backdrop dimming" src="https://github.com/user-attachments/assets/917d6c8f-716b-4a02-b32a-d45722b03d68" />
</figure>


## ✨ Features

- 🚀 Modal route helper with `showSpringBottomSheet`.
- 🧩 Reusable `SpringBottomSheet` widget for custom stacks and layouts.
- 🎯 Configurable snap points as viewport-height fractions.
- 🌀 Natural spring settling with Flutter's `SpringSimulation`.
- 🎛️ Drag handle, optional header, dimmed backdrop, rounded Material surface, and
  customizable shadow/elevation.
- 📜 Scroll-linked resizing for `ListView`, `CustomScrollView`, and other primary
  vertical scrollables.
- 🪄 Rubber-band resistance when the user drags beyond the sheet bounds.
- 🎮 Imperative `SpringBottomSheetController` for snapping and dismissal.
- 🎞️ Dependency-free staggered list/item animations for sheet content.
- 🧘 No third-party runtime dependencies.

## 📦 Installation

Install from pub.dev:

```bash
flutter pub add spring_bottom_sheet
```

Or add it manually to `pubspec.yaml`:

```yaml
dependencies:
  spring_bottom_sheet: ^1.0.0
```

Then import the package:

```dart
import 'package:spring_bottom_sheet/spring_bottom_sheet.dart';
```

## 🚀 Quick Start

Add a button anywhere in your Flutter screen and call `showSpringBottomSheet`.
This is the most basic way to open a springy modal sheet:

```dart
FilledButton(
  onPressed: () {
    showSpringBottomSheet(
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

Want more control? Add `snapSizes`, `headerBuilder`, or await the returned
`Future<T?>` to receive a value from `Navigator.pop`.

## 🎯 Snap Points

`snapSizes` are fractions of the available viewport height. The default value is:

```dart
const [0.35, 0.65, 0.92]
```

For example, `0.62` means the sheet snaps to 62% of the available height. The
available height is calculated from the parent constraints minus the top safe
area and `maxTopGap`, so the largest snap point can still leave breathing room
near the top of the screen.

Values are clamped between `0.0` and `1.0`, sorted, and de-duplicated. If every
value is invalid or empty after normalization, the sheet falls back to a single
60% snap point.

## 📜 Scroll-Linked Resizing

Scrollable content automatically works with the sheet when it uses the primary
scroll controller. The interaction mirrors Flutter's `DraggableScrollableSheet`:
drag upward to expand the sheet first, then scroll the content after the sheet
reaches its largest snap point; drag downward at the top of the content to
collapse the sheet.

```dart
showSpringBottomSheet(
  context: context,
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

If your scrollable needs an explicit controller, read the coordinated controller
from the sheet body context:

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

Set `enableContentDrag: false` when you want the scrollable to handle its own
drag gestures independently from the sheet.

## 🎮 Controller

Pass a `SpringBottomSheetController` when you need to control the sheet from
buttons, callbacks, or another widget.

```dart
final sheetController = SpringBottomSheetController();

showSpringBottomSheet(
  context: context,
  controller: sheetController,
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
          icon: const Icon(Icons.close_rounded),
          onPressed: () => sheetController.dismiss(),
        ),
      ],
    );
  },
  builder: (context) => const Center(child: Text('Controlled sheet')),
);
```

Available controller members:

| Member | Description |
| --- | --- |
| `height` | Current sheet height in logical pixels. |
| `snapToIndex(index, velocity: 0)` | Animates to the snap point at `index`. The index is clamped to the available range. |
| `snapToNearest(velocity: 0)` | Animates to the nearest snap point from the current height. |
| `dismiss(velocity: 0)` | Animates to the closed position when dismissal is configured. |

## 🧱 Using the Widget Directly

Use `SpringBottomSheet` directly when the sheet is part of your own widget tree,
for example inside a `Stack`.

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
          snapSizes: const [0.3, 0.6, 0.9],
          header: const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Custom header'),
          ),
          child: const Center(child: Text('Sheet body')),
        ),
      ],
    );
  }
}
```

When you use the widget directly, provide `onDismissed` if you want backdrop
taps, swipe-down gestures, or controller dismissal to close the sheet.

## 🎞️ Staggered Content

`SpringStaggeredListView` fades and slides each direct child from the bottom.
It is useful for bottom-sheet menus, action lists, forms, and selection panels.

```dart
SpringStaggeredListView(
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

Use `SpringStaggeredItem` when you want to animate individual widgets outside a
list.

```dart
SpringStaggeredItem(
  delay: const Duration(milliseconds: 180),
  child: FilledButton(
    onPressed: () {},
    child: const Text('Continue'),
  ),
)
```

## 📚 API Reference

### `showSpringBottomSheet`

| Parameter | Default | Description |
| --- | --- | --- |
| `context` | required | Build context used to find the target `Navigator`. |
| `builder` | required | Builds the sheet body. |
| `backdropColor` | `Color(0x990F172A)` | Backdrop color at full sheet progress. |
| `backgroundColor` | `Colors.white` | Sheet surface color. |
| `borderRadius` | `BorderRadius.vertical(top: Radius.circular(28))` | Sheet surface shape. |
| `clipBehavior` | `Clip.antiAlias` | Clip behavior for the sheet surface. |
| `controller` | `null` | Optional imperative controller. |
| `elevation` | `22` | Material elevation for the sheet. |
| `enableContentDrag` | `true` | Lets scroll gestures resize the sheet before content scrolls. |
| `enableDrag` | `true` | Enables dragging from the handle/header area. |
| `headerBuilder` | `null` | Builds custom content above the body and below the drag handle. |
| `initialSnapIndex` | `0` | Snap index used when the sheet opens. |
| `isDismissible` | `true` | Allows backdrop taps and swipe-down dismissal. |
| `maxTopGap` | `14` | Minimum visual gap from the top safe area at the largest snap. |
| `routeSettings` | `null` | Optional route settings for Navigator integrations. |
| `rubberBandConstant` | `0.55` | Resistance applied when dragging beyond snap bounds. |
| `shadowColor` | `Color(0x33111827)` | Material shadow color. |
| `showDragHandle` | `true` | Shows the default top drag handle. |
| `snapSizes` | `[0.35, 0.65, 0.92]` | Snap points as viewport-height fractions. |
| `spring` | `SpringDescription(mass: 1, stiffness: 210, damping: 20)` | Spring physics for open, close, and snap animations. |
| `springTolerance` | `Tolerance(distance: 0.6, velocity: 0.6)` | Tolerance for the spring simulation. |
| `useRootNavigator` | `false` | Pushes the route on the root navigator when `true`. |

### `SpringBottomSheet`

`SpringBottomSheet` exposes the same visual, gesture, snap, and spring options
as the route API. It also has:

| Property | Description |
| --- | --- |
| `child` | Required body content. |
| `open` | Required flag that controls whether the sheet is visible. |
| `header` | Optional header widget. Dragging is attached to the handle/header area. |
| `onDismissed` | Called after the sheet animates to the closed position through a dismiss action. |

## 🧪 Example App

Run the included example to see snap points, scroll-linked resizing, dismissal,
and staggered content together:

```bash
cd example
flutter run
```

## ✅ Testing

Run the package tests with:

```bash
flutter test
```

## 🛠️ Requirements

- 🎯 Dart SDK `>=3.8.0 <4.0.0`
- 💙 Flutter SDK compatible with the package environment

## 🤝 Contributing

Issues and pull requests are welcome. When changing behavior, please include a
focused test or update the example app so the interaction remains easy to
verify.

## ☕ Support

If this package saves you time or helps your project move faster, please consider
supporting its continued development through
[PayPal](https://www.paypal.me/trongnhangle).

I have never received any sponsorship or financial support for this work before,
so even a small contribution means a lot and helps me continue maintaining and
building open-source Flutter packages.

## 📄 License

This package is released under the [MIT License](LICENSE).
