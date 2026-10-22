import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Text(
          'Carb Crunchers',
          style: TextStyle(
          fontSize: 24.0, 
          fontWeight: FontWeight.bold,
           color: Color.fromARGB(255, 6, 239, 6),),
        ),
      ),
      ),
    );
  }
}