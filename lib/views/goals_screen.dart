import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/goals_repository.dart';
import '../nutrition/day_history_view.dart';
import '../nutrition/nutrition_day.dart';
import '../nutrition/nutrition_store.dart';

class GoalsScreen extends StatelessWidget {
  final GoalsRepository? repository;

  const GoalsScreen({super.key, this.repository});

  @override
  Widget build(BuildContext context) {
    // The existing widget tests supply a repository without starting Firebase.
    if (repository != null) {
      return _GoalsPage(
        repository: repository,
        history: const {},
        date: DateTime.now(),
      );
    }

    return DayHistoryView(
      builder: (history, date) => _GoalsPage(
        key: ValueKey(dayId(date)),
        history: history,
        date: date,
      ),
    );
  }
}

class _GoalsPage extends StatefulWidget {
  final GoalsRepository? repository;
  final History history;
  final DateTime date;

  const _GoalsPage({
    super.key,
    this.repository,
    required this.history,
    required this.date,
  });

  @override
  State<_GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<_GoalsPage> {
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

  final fields = {
    'Height (inches)': TextEditingController(),
    'Weight (lbs)': TextEditingController(),
    for (final entry in _defaultGoals.entries)
      entry.key: TextEditingController(text: entry.value.toString()),
  };

  Map<String, dynamic> _data = {};
  Map<String, double> _activeGoals = Map.of(_defaultGoals);

  String goal = 'Balanced';
  String currentGoal = 'Balanced';
  String? _selectedPreset;
  String? _loadError;
  bool _isLoading = true;
  bool _isSaving = false;

  String get _todayKey => dayId(widget.date);

  DateTime get _currentWeek {
    final date = widget.date;
    return DateTime(date.year, date.month, date.day - date.weekday + 1);
  }

  String get _currentWeekKey => dayId(_currentWeek);

  String get _nextWeekKey {
    final monday = _currentWeek;
    return dayId(DateTime(monday.year, monday.month, monday.day + 7));
  }

  NutritionDay? get _today => widget.history[_todayKey];

  bool get _canEdit => !_isLoading && !_isSaving && _loadError == null;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  @override
  void dispose() {
    for (final controller in fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is! Map) return {};
    return Map<String, dynamic>.from(value);
  }

  static List<Map<String, dynamic>> _presets(Map<String, dynamic> data) {
    final raw = data['presets'];
    if (raw is! List) return [];
    return raw.map(_asMap).toList();
  }

  Map<String, dynamic> _config(String focus, Map<String, double> values) {
    return {'focus': focus, 'values': values};
  }

  Map<String, dynamic> _readConfig(dynamic value) {
    final config = _asMap(value);
    final raw = _asMap(config['values']);
    final values = Map<String, double>.of(_defaultGoals);

    for (final key in _defaultGoals.keys) {
      final number = raw[key];
      if (number is num) values[key] = number.toDouble();
    }

    // Older weekly plans and presets may already contain metric measurements.
    final inches = raw['Height (inches)'];
    final cm = raw['Height (cm)'];
    if (inches is num) {
      values['Height (inches)'] = inches.toDouble();
    } else if (cm is num) {
      values['Height (inches)'] = cm / 2.54;
    }

    final lbs = raw['Weight (lbs)'];
    final kg = raw['Weight (kg)'];
    if (lbs is num) {
      values['Weight (lbs)'] = lbs.toDouble();
    } else if (kg is num) {
      values['Weight (lbs)'] = kg / 0.45359237;
    }

    final focus = config['focus'] == 'More protein' ? 'More protein' : 'Balanced';
    return _config(focus, values);
  }

  void _fillEditor(Map<String, dynamic> config) {
    goal = config['focus'] as String;
    final values = _asMap(config['values']);

    for (final entry in fields.entries) {
      entry.value.text = values[entry.key]?.toString() ?? '';
    }
  }

  Map<String, dynamic> _ensureWeek(
    Map<String, dynamic> data,
    Map<String, dynamic>? existingDay,
  ) {
    final weeks = _asMap(data['weeks']);
    if (weeks.containsKey(_currentWeekKey)) return data;

    // An existing user may have logged food before weekly plans were added.
    final previousDailyConfig = existingDay == null
        ? null
        : {
            'focus': existingDay['focus'],
            'values': existingDay['goals'],
          };

    weeks[_currentWeekKey] = _readConfig(
      data['defaultGoals'] ?? previousDailyConfig,
    );

    return {...data, 'weeks': weeks};
  }

  Future<Map<String, dynamic>> _updatePlan(
    Map<String, dynamic> Function(Map<String, dynamic>) change, {
    bool openToday = false,
  }) async {
    final repository = widget.repository;

    if (repository != null) {
      final original = await repository.load();
      final base = openToday ? _ensureWeek(original, null) : original;
      final updated = change(base);

      if (!identical(updated, original)) {
        await repository.save(updated);
      }
      return updated;
    }

    final store = NutritionStore();
    final dayRef = store.days.doc(_todayKey);
    final firestore = FirebaseFirestore.instance;
    final planRef = firestore.collection('user_goals').doc(store.days.parent!.id);

    return firestore.runTransaction((transaction) async {
      if (_todayKey != dayId(DateTime.now())) {
        throw StateError('The day changed. Reopen Goals and try again.');
      }

      final planDoc = await transaction.get(planRef);
      final original = planDoc.data() ?? <String, dynamic>{};

      Map<String, dynamic>? existingDay;
      if (openToday) {
        final dayDoc = await transaction.get(dayRef);
        existingDay = dayDoc.data();
      }

      final base = openToday ? _ensureWeek(original, existingDay) : original;
      final updated = change(base);

      if (!identical(updated, original)) {
        transaction.set(planRef, updated);
      }

      // Create today's targets once. Opening Goals again preserves logged meals.
      if (openToday && existingDay == null) {
        final weeks = _asMap(updated['weeks']);
        final active = _readConfig(weeks[_currentWeekKey]);

        transaction.set(dayRef, {
          'focus': active['focus'],
          'goals': active['values'],
          'totals': <String, double>{},
        });
      }

      return updated;
    });
  }

  Future<void> _loadGoals() async {
    try {
      final data = await _updatePlan((data) => data, openToday: true);
      final weeks = _asMap(data['weeks']);
      final active = _readConfig(weeks[_currentWeekKey]);
      final next = _readConfig(weeks[_nextWeekKey] ?? data['defaultGoals']);

      if (!mounted) return;

      setState(() {
        _data = data;
        _activeGoals = Map<String, double>.from(active['values'] as Map);
        currentGoal = active['focus'] as String;
        _fillEditor(next);
        _loadError = null;
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

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Map<String, double>? _readFields() {
    final values = <String, double>{};

    for (final field in fields.entries) {
      final key = field.key;
      final text = field.value.text.trim();

      if (text.isEmpty && (key == 'Height (inches)' || key == 'Weight (lbs)')) {
        continue;
      }

      final number = double.tryParse(text);
      final allowZero = key.endsWith('grace (g)') ||
          key == 'Daily fat (g)' ||
          key == 'Daily sugar (g)';

      if (number == null ||
          !number.isFinite ||
          (allowZero ? number < 0 : number <= 0)) {
        _message(
          '$key: enter a number '
          '${allowZero ? 'of zero or greater' : 'greater than zero'}.',
        );
        return null;
      }

      values[key] = number;
    }

    return values;
  }

  Future<bool> _saveChange(
    Map<String, dynamic> Function(Map<String, dynamic>) change,
    String message,
  ) async {
    if (!_canEdit) return false;

    setState(() => _isSaving = true);

    try {
      final updated = await _updatePlan(change);
      if (!mounted) return false;

      setState(() => _data = updated);
      _message(message);
      return true;
    } catch (error) {
      if (mounted) _message('Could not save goals: $error');
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> saveGoals() async {
    final values = _readFields();
    if (values == null) return;

    final next = _config(goal, values);

    await _saveChange((data) {
      final weeks = _asMap(data['weeks']);
      weeks[_nextWeekKey] = next;
      return {...data, 'weeks': weeks};
    }, "Next week's goals saved.");
  }

  Future<void> saveAsDefault() async {
    final values = _readFields();
    if (values == null) return;

    final config = _config(goal, values);
    await _saveChange(
      (data) => {...data, 'defaultGoals': config},
      'Default goals saved for future weeks.',
    );
  }

  Future<void> savePreset() async {
    final values = _readFields();
    if (values == null) return;

    var enteredName = '';
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save goal preset'),
        content: TextField(
          autofocus: true,
          onChanged: (value) => enteredName = value,
          decoration: const InputDecoration(labelText: 'Preset name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, enteredName.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!mounted || name == null || name.isEmpty) return;
    final config = _config(goal, values);

    final saved = await _saveChange((data) {
      final presets = _presets(data);
      presets.removeWhere((preset) => preset['name'] == name);
      presets.add({'name': name, ...config});
      return {...data, 'presets': presets};
    }, 'Preset "$name" saved.');

    if (saved && mounted) setState(() => _selectedPreset = name);
  }

  void _applyPreset(String? name) {
    if (name == null) return;

    for (final preset in _presets(_data)) {
      if (preset['name'] == name) {
        setState(() {
          _selectedPreset = name;
          _fillEditor(_readConfig(preset));
        });
        return;
      }
    }
  }

  Future<void> _deleteSelectedPreset() async {
    final name = _selectedPreset;
    if (name == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete preset?'),
        content: Text('Delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    final deleted = await _saveChange((data) {
      final presets = _presets(data);
      presets.removeWhere((preset) => preset['name'] == name);
      return {...data, 'presets': presets};
    }, 'Preset "$name" deleted.');

    if (deleted && mounted) setState(() => _selectedPreset = null);
  }

  void changeGoal(String value) {
    setState(() {
      goal = value;
      _selectedPreset = null;

      for (final entry in _defaultGoals.entries) {
        fields[entry.key]!.text = entry.value.toString();
      }

      if (value == 'More protein') {
        fields['Daily protein (g)']!.text = '150';
        fields['Weekly protein (g)']!.text = '1050';
      }
    });
  }

  Widget _buildFieldRow(String firstField, [String? secondField]) {
    Widget buildField(String label) => TextField(
      controller: fields[label],
      enabled: _canEdit,
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
    required Color color,
    String unit = 'g',
    String? graceKey,
  }) {
    final name = label.toLowerCase();
    final targets = _today?.goals ?? _activeGoals;
    final target = targets[targetKey] ?? 0.0;
    final eaten = _today?.eaten(name) ?? 0.0;
    final grace = graceKey == null ? 0.0 : targets[graceKey] ?? 0.0;
    final extra = eaten > target ? eaten - target : 0.0;

    final progress = target > 0
        ? (eaten / target).clamp(0.0, 1.0).toDouble()
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                graceKey == null
                    ? 'Goal ${target.toStringAsFixed(0)} $unit'
                    : 'Limit ${target.toStringAsFixed(1)} $unit'
                      '  ·  Grace +${grace.toStringAsFixed(1)} $unit',
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
          const SizedBox(height: 4),
          Text('${eaten.toStringAsFixed(1)} $unit logged'),
          if (graceKey != null) ...[
            Text('Extra: ${extra.toStringAsFixed(1)} $unit'),
            Text('Allowed up to ${(target + grace).toStringAsFixed(0)} $unit'),
          ] else
            Text('Target ${target.toStringAsFixed(0)} $unit'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final presets = _presets(_data);
    final selected = presets.any((preset) => preset['name'] == _selectedPreset)
        ? _selectedPreset
        : null;

    final streak = currentStreak(widget.history, widget.date);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 231, 206),
      appBar: AppBar(title: const Text('My Goals')),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: IgnorePointer(
        child: Semantics(
          label: 'Current streak: $streak ${streak == 1 ? 'day' : 'days'}',
          excludeSemantics: true,
          child: Material(
            color: Colors.white,
            elevation: 2,
            shape: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                '🔥 $streak',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 88),
        children: [
          if (_isLoading)
            const LinearProgressIndicator()
          else if (_loadError != null)
            Text(_loadError!, style: const TextStyle(color: Colors.red)),

          Text(
            'This week ($_currentWeekKey): goals are locked. '
            'You can edit next week any time before it starts ($_nextWeekKey).',
          ),
          const SizedBox(height: 12),
          Text(
            'Current focus: ${_today?.focus ?? currentGoal}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            key: ValueKey(goal),
            initialValue: goal,
            dropdownColor: Colors.white,
            decoration: const InputDecoration(
              labelText: "Next week's goal focus",
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            items: const [
              DropdownMenuItem(value: 'Balanced', child: Text('Balanced')),
              DropdownMenuItem(value: 'More protein', child: Text('More protein')),
            ],
            onChanged: _canEdit
                ? (value) {
                    if (value != null) changeGoal(value);
                  }
                : null,
          ),
          const SizedBox(height: 8),
          const Text('Changes below apply to next week.'),
          const SizedBox(height: 20),

          if (presets.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              key: ValueKey('preset-$selected'),
              initialValue: selected,
              decoration: const InputDecoration(
                labelText: 'Use a saved preset',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final preset in presets)
                  DropdownMenuItem<String>(
                    value: preset['name'] as String,
                    child: Text(preset['name'] as String),
                  ),
              ],
              onChanged: _canEdit ? _applyPreset : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _canEdit && selected != null
                    ? _deleteSelectedPreset
                    : null,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete selected preset'),
              ),
            ),
          ],

          _buildFieldRow('Height (inches)', 'Weight (lbs)'),
          _buildFieldRow('Daily calories'),
          _buildFieldRow('Daily protein (g)'),
          _buildFieldRow('Daily carbs (g)'),
          _buildFieldRow('Daily fat (g)', 'Daily fat grace (g)'),
          _buildFieldRow('Daily sugar (g)', 'Daily sugar grace (g)'),
          _buildFieldRow('Weekly calories', 'Weekly protein (g)'),

          ElevatedButton(
            onPressed: _canEdit ? saveGoals : null,
            child: const Text("Save Next Week's Goals"),
          ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: _canEdit ? saveAsDefault : null,
                child: const Text('Set as Default'),
              ),
              OutlinedButton(
                onPressed: _canEdit ? savePreset : null,
                child: const Text('Save as Preset'),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Text(
            'Today’s recipe nutrition',
            style: Theme.of(context).textTheme.titleMedium,
          ),
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