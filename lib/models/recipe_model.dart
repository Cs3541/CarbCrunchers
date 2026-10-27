import 'package:carb_cruncher/models/ingredient_model.dart';
import 'package:carb_cruncher/models/step_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ingredient_model.dart';
import '../models/step_model.dart';

class Recipe {
    final String name;
    final String? description;
    final int? calories;
    final IngredientModel? ingredients;
    final StepModel? steps;
    final String? imageURL;
    final List<String>? keywords;
    final int? cooktime;
    final int? servings;

    Recipe({
        required this.name,
        this.description,
        this.calories,
        this.ingredients,
        this.steps,
        this.imageURL,
        this.keywords,
        this.cooktime,
        this.servings,
    });

    static final _firestore = FirebaseFirestore.instance;
    static final _auth = FirebaseAuth.instance;

    static Future<List<Recipe>> fetchCourses() async {
        final userId = _auth.currentUser?.uid;
        if (userId == null) return [];

        final snapshot = await _firestore
            .collection('SavedRecipes')
            .where('userId', isEqualTo: userId)
            .get();

        return snapshot.docs.map((doc) {
            final data = doc.data();
            return Recipe(
                name: data['name'] as String? ?? '',
                description: data['description'] as String?,
                calories: (data['calories'] as num?)?.toInt(),
            );
        }).toList();
    }

    static Future<void> createRecipe(
        String name,
        String? description,
        int? calories,
        IngredientModel? ingredients,
        StepModel? steps,

    ) async {
        final userId = _auth.currentUser?.uid;
        if (userId == null) return;

        await _firestore.collection('SavedRecipes').add({
            'userId': userId,
            'name': name,
            'description': description,
            'calories': calories,
            'ingredients': ingredients,
            'steps': steps,
        });
    }
}