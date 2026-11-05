import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../models/recipe_model.dart';

class RecipeSheetContent extends StatefulWidget {
  final Recipe recipe;

  const RecipeSheetContent({super.key, required this.recipe});

  @override
  State<RecipeSheetContent> createState() => _RecipeSheetContentState();
}

class _RecipeSheetContentState extends State<RecipeSheetContent> {
  final PageController pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PageView(
                  controller: pageController,
                  children:
                      widget.recipe.steps?.map((step) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            step.text,
                            style: const TextStyle(fontSize: 16.0),
                          ),
                        );
                      }).toList() ??
                      [const Text('No steps available')],
                ),
              ),
              SmoothPageIndicator(
                controller: pageController,
                count: widget.recipe.steps?.length ?? 1,
                effect: const WormEffect(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
