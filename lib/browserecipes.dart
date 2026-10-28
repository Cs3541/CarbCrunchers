import 'package:carb_cruncher/Models/category_model.dart';
import 'package:carb_cruncher/Models/recipe_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import './widgets/browse/category_section.dart';

enum BrowseRecipiesState { loading, loaded, error }

class BrowseRecipiesScreen extends StatefulWidget {
  const BrowseRecipiesScreen({super.key});

  @override
  State<BrowseRecipiesScreen> createState() => _BrowseRecipiesState();
}

class _BrowseRecipiesState extends State<BrowseRecipiesScreen> {
  BrowseRecipiesState _state = BrowseRecipiesState.loading;

  Map<RecipeCategory, List<Recipe>> _recipes = {};
  final Map<RecipeCategory, DocumentSnapshot?> _lastDoc = {};
  final Set<RecipeCategory> _loading = {};
  final Set<RecipeCategory> _done = {};

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    await Future.wait(recipeCategories.map(_loadMore));
    if (!mounted) return;
    setState(() => _state = BrowseRecipiesState.loaded);
  }

  Future<void> _loadMore(RecipeCategory category) async {
    if (_loading.contains(category) || _done.contains(category)) return;
    setState(() => _loading.add(category));

    try {
      final result = await Recipe.fetchRecipesByCategory(
        category,
        after: _lastDoc[category],
      );
      final recipes = result['recipes'] as List<Recipe>;

      if (!mounted) return;
      setState(() {
        _recipes.putIfAbsent(category, () => []).addAll(recipes);
        _lastDoc[category] = result['lastDoc'] as DocumentSnapshot?;
        if (recipes.length < 20) _done.add(category);
        _loading.remove(category);
      });
    } catch (e) {
      debugPrint('Error loading ${category.name}: $e');
    } finally {
      if (mounted) setState(() => _loading.remove(category));
    }
  }

  @override
  Widget build(BuildContext context) {
    // app bar with title "My Recipes" and a back button
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Recipes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _state == BrowseRecipiesState.loading
          ? const Center(child: CircularProgressIndicator())
          : _state == BrowseRecipiesState.error
          ? const Center(child: Text('Failed to load recipes.'))
          : ListView(
              children: [
                for (final category in recipeCategories)
                  RecipeCategorySection(
                    category: category,
                    recipies: _recipes[category] ?? [],
                    isLoading: false,
                    onLoadMore: () => _loadMore(category),
                  ),
              ],
            ),
    );
  }
}
