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
    'Daily protein grace (g)': TextEditingController(text: '0'),
    'Daily carbs (g)': TextEditingController(text: '250'),
    'Daily carbs grace (g)': TextEditingController(text: '0'),
    'Daily fat (g)': TextEditingController(text: '70'),
    'Daily fat grace (g)': TextEditingController(text: '0'),
    'Daily sugar (g)': TextEditingController(text: '25'),
    'Daily sugar grace (g)': TextEditingController(text: '0'),
    'Weekly calories': TextEditingController(text: '14000'),
    'Weekly protein (g)': TextEditingController(text: '700'),
  };

  Map<String, double> saved = {
    'Daily calories': 2000,
    'Daily protein (g)': 100,
    'Daily protein grace (g)': 0,
    'Daily carbs (g)': 250,
    'Daily carbs grace (g)': 0,
    'Daily fat (g)': 70,
    'Daily fat grace (g)': 0,
    'Daily sugar (g)': 25,
    'Daily sugar grace (g)': 0,
    'Weekly calories': 14000,
    'Weekly protein (g)': 700,
  };

  void saveGoals() {
    final values = <String, double>{};

    for (final field in fields.entries) {
      final text = field.value.text.trim();
      if (text.isEmpty &&
          (field.key == 'Height (cm)' || field.key == 'Weight (kg)')) {
        continue;
      }

      final number = double.tryParse(text);
      final isGraceValue = field.key.endsWith('grace (g)');

      if (number == null ||
          !number.isFinite ||
          (isGraceValue ? number < 0 : number <= 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${field.key}: enter a number '
              '${isGraceValue ? 'of zero or greater' : 'greater than zero'}.',
            ),
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
      fields['Daily protein grace (g)']!.text = '0';
      fields['Daily carbs (g)']!.text = '250';
      fields['Daily carbs grace (g)']!.text = '0';
      fields['Daily fat (g)']!.text = '70';
      fields['Daily fat grace (g)']!.text = '0';
      fields['Daily sugar (g)']!.text = '25';
      fields['Daily sugar grace (g)']!.text = '0';
      fields['Weekly calories']!.text = '14000';
      fields['Weekly protein (g)']!.text = '${protein * 7}';
    });
  }

  Widget _buildField(String label) {
    return TextField(
      controller: fields[label],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildFieldRow(String firstField, [String? secondField]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: _buildField(firstField)),
          if (secondField != null) ...[
            const SizedBox(width: 12),
            Expanded(child: _buildField(secondField)),
          ],
        ],
      ),
    );
  }

  Widget _buildMacroGoalBar({
    required String label,
    required String targetKey,
    required String graceKey,
    required Color color,
  }) {
    final target = saved[targetKey]!;
    final grace = saved[graceKey]!;
    final allowedTotal = target + grace;
    final targetFraction = target / allowedTotal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                'Goal ${target.toStringAsFixed(0)} g'
                '  ·  Grace +${grace.toStringAsFixed(0)} g',
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 16,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: color.withOpacity(0.22)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: targetFraction,
                    child: ColoredBox(color: color),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Allowed up to ${allowedTotal.toStringAsFixed(0)} g',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
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
      backgroundColor: const Color.fromARGB(255, 247, 231, 206),
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
            dropdownColor: Colors.white,
            decoration: const InputDecoration(
              labelText: 'Goal focus',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
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

          _buildFieldRow('Height (cm)', 'Weight (kg)'),
          _buildFieldRow('Daily calories'),
          _buildFieldRow('Daily protein (g)', 'Daily protein grace (g)'),
          _buildFieldRow('Daily carbs (g)', 'Daily carbs grace (g)'),
          _buildFieldRow('Daily fat (g)', 'Daily fat grace (g)'),
          _buildFieldRow('Daily sugar (g)', 'Daily sugar grace (g)'),
          _buildFieldRow('Weekly calories', 'Weekly protein (g)'),

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
          const SizedBox(height: 24),
          Text(
            'Daily macro goals',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Solid color = goal; lighter color = grace allowance.'),
          const SizedBox(height: 12),
          _buildMacroGoalBar(
            label: 'Protein',
            targetKey: 'Daily protein (g)',
            graceKey: 'Daily protein grace (g)',
            color: Colors.blue,
          ),
          _buildMacroGoalBar(
            label: 'Carbs',
            targetKey: 'Daily carbs (g)',
            graceKey: 'Daily carbs grace (g)',
            color: Colors.deepOrange,
          ),
          _buildMacroGoalBar(
            label: 'Fat',
            targetKey: 'Daily fat (g)',
            graceKey: 'Daily fat grace (g)',
            color: Colors.green,
          ),
          _buildMacroGoalBar(
            label: 'Sugar',
            targetKey: 'Daily sugar (g)',
            graceKey: 'Daily sugar grace (g)',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }
}