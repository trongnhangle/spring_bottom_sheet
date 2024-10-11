library spring_bottom_sheet;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// A BottomSheet widget with a spring animation effect.
class SpringBottomSheet extends StatefulWidget {
  const SpringBottomSheet({Key? key}) : super(key: key);

  @override
  _SpringBottomSheetState createState() => _SpringBottomSheetState();
}

class _SpringBottomSheetState extends State<SpringBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _controller.addListener(() {
      setState(() {});
    });

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20 * _controller.value),
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5 * _controller.value,
        color: Colors.white,
        child: const Center(
          child: Text(
            'Spring BottomSheet Content',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}

/// Function to show the SpringBottomSheet.
void showSpringBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (context) => const SpringBottomSheet(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}
