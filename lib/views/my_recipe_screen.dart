import 'package:carb_cruncher/Models/filter_model.dart';
import 'package:carb_cruncher/models/category_model.dart';
import 'package:flutter/material.dart';
import '../../models/recipe_model.dart';
import '../../presenters/recipe_presenter.dart';
import '../../models/step_model.dart';
import '../../models/ingredient_model.dart';
import '../../models/nutrition_model.dart';
import '../views/recipe_page.dart';
import '../../Models/filter_model.dart';
import '../Models/search.model.dart';
import '../Models/auth_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class MyRecipeScreen extends StatefulWidget {
  const MyRecipeScreen({super.key});
  
  @override
  State<MyRecipeScreen> createState() => _MyRecipeScreenState();
}

class _MyRecipeScreenState extends State<MyRecipeScreen> {
  final RecipePresenter _recipePresenter = RecipePresenter();
  final SearchModel _searchModel = SearchModel();
  final GlobalKey _tileKey = GlobalKey();
  List<Recipe> _myRecipes = [];
  List<Recipe> _filteredMyRecipes = [];
  final Set<Recipe> _selectedRecipes = {};
  bool _isLoading = true;


  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;
  final ingredientControllers = <TextEditingController>[];
  final stepControllers = <TextEditingController>[];
  final nutritionControllers = <TextEditingController>[];
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

  //Dialog to delete a recipe
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

  //Dialog to add a recipe
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
    var saveStarted = false;

    nutritionControllers.clear();
    ingredientControllers.clear();
    stepControllers.clear();

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
                if (saveStarted || recipeTitle.isEmpty) return;
                saveStarted = true;

                final newRecipe = Recipe(
                  title: recipeTitle,
                  userId: _auth.currentUser?.uid,
                  userRecipeIdentifier: _auth.currentUser?.email,
                  description: description,
                  ingredients: ingredients,
                  steps: steps,
                  imageURL: imageURL,
                  keywords: keywords,
                  nutrition: nutrition,
                  cooktime: cooktime,
                  servings: servings,
                );

                try {
                  await _recipePresenter.addUserRecipe(newRecipe);
                  if (!mounted) return;
                  setState(() {});
                  Navigator.of(context).pop();
                } catch (error) {
                  saveStarted = false;
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not save recipe: $error')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  bool isFilterActive = false;
  String? filterType = 'none';
  String? recipeType = 'none';
  Filter_Model filterController = Filter_Model();
  ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  //Main Screen, displays recipes and can click on recipes
  @override
  Widget build(BuildContext context) {
    final recipesToDisplay = _searchModel.searchRecipes(
      isFilterActive ? _filteredMyRecipes : _myRecipes,
      _searchQuery,
    );

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
              itemCount: recipesToDisplay.length,
              itemBuilder: (context, index) {
                final recipe = recipesToDisplay[index];
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
                        width: 120,
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
                            //SizedBox(width: 12.0),
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
                        heroTag: 'editRecipe-${recipe.userId ?? index}',
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
        width: 425,
        child: ListView(
          scrollDirection: Axis.vertical,
          children: [
            CloseButton(
              color: Colors.black,
              onPressed: () {Navigator.pop(context);},
            ),
            DrawerHeader(
              child: Center(
                child: Text(
                  'Recipe Options',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Homemade Apple',
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: ExpansionTile(
                  expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                  key: _tileKey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                        side: const BorderSide(
                        color: Color(0xFFB45309),
                       width: 4.0,
                      ),
                    ),
                    collapsedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: const BorderSide(
                      color: Color(0xFFB45309),
                      width: 4.0,
                      ),
                    ),
                  backgroundColor: const Color.fromARGB(255, 247, 231, 206),
                  collapsedBackgroundColor: const Color.fromARGB(255, 247, 231, 206),
                  expandedAlignment: Alignment.center,
                  onExpansionChanged: (bool expanded) {
                    Future.delayed(const Duration(milliseconds: 200), () {
                        final context = _tileKey.currentContext;
                        if (context != null) {
                          Scrollable.ensureVisible(
                            context,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      });
                    },
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
                    children: [
                      SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: SearchAnchor(
                          viewBarPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            viewBackgroundColor: const Color.fromARGB(255, 247, 231, 206),
                            builder: (BuildContext context, SearchController controller) {
                              return SearchBar(
                                constraints: const BoxConstraints(
                                  minHeight: 44,
                                  maxHeight: 44,
                                  ),
                                  padding: const WidgetStatePropertyAll(
                                    EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                backgroundColor: const WidgetStatePropertyAll<Color?>(Color.fromARGB(255, 216, 190, 129),),
                                shape: WidgetStatePropertyAll<OutlinedBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    side: BorderSide(
                                      color: Color(0xFFB45309),
                                      width: 4.0,
                                    ),
                                  ),
                                ),
                                hintText: 'Search for a Recipe Here!',
                                controller: controller,
                                onTap: () {
                                  controller.openView();
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                  controller.openView();
                                },
                                leading: const Icon(Icons.search),
                              );
                            },
                            suggestionsBuilder:
                                (BuildContext context,
                                    SearchController controller) {
                              final matchingRecipes = _searchModel.searchRecipes(
                                _myRecipes,
                                controller.text,
                              );
                              if (matchingRecipes.isNotEmpty) {
                                return matchingRecipes.map((Recipe recipe) {
                                  return ListTile(
                                    title: Text(recipe.title),
                                    onTap: () {
                                      setState(() {
                                        _searchQuery = recipe.title;
                                      });
                                      controller.closeView(recipe.title);
                                    },
                                  );
                                }).toList();
                              }
                              return <Widget>[
                                ListTile(
                                  title: Text(
                                    _myRecipes.isEmpty
                                        ? 'No Recipes Available'
                                        : 'No matching recipes available',
                                  ),
                                ),
                              ];
                            },
                          ),
                      ),

                      Column(
                        children: [
                          SizedBox(height: 50),
                          DropdownMenu<String>(
                            inputDecorationTheme: InputDecorationTheme(
                              filled: true,
                              fillColor: Color.fromARGB(255, 216, 190, 129),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(
                                  color: Color(0xFFB45309),
                                  width: 4.0,
                                ),
                              ),
                            ),
                            onSelected: (String? value) {
                              setState(() {
                                recipeType = value; // In the nutrition dropdown callback
                                isFilterActive =
                                    recipeType != null &&
                                    recipeType != 'none' &&
                                    filterType != null &&
                                    filterType != 'none';
                                _filteredMyRecipes = List<Recipe>.from(_myRecipes);
                                if (isFilterActive) {
                                  filterController.filterRecipe(
                                    _filteredMyRecipes,
                                    recipeType,
                                    filterType,
                                  );
                                }
                              });
                            },
                            initialSelection: recipeType,
                            label: Text('Nutrition Filter',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Homemade Apple',
                              color: Color(0xFFB45309),
                              ),
                            ),
                            hintText: 'Select a Filter',
                            dropdownMenuEntries: [
                              DropdownMenuEntry<String>(
                                value: 'none',
                                label: 'None',
                                style: MenuItemButton.styleFrom(
                                foregroundColor: Color(0xFFB45309),
                                backgroundColor: const Color.fromARGB(255, 247, 231, 206),
                                ),
                              ),
                              DropdownMenuEntry<String>(
                                value: 'calories',
                                label: 'Calories',
                                style: MenuItemButton.styleFrom(
                                foregroundColor: Color(0xFFB45309),
                                backgroundColor: const Color.fromARGB(255, 247, 231, 206),
                                ),
                              ),
                              DropdownMenuEntry<String>(
                                value: 'fat',
                                label: 'Fat',
                                style: MenuItemButton.styleFrom(
                                foregroundColor: Color(0xFFB45309),
                                backgroundColor: const Color.fromARGB(255, 247, 231, 206),
                                ),
                              ),
                              DropdownMenuEntry<String>(
                                value: 'carbs',
                                label: 'Carbs',
                                style: MenuItemButton.styleFrom(
                                foregroundColor: Color(0xFFB45309),
                                backgroundColor: const Color.fromARGB(255, 247, 231, 206),
                                ),
                              ),
                              DropdownMenuEntry<String>(
                                value: 'servings',
                                label: 'Servings',
                                style: MenuItemButton.styleFrom(
                                foregroundColor: Color(0xFFB45309),
                                backgroundColor: const Color.fromARGB(255, 247, 231, 206),
                                ),
                              ),
                              DropdownMenuEntry<String>(
                                value: 'fiber',
                                label: 'Fiber',
                                style: MenuItemButton.styleFrom(
                                foregroundColor: Color(0xFFB45309),
                                backgroundColor: const Color.fromARGB(255, 247, 231, 206),
                                ),
                              ),
                              DropdownMenuEntry<String>(
                                value: 'protein',
                                label: 'Protein',
                                style: MenuItemButton.styleFrom(
                                foregroundColor: Color(0xFFB45309),
                                backgroundColor: const Color.fromARGB(255, 247, 231, 206),
                                ),
                              ),
                              DropdownMenuEntry<String>(
                                value: 'sodium',
                                label: 'Sodium',
                                style: MenuItemButton.styleFrom(
                                foregroundColor: Color(0xFFB45309),
                                backgroundColor: const Color.fromARGB(255, 247, 231, 206),
                                ),
                              ),
                              DropdownMenuEntry<String>(
                                value: 'sugar',
                                label: 'Sugar',
                                style: MenuItemButton.styleFrom(
                                foregroundColor: Color(0xFFB45309),
                                backgroundColor: const Color.fromARGB(255, 247, 231, 206),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24),
                          DropdownMenu<String>(
                            inputDecorationTheme: InputDecorationTheme(
                              filled: true,
                              fillColor: Color.fromARGB(255, 216, 190, 129),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(
                                  color: Color(0xFFB45309),
                                  width: 4.0,
                                ),
                              ),
                            ),
                            onSelected: (String? value) {
                              setState(() {
                                filterType = value; // In the nutrition dropdown callback
                                isFilterActive =
                                    recipeType != null &&
                                    recipeType != 'none' &&
                                    filterType != null &&
                                    filterType != 'none';
                                _filteredMyRecipes = List<Recipe>.from(_myRecipes);
                                if (isFilterActive) {
                                  filterController.filterRecipe(
                                    _filteredMyRecipes,
                                    recipeType,
                                    filterType,
                                  );
                                }
                              });
                            },
                            initialSelection: filterType,
                            label: Text('Recipe Title Filter',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Homemade Apple',
                              color: Color(0xFFB45309),
                              ),
                            ),
                            hintText: 'Select a Filter',
                            dropdownMenuEntries: [
                              DropdownMenuEntry<String>(
                                value: 'none',
                                label: 'None',
                                style: MenuItemButton.styleFrom(
                                foregroundColor: Color(0xFFB45309),
                                backgroundColor: const Color.fromARGB(255, 247, 231, 206),
                                ),
                              ),
                              DropdownMenuEntry<String>(
                                value: 'ascending',
                                label: 'Ascending',
                                style: MenuItemButton.styleFrom(
                                foregroundColor: Color(0xFFB45309),
                                backgroundColor: const Color.fromARGB(255, 247, 231, 206),
                                ),
                              ),
                              DropdownMenuEntry<String>(
                                value: 'descending',
                                label: 'Descending',
                                style: MenuItemButton.styleFrom(
                                foregroundColor: Color(0xFFB45309),
                                backgroundColor: const Color.fromARGB(255, 247, 231, 206),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24),
                        ],
                      ),
          ],
        ),
      ),
      Material(
              type: MaterialType.transparency,
              child: Padding(
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
            ),

            Material(
              type: MaterialType.transparency,
              child: Padding(
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
            ),
    ]
  )
)
);
}
}

Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFB45309),
      width: 60,
      height: 100,
      child: const Icon(Icons.restaurant, color: Color.fromARGB(255, 247, 231, 206)),
    );
  }
