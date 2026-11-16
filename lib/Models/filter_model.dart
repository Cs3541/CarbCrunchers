import '../../models/recipe_model.dart';

class Filter{

void swapRecipes(List<Recipe> recipeList, int firstIndex, int secondIndex) {
    if (firstIndex == secondIndex) return;
    final temp = recipeList[firstIndex];
    recipeList[firstIndex] = recipeList[secondIndex];
    recipeList[secondIndex] = temp;
  }

   double _recipeSortValue(Recipe recipe, String? field) {
    final nutrition = recipe.nutrition;
    switch (field) {
      case 'calories':
        return nutrition?.calories ?? 0;
      case 'carbs':
        return nutrition?.carbs ?? 0;
      case 'fat':
        return nutrition?.fat ?? 0;
      case 'servings':
        return (recipe.servings ?? 0).toDouble();
      case 'fiber':
        return nutrition?.fiber ?? 0;
      case 'protein':
        return nutrition?.protein ?? 0;
      case 'sodium':
        return nutrition?.sodiumMg ?? 0;
      case 'sugar':
        return nutrition?.sugar ?? 0;
      default:
        return 0.0;
    }
  }

  List<Recipe> filterRecipe(List<Recipe> myRecipeList, String? type, String? filter){
    int i = 0;
    int j = 0;
    for (i = 0; i < myRecipeList.length -1; i++){
      for (j = 0; j < myRecipeList.length - 1; j++){
        final currentValue = _recipeSortValue(myRecipeList[j], type);
        final nextValue = _recipeSortValue(myRecipeList[j + 1], type);
        if (filter == "ascending" && currentValue > nextValue) {swapRecipes(myRecipeList, j, j + 1);} 
        else if (filter == "descending" && currentValue < nextValue) {swapRecipes(myRecipeList, j, j + 1);}
      }
    }
    
    return myRecipeList;
  }




}