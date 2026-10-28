import 'package:carb_cruncher/Models/recipe_model.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/category_model.dart';

class RecipePresenter {
  final List<Recipe> _recipes = [];

  Future<void> fetchRecipesByCategory(RecipeCategory category) async {
    List<Recipe> _recipes = [];
    try {
      final result = await Recipe.fetchRecipesByCategory(
        category,
        after: null,
        pageSize: 20,
      );
      final recipes = result['recipes'] as List<Recipe>;
      final lastDoc = result['lastDoc'];
      _recipes.addAll(recipes);
    } catch (e) {
      print('Error fetching recipes: $e');
    }
  }
}
