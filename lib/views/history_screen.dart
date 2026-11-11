import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

enum _HistoryPeriod { week, month, year }

class _HistoryScreenState extends State<HistoryScreen> {
  static const _backgroundColor = Color.fromARGB(255, 247, 231, 206);
  static const _primaryColor = Color(0xFF1F5DA8);

  _HistoryPeriod _period = _HistoryPeriod.week;

  List<DateTime> get _axisDates {
    final today = DateTime.now();

    switch (_period) {
      case _HistoryPeriod.week:
        return List.generate(
          7,
          (index) => today.subtract(Duration(days: 6 - index)),
        );
      case _HistoryPeriod.month:
        return [29, 22, 15, 8, 0]
            .map((daysAgo) => today.subtract(Duration(days: daysAgo)))
            .toList();
      case _HistoryPeriod.year:
        return List.generate(
          7,
          (index) => DateTime(
            today.year,
            today.month - 11 + (11 * index / 6).round(),
          ),
        );
    }
  }

  String _formatDate(DateTime date) {
    if (_period == _HistoryPeriod.year) {
      const monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return monthNames[date.month - 1];
    }

    return '${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final labels = _axisDates.map(_formatDate).toList();

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: _backgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
            segments: const [
              ButtonSegment(
                value: _HistoryPeriod.week,
                label: Text('1 week'),
              ),
              ButtonSegment(
                value: _HistoryPeriod.month,
                label: Text('1 month'),
              ),
              ButtonSegment(
                value: _HistoryPeriod.year,
                label: Text('1 year'),
              ),
            ],
            selected: {_period},
            onSelectionChanged: (selection) {
              setState(() => _period = selection.first);
            },
          ),
          const SizedBox(height: 20),
          Container(
            height: 320,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _primaryColor.withOpacity(0.16)),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HistoryGridPainter(
                      labels: labels,
                      gridColor: _primaryColor.withOpacity(0.14),
                      labelColor: Colors.black54,
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    'No history data yet',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryGridPainter extends CustomPainter {
  const _HistoryGridPainter({
    required this.labels,
    required this.gridColor,
    required this.labelColor,
  });

  final List<String> labels;
  final Color gridColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    const leftInset = 8.0;
    const rightInset = 8.0;
    const topInset = 8.0;
    const bottomInset = 28.0;
    final plotWidth = size.width - leftInset - rightInset;
    final plotHeight = size.height - topInset - bottomInset;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var index = 0; index <= 4; index++) {
      final y = topInset + plotHeight * index / 4;
      canvas.drawLine(
        Offset(leftInset, y),
        Offset(size.width - rightInset, y),
        gridPaint,
      );
    }

    for (var index = 0; index < labels.length; index++) {
      final x = leftInset + plotWidth * index / (labels.length - 1);
      canvas.drawLine(
        Offset(x, topInset),
        Offset(x, topInset + plotHeight),
        gridPaint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[index],
          style: TextStyle(color: labelColor, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final labelX = (x - textPainter.width / 2)
          .clamp(leftInset, size.width - rightInset - textPainter.width)
          .toDouble();
      textPainter.paint(
        canvas,
        Offset(labelX, size.height - textPainter.height),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HistoryGridPainter oldDelegate) {
    return oldDelegate.labels != labels ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.labelColor != labelColor;
  }
}
