import 'package:carb_cruncher/views/auth_gate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Signed-out users are shown signup instead of the app', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          authStateChanges: Stream<User?>.value(null),
          initialUser: null,
          signedOutScreen: const Text('Sign up or sign in'),
          signedInScreen: const Text('Home'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign up or sign in'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });
}
