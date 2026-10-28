import 'package:flutter/material.dart';

import '../models/recipe_model.dart';
import '../recipe_page.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const RecipeCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300, // every card in the row is this wide
      child: Card(
        clipBehavior: Clip.antiAlias, // crops the image to the rounded corners
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecipePage(recipe: recipe),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 110,
                width: double.infinity,
                child: recipe.imageURL == null
                    ? _placeholder()
                    : Image.network(
                        recipe.imageURL!,
                        fit: BoxFit.cover, // fill the box, crop the edges
                        errorBuilder: (_, __, ___) => _placeholder(),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Carbs per serving: ${recipe.nutrition?.carbs ?? 'N/A'}g',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: Colors.grey.shade300,
    alignment: Alignment.center,
    child: const Icon(Icons.restaurant, color: Colors.grey),
  );
}
