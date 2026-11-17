import 'package:carb_cruncher/models/recipe_model.dart';
import 'package:flutter/material.dart';

class RecipeSearchDelegate extends SearchDelegate<Recipe?> {
  RecipeSearchDelegate() : super(searchFieldLabel: 'Search recipes');

  String? _cachedQuery;
  Future<List<Recipe>>? _cachedFuture;

  Future<List<Recipe>> _search(String q) {
    if (q == _cachedQuery && _cachedFuture != null) return _cachedFuture!;
    _cachedQuery = q;
    _cachedFuture = () async {
      await Future.delayed(const Duration(milliseconds: 300));
      if (q != query.trim()) return const <Recipe>[]; // user kept typing; skip
      return Recipe.searchRecipies(q);
    }();
    return _cachedFuture!;
  }

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
  ];

  @override
  Widget buildSuggestions(BuildContext context) => _buildResults(context);

  @override
  Widget buildResults(BuildContext context) => _buildResults(context);

  Widget _buildResults(BuildContext context) {
    final q = query.trim();
    if (q.isEmpty) {
      return const Center(child: Text('Start typing to search recipes'));
    }

    return FutureBuilder<List<Recipe>>(
      future: _search(q),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return const Center(child: Text('Search failed.'));
        }
        final results = snap.data ?? [];
        if (results.isEmpty) {
          return Center(child: Text('No recipes match "$q"'));
        }
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, i) {
            final r = results[i];
            return ListTile(
              title: Text(r.title),
              onTap: () => close(context, r),
            );
          },
        );
      },
    );
  }
}
