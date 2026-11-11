// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carb_cruncher/views/auth_gate.dart';
import 'package:carb_cruncher/views/goals_screen.dart';

void main() {
  testWidgets('Goals screen displays its configuration controls', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: GoalsScreen()));

    expect(find.text('My Goals'), findsOneWidget);
    expect(find.text('Goal focus'), findsOneWidget);

    final dropdown = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>),
    );
    expect(dropdown.dropdownColor, Colors.white);

    final textFields = tester.widgetList<TextField>(find.byType(TextField));
    expect(textFields, hasLength(10));
    expect(find.text('Weekly sugar (g)'), findsNothing);
    expect(find.text('Weekly sugar grace (g)'), findsNothing);
    expect(find.text('Daily fat grace (g)'), findsOneWidget);
    expect(find.text('Daily sugar grace (g)'), findsOneWidget);
    expect(find.text('Weekly fat (g)'), findsNothing);
    for (final textField in textFields) {
      expect(textField.decoration?.filled, isTrue);
      expect(textField.decoration?.fillColor, Colors.white);
    }
  });

  testWidgets('Signed-out users see login before entering home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          authStateChanges: Stream.value(null),
          initialUser: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text("Don't have an account?"), findsOneWidget);
    expect(find.text('Browse Recipes'), findsNothing);
  });
}
