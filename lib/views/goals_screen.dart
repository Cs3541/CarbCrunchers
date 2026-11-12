import 'package:flutter/material.dart';

import '../models/goals_repository.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key, this.repository});

  final GoalsRepository? repository;

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  String goal = 'Balanced';
  late final GoalsRepository _repository;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  String? _selectedPreset;
  String currentGoal = 'Balanced';
  Map<String, dynamic> _data = {};

  final fields = {
    'Height (cm)': TextEditingController(),
    'Weight (kg)': TextEditingController(),
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

  Map<String, double> saved = {
    'Daily calories': 2000,
    'Daily protein (g)': 100,
    'Daily carbs (g)': 250,
    'Daily fat (g)': 70,
    'Daily fat grace (g)': 0,
    'Daily sugar (g)': 25,
    'Daily sugar grace (g)': 0,
    'Weekly calories': 14000,
    'Weekly protein (g)': 700,
  };

  static const _defaultGoals = <String, double>{
    'Daily calories': 2000,
    'Daily protein (g)': 100,
    'Daily carbs (g)': 250,
    'Daily fat (g)': 70,
    'Daily fat grace (g)': 0,
    'Daily sugar (g)': 25,
    'Daily sugar grace (g)': 0,
    'Weekly calories': 14000,
    'Weekly protein (g)': 700,
  };

  DateTime get _currentWeek => _weekStart(DateTime.now());
  DateTime get _nextWeek => _currentWeek.add(const Duration(days: 7));
  String get _currentWeekKey => _weekKey(_currentWeek);
  String get _nextWeekKey => _weekKey(_nextWeek);

  static DateTime _weekStart(DateTime date) {
    final daysFromMonday = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  static String _weekKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is! Map) return <String, dynamic>{};
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  Map<String, dynamic> _config(
    String focus,
    Map<String, double> values,
  ) => {
    'focus': focus,
    'values': values,
  };

  Map<String, dynamic> _readConfig(dynamic value) {
    final config = _asMap(value);
    final rawValues = _asMap(config['values']);
    final values = <String, double>{};

    for (final key in _defaultGoals.keys) {
      final number = rawValues[key];
      values[key] = number is num ? number.toDouble() : _defaultGoals[key]!;
    }

    return {
      'focus': config['focus'] is String ? config['focus'] as String : 'Balanced',
      'values': values,
    };
  }

  Map<String, dynamic> _configForEditor(Map<String, dynamic> config) {
    final values = _asMap(config['values']);
    for (final field in fields.entries) {
      field.value.text = values[field.key]?.toString() ?? '';
    }
    return config;
  }

  Future<void> _loadGoals() async {
    try {
      var data = await _repository.load();
      final weeks = _asMap(data['weeks']);
      final defaultConfig = _readConfig(data['defaultGoals'] ?? {
        'focus': 'Balanced',
        'values': _defaultGoals,
      });
      final currentConfig = _readConfig(
        weeks[_currentWeekKey] ?? defaultConfig,
      );
      final nextConfig = _readConfig(
        weeks[_nextWeekKey] ?? defaultConfig,
      );

      if (!weeks.containsKey(_currentWeekKey)) {
        weeks[_currentWeekKey] = currentConfig;
        data = {...data, 'weeks': weeks};
        await _repository.save(data);
      }

      if (!mounted) return;
      setState(() {
        _data = data;
        saved = Map<String, double>.from(_asMap(currentConfig['values']).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ));
        currentGoal = currentConfig['focus'] as String;
        goal = nextConfig['focus'] as String;
        _configForEditor(nextConfig);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Could not load goals: $error';
        _isLoading = false;
      });
    }
  }

  Map<String, double>? _readFields() {
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
        return null;
      }

      values[field.key] = number;
    }

    return values;
  }

  Future<bool> _saveData(Map<String, dynamic> updated) async {
    setState(() => _isSaving = true);
    try {
      await _repository.save(updated);
      if (!mounted) return false;
      setState(() {
        _data = updated;
        _isSaving = false;
      });
      return true;
    } catch (error) {
      if (!mounted) return false;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save goals: $error')),
      );
      return false;
    }
  }

  Future<void> saveGoals() async {
    if (_isLoading || _loadError != null || _isSaving) return;
    final values = _readFields();
    if (values == null) return;

    final weeks = _asMap(_data['weeks']);
    weeks[_nextWeekKey] = _config(goal, values);
    final updated = {..._data, 'weeks': weeks};
    if (!await _saveData(updated)) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Next week's goals saved.")),
    );
  }

  Future<void> saveAsDefault() async {
    if (_isLoading || _loadError != null || _isSaving) return;
    final values = _readFields();
    if (values == null) return;

    final updated = {
      ..._data,
      'defaultGoals': _config(goal, values),
    };
    if (!await _saveData(updated)) return;
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Default goals saved for future weeks.')),
    );
  }

  Future<void> savePreset() async {
    if (_isLoading || _loadError != null || _isSaving) return;
    final values = _readFields();
    if (values == null) return;

    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save goal preset'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Preset name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (name == null || name.isEmpty || !mounted) return;

    final presets = List<Map<String, dynamic>>.from(
      (_data['presets'] as List? ?? const []).map(_asMap),
    );
    presets.removeWhere((preset) => preset['name'] == name);
    presets.add({'name': name, ..._config(goal, values)});
    if (!await _saveData({..._data, 'presets': presets})) return;

    if (!mounted) return;
    setState(() => _selectedPreset = name);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Preset "$name" saved.')),
    );
  }

  void _applyPreset(String? name) {
    if (name == null) return;
    final presets = (_data['presets'] as List? ?? const [])
        .map(_asMap)
        .where((preset) => preset['name'] == name);
    if (presets.isEmpty) return;
    final config = _readConfig(presets.first);
    setState(() {
      _selectedPreset = name;
      goal = config['focus'] as String;
      _configForEditor(config);
    });
  }

  Future<void> _deleteSelectedPreset() async {
    if (_isLoading || _loadError != null || _isSaving) return;
    final name = _selectedPreset;
    if (name == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete preset?'),
        content: Text('Delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final presets = List<Map<String, dynamic>>.from(
      (_data['presets'] as List? ?? const []).map(_asMap),
    )..removeWhere((preset) => preset['name'] == name);
    if (!await _saveData({..._data, 'presets': presets})) return;

    if (!mounted) return;
    setState(() => _selectedPreset = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Preset "$name" deleted.')),
    );
  }

  void changeGoal(String value) {
    setState(() {
      goal = value;

      // Example targets for the interface, not personal health advice.
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

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? FirestoreGoalsRepository();
    _loadGoals();
  }

  Widget _buildFieldRow(String firstField, [String? secondField]) {
    Widget buildField(String label) => TextField(
      controller: fields[label],
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
    String unit = 'g',
    String? graceKey,
    required Color color,
  }) {
    final target = saved[targetKey]!;
    final grace = graceKey == null ? 0.0 : saved[graceKey]!;
    final allowedTotal = target + grace;
    final targetFraction = graceKey == null ? 1.0 : target / allowedTotal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (graceKey == null)
                Text('Goal ${target.toStringAsFixed(0)} $unit')
              else
                Text(
                  'Goal ${target.toStringAsFixed(0)} $unit'
                  '  ·  Grace +${grace.toStringAsFixed(0)} $unit',
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
                  if (graceKey != null)
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: targetFraction,
                      child: ColoredBox(color: color),
                    )
                  else
                    ColoredBox(color: color),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (graceKey != null)
            Text(
              'Allowed up to ${allowedTotal.toStringAsFixed(0)} $unit',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Text(
              'Target ${target.toStringAsFixed(0)} $unit',
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
          if (_isLoading)
            const LinearProgressIndicator()
          else if (_loadError != null)
            Text(_loadError!, style: const TextStyle(color: Colors.red)),
          Text(
            'This week (${_weekKey(_currentWeek)}): goals are locked. '
            'You can edit next week any time before it starts '
            '(${_weekKey(_nextWeek)}).',
          ),
          const SizedBox(height: 12),
          Text(
            'Current focus: $currentGoal',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            initialValue: goal,
            key: ValueKey(goal),
            dropdownColor: Colors.white,
            decoration: const InputDecoration(
              labelText: "Next week's goal focus",
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
              if (value != null && !_isLoading && _loadError == null) {
                changeGoal(value);
              }
            },
          ),

          const SizedBox(height: 8),
          const Text(
            'Edit these goals for next week; current-week goals cannot be changed.',
          ),
          const SizedBox(height: 20),

          if ((_data['presets'] as List? ?? const []).isNotEmpty) ...[
            DropdownButtonFormField<String>(
              key: ValueKey(_selectedPreset),
              initialValue: _selectedPreset,
              decoration: const InputDecoration(
                labelText: 'Use a saved preset',
                border: OutlineInputBorder(),
              ),
              items: (_data['presets'] as List)
                  .map(_asMap)
                  .map(
                    (preset) => DropdownMenuItem<String>(
                      value: preset['name'] as String,
                      child: Text(preset['name'] as String),
                    ),
                  )
                  .toList(),
              onChanged: _loadError == null ? _applyPreset : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _selectedPreset == null ||
                        _isLoading ||
                        _loadError != null ||
                        _isSaving
                    ? null
                    : _deleteSelectedPreset,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete selected preset'),
              ),
            ),
          ],

          _buildFieldRow('Height (cm)', 'Weight (kg)'),
          _buildFieldRow('Daily calories'),
          _buildFieldRow('Daily protein (g)'),
          _buildFieldRow('Daily carbs (g)'),
          _buildFieldRow('Daily fat (g)', 'Daily fat grace (g)'),
          _buildFieldRow('Daily sugar (g)', 'Daily sugar grace (g)'),
          _buildFieldRow('Weekly calories', 'Weekly protein (g)'),

          ElevatedButton(
            onPressed: _isLoading || _loadError != null || _isSaving
                ? null
                : saveGoals,
            child: const Text("Save Next Week's Goals"),
          ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: _isLoading || _loadError != null || _isSaving
                    ? null
                    : saveAsDefault,
                child: const Text('Set as Default'),
              ),
              OutlinedButton(
                onPressed: _isLoading || _loadError != null || _isSaving
                    ? null
                    : savePreset,
                child: const Text('Save as Preset'),
              ),
            ],
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
            'Daily nutrition goals',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Solid color = target; lighter color = grace allowance.'),
          const SizedBox(height: 12),
          _buildMacroGoalBar(
            label: 'Calories',
            targetKey: 'Daily calories',
            unit: 'calories',
            color: Colors.red,
          ),
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