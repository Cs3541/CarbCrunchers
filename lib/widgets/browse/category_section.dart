import 'package:carb_cruncher/models/category_model.dart';
import 'package:flutter/material.dart';

import '../recipe_card.dart';
import '../../models/recipe_model.dart';

class RecipeCategorySection extends StatefulWidget {
  final RecipeCategory category;
  final List<Recipe> recipies;
  final bool isLoading;
  final VoidCallback onLoadMore;

  const RecipeCategorySection({
    super.key,
    required this.category,
    required this.recipies,
    required this.isLoading,
    required this.onLoadMore,
  });

  @override
  State<RecipeCategorySection> createState() => _RecipeCategorySectionState();
}

class _RecipeCategorySectionState extends State<RecipeCategorySection> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.position.pixels >=
          _controller.position.maxScrollExtent - 200) {
        widget.onLoadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipes = widget.recipies;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            widget.category.name,
            style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 200.0, // Adjust the height as needed
          child: ListView.builder(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            itemCount: recipes.length + (widget.isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < recipes.length) {
                final recipe = recipes[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: RecipeCard(recipe: recipe),
                );
              } else {
                return const Center(
                  child: SizedBox(
                    width: 24.0,
                    height: 24.0,
                    child: CircularProgressIndicator(),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
