import 'package:flutter/material.dart';

import '../nutrition/day_history_view.dart';
import '../nutrition/nutrition_day.dart';
import '../nutrition/nutrition_store.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DayHistoryView(
      builder: (days, today) {
        final id = dayId(today);

        return GoalEditor(
          key: ValueKey('$id-${days.containsKey(id)}'),
          days: days,
          today: today,
          save: NutritionStore().saveGoals,
        );
      },
    );
  }
}

class GoalEditor extends StatefulWidget {
  final History days;
  final DateTime today;
  final Future<void> Function(String, Numbers, String) save;

  const GoalEditor({
    super.key,
    required this.days,
    required this.today,
    required this.save,
  });

  @override
  State<GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends State<GoalEditor> {
  String goal = 'Balanced';
  bool saving = false;

  final fields = {
    'Height (inches)': TextEditingController(),
    'Weight (lbs)': TextEditingController(),
    'Daily calories': TextEditingController(text: '2000'),
    'Daily protein (g)': TextEditingController(text: '100'),
    'Daily carbs (g)': TextEditingController(text: '250'),
    'Daily fat (g)': TextEditingController(text: '70'),
    'Daily fat grace (g)': TextEditingController(text: '0'),
    'Daily sugar (g)': TextEditingController(text: '25'),
    'Daily sugar grace (g)': TextEditingController(text: '0'),
    'Weekly calories': TextEditingController(text: '14000'),
    'Weekly protein (g)': TextEditingController(text: '700'),
  };

  String get todayId => dayId(widget.today);
  NutritionDay? get today => widget.days[todayId];

  @override
  void initState() {
    super.initState();

    // Start a new day with the user's most recently saved goals.
    final dates = widget.days.keys
        .where((id) => id.compareTo(todayId) <= 0)
        .toList()
      ..sort();

    if (dates.isEmpty) return;

    final previous = widget.days[dates.last]!;
    goal = previous.focus;

    for (final entry in previous.goals.entries) {
      fields[entry.key]?.text = entry.value.toString();
    }
  }

  Future<void> saveGoals() async {
    if (saving || today != null) return;

    final values = <String, double>{};

    for (final field in fields.entries) {
      final text = field.value.text.trim();

      if (text.isEmpty &&
          (field.key == 'Height (inches)' || field.key == 'Weight (lbs)')) {
        continue;
      }

      final number = double.tryParse(text);
      final allowZero = field.key.endsWith('grace (g)') ||
          field.key == 'Daily fat (g)' ||
          field.key == 'Daily sugar (g)';

      if (number == null ||
          !number.isFinite ||
          (allowZero ? number < 0 : number <= 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${field.key}: enter a number '
              '${allowZero ? 'of zero or greater' : 'greater than zero'}.',
            ),
          ),
        );
        return;
      }

      values[field.key] = number;
    }

    setState(() => saving = true);

    try {
      await widget.save(todayId, values, goal);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void changeGoal(String value) {
    setState(() {
      goal = value;

      final protein = goal == 'More protein' ? 150 : 100;

      fields['Daily calories']!.text = '2000';
      fields['Daily protein (g)']!.text = '$protein';
      fields['Daily carbs (g)']!.text = '250';
      fields['Daily fat (g)']!.text = '70';
      fields['Daily fat grace (g)']!.text = '0';
      fields['Daily sugar (g)']!.text = '25';
      fields['Daily sugar grace (g)']!.text = '0';
      fields['Weekly calories']!.text = '14000';
      fields['Weekly protein (g)']!.text = '${protein * 7}';
    });
  }

  Widget _buildFieldRow(String firstField, [String? secondField]) {
    Widget buildField(String label) => TextField(
      controller: fields[label],
      enabled: today == null && !saving,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: buildField(firstField)),
          if (secondField != null) ...[
            const SizedBox(width: 12),
            Expanded(child: buildField(secondField)),
          ],
        ],
      ),
    );
  }

  Widget _buildMacroGoalBar({
    required String label,
    required String targetKey,
    String? graceKey,
    required Color color,
  }) {
    final name = label.toLowerCase();
    final log = today;
    final eaten = log?.eaten(name) ?? 0.0;
    final target = log?.goals[targetKey] ?? 0.0;
    final restricted = graceKey != null;
    final grace = restricted ? log?.goals[graceKey] ?? 0.0 : 0.0;

    // A serving with 25 g toward a 100 g goal fills one quarter of the bar.
    final progress = target > 0
        ? (eaten / target).clamp(0.0, 1.0).toDouble()
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (log != null)
                Text(
                  '${eaten.toStringAsFixed(1)} / '
                  '${target.toStringAsFixed(1)} g'
                  '${restricted ? ' limit' : ''}',
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
                  const ColoredBox(color: Colors.white),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: ColoredBox(color: color),
                  ),
                ],
              ),
            ),
          ),
          if (restricted && log != null) ...[
            const SizedBox(height: 4),
            Text(
              'Extra: ${log.extra(name).toStringAsFixed(1)} g'
              ' / ${grace.toStringAsFixed(1)} g allowance',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
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
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 231, 206),
      appBar: AppBar(
        title: const Text('My Goals'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Current streak: ${currentStreak(widget.days, widget.today)} days',
          ),
          Text(
            today == null
                ? 'Save your goals to start logging today.'
                : 'Today’s goals are locked until tomorrow.',
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
            onChanged: today != null || saving
                ? null
                : (value) {
                    if (value != null) changeGoal(value);
                  },
          ),

          const SizedBox(height: 8),
          const Text(
            'Changing your focus fills in sample starter targets. '
            'You can edit them before saving.',
          ),
          const SizedBox(height: 20),

          _buildFieldRow('Height (inches)', 'Weight (lbs)'),
          _buildFieldRow('Daily calories'),
          _buildFieldRow('Daily protein (g)', 'Daily carbs (g)'),
          _buildFieldRow('Daily fat (g)', 'Daily fat grace (g)'),
          _buildFieldRow('Daily sugar (g)', 'Daily sugar grace (g)'),
          _buildFieldRow('Weekly calories', 'Weekly protein (g)'),

          if (today == null)
            ElevatedButton(
              onPressed: saving ? null : saveGoals,
              child: const Text('Save Profile and Goals'),
            ),

          const SizedBox(height: 24),
          Text(
            'Today’s recipe nutrition',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          _buildMacroGoalBar(
            label: 'Protein',
            targetKey: 'Daily protein (g)',
            color: Colors.blue,
          ),
          _buildMacroGoalBar(
            label: 'Carbs',
            targetKey: 'Daily carbs (g)',
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