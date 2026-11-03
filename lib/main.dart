import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'Presenters/AuthPresenter.dart';
import 'auth_gate.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authPresenter = AuthPresenter();

    return MaterialApp(
      title: 'Carb Crunchers',
      theme: ThemeData(primaryColor: const Color.fromARGB(255, 248, 76, 2)),
      home: AuthGate(
        authStateChanges: authPresenter.authStateChanges(),
        initialUser: authPresenter.currentUser,
      ),
    );
  }
}
