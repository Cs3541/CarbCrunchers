import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/meal_plan_model.dart';
import '../presenters/meal_plan_presenter.dart';
import '../models/recipe_model.dart';
import 'recipe_page.dart';

class MyMealsScreen extends StatefulWidget {
  const MyMealsScreen({super.key});

  @override
  State<MyMealsScreen> createState() => _MyMealsScreenState();
}

class _MyMealsScreenState extends State<MyMealsScreen> {
  late final MealPlanPresenter _presenter;

  // State for the inline drawer "Add Meal" dropdown
  String _drawerMealType = 'Breakfast';
  late DateTime _drawerDate;
  String? _drawerRecipeId;
  bool _drawerShowSavedOnly = false;
  List<dynamic> _availableRecipes = [];

  @override
  void initState() {
    super.initState();
    _presenter = MealPlanPresenter();
    _presenter.fetchMealsForWeek();
    _drawerDate = _presenter.selectedWeekStart;
    _loadRecipesForDrawer();
  }

  Future<void> _loadRecipesForDrawer() async {
    final recipes = await _fetchAvailableRecipes(savedOnly: _drawerShowSavedOnly);
    if (mounted) {
      setState(() {
        _availableRecipes = recipes;
      });
    }
  }

  @override
  void dispose() {
    _presenter.dispose();
    super.dispose();
  }

  Map<String, List<PlannedMeal>> _groupMealsByDay(List<PlannedMeal> meals) {
    final Map<String, List<PlannedMeal>> grouped = {
      'Sunday': [],
      'Monday': [],
      'Tuesday': [],
      'Wednesday': [],
      'Thursday': [],
      'Friday': [],
      'Saturday': [],
    };

    final dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];

    for (var meal in meals) {
      String dayName = dayNames[meal.date.weekday % 7];
      grouped[dayName]?.add(meal);
    }
    return grouped;
  }

  // Fetch available recipes from Firestore for the dropdown
  Future<List> _fetchAvailableRecipes({
    required bool savedOnly,
  }) async {
    if (savedOnly) {
      final savedRecipes = await Recipe.fetchUserRecipes();
      return savedRecipes.map((r) {
        final identifier = r.userRecipeIdentifier ?? r.title;
        return {
          'id': identifier,
          'title': r.title,
          'source': 'saved_recipes',
          'savedRecipeIdentifier': identifier,
        };
      }).toList();
    }

    final snapshot =
        await FirebaseFirestore.instance.collection('recipes').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'title': (data['title'] ?? 'Untitled Recipe').toString(),
        'source': 'recipes',
        'savedRecipeIdentifier': null,
      };
    }).toList();
  }

  // Add or Swap Dialog
  void _showAddEditMealDialog({PlannedMeal? existingMeal}) async {
    String selectedMealType = existingMeal?.mealType ?? 'Breakfast';
    DateTime selectedDate = existingMeal?.date ?? _presenter.selectedWeekStart;
    String? selectedRecipeId = existingMeal?.recipeId;
    bool showSavedOnly = false;

    // Fetch existing recipes for dropdown selection
    var availableRecipes = await _fetchAvailableRecipes(savedOnly: showSavedOnly);
  

    if (!mounted) return;

    // Meal Editor
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existingMeal == null ? 'Schedule a Meal' : 'Swap Meal',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('All Recipes'),
                        icon: Icon(Icons.menu_book),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('My Saved'),
                        icon: Icon(Icons.favorite),
                      ),
                    ],
                    selected: {showSavedOnly},
                    onSelectionChanged: (Set<bool> newSelection) async {
                      final nextValue = newSelection.first;
                      final updatedList = await _fetchAvailableRecipes(savedOnly: nextValue);
                      setModalState(() {
                        showSavedOnly = nextValue;
                        availableRecipes = updatedList;
                        selectedRecipeId = null; // Reset selection when switching lists
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // 1. Meal Type Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedMealType,
                    decoration: const InputDecoration(labelText: 'Meal Slot'),
                    items: ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                        .map((type) =>
                            DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => selectedMealType = val!),
                  ),
                  const SizedBox(height: 12),

                  // 2. Date Picker
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date'),
                    subtitle: Text(
                        '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // 3. Recipe Dropdown (Pulls real recipes from database)
                  //Searchable Drop Down
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return DropdownMenu(
                        width: constraints.maxWidth,
                        initialSelection: availableRecipes.any((r) => r['id'] == selectedRecipeId)
                          ? selectedRecipeId
                          : null,
                        label: const Text('Select Recipe'),
                        hintText: 'Choose a recipe',
                        
                        // Opens keyboard
                        requestFocusOnTap: true,

                        enableFilter: true,
                        enableSearch: true,

                        menuHeight: 250,

                        onSelected: (String? val) {
                          setModalState(() => selectedRecipeId = val);
                        },
                        dropdownMenuEntries: availableRecipes.map<DropdownMenuEntry<String>>(
                          (rec) {
                            return DropdownMenuEntry<String>(
                              value: rec['id']!,
                              label: rec['title']!, // Searching automatically filters against this string
                            );
                          },
                        ).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24,),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F5DA8),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        if (selectedRecipeId == null ||
                            selectedRecipeId!.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a Recipe'),
                            ),
                          );
                          return;
                        }

                        Navigator.pop(context);

                        await _presenter.savePlannedMeal(
                          existingDocId: existingMeal?.id,
                          mealType: selectedMealType,
                          date: selectedDate,
                          recipeId: selectedRecipeId!,
                        );
                      },
                      child: Text(
                        existingMeal == null ? 'Add to Plan' : 'Update / Swap',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 231, 206),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F5DA8),
        elevation: 0,
        // Ensures the automatic endDrawer three-line icon is white
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            InkWell(
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _presenter.selectedWeekStart,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (pickedDate != null) {
                  setState(() {
                    _presenter.selectedWeekStart = pickedDate.subtract(
                      Duration(days: pickedDate.weekday % 7),
                    );
                    _presenter.fetchMealsForWeek();
                  });
                }
              },
              child: Row(
                children: const [
                  Text(
                    'This Week',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
              onPressed: () => setState(() => _presenter.changeWeek(-1)),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white),
              onPressed: () => setState(() => _presenter.changeWeek(1)),
            ),
          ],
        ),
      ),

      endDrawer: Drawer(
        backgroundColor: const Color.fromARGB(255, 247, 231, 206),
        child: Column(
          children: [
            // 1. Compact Blue Header
            Container(
              width: double.infinity,
              color: const Color(0xFF1F5DA8),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: const SafeArea(
                bottom: false,
                child: Text(
                  'Meal Options',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Scrollable Drawer Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 2. Outlined Container + 3. Inline Dropdown ExpansionTile
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      border: Border.all(
                        color: const Color(0xFF1F5DA8),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Theme(
                      // Removes default top/bottom divider lines of ExpansionTile
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        leading: const Icon(
                          Icons.add_circle_outline,
                          color: Color(0xFF1F5DA8),
                        ),
                        title: const Text(
                          'Schedule New Meal',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        iconColor: const Color(0xFF1F5DA8),
                        collapsedIconColor: const Color(0xFF1F5DA8),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        onExpansionChanged: (isExpanded) {
                          if (isExpanded) {
                            // Refresh recipes & sync default date to current viewed week
                            _loadRecipesForDrawer();
                            setState(() {
                              _drawerDate = _presenter.selectedWeekStart;
                            });
                          }
                        },
                        children: [
                          // Meal Type Dropdown
                          DropdownButtonFormField<String>(
                            value: _drawerMealType,
                            decoration: const InputDecoration(
                              labelText: 'Meal Slot',
                              isDense: true,
                            ),
                            items: ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                                .map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _drawerMealType = val!),
                          ),
                          const SizedBox(height: 12),

                          // Date Picker Row
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _drawerDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() => _drawerDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date',
                                isDense: true,
                                suffixIcon: Icon(Icons.calendar_today, size: 18),
                              ),
                              child: Text(
                                '${_drawerDate.month}/${_drawerDate.day}/${_drawerDate.year}',
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: false,
                                label: Text('All'),
                                icon: Icon(Icons.menu_book, size: 16),
                              ),
                              ButtonSegment(
                                value: true,
                                label: Text('My Saved'),
                                icon: Icon(Icons.favorite, size: 16),
                              ),
                            ],
                            selected: {_drawerShowSavedOnly},
                            onSelectionChanged: (Set<bool> newSelection) async {
                              final nextValue = newSelection.first;
                              final updatedList = await _fetchAvailableRecipes(savedOnly: nextValue);
                              setState(() {
                                _drawerShowSavedOnly = nextValue;
                                _availableRecipes = updatedList;
                                _drawerRecipeId = null;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Searchable Recipe Dropdown
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return DropdownMenu<String>(
                                width: constraints.maxWidth,
                                initialSelection: _availableRecipes
                                        .any((r) => r['id'] == _drawerRecipeId)
                                    ? _drawerRecipeId
                                    : null,
                                label: const Text('Select Recipe'),
                                hintText: 'Choose a recipe',
                                requestFocusOnTap: true,
                                enableFilter: true,
                                enableSearch: true,
                                menuHeight: 200,
                                onSelected: (String? val) {
                                  setState(() => _drawerRecipeId = val);
                                },
                                dropdownMenuEntries: _availableRecipes
                                    .map<DropdownMenuEntry<String>>((rec) {
                                  return DropdownMenuEntry<String>(
                                    value: rec['id']!,
                                    label: rec['title']!,
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1F5DA8),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () async {
                                if (_drawerRecipeId == null ||
                                    _drawerRecipeId!.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please select a Recipe'),
                                    ),
                                  );
                                  return;
                                }

                                // Close the drawer
                                Navigator.pop(context);

                                await _presenter.savePlannedMeal(
                                  mealType: _drawerMealType,
                                  date: _drawerDate,
                                  recipeId: _drawerRecipeId!,
                                );

                                // Reset selected recipe for next time
                                setState(() => _drawerRecipeId = null);
                              },
                              child: const Text('Add to Plan'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: StreamBuilder<List<PlannedMeal>>(
        stream: _presenter.mealsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final groupedMeals = _groupMealsByDay(snapshot.data ?? []);

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: groupedMeals.entries.map((entry) {
              final dayName = entry.key;
              final mealsForDay = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      dayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (mealsForDay.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        'No meals scheduled',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    ...mealsForDay.map((meal) => _buildMealCard(context, meal)),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, PlannedMeal meal) {
    final recipe = meal.recipe;

    return GestureDetector(
      onTap: () {
        if (recipe != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipePage(recipe: recipe),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Meal type vertical badge
            Container(
              width: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFF0F0F0),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  bottomLeft: Radius.circular(16.0),
                ),
              ),
              child: Center(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    meal.mealType,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            // Recipe Image
            ClipRRect(
              child: recipe?.imageURL != null
                  ? Image.network(
                      recipe!.imageURL!,
                      width: 90,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            const SizedBox(width: 12.0),
            // Title and Sides
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      recipe?.title ?? 'Unknown Meal',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    ...meal.sides.map(
                      (side) => Text(
                        side,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Swap Button
            IconButton(
              icon: const Icon(Icons.swap_horiz, color: Colors.black54),
              onPressed: () => _showAddEditMealDialog(existingMeal: meal),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
            const SizedBox(width: 12.0),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 90,
      height: 100,
      color: Colors.grey[300],
      child: const Icon(Icons.restaurant, color: Colors.grey),
    );
  }
}