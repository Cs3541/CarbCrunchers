import 'package:carb_cruncher/views/articles_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../Presenters/AuthPresenter.dart';
import '../widgets/profile_avatar.dart';
import 'goals_screen.dart';

import 'browserecipes.dart';
import 'my_recipe_screen.dart';
import 'meal_plan_view.dart';
import 'recipe_page.dart';
import '../Views/profile_screen.dart';
import '../Models/meal_plan_model.dart';
import 'shopping_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PlannedMeal> _todaysMeals = [];
  bool _isLoadingMeals = true;
  String? _mealLoadError;

  @override
  void initState() {
    super.initState();
    _loadTodaysMeals();
  }

  Future<void> _loadTodaysMeals() async {
    try {
      final meals = await PlannedMeal.fetchMealsForUser();
      final now = DateTime.now();
      final todaysMeals = meals.where((meal) {
        return meal.date.year == now.year &&
            meal.date.month == now.month &&
            meal.date.day == now.day;
      }).toList();
      const mealOrder = {'Breakfast': 0, 'Lunch': 1, 'Dinner': 2};
      todaysMeals.sort(
        (a, b) =>
            (mealOrder[a.mealType] ?? 3).compareTo(mealOrder[b.mealType] ?? 3),
      );

      if (!mounted) return;
      setState(() {
        _todaysMeals = todaysMeals;
        _mealLoadError = null;
        _isLoadingMeals = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _mealLoadError = 'Could not load today\'s meal plan';
        _isLoadingMeals = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authPresenter = AuthPresenter();
    final database = FirebaseDatabase.instance;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 231, 206),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 72.0,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 48.0),
                              child: Text(
                                'Carb Crunchers',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 28.0,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Homemade Apple',
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              child: StreamBuilder<User?>(
                                stream: authPresenter.userChanges(),
                                initialData: authPresenter.currentUser,
                                builder: (context, snapshot) {
                                  final user = snapshot.data;
                                  if (user == null) {
                                    return _buildProfileButton(context, null);
                                  }

                                  return StreamBuilder<DatabaseEvent>(
                                    stream: database
                                        .ref('profileImages/${user.uid}')
                                        .onValue,
                                    builder: (context, imageSnapshot) =>
                                        _buildProfileButton(
                                          context,
                                          imageSnapshot.data?.snapshot.value,
                                        ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      SizedBox(
                        height: 160.0,
                        child: Row(
                          children: [
                            Expanded(
                              child: Center(
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              BrowseRecipiesScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1F5DA8),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Browse Recipes'),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: Center(
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const MyRecipeScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1F5DA8),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text("My Recipes"),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      _buildTodaysMealPlan(context),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomAppBar(
          height: 64.0,
          padding: EdgeInsets.zero,
          color: const Color(0xFFE4CFB2),
          child: Row(
            children: [
              _buildNavigationItem(
                icon: _buildGoalIcon(),
                label: 'Goals',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GoalsScreen()),
                ),
              ),
              _buildNavigationItem(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Color(0xFF1F5DA8),
                ),
                label: 'Shopping Cart',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ShoppingListsScreen(),
                  ),
                ),
              ),
              _buildNavigationItem(
                icon: const Icon(
                  Icons.menu_book_outlined,
                  color: Color(0xFF1F5DA8),
                ),
                label: 'Articles',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ArticlesPage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 2.0),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1F5DA8),
                  fontSize: 12.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalIcon() {
    return Image.asset(
      'assets/images/goals_target.png',
      width: 28,
      height: 28,
      excludeFromSemantics: true,
    );
  }

  Widget _buildTodaysMealPlan(BuildContext context) {
    final now = DateTime.now();
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final dateLabel =
        '${dayNames[now.weekday - 1]}, ${monthNames[now.month - 1]} ${now.day}, ${now.year}';

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFB45309), width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyMealsScreen()),
          );
          await _loadTodaysMeals();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Today's Meal Plan",
                      style: TextStyle(
                        fontFamily: 'Homemade Apple',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: Color(0xFFB45309),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                dateLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoadingMeals)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_mealLoadError != null)
                Text(_mealLoadError!, style: const TextStyle(color: Colors.red))
              else if (_todaysMeals.isEmpty)
                const Text(
                  'No meals planned for today.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                ..._todaysMeals.map((meal) {
                  final recipe = meal.recipe;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        _buildMealImage(meal.recipe?.imageURL),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meal.mealType,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F5DA8),
                                ),
                              ),
                              Text(
                                meal.recipe?.title ?? 'Unknown meal',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Open recipe',
                          onPressed: recipe == null
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          RecipePage(recipe: recipe),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealImage(String? imageUrl) {
    Widget imagePlaceholder() => Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.restaurant, color: Colors.grey),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 64,
        height: 64,
        child: imageUrl == null || imageUrl.isEmpty
            ? imagePlaceholder()
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => imagePlaceholder(),
              ),
      ),
    );
  }

  Widget _buildProfileButton(BuildContext context, Object? profileData) {
    return IconButton(
      tooltip: 'Profile',
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFF1F5DA8),
        foregroundColor: Colors.white,
        fixedSize: const Size(40, 40),
        padding: EdgeInsets.zero,
      ),
      icon: ProfileAvatar(profileData: profileData, radius: 20),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
      },
    );
  }
}
