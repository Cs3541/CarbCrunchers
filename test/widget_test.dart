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
import 'package:carb_cruncher/models/goals_repository.dart';

class FakeGoalsRepository implements GoalsRepository {
  Map<String, dynamic> data = {};

  @override
  Future<Map<String, dynamic>> load() async => Map.of(data);

  @override
  Future<void> save(Map<String, dynamic> data) async {
    this.data = Map.of(data);
  }
}

void main() {
  testWidgets('Goals screen displays its configuration controls', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: GoalsScreen(repository: FakeGoalsRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Goals'), findsOneWidget);
    expect(find.text("Next week's goal focus"), findsOneWidget);

    final dropdown = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>),
    );
    expect(dropdown.dropdownColor, Colors.white);

    final textFields = tester.widgetList<TextField>(find.byType(TextField));
    expect(textFields, hasLength(11));
    expect(find.text('Weekly sugar (g)'), findsNothing);
    expect(find.text('Weekly sugar grace (g)'), findsNothing);
    expect(find.text('Daily fat grace (g)'), findsOneWidget);
    expect(find.text('Daily sugar grace (g)'), findsOneWidget);
    expect(find.text('Weekly fat (g)'), findsNothing);
    expect(find.text('Weekly sugar (g)'), findsNothing);
    expect(find.text('Daily protein grace (g)'), findsNothing);
    expect(find.text('Daily carbs grace (g)'), findsNothing);
    expect(find.text('Daily carbs (g)'), findsOneWidget);
    expect(find.text('Calories'), findsOneWidget);
    expect(find.text('Goal 2000 calories'), findsOneWidget);
    expect(find.text('Target 2000 calories'), findsOneWidget);
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('Carbs'), findsOneWidget);
    expect(find.text('Fat'), findsOneWidget);
    expect(find.text('Sugar'), findsOneWidget);
    for (final textField in textFields) {
      expect(textField.decoration?.filled, isTrue);
      expect(textField.decoration?.fillColor, Colors.white);
    }
  });

  testWidgets('Saving fat grace updates the graph threshold', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = FakeGoalsRepository();
    await tester.pumpWidget(
      MaterialApp(home: GoalsScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    final fatGraceField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Daily fat grace (g)',
    );
    await tester.enterText(fatGraceField, '15');
    await tester.tap(find.text("Save Next Week's Goals"));
    await tester.pumpAndSettle();

    expect(find.text("Next week's goals saved."), findsOneWidget);
    final weeks = repository.data['weeks'] as Map<String, dynamic>;
    final nextGoals = weeks.values
        .map((week) => week as Map<String, dynamic>)
        .singleWhere(
          (week) =>
              (week['values'] as Map<String, dynamic>)['Daily fat grace (g)'] ==
              15,
        );
    expect(
      (nextGoals['values'] as Map<String, dynamic>)['Daily fat grace (g)'],
      15,
    );
    expect(find.text('Allowed up to 70 g'), findsOneWidget);
  });

  testWidgets('Saving defaults does not change the locked current week', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = FakeGoalsRepository();
    await tester.pumpWidget(
      MaterialApp(home: GoalsScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    final proteinField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Daily protein (g)',
    );
    await tester.enterText(proteinField, '140');
    await tester.tap(find.text('Set as Default'));
    await tester.pumpAndSettle();

    final defaultGoals = repository.data['defaultGoals'] as Map<String, dynamic>;
    expect(
      (defaultGoals['values'] as Map<String, dynamic>)['Daily protein (g)'],
      140,
    );
    final weeks = repository.data['weeks'] as Map<String, dynamic>;
    final currentWeek = weeks.values
        .map((week) => week as Map<String, dynamic>)
        .singleWhere(
          (week) =>
              (week['values'] as Map<String, dynamic>)['Daily protein (g)'] ==
              100,
        );
    expect(
      (currentWeek['values'] as Map<String, dynamic>)['Daily protein (g)'],
      100,
    );
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
