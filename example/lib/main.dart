// ignore_for_file: depend_on_referenced_packages

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
