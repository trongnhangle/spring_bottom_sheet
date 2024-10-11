
# spring_bottom_sheet

A Flutter package that adds a spring animation effect to the BottomSheet widget, providing a smooth and natural transition when displaying modal sheets.

## Features

- Customizable spring animation for the BottomSheet.
- Seamless integration with Flutter's `showModalBottomSheet` function.
- Easy to use with simple configuration.

## Installation

Add the following line to your `pubspec.yaml` under the `dependencies` section:

```yaml
dependencies:
  spring_bottom_sheet: ^0.0.1
```

Then, run the command:

```bash
flutter pub get
```

## Usage

To use the `SpringBottomSheet`, import it into your project and call the `showSpringBottomSheet` function:

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
      title: 'Spring BottomSheet Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Spring BottomSheet Demo'),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Show Spring BottomSheet'),
          onPressed: () {
            showSpringBottomSheet(context);
          },
        ),
      ),
    );
  }
}
```

### Example

The package comes with a demo app. You can find the source code in the `example` folder.

To run the example, use the following command:

```bash
flutter run example/lib/main.dart
```

## Customization

You can customize the spring animation by adjusting the `SpringDescription` inside the `SpringBottomSheet` widget, which includes the mass, stiffness, and damping parameters to control the bounce effect:

```dart
_controller.animateWith(
  SpringSimulation(
    SpringDescription(
      mass: 1,
      stiffness: 500,
      damping: 25,
    ),
    0,
    1,
    0,
  ),
);
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
