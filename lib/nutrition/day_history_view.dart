import 'dart:async';

import 'package:flutter/material.dart';

import 'nutrition_day.dart';
import 'nutrition_store.dart';

class DayHistoryView extends StatefulWidget {
  final Widget Function(History, DateTime) builder;

  const DayHistoryView({
    super.key,
    required this.builder,
  });

  @override
  State<DayHistoryView> createState() => _DayHistoryViewState();
}

class _DayHistoryViewState extends State<DayHistoryView>
    with WidgetsBindingObserver {
  late final stream = NutritionStore().watch();

  Timer? timer;
  DateTime today = DateTime.now();

  void refresh() {
    final now = DateTime.now();

    if (dayId(now) != dayId(today)) {
      setState(() => today = now);
    }

    timer?.cancel();

    final midnight = DateTime(now.year, now.month, now.day + 1);
    timer = Timer(midnight.difference(now), refresh);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<History>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Could not load nutrition goals.'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return widget.builder(snapshot.data!, today);
      },
    );
  }
}