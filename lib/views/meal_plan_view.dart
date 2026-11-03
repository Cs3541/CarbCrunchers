import 'package:flutter/material.dart';
import '../models/meal_plan_model.dart';
import '../presenters/meal_plan_presenter.dart';
import '../recipe_page.dart';

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
        // Open RecipePage if recipe data exists
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
            // Meal type vertical badge (Breakfast, Lunch, Dinner, Snack)
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
            // Recipe Thumbnail
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
            // Recipe Title and Sides
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
            // Right Arrow Navigation Indicator
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