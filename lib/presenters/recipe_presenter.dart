import '../models/recipe_model.dart';
import '../models/category_model.dart';

class RecipePresenter {
  final List<Recipe> _recipes = [];
  List<Recipe> get recipes => _recipes;

  Future<void> fetchRecipesByCategory(RecipeCategory category) async {
    final result = await Recipe.fetchRecipesByCategory(
      category,
      after: null,
      pageSize: 20,
    );
    final recipes = result['recipes'] as List<Recipe>;
    _recipes.addAll(recipes);
  }

  Future<void> loadRecipes() async {
    final fetched = await Recipe.fetchUserRecipes();
    _recipes
      ..clear()
      ..addAll(fetched);
  }

  Future<void> addUserRecipe(Recipe recipe) async {
    await Recipe.addUserRecipe(recipe);
    throw StateError('Cannot add a recipe without a logged-in user.');
  }

  Future<void> deleteUserRecipe(Recipe recipe) async {
    await Recipe.deleteUserRecipe(recipe);
    _recipes.removeWhere((r) => r.id == recipe.id);
  }
}
