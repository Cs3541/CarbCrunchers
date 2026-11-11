import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _presenter = MealPlanPresenter();
    _presenter.fetchMealsForWeek();
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
  Future<List> _fetchAvailableRecipes() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('recipes').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'title': (data['title'] ?? 'Untitled Recipe').toString(),
      };
    }).toList();
  }

  // Add or Swap Dialog
  void _showAddEditMealDialog({PlannedMeal? existingMeal}) async {
    String selectedMealType = existingMeal?.mealType ?? 'Breakfast';
    DateTime selectedDate = existingMeal?.date ?? _presenter.selectedWeekStart;
    String? selectedRecipeId = existingMeal?.recipeId;

    // Fetch existing recipes for dropdown selection
    final availableRecipes = await _fetchAvailableRecipes();

    if (!mounted) return;

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
                  DropdownButtonFormField<String>(
                    value: availableRecipes
                            .any((r) => r['id'] == selectedRecipeId)
                        ? selectedRecipeId
                        : null,
                    decoration:
                        const InputDecoration(labelText: 'Select Recipe'),
                    hint: const Text('Choose a recipe'),
                    items: availableRecipes
                      .map<DropdownMenuItem<String>>(
                        (rec) => DropdownMenuItem<String>(
                          value: rec['id'],
                          child: Text(
                            rec['title']!,
                            overflow: TextOverflow.ellipsis,
                            ),
                      ),)
                      .toList(),
                    isExpanded: true,
                    onChanged: (val) =>
                        setModalState(() => selectedRecipeId = val),
                  ),
                  const SizedBox(height: 24),

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

      // ADDED: Floating Action Button in Bottom Right Corner!
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1F5DA8),
        onPressed: () => _showAddEditMealDialog(),
        child: const Icon(Icons.add, color: Colors.white),
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