import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/nutrition_model.dart';
import 'nutrition_day.dart';

class ExtraServing implements Exception {
  final String details;

  ExtraServing(this.details);
}

class NutritionStore {
  final days = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection('nutritionDays');

  NutritionDay read(Map<String, dynamic> data) {
    Numbers numbers(String key) {
      final values = Map<String, num>.from(data[key] as Map);

      return values.map(
        (name, value) => MapEntry(name, value.toDouble()),
      );
    }

    return NutritionDay(
      numbers('goals'),
      numbers('totals'),
      data['focus'] as String,
    );
  }

  Stream<History> watch() {
    return days.snapshots().map((snapshot) {
      return {
        for (final doc in snapshot.docs) doc.id: read(doc.data()),
      };
    });
  }

  Future<void> saveGoals(String date, Numbers values, String focus) async {
    final ref = days.doc(date);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final doc = await transaction.get(ref);

      if (date != dayId(DateTime.now())) {
        throw StateError('The day changed. Open today’s goals.');
      }

      if (doc.exists) {
        throw StateError('Today’s goals are already locked.');
      }

      transaction.set(ref, {
        'goals': values,
        'focus': focus,
        'totals': <String, double>{},
      });
    });
  }

  Future<void> logServing(
    String date,
    Nutrition nutrition, {
    bool allowExtra = false,
  }) async {
    final ref = days.doc(date);

    final serving = {
      'calories': nutrition.calories,
      'protein': nutrition.protein,
      'carbs': nutrition.carbs,
      'fat': nutrition.fat,
      'sugar': nutrition.sugar,
    };

    if (serving.values.any((value) => !value.isFinite || value < 0)) {
      throw StateError('This recipe has invalid nutrition values.');
    }

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final doc = await transaction.get(ref);
      final data = doc.data();

      if (date != dayId(DateTime.now())) {
        throw StateError('The day changed. Try again.');
      }

      if (data == null) {
        throw StateError('Save today’s goals before logging a serving.');
      }

      final day = read(data);
      final totals = {
        for (final item in serving.entries)
          item.key: day.eaten(item.key) + item.value,
      };

      final prompts = <String>[];

      for (final name in ['fat', 'sugar']) {
        if (serving[name]! == 0) continue;

        final extra = totals[name]! - day.target(name);

        if (extra > 1e-6) {
          final pastLimit = extra > day.allowance(name) + 1e-6;

          prompts.add(
            '$name: ${extra.toStringAsFixed(1)} g extra today'
            '${pastLimit ? ' (past your streak limit)' : ''}',
          );
        }
      }

      if (prompts.isNotEmpty && !allowExtra) {
        throw ExtraServing(prompts.join('\n'));
      }

      transaction.update(ref, {'totals': totals});
    });
  }
}