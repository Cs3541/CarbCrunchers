import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../nutrition/nutrition_day.dart';
import '../nutrition/nutrition_store.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.historyStream});

  final Stream<History>? historyStream;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

enum _HistoryPeriod {
  week('1 week'),
  month('1 month'),
  year('1 year');

  const _HistoryPeriod(this.label);

  final String label;
}

enum _HistoryMetric {
  calories('Calories', 'calories', 'Daily calories', 'kcal'),
  protein('Protein', 'protein', 'Daily protein (g)', 'g'),
  carbs('Carbs', 'carbs', 'Daily carbs (g)', 'g'),
  sugar('Sugar', 'sugar', 'Daily sugar (g)', 'g'),
  fat('Fat', 'fat', 'Daily fat (g)', 'g');

  const _HistoryMetric(this.label, this.nutrient, this.goalKey, this.unit);

  final String label;
  final String nutrient;
  final String goalKey;
  final String unit;
}

class _HistorySummary {
  const _HistorySummary({
    required this.minimum,
    required this.maximum,
    required this.average,
    required this.goal,
    required this.dayCount,
  });

  final double minimum;
  final double maximum;
  final double average;
  final double goal;
  final int dayCount;
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _backgroundColor = Color.fromARGB(255, 247, 231, 206);
  static const _primaryColor = Color(0xFF1F5DA8);
  static const _goalColor = Color(0xFFE76F00);

  late final Stream<History> _history =
      widget.historyStream ?? NutritionStore().watch();

  _HistoryPeriod _period = _HistoryPeriod.week;
  _HistoryMetric _metric = _HistoryMetric.calories;

  _HistorySummary? _summarize(History history, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final start = switch (_period) {
      _HistoryPeriod.week => today.subtract(const Duration(days: 6)),
      _HistoryPeriod.month => today.subtract(const Duration(days: 29)),
      _HistoryPeriod.year => DateTime(today.year, today.month - 11),
    };
    final end = today.add(const Duration(days: 1));
    final days = history.entries
        .where((entry) {
          final date = DateTime.tryParse(entry.key);
          return date != null &&
              !date.isBefore(start) &&
              date.isBefore(end) &&
              entry.value.goals[_metric.goalKey] != null;
        })
        .map((entry) => entry.value)
        .toList();

    if (days.isEmpty) return null;

    final intakes = days.map((day) => day.eaten(_metric.nutrient)).toList();
    final goals = days
        .map((day) => day.goals[_metric.goalKey]!)
        .toList();

    return _HistorySummary(
      minimum: intakes.reduce(math.min),
      maximum: intakes.reduce(math.max),
      average: intakes.reduce((total, value) => total + value) / intakes.length,
      goal: goals.reduce((total, value) => total + value) / goals.length,
      dayCount: days.length,
    );
  }

  double _maxY(_HistorySummary summary) {
    final maxValue = math.max(summary.maximum, summary.goal);
    return maxValue == 0 ? 1 : maxValue * 1.15;
  }

  String _formatValue(double value) =>
      value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: _backgroundColor,
      ),
      body: StreamBuilder<History>(
        stream: _history,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load history data. Please try again.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final summary = _summarize(snapshot.data!, DateTime.now());

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<_HistoryMetric>(
                  key: const ValueKey('history-metric-selector'),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      return states.contains(WidgetState.selected)
                          ? _primaryColor
                          : Colors.white;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      return states.contains(WidgetState.selected)
                          ? Colors.white
                          : _primaryColor;
                    }),
                    side: WidgetStateProperty.resolveWith((states) {
                      return BorderSide(
                        color: states.contains(WidgetState.selected)
                            ? _primaryColor
                            : _primaryColor.withOpacity(0.35),
                      );
                    }),
                  ),
                  segments: [
                    for (final metric in _HistoryMetric.values)
                      ButtonSegment(
                        value: metric,
                        label: Text(metric.label),
                      ),
                  ],
                  selected: {_metric},
                  onSelectionChanged: (selection) {
                    setState(() => _metric = selection.first);
                  },
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<_HistoryPeriod>(
                key: const ValueKey('history-range-selector'),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.selected)
                        ? _primaryColor
                        : Colors.white;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.selected)
                        ? Colors.white
                        : _primaryColor;
                  }),
                  side: WidgetStateProperty.resolveWith((states) {
                    return BorderSide(
                      color: states.contains(WidgetState.selected)
                          ? _primaryColor
                          : _primaryColor.withOpacity(0.35),
                    );
                  }),
                ),
                segments: [
                  for (final period in _HistoryPeriod.values)
                    ButtonSegment(value: period, label: Text(period.label)),
                ],
                selected: {_period},
                onSelectionChanged: (selection) {
                  setState(() => _period = selection.first);
                },
              ),
              const SizedBox(height: 20),
              Text(
                '${_metric.label} (${_metric.unit}) · ${_period.label}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (summary != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Daily values from ${summary.dayCount} '
                  '${summary.dayCount == 1 ? 'day' : 'days'} '
                  'with this goal recorded',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  _LegendItem(
                    color: _primaryColor,
                    label: 'Min / Max / Avg',
                  ),
                  const SizedBox(width: 20),
                  _LegendItem(color: _goalColor, label: 'Daily goal'),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 320,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _primaryColor.withOpacity(0.16)),
                ),
                child: summary == null
                    ? const Center(
                        child: Text(
                          'No history data yet',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : Semantics(
                        label:
                            'Minimum ${_formatValue(summary.minimum)} '
                            '${_metric.unit}; maximum '
                            '${_formatValue(summary.maximum)} '
                            '${_metric.unit}; average '
                            '${_formatValue(summary.average)} '
                            '${_metric.unit}; average daily goal '
                            '${_formatValue(summary.goal)} '
                            '${_metric.unit}',
                        child: ExcludeSemantics(
                          child: CustomPaint(
                            key: const ValueKey('history-summary-chart'),
                            painter: _HistoryBarPainter(
                              summary: summary,
                              maxY: _maxY(summary),
                              gridColor: _primaryColor.withOpacity(0.14),
                              labelColor: Colors.black54,
                              intakeColor: _primaryColor,
                              goalColor: _goalColor,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _HistoryBarPainter extends CustomPainter {
  const _HistoryBarPainter({
    required this.summary,
    required this.maxY,
    required this.gridColor,
    required this.labelColor,
    required this.intakeColor,
    required this.goalColor,
  });

  final _HistorySummary summary;
  final double maxY;
  final Color gridColor;
  final Color labelColor;
  final Color intakeColor;
  final Color goalColor;

  static const _labels = ['Min', 'Max', 'Avg', 'Goal'];

  @override
  void paint(Canvas canvas, Size size) {
    const leftInset = 42.0;
    const rightInset = 8.0;
    const topInset = 24.0;
    const bottomInset = 28.0;
    final plotWidth = size.width - leftInset - rightInset;
    final plotHeight = size.height - topInset - bottomInset;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var index = 0; index <= 4; index++) {
      final fraction = index / 4;
      final y = topInset + plotHeight * fraction;
      canvas.drawLine(
        Offset(leftInset, y),
        Offset(size.width - rightInset, y),
        gridPaint,
      );
      final value = maxY * (1 - fraction);
      _paintText(
        canvas,
        value.toStringAsFixed(maxY < 10 ? 1 : 0),
        Offset(0, y - 6),
        labelColor,
      );
    }

    final values = [
      summary.minimum,
      summary.maximum,
      summary.average,
      summary.goal,
    ];
    final barWidth = math.min(44.0, plotWidth / 8);
    final baseline = topInset + plotHeight;

    for (var index = 0; index < values.length; index++) {
      final centerX = leftInset + plotWidth * (index + 0.5) / values.length;
      final barHeight = plotHeight * values[index] / maxY;
      final rect = Rect.fromLTWH(
        centerX - barWidth / 2,
        baseline - barHeight,
        barWidth,
        barHeight,
      );
      final paint = Paint()
        ..color = index == values.length - 1 ? goalColor : intakeColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint,
      );

      final valueLabel = values[index] == values[index].roundToDouble()
          ? values[index].toStringAsFixed(0)
          : values[index].toStringAsFixed(1);
      _paintCenteredText(
        canvas,
        valueLabel,
        Offset(centerX, math.max(0, rect.top - 16)),
        labelColor,
      );
      _paintCenteredText(
        canvas,
        _labels[index],
        Offset(centerX, size.height - 18),
        labelColor,
      );
    }
  }

  void _paintText(Canvas canvas, String text, Offset offset, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  void _paintCenteredText(
    Canvas canvas,
    String text,
    Offset center,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(center.dx - painter.width / 2, center.dy));
  }

  @override
  bool shouldRepaint(covariant _HistoryBarPainter oldDelegate) {
    return oldDelegate.summary != summary ||
        oldDelegate.maxY != maxY ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.intakeColor != intakeColor ||
        oldDelegate.goalColor != goalColor;
  }
}
