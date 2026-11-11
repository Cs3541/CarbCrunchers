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
import 'package:carb_cruncher/views/history_screen.dart';

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
    expect(textFields, hasLength(13));
    expect(find.text('Weekly sugar (g)'), findsNothing);
    expect(find.text('Weekly sugar grace (g)'), findsNothing);
    expect(find.text('Daily fat grace (g)'), findsOneWidget);
    expect(find.text('Daily sugar grace (g)'), findsOneWidget);
    expect(find.text('Weekly fat (g)'), findsNothing);
    expect(find.text('Weekly sugar (g)'), findsNothing);
    expect(find.text('Daily protein grace (g)'), findsOneWidget);
    expect(find.text('Daily carbs (g)'), findsOneWidget);
    expect(find.text('Daily carbs grace (g)'), findsOneWidget);
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('Carbs'), findsOneWidget);
    expect(find.text('Fat'), findsOneWidget);
    expect(find.text('Sugar'), findsOneWidget);
    for (final textField in textFields) {
      expect(textField.decoration?.filled, isTrue);
      expect(textField.decoration?.fillColor, Colors.white);
    }
  });

  testWidgets('Saving macro grace updates the graph threshold', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: GoalsScreen()));

    final proteinGraceField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Daily protein grace (g)',
    );
    await tester.enterText(proteinGraceField, '15');
    await tester.tap(find.text('Save Profile and Goals'));
    await tester.pump();

    expect(find.text('Allowed up to 115 g'), findsOneWidget);
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

  testWidgets('History screen shows an empty graph with range selectors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HistoryScreen()));

    expect(find.text('History'), findsOneWidget);
    expect(find.text('1 week'), findsOneWidget);
    expect(find.text('1 month'), findsOneWidget);
    expect(find.text('1 year'), findsOneWidget);
    expect(find.text('No history data yet'), findsOneWidget);

    final rangeSelector = tester.widget<SegmentedButton<dynamic>>(
      find.byKey(const ValueKey('history-range-selector')),
    );
    expect(
      rangeSelector.style?.backgroundColor?.resolve({WidgetState.selected}),
      const Color(0xFF1F5DA8),
    );
    expect(
      rangeSelector.style?.foregroundColor?.resolve({WidgetState.selected}),
      Colors.white,
    );
    expect(
      rangeSelector.style?.backgroundColor?.resolve({}),
      Colors.white,
    );

    await tester.tap(find.text('1 month'));
    await tester.pumpAndSettle();
    expect(find.text('No history data yet'), findsOneWidget);
  });
}
