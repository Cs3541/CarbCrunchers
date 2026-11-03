import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './recipe_model.dart';

class PlannedMeal {
  final String id;
  final String mealType; // 'Breakfast', 'Lunch', 'Dinner', 'Snack'
  final List<String> sides;
  final DateTime date;
  final String recipeId;
  final Recipe? recipe;

  PlannedMeal({
    required this.id,
    required this.mealType,
    required this.date,
    required this.recipeId,
    this.sides = const [],
    this.recipe,
  });

  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // Stored meal plan for the logged-in user
  static Future<List<PlannedMeal>> fetchMealsForUser() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    // filtering by logged-in userId
    final snapshot = await _firestore
        .collection('meal_plans')
        .where('userId', isEqualTo: userId)
        .get();

    List<PlannedMeal> userMeals = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      
      userMeals.add(
        PlannedMeal(
          id: doc.id,
          mealType: data['mealType'] ?? 'Meal',
          date: (data['date'] as Timestamp).toDate(),
          recipeId: data['recipeId'] ?? '',
          sides: List<String>.from(data['sides'] ?? []),
        ),
      );
    }

    return userMeals;
  }

  // Add a new meal with the user's ID
  static Future<void> addMeal({
    required String mealType,
    required DateTime date,
    required String recipeId,
    List<String> sides = const [],
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('meal_plans').add({
      'userId': userId, // Storing user ID
      'mealType': mealType,
      'date': Timestamp.fromDate(date),
      'recipeId': recipeId,
      'sides': sides,
    });
  }
}