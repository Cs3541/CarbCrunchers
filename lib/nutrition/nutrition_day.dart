import 'dart:math' as math;

typedef Numbers = Map<String, double>;
typedef History = Map<String, NutritionDay>;

String dayId(DateTime date) => date.toIso8601String().substring(0, 10);

class NutritionDay {
  final Numbers goals;
  final Numbers totals;
  final String focus;

  const NutritionDay(this.goals, this.totals, this.focus);

  double eaten(String name) => totals[name] ?? 0.0;

  double target(String name) => goals['Daily $name (g)']!;

  double allowance(String name) => goals['Daily $name grace (g)'] ?? 0.0;

  double extra(String name) => math.max(0.0, eaten(name) - target(name));

  bool get withinLimits {
    return ['fat', 'sugar'].every(
      (name) => extra(name) <= allowance(name) + 1e-6,
    );
  }

  bool get qualifies {
    final reachedTargets = ['protein', 'carbs'].every(
      (name) => eaten(name) + 1e-6 >= target(name),
    );

    return reachedTargets && withinLimits;
  }
}

int currentStreak(History history, DateTime now) {
  DateTime previousDay(DateTime date) {
    return DateTime(date.year, date.month, date.day - 1);
  }

  final today = history[dayId(now)];

  if (today?.withinLimits == false) return 0;

  // Keep yesterday's streak visible while the user works on today's goals.
  var date = today?.qualifies == true ? now : previousDay(now);
  var count = 0;

  while (history[dayId(date)]?.qualifies == true) {
    count++;
    date = previousDay(date);
  }

  return count;
}