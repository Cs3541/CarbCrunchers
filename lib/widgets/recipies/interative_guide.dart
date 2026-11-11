import 'dart:async';

import 'package:carb_cruncher/widgets/recipies/timer_chip.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../models/recipe_model.dart';

class InteractiveRecipeGuide extends StatefulWidget {
  final Recipe recipe;
  final int seconds;

  const InteractiveRecipeGuide({
    super.key,
    required this.recipe,
    this.seconds = 600,
  });

  @override
  State<InteractiveRecipeGuide> createState() => _InteractiveRecipeGuideState();
}

class _InteractiveRecipeGuideState extends State<InteractiveRecipeGuide> {
  int currentStep = 0;
  final PageController pageController = PageController();
  final Duration _pageDuration = const Duration(milliseconds: 300);

  // page number
  int currentPage = 0;
  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void onPageChanged(int index) {
    debugPrint('Page changed to $index');
    setState(() {
      currentStep = index;
      debugPrint(
        "Remaining time for step $index: ${widget.recipe.steps?[index].timerSec ?? 500}",
      );
    });
  }

  @override
  void initState() {
    super.initState();
    pageController.addListener(() {
      final page = pageController.page?.round() ?? 0;
      debugPrint('Page controller listener: page = $page');
      currentPage = page;
      //onPageChanged(page);
    });
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.recipe.steps ?? [];

    if (steps.isEmpty) {
      return const Center(child: Text('No steps available'));
    }

    final total = (steps.length + 1);
    final isLast = currentStep == (total - 1);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Step ${currentStep + 1} of $total',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    SmoothPageIndicator(
                      controller: pageController,
                      count: total,
                      effect: const WormEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                        spacing: 4,
                        activeDotColor: Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              TimerChip(
                key: ValueKey(currentPage),
                seconds: currentStep == 0
                    ? (widget.recipe.steps![currentPage].timerSec ?? 500)
                    : 500,
                onDone: () {
                  if (isLast) {
                    Navigator.of(context).pop();
                  } else {
                    pageController.nextPage(
                      duration: _pageDuration,
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ],
          ),

          // Steps
          Expanded(
            child: PageView.builder(
              controller: pageController,
              itemCount: total,
              onPageChanged: (i) => setState(() => currentStep = i),
              itemBuilder: (context, index) {
                // completed all steps
                if (index == steps.length) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'All steps completed!',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  );
                } else {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        steps[index].text,
                        style: const TextStyle(
                          fontSize: 24.0,
                          height: 2,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ),

          // Navigation
          Row(
            children: [
              if (currentStep > 0)
                TextButton.icon(
                  onPressed: () => pageController.previousPage(
                    duration: _pageDuration,
                    curve: Curves.easeInOut,
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                ),
              const Spacer(),
              FloatingActionButton.extended(
                heroTag: null,
                onPressed: () {
                  if (isLast) {
                    Navigator.of(context).pop();
                  } else {
                    pageController.nextPage(
                      duration: _pageDuration,
                      curve: Curves.easeInOut,
                    );
                  }
                },
                icon: Icon(isLast ? Icons.check : Icons.arrow_forward),
                label: Text(isLast ? 'Done' : 'Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
