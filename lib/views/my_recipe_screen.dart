import 'package:flutter/material.dart';

import '../../models/recipe_model.dart';
import '../../presenters/recipe_presenter.dart';
import '../../models/step_model.dart';
import '../../models/ingredient_model.dart';
import '../../models/nutrition_model.dart';
import '../views/recipe_page.dart';

class MyRecipeScreen extends StatefulWidget {
  const MyRecipeScreen({super.key});

  @override
  State<MyRecipeScreen> createState() => _MyRecipeScreenState();
}

class _MyRecipeScreenState extends State<MyRecipeScreen> {
  final RecipePresenter _recipePresenter = RecipePresenter();
  List<Recipe> _myRecipes = [];
  final Set<Recipe> _selectedRecipes = {};
  bool _isLoading = true;

  //Controllers to allow for variable number of ingredients/steps/nutrition information to be added to the recipe
  final ingredientControllers = <TextEditingController>[];
  final stepControllers = <TextEditingController>[];
  final nutritionControllers = <TextEditingController>[]; //Has a set number of fields and labels but can always add more
  final List<String> nutritionLabels = [
    'Calories',
    'Carbs',
    'Fat',
    'Fiber',
    'Protein',
    'Sodium (mg)',
    'Sugar',
  ];

  @override
  void initState() {
    super.initState();
    _fetchMyRecipes();
  }

  //Loads User Data
  Future<void> _fetchMyRecipes() async {
    await _recipePresenter.loadRecipes();
    setState(() {
      _myRecipes = _recipePresenter.recipes;
      _isLoading = false;
    });
  }

  //Dialog to edit a recipe
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

                //Ingredients
                StatefulBuilder(
                  builder: (context, setDialogState) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          for (var i = 0; i < ingredientControllers.length; i++)
                            TextField(
                              controller: ingredientControllers[i],
                              decoration: InputDecoration(
                                labelText: 'Ingredient ${i+1}: ',
                                hintText: 'Ingredient Goes Here!'
                              ),
                            ),
                          TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                ingredientControllers.add(TextEditingController());
                              });
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add ingredient'),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                //Recipe Steps
                StatefulBuilder(
                  builder: (context, setDialogState) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          for (var i = 0; i < stepControllers.length; i++)
                            TextField(
                              controller: stepControllers[i],
                              decoration: InputDecoration(
                                labelText: 'Recipe Step ${i+1}: ',
                                hintText: 'Input a Recipe Step!',
                              ),
                            ),
                          TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                stepControllers.add(TextEditingController());
                              });
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Recipe Steps'),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                //Nutrition Information
                StatefulBuilder(
                  builder: (context, setDialogState) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          for (var i = 0; i < nutritionControllers.length && i < 7; i++)
                            TextField(
                              controller: nutritionControllers[i],
                              decoration: InputDecoration(
                                labelText: nutritionLabels[i],
                                hintText: 'Input the ${nutritionLabels[i]}',
                              ),
                            ),
                          TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                nutritionControllers.add(TextEditingController());
                              });
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Recipe Nutrition'),
                          ),
                        ],
                      ),
                    );
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
                    final index = _myRecipes.indexWhere(
                      (r) => r.title == recipe.title,
                    );
                    if (index != -1) {
                      _myRecipes[index] = updatedRecipe;
                    }
                    if (_selectedRecipes.remove(recipe)) {
                      _selectedRecipes.add(updatedRecipe);
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

  Future<void> _deleteSelectedRecipes() async {
    if (_selectedRecipes.isEmpty) return;

    final selectedRecipes = _selectedRecipes.toList();

    for (final recipe in selectedRecipes) {
        final originalIndex = _myRecipes.indexOf(recipe);

         setState(() {
          _myRecipes.remove(recipe);
          _selectedRecipes.remove(recipe);
        });

      try {
      await _recipePresenter.deleteUserRecipe(recipe);
      } catch (error) {
        if (!mounted) return;

        // Restore the recipe if the delete request failed.
        setState(() {
          _myRecipes.insert(originalIndex, recipe);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete recipe: $error')),
        );
      }
    }
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

    nutritionControllers.clear;
    ingredientControllers.clear;
    

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

                //Ingredients
                StatefulBuilder(
                  builder: (context, setDialogState) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          for (var i = 0; i < ingredientControllers.length; i++)
                            TextField(
                              controller: ingredientControllers[i],
                              decoration: InputDecoration(
                                labelText: 'Ingredient ${i+1}: ',
                                hintText: 'Ingredient Goes Here!'
                              ),
                            ),
                          TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                ingredientControllers.add(TextEditingController());
                              });
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add ingredient'),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                //Recipe Steps
                StatefulBuilder(
                  builder: (context, setDialogState) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          for (var i = 0; i < stepControllers.length; i++)
                            TextField(
                              controller: stepControllers[i],
                              decoration: InputDecoration(
                                labelText: 'Recipe Step ${i+1}: ',
                                hintText: 'Input a Recipe Step!',
                              ),
                            ),
                          TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                stepControllers.add(TextEditingController());
                              });
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Recipe Steps'),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                //Nutrition Information
                StatefulBuilder(
                  builder: (context, setDialogState) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          for (var i = 0; i < nutritionControllers.length && i < 7; i++)
                            TextField(
                              controller: nutritionControllers[i],
                              decoration: InputDecoration(
                                labelText: nutritionLabels[i],
                                hintText: 'Input the ${nutritionLabels[i]}',
                              ),
                            ),
                          TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                nutritionControllers.add(TextEditingController());
                              });
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Recipe Nutrition'),
                          ),
                        ],
                      ),
                    );
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
                  await _recipePresenter.addUserRecipe(newRecipe);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showFilterRecipeDialog() {}

  //Main Screen, displays recipes and can click on recipes
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 231, 206),
      appBar:   AppBar(
        title: Text(
          'My Recipes',
          style: const TextStyle(
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: ListTile(
                      minVerticalPadding: 30.0,
                      minTileHeight: 30.0,
                      tileColor: const Color.fromARGB(255, 247, 231, 206),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 10.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side: const BorderSide(
                          color: Color(0xFFB45309),
                          width: 4.0,
                        ),
                      ),
                      leading: SizedBox (
                        width: 200,
                        child: Row(
                          children: [
                            Checkbox(
                              value: _selectedRecipes.contains(recipe),
                              activeColor: const Color(0xFFB45309),
                              onChanged: (selected) {
                                setState(() {
                                  if (selected == true) {
                                    _selectedRecipes.add(recipe);
                                  } else {
                                    _selectedRecipes.remove(recipe);
                                  }
                                });
                              },
                            ),
                            ClipRRect(
                              child: recipe.imageURL != null
                                  ? Image.network(
                                      recipe.imageURL!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => _imagePlaceholder(),
                                    )
                                  : _imagePlaceholder(),
                            ),
                            SizedBox(width: 12.0),
                          ],
                        ),
                      ),
                      title: Text(recipe.title),
                      titleTextStyle: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                      subtitle: Text(recipe.description ?? ''),
                      subtitleTextStyle: const TextStyle(
                        fontSize: 14.0,
                        color: Color(0xFFB45309),
                      ),
                      trailing: FloatingActionButton(
                        tooltip: 'Edit Recipe',
                        backgroundColor: const Color(0xFFB45309),
                        mini: true,
                        heroTag: 'editRecipe-${recipe.id ?? index}',
                        onPressed: () {
                          _showEditRecipeDialog(recipe);
                        },
                        child: const Icon(Icons.edit, color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecipePage(recipe: recipe),
                          ),
                        );
                      },
                    ),
                  ),
                    const SizedBox(height: 10.0),
                  ],
                );
              },
            ),
        endDrawer: Drawer(
        backgroundColor: const Color.fromARGB(255, 216, 190, 129),
        child: ListView(
          scrollDirection: Axis.vertical,
          children: [
            DrawerHeader(child: Text('Recipe Options',
            textAlign: TextAlign.center,
            style: const TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'Homemade Apple',
            color: Color(0xFFB45309),
          ),
          )),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: ListTile(      
                title: Text(
                  'Filter Recipes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Homemade Apple',
                    color: Color(0xFFB45309),
                  ),
                ),
                trailing: Icon(Icons.search),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: const BorderSide(
                    color: Color(0xFFB45309),
                    width: 4.0,
                  ),
                ),
                tileColor: const Color.fromARGB(255, 247, 231, 206),
                hoverColor: const Color.fromARGB(255, 212, 133, 6),
                onTap: _showFilterRecipeDialog,
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: ListTile(      
                title: Text(
                  'Add Recipe',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Homemade Apple',
                    color: Color(0xFFB45309),
                  ),
                ),
                trailing: Icon(Icons.add),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: const BorderSide(
                    color: Color(0xFFB45309),
                    width: 4.0,
                  ),
                ),
                tileColor: const Color.fromARGB(255, 247, 231, 206),
                hoverColor: const Color.fromARGB(255, 212, 133, 6),
                onTap: _showAddRecipeDialog,
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: ListTile(      
                title:Text(
                  'Delete Recipe',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Homemade Apple',
                    color: Color(0xFFB45309),
                  ),
                ),
                trailing: Icon(Icons.delete),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: const BorderSide(
                    color: Color(0xFFB45309),
                    width: 4.0,
                  ),
                ),
                tileColor: const Color.fromARGB(255, 247, 231, 206),
                hoverColor: const Color.fromARGB(255, 212, 133, 6),
                onTap: _deleteSelectedRecipes,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _imagePlaceholder() {
    return Container(
      width: 60,
      height: 100,
      color: Colors.grey[300],
      child: const Icon(Icons.restaurant, color: Colors.grey),
    );
  }
