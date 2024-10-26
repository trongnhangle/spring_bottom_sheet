# Spring Bottom Sheet 🌟

### Hey Awesome Developer! ☕️

If this package makes your bottom sheets bounce with joy and saves you hours of animation headaches, consider buying me a coffee! After all, great code runs on caffeine! 

```
⭐️ "Good code is like good coffee - it keeps you running smoothly!" ⭐️
```

<p align="center">
  <img src="https://media.giphy.com/media/3jVT4U5bilspG/giphy.gif" alt="Funny Coffee GIF" width="200">
</p>

**Support my caffeinated coding adventures:**
- 🎯 [Buy Me a Coffee on Ko-fi](https://ko-fi.com/trongnhangle) 
- 💖 [Feed My PayPal Coffee Fund](https://www.paypal.me/trongnhangle)

*Your support helps me stay awake to create more awesome Flutter packages!* 😄

---

A Flutter package that provides a beautiful spring-animated bottom sheet with customizable properties and smooth animations.

[![pub package](https://img.shields.io/pub/v/spring_bottom_sheet.svg)](https://pub.dev/packages/spring_bottom_sheet)
[![likes](https://img.shields.io/pub/likes/spring_bottom_sheet)](https://pub.dev/packages/spring_bottom_sheet/score)
[![popularity](https://img.shields.io/pub/popularity/spring_bottom_sheet)](https://pub.dev/packages/spring_bottom_sheet/score)

[Rest of the README content remains the same...]

## Features

- 🎯 Spring-like animation effect
- 🎨 Fully customizable appearance
- 📱 Responsive design
- 🔄 Smooth drag gestures
- ⚡ Easy to implement
- 🛠 Highly configurable

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  spring_bottom_sheet: ^latest_version
```

## Usage

First, import the package:

```dart
import 'package:spring_bottom_sheet/spring_bottom_sheet.dart';
```

### Basic Usage

```dart
showSpringBottomSheet(
  context: context,
  builder: (context) => Container(
    padding: EdgeInsets.all(16),
    child: Text('Hello from Spring Bottom Sheet!'),
  ),
);
```

### Advanced Usage with Custom Properties

```dart
showSpringBottomSheet(
  context: context,
  builder: (context) => YourCustomWidget(),
  backgroundColor: Colors.white,
  elevation: 8.0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  clipBehavior: Clip.antiAliasWithSaveLayer,
  isScrollControlled: true,
  isDismissible: true,
  enableDrag: true,
  showDragHandle: true,
);
```

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `context` | `BuildContext` | Required | The build context |
| `builder` | `WidgetBuilder` | Required | Builder for bottom sheet content |
| `backgroundColor` | `Color?` | `Colors.white` | Background color of the sheet |
| `elevation` | `double?` | - | Sheet's elevation |
| `shape` | `ShapeBorder?` | - | Shape of the bottom sheet |
| `clipBehavior` | `Clip?` | - | How to clip the bottom sheet's content |
| `constraints` | `BoxConstraints?` | - | Size constraints |
| `barrierColor` | `Color?` | - | Color of the modal barrier |
| `isScrollControlled` | `bool` | `false` | Whether the sheet is scrollable |
| `scrollControlDisabledMaxHeightRatio` | `double` | `9.0/16.0` | Maximum height ratio when scroll is disabled |
| `isDismissible` | `bool` | `true` | Can be dismissed by tapping outside |
| `enableDrag` | `bool` | `true` | Can be dragged up/down |
| `showDragHandle` | `bool?` | - | Shows a drag handle at the top |
| `useSafeArea` | `bool` | `false` | Respects system UI padding |

## Example Project

Here's a complete example showing how to use Spring Bottom Sheet:

```dart
import 'package:flutter/material.dart';
import 'package:spring_bottom_sheet/spring_bottom_sheet.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spring BottomSheet Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spring Bottom Sheet Demo')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Show Spring BottomSheet'),
          onPressed: () {
            showSpringBottomSheet(
              context: context,
              builder: (context) => Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Spring Bottom Sheet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'This is a custom bottom sheet with spring animation!',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
              isScrollControlled: true,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

## Animation Customization

The spring animation uses the following default parameters:
- Mass: 1.0
- Stiffness: 500.0
- Damping: 25.0

These values can be modified by extending the `SpringBottomSheet` widget and overriding the spring simulation parameters.

## Contributing

Contributions are welcome! If you find a bug or want to add a feature, please feel free to:
1. Open an issue
2. Create a pull request

## License

```
MIT License

Copyright (c) 2024 TRONG NHAN NGUYEN LE

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```