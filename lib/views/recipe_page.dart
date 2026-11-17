import 'package:carb_cruncher/interactive_recipe_screen.dart';
import 'package:carb_cruncher/models/nutrition_model.dart';
import 'package:flutter/material.dart';

import '../Presenters/recipe_presenter.dart';
import '../models/recipe_model.dart';
import '../nutrition/nutrition_day.dart';
import '../nutrition/nutrition_store.dart';
import '../Models/meal_plan_model.dart';

// THIS IS NOT FINAL.
// This is a just a basic scaffold of the recipe page, and it can be changed later.

class RecipePage extends StatefulWidget {
  final Recipe recipe;

  final bool showSaveButton;

  const RecipePage({
    super.key,
    required this.recipe,
    this.showSaveButton = true,
  });

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  final RecipePresenter _recipePresenter = RecipePresenter();
  final Set<int> _checked = {};
  bool _logging = false;

  Future<void> _showAddToMealPlanDialog() async {
    final recipe = widget.recipe;
    String selectedMealType = 'Breakfast';
    DateTime selectedDate = DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add to Meal Plan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedMealType,
                    decoration: const InputDecoration(labelText: 'Meal'),
                    items: ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => selectedMealType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date'),
                    subtitle: Text(
                      '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setSheetState(() => selectedDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F5DA8),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        final isSavedRecipe =
                            recipe.userRecipeIdentifier != null &&
                            recipe.userRecipeIdentifier!.isNotEmpty;
                        final recipeId = isSavedRecipe
                            ? recipe.userRecipeIdentifier!
                            : recipe.userId ?? recipe.title;
                        final messenger = ScaffoldMessenger.of(context);

                        try {
                          await PlannedMeal.addOrUpdateMeal(
                            mealType: selectedMealType,
                            date: selectedDate,
                            recipeId: recipeId,
                            recipeSource: isSavedRecipe
                                ? 'saved_recipes'
                                : 'recipes',
                            savedRecipeIdentifier: isSavedRecipe
                                ? recipe.userRecipeIdentifier
                                : null,
                          );
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                '${recipe.title} added to $selectedMealType.',
                              ),
                            ),
                          );
                        } catch (error) {
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Could not add recipe to meal plan. $error',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Add to Plan'),
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

  Future<void> _logServing() async {
    final recipe = widget.recipe;
    final nutrition = recipe.nutrition;

    if (nutrition == null || _logging) return;

    setState(() => _logging = true);
    final date = dayId(DateTime.now());

    try {
      final store = NutritionStore();

      try {
        await store.logServing(date, nutrition);
      } on ExtraServing catch (extra) {
        if (!mounted) return;

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Log this serving?'),
            content: Text(
              '${extra.details}\n\n'
              'The extra grams will show below your goal bar.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Log serving'),
              ),
            ],
          ),
        );

        if (confirmed != true || !mounted) return;

        await store.logServing(date, nutrition, allowExtra: true);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logged one serving of ${recipe.title}.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not log this serving. $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _logging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final theme = Theme.of(context);
    final ingredients = recipe.ingredients;
    final steps = recipe.steps ?? [];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 231, 206),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: recipe.imageURL == null
                  ? _imagePlaceholder()
                  : Image.network(
                      recipe.imageURL!,
                      fit: BoxFit.cover,
                      cacheWidth: 1000,
                      errorBuilder: (_, _, _) => _imagePlaceholder(),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This recipe matches your nutrition preferences!',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick facts
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (recipe.cooktime != null && recipe.cooktime! > 0)
                        _InfoChip(
                          icon: Icons.schedule,
                          label: _formatMinutes(recipe.cooktime!),
                        ),
                      if (recipe.servings != null)
                        _InfoChip(
                          icon: Icons.people_outline,
                          label: '${recipe.servings} servings',
                        ),
                      if (recipe.nutrition != null)
                        _InfoChip(
                          icon: Icons.local_fire_department_outlined,
                          label:
                              '~${recipe.nutrition!.calories.round()} cal / serving',
                        ),
                    ],
                  ),

                  // Nutrition
                  if (recipe.nutrition != null) ...[
                    const SizedBox(height: 24),
                    _SectionTitle('Nutrition per serving'),
                    const SizedBox(height: 8),
                    _NutritionRow(nutrition: recipe.nutrition!),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _logging ? null : _logServing,
                      icon: const Icon(Icons.add),
                      label: Text(_logging ? 'Logging…' : 'Log one serving'),
                    ),
                  ],

                  // Ingredients
                  const SizedBox(height: 24),
                  _SectionTitle('Ingredients'),
                  if (ingredients.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No ingredients listed.'),
                    ),
                  for (var i = 0; i < ingredients.length; i++)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      value: _checked.contains(i),
                      onChanged: (on) => setState(() {
                        on == true ? _checked.add(i) : _checked.remove(i);
                      }),
                      title: Text(
                        ingredients[i].raw,
                        style: _checked.contains(i)
                            ? const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                    ),

                  // Steps
                  const SizedBox(height: 24),
                  _SectionTitle('Steps'),
                  const SizedBox(height: 8),
                  for (var i = 0; i < steps.length; i++)
                    _StepTile(
                      number: i + 1,
                      text: steps[i].text,
                      timerSec: steps[i].timerSec,
                    ),

                  const SizedBox(height: 80), // room above the button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            if (widget.showSaveButton)
              ElevatedButton(
                onPressed: () {
                  _recipePresenter.addUserRecipe(recipe);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Recipe Saved'),
                      titleTextStyle: const TextStyle(
                        fontSize: 28.0,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Homemade Apple',
                        color: Color(0xFFB45309),
                      ),
                      content: const Text(
                        'This recipe has been saved to your collection.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Save Recipe'),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _showAddToMealPlanDialog,
                child: const Text('Add to Meal Plan'),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        InteractiveRecipeScreen(recipe: recipe),
                  ),
                );
              },
              child: Text('Start Cooking'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    color: Colors.grey.shade300,
    alignment: Alignment.center,
    child: const Icon(Icons.restaurant, size: 64, color: Colors.grey),
  );

  static String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes min';
    final m = minutes % 60;
    return m == 0 ? '${minutes ~/ 60} hr' : '${minutes ~/ 60} hr $m min';
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleMedium);
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 18),
    label: Text(label),
    visualDensity: VisualDensity.compact,
  );
}

class _NutritionRow extends StatelessWidget {
  final Nutrition nutrition;

  const _NutritionRow({required this.nutrition});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Protein', '${nutrition.protein.round()} g'),
      ('Carbs', '${nutrition.carbs.round()} g'),
      ('Fat', '${nutrition.fat.round()} g'),
      ('Fiber', '${nutrition.fiber.round()} g'),
      ('Sugar', '${nutrition.sugar.round()} g'),
      ('Sodium', '${nutrition.sodiumMg.round()} mg'),
    ];
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (label, value) in items)
          Container(
            width: 100,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(value, style: theme.textTheme.titleMedium),
                Text(label, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  final int number;
  final String text;
  final int? timerSec;

  const _StepTile({required this.number, required this.text, this.timerSec});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: theme.textTheme.bodyMedium),
                if (timerSec != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(timerSec! / 60).round()} min',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
