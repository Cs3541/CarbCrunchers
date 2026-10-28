import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'homescreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const carbCrunchersApp());
}

class carbCrunchersApp extends StatelessWidget {
  const carbCrunchersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carb Crunchers',
      theme: ThemeData(primaryColor: const Color.fromARGB(255, 248, 76, 2)),
      home: const HomeScreen(),
    );
  }
}
