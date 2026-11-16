import 'package:carb_cruncher/models/recipe_model.dart';

class SearchModel {
  Recipe? searchRecipe(List<Recipe> recipes, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return null;
    }

    for (final recipe in recipes) {
      if (recipe.title.trim().toLowerCase() == normalizedQuery) {
        return recipe;
      }
    }

    return null;
  }

  List<Recipe> searchRecipes(List<Recipe> recipes, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return List<Recipe>.of(recipes);
    }

    return recipes
        .where(
          (recipe) => recipe.title.toLowerCase().contains(normalizedQuery),
        )
        .toList();
  }
}
