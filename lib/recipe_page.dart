import 'package:carb_cruncher/models/nutrition_model.dart';
import 'package:flutter/material.dart';

import './models/recipe_model.dart';

// THIS IS NOT FINAL.
// This is a just a basic scaffold of the recipe page, and it can be changed later.

class RecipePage extends StatefulWidget {
  final Recipe recipe;

  const RecipePage({super.key, required this.recipe});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  final Set<int> _checked = {};

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final theme = Theme.of(context);
    final ingredients = recipe.ingredients ?? [];
    final steps = recipe.steps ?? [];

    return Scaffold(
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
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
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
      floatingActionButton: steps.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start cooking'),
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
