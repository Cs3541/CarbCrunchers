import 'package:flutter/material.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  String goal = 'Balanced';

  final fields = {
    'Height (cm)': TextEditingController(),
    'Weight (kg)': TextEditingController(),
    'Daily calories': TextEditingController(text: '2000'),
    'Daily protein (g)': TextEditingController(text: '100'),
    'Weekly calories': TextEditingController(text: '14000'),
    'Weekly protein (g)': TextEditingController(text: '700'),
  };

  Map<String, double> saved = {
    'Daily calories': 2000,
    'Daily protein (g)': 100,
    'Weekly calories': 14000,
    'Weekly protein (g)': 700,
  };

  void saveGoals() {
    final values = <String, double>{};

    for (final field in fields.entries) {
      final number = double.tryParse(field.value.text.trim());

      if (number == null || !number.isFinite || number <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${field.key}: enter a number greater than zero.'),
          ),
        );
        return;
      }

      values[field.key] = number;
    }

    setState(() {
      saved = values;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile and goals updated.')),
    );
  }

  void changeGoal(String value) {
    setState(() {
      goal = value;

      // Example targets for the interface, not personal health advice.
      final protein = goal == 'More protein' ? 150 : 100;

      fields['Daily calories']!.text = '2000';
      fields['Daily protein (g)']!.text = '$protein';
      fields['Weekly calories']!.text = '14000';
      fields['Weekly protein (g)']!.text = '${protein * 7}';
    });
  }

  @override
  void dispose() {
    for (final controller in fields.values) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caloriePercent = 500 / saved['Daily calories']! * 100;
    final proteinPercent = 35 / saved['Daily protein (g)']! * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Goals'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Demo: targets and food totals are examples. '
            'Changes reset when you leave this screen.',
          ),
          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            initialValue: goal,
            decoration: const InputDecoration(
              labelText: 'Goal focus',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Balanced',
                child: Text('Balanced'),
              ),
              DropdownMenuItem(
                value: 'More protein',
                child: Text('More protein'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                changeGoal(value);
              }
            },
          ),

          const SizedBox(height: 8),
          const Text(
            'Changing your focus fills in sample starter targets. '
            'You can edit them before saving.',
          ),
          const SizedBox(height: 20),

          // Creates one text box for each entry in fields.
          ...fields.entries.map((field) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: field.value,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: field.key,
                  border: const OutlineInputBorder(),
                ),
              ),
            );
          }),

          ElevatedButton(
            onPressed: saveGoals,
            child: const Text('Save Profile and Goals'),
          ),

          const SizedBox(height: 24),
          Text(
            'Progress — sample food totals',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Today: 1,200 / '
            '${saved['Daily calories']!.toStringAsFixed(0)} calories',
          ),
          Text(
            'Today: 60 / '
            '${saved['Daily protein (g)']!.toStringAsFixed(0)} g protein',
          ),
          const SizedBox(height: 8),
          Text(
            'This week: 6,500 / '
            '${saved['Weekly calories']!.toStringAsFixed(0)} calories',
          ),
          Text(
            'This week: 320 / '
            '${saved['Weekly protein (g)']!.toStringAsFixed(0)} g protein',
          ),

          const SizedBox(height: 24),
          Text(
            'Recipe contribution',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Chicken and rice — sample serving'),
          Text(
            '500 calories = ${caloriePercent.toStringAsFixed(0)}% '
            'of your daily calorie target',
          ),
          Text(
            '35 g protein = ${proteinPercent.toStringAsFixed(0)}% '
            'of your daily protein target',
          ),
        ],
      ),
    );
  }
}