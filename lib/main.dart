import 'dart:async';
import 'package:flutter/material.dart';
import 'homescreen.dart';


void main() {
  runApp(const carbCrunchersApp());
}

class carbCrunchersApp extends StatelessWidget {
  const carbCrunchersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carb Crunchers',
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 248, 76, 2),
      ),
      home: const HomeScreen(),
    );
  }
}