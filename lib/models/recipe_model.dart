import 'package:carb_cruncher/models/ingredient_model.dart';
import 'package:carb_cruncher/models/step_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/nutrition_model.dart';
import '../models/category_model.dart';

class Recipe {
  final String title;
  final List<IngredientModel> ingredients;
  final List<StepModel>? steps;
  final String? imageURL;
  final List<String>? keywords;
  final int? cooktime;
  final Nutrition? nutrition;
  final int? servings;

  Recipe({
    required this.title,
    this.nutrition,
    required this.ingredients,
    this.steps,
    this.imageURL,
    this.keywords,
    this.cooktime,
    this.servings,
  });

  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<Map<String, dynamic>> fetchRecipesByCategory(
    RecipeCategory category, {
    DocumentSnapshot? after, // null = first page
    int pageSize = 20,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('recipes')
        .where('keywords', arrayContainsAny: category.keywords)
        .orderBy(FieldPath.documentId)
        .limit(pageSize);

    if (after != null) {
      query = query.startAfterDocument(after);
    }

    debugPrint(
      "called fetchRecipesByCategory for ${category.name} with after: ${after?.id}",
    );

    final snapshot = await query.get();

    final recipes = snapshot.docs.map((doc) {
      final data = doc.data();
      return Recipe.fromMap(doc.id, data);
    }).toList();

    debugPrint(
      "fetched ${recipes.length} recipes for ${category.name} with after: ${after?.id}",
    );

    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

    return {'recipes': recipes, 'lastDoc': lastDoc};
  }

  factory Recipe.fromMap(String id, Map<String, dynamic> map) {
    final cookSeconds =
        (map['cook_time_sec'] as num?) ?? (map['total_time_sec'] as num?);

    return Recipe(
      title: (map['title']) as String? ?? '',
      ingredients: (map['ingredients'] as List? ?? [])
          .map((e) => IngredientModel.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      steps: (map['steps'] as List? ?? [])
          .map((e) => StepModel.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      imageURL: map['image_url'] as String?,
      nutrition: map['nutrition'] != null
          ? Nutrition.fromMap(Map<String, dynamic>.from(map['nutrition']))
          : null,
      keywords: (map['keywords'] as List? ?? []).cast<String>(),
      cooktime: cookSeconds == null ? null : cookSeconds.toInt() ~/ 60,
      servings: (map['servings'] as num?)?.toInt(),
    );
  }

  static Future<List<Recipe>> fetchUserRecipes() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final snapshot = await _firestore
        .collection('SavedRecipes')
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Recipe(
        title: data['title'] as String? ?? '',
        ingredients: (data['ingredients'] as List? ?? [])
            .map((e) => IngredientModel.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        steps: (data['steps'] as List? ?? [])
            .map((e) => StepModel.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        imageURL: data['image_url'] as String?,
        nutrition: data['nutrition'] != null
            ? Nutrition.fromMap(Map<String, dynamic>.from(data['nutrition']))
            : null,
        keywords: (data['keywords'] as List<String>?)
            ?.map((keyword) => keyword)
            .toList(),
        cooktime: (data['cook_time_sec'] as num?)?.toInt(),
        servings: (data['servings'] as num?)?.toInt(),
      );
    }).toList();
  }

  static Future<void> createRecipe(
    String name,
    String? description,
    IngredientModel? ingredients,
    Nutrition? nutrition,
    StepModel? steps,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('SavedRecipes').add({
      'userId': userId,
      'name': name,
      'description': description,
      'ingredients': ingredients,
      'steps': steps,
    });
  }
}
