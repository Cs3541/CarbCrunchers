import 'package:flutter/material.dart';

import '../models/recipe_model.dart';
import '../presenters/recipe_presenter.dart';
import '../models/step_model.dart';
import '../models/ingredient_model.dart';
import '../models/nutrition_model.dart';

class MyRecipeScreen extends StatefulWidget {
  const MyRecipeScreen({super.key});

  @override
  State<MyRecipeScreen> createState() => _MyRecipeScreenState();
}

class _MyRecipeScreenState extends State<MyRecipeScreen> {
  final RecipePresenter _recipePresenter = RecipePresenter();
  List<Recipe> _myRecipes = [];
  bool _isLoading = true;
  final ingredientControllers = <TextEditingController>[];
  final stepControllers = <TextEditingController>[];


  @override
  void initState() {
    super.initState();
    _fetchMyRecipes();
  }

  Future<void> _fetchMyRecipes() async {
    await _recipePresenter.loadRecipes();
    setState(() {
      _myRecipes = _recipePresenter.recipes;
      _isLoading = false;
    });
  }

  void _showEditRecipeDialog(Recipe recipe) {
    String recipeTitle = recipe.title;
    String? description = recipe.description;
    List<IngredientModel> ingredients = recipe.ingredients;
    List<StepModel>? steps = recipe.steps;
    String? imageURL = recipe.imageURL;
    List<String>? keywords = recipe.keywords;
    Nutrition? nutrition = recipe.nutrition;
    int? cooktime = recipe.cooktime;
    int? servings = recipe.servings;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Recipe'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'New Recipe Title'),
                  controller: TextEditingController(text: recipeTitle),
                  onChanged: (value) {
                    recipeTitle = value;
                  },
                ),
                // Add more fields for ingredients, steps, imageURL, keywords, nutrition, cooktime, servings
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (recipeTitle.isNotEmpty) {
                  final updatedRecipe = Recipe(
                    title: recipeTitle,
                    description: description,
                    ingredients: ingredients,
                    steps: steps,
                    imageURL: imageURL,
                    keywords: keywords,
                    nutrition: nutrition,
                    cooktime: cooktime,
                    servings: servings,
                  );
                  Navigator.of(context).pop();
                  setState(() {
                    final index = _myRecipes.indexOf(recipe);
                    if (index != -1) {
                      _myRecipes[index] = updatedRecipe;
                    }
                  });
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

  }

  void _showAddRecipeDialog() {
    String recipeTitle = '';
    String? description = '';
    List<IngredientModel> ingredients = [];
    List<StepModel>? steps = [];
    String? imageURL;
    List<String>? keywords = [];
    Nutrition? nutrition;
    int? cooktime;
    int? servings;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Recipe'),
          content: SingleChildScrollView(
            child: Column(
              children: [

                //Recipe Title
                TextField(
                  decoration: const InputDecoration(labelText: 'Recipe Title'),
                  onChanged: (value) {
                    recipeTitle = value;
                  },
                ),

                //Recipe Description
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'If desired, enter a description for your recipe',
                  ),
                  keyboardType: TextInputType.multiline,
                  onChanged: (value) {
                    description = value;
                  },
                ),

                //Ingredients
                Column(
                  children: [
                    for (var i = 0; i < ingredientControllers.length; i++)
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: TextField(
                                controller: ingredientControllers[i],
                                decoration: InputDecoration(labelText: 'Ingredient ${i + 1}'),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              setState(() {
                                ingredientControllers.removeAt(i).dispose();
                              });
                            },
                          ),
                        ],
                      ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          ingredientControllers.add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add ingredient'),
                    ),
                  ],
                ),

                //Recipe Steps
                Column(
                  children: [
                    for (var i = 0; i < stepControllers.length; i++)
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: TextField(
                                controller: stepControllers[i],
                                decoration: InputDecoration(labelText: 'Recipe Step ${i + 1}'),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              setState(() {
                                stepControllers.removeAt(i).dispose();
                              });
                            },
                          ),
                        ],
                      ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          stepControllers.add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Recipe Step'),
                    ),
                  ],
                ),

                //Nutrition Information
                FloatingActionButton(
                  tooltip: 'If desired, add nutritional information for the recipe',
                  onPressed: () {
                    // Implement the logic to add nutritional information
                  },
                  child: const Icon(Icons.add),
                ),

                //Recipe Servings
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Servings',
                    hintText: 'If desired, enter the number of servings',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    servings = int.tryParse(value);
                  },
                ),

                //Recipe Cook Time
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Cook Time (minutes)',
                    hintText: 'If desired, enter the cook time in minutes',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    cooktime = int.tryParse(value);
                  },
                ),

                //Recipe Keywords
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Keywords',
                    hintText: 'If desired, enter keywords separated by commas',
                  ),
                  onChanged: (value) {
                    keywords = value.split(',').map((e) => e.trim()).toList();
                  },
                ),

                //ImageURL
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'If desired, enter an image URL for your recipe',
                  ),
                  onChanged: (value) {
                    imageURL = value;
                  },
                ),

              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (recipeTitle.isNotEmpty) {
                  final newRecipe = Recipe(
                    title: recipeTitle,
                    description: description,
                    ingredients: ingredients,
                    steps: steps,
                    imageURL: imageURL,
                    keywords: keywords,
                    nutrition: nutrition,
                    cooktime: cooktime,
                    servings: servings,
                  );
                  Navigator.of(context).pop();
                  setState(() {
                    _myRecipes.add(newRecipe);
                  });
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 231, 206),
      appBar: AppBar(
        title: const Text(
          'My Recipes',
        style: TextStyle(
          fontSize: 28.0,
          fontWeight: FontWeight.bold,
          fontFamily: 'Homemade Apple',
          color: Color(0xFFB45309),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _myRecipes.length,
              itemBuilder: (context, index) {
                final recipe = _myRecipes[index];
                return Column(
                  children: [
                    ListTile(
                      tileColor: const Color.fromARGB(255, 247, 231, 206),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side: const BorderSide(color: Color(0xFFB45309), width: 2.0),
                      ),
                      title: Text(recipe.title),
                      titleTextStyle: const TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                      subtitle: Text(recipe.description ?? ''),
                      subtitleTextStyle: const TextStyle(
                        fontSize: 16.0,
                        color: Color(0xFFB45309),
                      ),
                      trailing: FloatingActionButton(
                        tooltip: 'Edit Recipe',
                        backgroundColor: const Color(0xFFB45309),
                        mini: true,
                        onPressed: () {
                          _showEditRecipeDialog(recipe);
                        },
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecipeDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
