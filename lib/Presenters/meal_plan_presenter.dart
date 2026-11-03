import 'dart:async';
import '../models/meal_plan_model.dart';

class MealPlanPresenter {
  // Start the selected week on Sunday of the current week
  DateTime selectedWeekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday % 7),
  );

  final StreamController<List<PlannedMeal>> _mealsController =
      StreamController<List<PlannedMeal>>.broadcast();

  Stream<List<PlannedMeal>> get mealsStream => _mealsController.stream;

  // Load meals from Firestore and filter for the selected week
  Future<void> fetchMealsForWeek() async {
    final allUserMeals = await PlannedMeal.fetchMealsForUser();

    final weekStart = DateTime(
      selectedWeekStart.year,
      selectedWeekStart.month,
      selectedWeekStart.day,
    );
    final weekEnd = weekStart.add(const Duration(days: 7));

    // Filter meals falling within this 7-day window
    final weekMeals = allUserMeals.where((meal) {
      return meal.date.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
          meal.date.isBefore(weekEnd);
    }).toList();

    _mealsController.sink.add(weekMeals);
  }

  // Change selected week forward (+1) or backward (-1)
  void changeWeek(int offsetWeeks) {
    selectedWeekStart = selectedWeekStart.add(Duration(days: offsetWeeks * 7));
    fetchMealsForWeek();
  }

  void dispose() {
    _mealsController.close();
  }
}