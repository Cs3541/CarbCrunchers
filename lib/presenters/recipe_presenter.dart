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

  Future<void> loadRecipes() async{
    final fetched = await Recipe.fetchUserRecipes();
    _recipes
    ..clear()
    ..addAll(fetched);
  }

  Future<void> addUserRecipe(Recipe recipe) async {
    final id = await Recipe.addUserRecipe(recipe);
    _recipes.add(recipe.withId(id));
  }

  Future<void> updateUserRecipe(Recipe recipe) async {
    await Recipe.updateUserRecipe(recipe);
    final index = _recipes.indexWhere((savedRecipe) => savedRecipe.id == recipe.id);
    if (index != -1) _recipes[index] = recipe;
  }

  Future<void> deleteUserRecipe(Recipe recipe) async {
    final id = recipe.id;
    if (id == null) {
      throw StateError('Cannot delete a recipe without a Firestore document ID.');
    }
    await Recipe.deleteUserRecipe(id);
    _recipes.removeWhere((savedRecipe) => savedRecipe.id == id);
  }

}
