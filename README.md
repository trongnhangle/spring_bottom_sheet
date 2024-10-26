<div align="center">  
 <h1 align="center" style="font-size: 70px;">Spring Bottom Sheet 🌟</h1>

### Hey Awesome Developer! ☕️

If this package makes your bottom sheets bounce with joy and saves you hours of animation headaches, consider buying me a coffee! After all, great code runs on caffeine! 

```
⭐️ "Good code is like good coffee - it keeps you running smoothly!" ⭐️
```

<p align="center">
  <img src="https://media.giphy.com/media/3jVT4U5bilspG/giphy.gif" alt="Funny Coffee GIF" width="200">
</p>

<div align="center">
  <h2>Support my caffeinated coding adventures:</h2>
  <p style="font-size: 18px;">
    🎯 Buy Me a Coffee on <a href="https://ko-fi.com/trongnhangle" style="font-size: 22px; font-weight: bold;">Ko-fi</a><br>
    💖 Feed My <a href="https://www.paypal.me/trongnhangle" style="font-size: 22px; font-weight: bold;">PayPal</a> Coffee Fund
  </p>
</div>


*Your support helps me stay awake to create more awesome Flutter packages!* 😄

---

A lightweight Flutter package that provides a beautiful spring-animated bottom sheet with automatic height adjustment and smooth animations.

[![pub package](https://img.shields.io/pub/v/spring_bottom_sheet.svg)](https://pub.dev/packages/spring_bottom_sheet)
[![likes](https://img.shields.io/pub/likes/spring_bottom_sheet)](https://pub.dev/packages/spring_bottom_sheet/score)
[![popularity](https://img.shields.io/pub/popularity/spring_bottom_sheet)](https://pub.dev/packages/spring_bottom_sheet/score)

[Rest of the README content remains the same...]

## Features

- 🎯 Natural spring animation effect
- 📏 Auto-adjusting height based on content
- 🎨 Smart height measurement system
- 🚀 Optimized performance with value notifiers
- 🪄 Simple to implement
- 🎉 Zero external dependencies

## Demo
![spring_bottom_sheet](https://github.com/user-attachments/assets/c8483be3-ae89-4bcb-90f6-392833ef535c)


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
showModalBottomSheet(
  context: context,
  builder: (context) => SpringBottomSheet(
    child: Container(
      color: Colors.white,
      height: 150,
      child: Center(
        child: Text('Bottom Sheet Content'),
      ),
    ),
  ),
  isScrollControlled: true,
);
```

### Complete Example

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
      backgroundColor: Colors.black,
      body: Center(
        child: ElevatedButton(
          child: const Text('Show Spring BottomSheet'),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => SpringBottomSheet(
                child: Container(
                  color: Colors.white,
                  height: 150,
                  child: const Center(
                    child: Text(
                      'This is your child!',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              ),
              isScrollControlled: true,
            );
          },
        ),
      ),
    );
  }
}
```

## How It Works

The `SpringBottomSheet` uses several advanced Flutter features to provide smooth animations:

1. **Height Measurement**: Uses a `GlobalKey` and `RenderBox` to accurately measure content height
2. **Value Notifier**: Efficiently tracks and updates height changes
3. **Spring Animation**: Implements custom spring physics with the following parameters:
   ```dart
   SpringDescription(
     mass: 1,      // Controls the weight feeling
     stiffness: 500, // Controls the spring force
     damping: 25,   // Controls bounce reduction
   )
   ```

## Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `child` | `Widget` | Yes | The content to be displayed inside the bottom sheet |

## Key Features Explained

1. **Automatic Height Measurement**
   - Uses `GlobalKey` to measure actual content height
   - Adjusts animation based on measured height
   - No manual height calculations needed

2. **Optimized Performance**
   - Uses `ValueNotifier` for efficient updates
   - Implements `SingleTickerProviderStateMixin` for animation
   - Minimal rebuild strategy with `AnimatedBuilder`

3. **Smart Animation System**
   - Post-frame callback ensures accurate measurements
   - Spring physics for natural feel
   - Cleanup handling in dispose method

## Contributing

Contributions are welcome! If you find a bug or want to add a feature, please:
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
