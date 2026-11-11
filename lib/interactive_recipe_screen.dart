import 'package:carb_cruncher/models/nutrition_model.dart';
import 'package:flutter/material.dart';

import './models/recipe_model.dart';
import '../widgets/recipies/interative_guide.dart';

class InteractiveRecipeScreen extends StatefulWidget {
  final Recipe recipe;

  const InteractiveRecipeScreen({super.key, required this.recipe});

  @override
  State<InteractiveRecipeScreen> createState() =>
      _InteractiveRecipeScreenState();
}

class _InteractiveRecipeScreenState extends State<InteractiveRecipeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.recipe.title)),
      body: Stack(children: [InteractiveRecipeGuide(recipe: widget.recipe)]),
    );
  }
}
