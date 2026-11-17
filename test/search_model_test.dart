import 'package:carb_cruncher/Models/search.model.dart';
import 'package:carb_cruncher/models/recipe_model.dart';
import 'package:flutter_test/flutter_test.dart';

Recipe _recipe(String title) => Recipe(
      title: title,
      description: null,
      ingredients: const [],
      keywords: const [],
    );

void main() {
  final searchModel = SearchModel();

  test('searches recipe titles without case sensitivity', () {
    final recipes = [
      _recipe('Apple Pie'),
      _recipe('Banana Bread'),
      _recipe('Apple Crumble'),
    ];

    final results = searchModel.searchRecipes(recipes, '  aPpLe ');

    expect(results.map((recipe) => recipe.title), [
      'Apple Pie',
      'Apple Crumble',
    ]);
    expect(searchModel.searchRecipes(recipes, 'no match'), isEmpty);
  });

  test('finds an exact recipe title and returns null when absent', () {
    final recipe = _recipe('Apple Pie');
    final recipes = [recipe, _recipe('Apple Crumble')];

    expect(searchModel.searchRecipe(recipes, ' apple pie '), same(recipe));
    expect(searchModel.searchRecipe(recipes, 'Banana Bread'), isNull);
    expect(searchModel.searchRecipe(recipes, ''), isNull);
  });

  test('returns all recipes for an empty query', () {
    final recipes = [_recipe('Apple Pie'), _recipe('Banana Bread')];

    final results = searchModel.searchRecipes(recipes, '  ');

    expect(results, hasLength(2));
    expect(results[0], same(recipes[0]));
    expect(results[1], same(recipes[1]));
  });
}
