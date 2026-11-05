import 'package:flutter/material.dart';

import '../../models/recipe_model.dart';

class InteractiveRecipeGuideSheet extends StatefulWidget {
  final Recipe recipe;

  const InteractiveRecipeGuideSheet({super.key, required this.recipe});

  @override
  State<InteractiveRecipeGuideSheet> createState() =>
      _InteractiveRecipeGuideSheetState();
}

class _InteractiveRecipeGuideSheetState
    extends State<InteractiveRecipeGuideSheet> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.recipe.title,
                style: const TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
