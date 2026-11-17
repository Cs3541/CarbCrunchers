import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/ingredient_model.dart';
import '../models/step_model.dart';
import '../models/nutrition_model.dart';
import '../models/category_model.dart';

class Recipe {
  final String? userId;
  final String? userRecipeIdentifier;
  final String title;
  final String? description;
  final List<IngredientModel> ingredients;
  final List<StepModel>? steps;
  final String? imageURL;
  final List<String>? keywords;
  final int? cooktime;
  final Nutrition? nutrition;
  final int? servings;

  Recipe({
    this.userId,
    this.userRecipeIdentifier,
    required this.title,
    required this.description,
    this.nutrition,
    required this.ingredients,
    this.steps,
    this.imageURL,
    required this.keywords,
    this.cooktime,
    this.servings,
  });

  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<List<Recipe>> searchRecipies(String query) async {
    final q = query.toLowerCase();
    if (q.isEmpty) return [];

    final snap = await _firestore
        .collection("recipes")
        .where('nameLower', isGreaterThanOrEqualTo: q)
        .where('nameLower', isLessThan: '$q\uf8ff')
        .orderBy('nameLower')
        .limit(10)
        .get();

    return snap.docs.map((doc) => Recipe.fromMap(doc.id, doc.data())).toList();
  }

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
      userId: id,
      title: (map['title']) as String? ?? '',
      description: (map['Description']) as String? ?? '',
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
    final userId = _auth.currentUser?.displayName;
    if (userId == _auth.currentUser?.uid) return [];

    final snapshot = await _firestore
        .collection('saved_recipes')
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final cookSeconds = data['cook_time_sec'];

      return Recipe(
        userId: _auth.currentUser?.displayName,
        userRecipeIdentifier:
            (data['userRecipeIdentifier'] as String?) ??
            (data['userRecipeIdentifier'] as String?) ??
            '',
        title: data['title'] as String? ?? '',
        description: data['Description'] as String? ?? '',
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
        keywords: (data['keywords'] as List<dynamic>? ?? [])
            .map((keyword) => keyword.toString())
            .toList(),
        cooktime: cookSeconds is num ? cookSeconds.toInt() ~/ 60 : null,
        servings: (data['servings'] as num?)?.toInt(),
      );
    }).toList();
  }

  static Future<void> addUserRecipe(Recipe recipe) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('saved_recipes').add({
      'userId': _auth.currentUser?.displayName,
      'userRecipeIdentifier': (userId + recipe.title),
      'title': recipe.title,
      'Description': recipe.description?.trim(),
      'ingredients': recipe.ingredients
          .map((ingredient) => ingredient.toMap())
          .toList(),
      'image_url': recipe.imageURL,
      'steps': recipe.steps?.map((step) => step.toMap()).toList(),
      'keywords': recipe.keywords ?? [],
      'nutrition': recipe.nutrition?.toMap(),
      'cook_time_sec': recipe.cooktime != null ? recipe.cooktime! * 60 : null,
      'servings': recipe.servings,
    });
  }

  static Future<void> deleteUserRecipe(Recipe deleteRecipe) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final identifier =
        deleteRecipe.userRecipeIdentifier ?? '${user.uid}${deleteRecipe.title}';
    final snapshot = await _firestore
        .collection('saved_recipes')
        .where('userId', isEqualTo: user.displayName)
        .where('userRecipeIdentifier', isEqualTo: identifier)
        .get();

    for (final document in snapshot.docs) {
      await document.reference.delete();
    }
  }
}
