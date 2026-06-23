## 1.0.0

This is a **complete rewrite** of the package. The public API is not
backward-compatible with 0.0.3. Follow the migration guide below.

### New features

- **`showSpringBottomSheet`** – a `showModalBottomSheet`-style route API that
  pushes a spring-animated sheet onto the navigator stack and returns a
  `Future<T?>` when dismissed.
- **`SpringBottomSheet`** – fully rebuilt widget with spring physics, multiple
  snap points, drag gestures, rubber-band overscroll bounds, a dimmed backdrop,
  and optional header area.
- **`SpringBottomSheetController`** – imperative controller with
  `snapToIndex`, `snapToNearest`, and `dismiss` actions.
- **`SpringBottomSheetScrollController`** – inherited scroll controller that
  coordinates a scrollable child with the surrounding sheet so content drags
  resize the sheet before the list scrolls.
- **`SpringStaggeredListView`** / **`SpringStaggeredItem`** –
  dependency-free widgets that fade and slide list items from the bottom with
  configurable stagger delay.

### Breaking changes & migration guide

#### 1. Minimum Flutter / Dart SDK raised

| | 0.0.3 | 1.0.0 |
|---|---|---|
| Dart SDK | `>=3.4.1 <4.0.0` | `>=3.8.0 <4.0.0` |

Update your `pubspec.yaml` environment constraint if needed and run
`flutter pub upgrade`.

---

#### 2. `SpringBottomSheet` constructor changed completely

In 0.0.3 the widget accepted only `child` and handled everything
(sizing, spring params, animation trigger) internally.

```dart
// 0.0.3
SpringBottomSheet(
  child: MyContent(),
)
```

In 1.0.0 the widget is a **stateful overlay layer**. You control visibility
with the required `open` bool, and the sheet snaps to fractional screen-height
points instead of sizing to the child's intrinsic height.

```dart
// 1.0.0
SpringBottomSheet(
  open: _isOpen,              // required – replaces the old auto-trigger
  onDismissed: () => setState(() => _isOpen = false),
  child: MyContent(),
)
```

**Minimal migration steps:**

1. Add `open: _isOpen` to every `SpringBottomSheet(...)` call.
2. Add `onDismissed:` to react when the user swipes it away.
3. Remove any wrapper logic that showed/hid the widget by inserting or
   removing it from the tree – `open` replaces that pattern.

---

#### 3. Auto-sizing replaced by `snapSizes`

The old widget measured the child's `RenderBox` height and expanded to fill
it. In 1.0.0 the sheet occupies fractional heights defined by `snapSizes`
(default `[0.35, 0.65, 0.92]`).

If you were relying on the auto-sized behaviour, pass a single snap size that
approximates your content height as a fraction of the screen:

```dart
SpringBottomSheet(
  open: _isOpen,
  snapSizes: const [0.5],   // ~50% of screen height
  child: MyContent(),
)
```

---

#### 4. Entrance animation is now driven by `open`, not by widget insertion

In 0.0.3 inserting the widget into the tree was what triggered the spring
entrance. In 1.0.0 the widget must always be present in the tree; flipping
`open` from `false` to `true` starts the spring entrance.

```dart
// 0.0.3 pattern — no longer works as expected
if (_isOpen)
  SpringBottomSheet(child: MyContent())

// 1.0.0 pattern
SpringBottomSheet(
  open: _isOpen,
  child: MyContent(),
)
```

---

#### 5. Hardcoded spring parameters are now customisable

The 0.0.3 spring was fixed at `SpringDescription(mass: 1, stiffness: 500, damping: 25)`.
The 1.0.0 default is softer (`stiffness: 210, damping: 20`). If your design
relies on the bouncier old feel, pass the old values explicitly:

```dart
SpringBottomSheet(
  open: _isOpen,
  spring: const SpringDescription(mass: 1, stiffness: 500, damping: 25),
  child: MyContent(),
)
```

---

#### 6. Modal route usage (replaces `showModalBottomSheet` wrappers)

If you were wrapping `SpringBottomSheet` inside `showModalBottomSheet`, switch
to the new first-class function:

```dart
// 0.0.3
showModalBottomSheet(
  context: context,
  builder: (_) => SpringBottomSheet(child: MyContent()),
);

// 1.0.0
showSpringBottomSheet(
  context: context,
  builder: (_) => MyContent(),
);
```

---

### New constructor parameters at a glance

| Parameter | Default | Description |
|---|---|---|
| `open` *(required)* | – | Drives open/close animation |
| `snapSizes` | `[0.35, 0.65, 0.92]` | Fractional snap heights |
| `initialSnapIndex` | `0` | Which snap point to open to |
| `onDismissed` | `null` | Called after sheet closes |
| `isDismissible` | `true` | Backdrop tap / swipe-down closes |
| `enableDrag` | `true` | Handle/header drag resizes sheet |
| `enableContentDrag` | `true` | Content drag resizes sheet |
| `controller` | `null` | Imperative `SpringBottomSheetController` |
| `header` | `null` | Widget pinned above scrollable body |
| `showDragHandle` | `true` | Shows default pill drag handle |
| `backdropColor` | `0x990F172A` | Dimmed backdrop tint |
| `backgroundColor` | `Colors.white` | Sheet surface color |
| `borderRadius` | `28 px top` | Sheet corner radius |
| `elevation` | `22` | Material elevation |
| `shadowColor` | `0x33111827` | Shadow tint |
| `maxTopGap` | `14` | Minimum gap between sheet top and screen top |
| `rubberBandConstant` | `0.55` | Overscroll rubber-band resistance |
| `spring` | `mass 1 / stiffness 210 / damping 20` | Spring physics |
| `springTolerance` | `distance 0.6 / velocity 0.6` | Simulation stop threshold |

---

## 0.0.3

- Updated to optimize usability, making it more user-friendly compared to the
  previous version.

## 0.0.2

- Updated to optimize usability, making it more user-friendly compared to the
  previous version.

## 0.0.1

- Initial release.
