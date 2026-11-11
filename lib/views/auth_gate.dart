import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'homescreen.dart';
import 'login.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    required this.authStateChanges,
    required this.initialUser,
    this.signedOutScreen = const LoginScreen(),
    this.signedInScreen = const HomeScreen(),
    super.key,
  });

  final Stream<User?> authStateChanges;
  final User? initialUser;
  final Widget signedOutScreen;
  final Widget signedInScreen;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authStateChanges,
      initialData: initialUser,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Unable to verify your sign-in status: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return snapshot.data == null ? signedOutScreen : signedInScreen;
      },
    );
  }
}
