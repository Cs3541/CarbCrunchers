import 'dart:async';

import '../models/shopping_list_model.dart';
import '../models/meal_plan_model.dart';

class ShoppingListPresenter {
  final StreamController<List<ShoppingListModel>> _listsController =
      StreamController<List<ShoppingListModel>>.broadcast();

  Stream<List<ShoppingListModel>> get listsStream => _listsController.stream;

  Future<void> fetchShoppingLists() async {
    final lists = await ShoppingListModel.fetchListsForUser();
    if (!_listsController.isClosed) {
      _listsController.sink.add(lists);
    }
  }

  Future<List<PlannedMeal>> fetchSelectableMeals() async {
    final meals = await PlannedMeal.fetchMealsForUser();

  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);

  // Keep only meals scheduled for today or later
  final upcomingMeals = meals
      .where((meal) => !meal.date.isBefore(startOfToday))
      .toList();

  // Sort chronologically so today's meals appear first
  upcomingMeals.sort((a, b) => a.date.compareTo(b.date));
  return upcomingMeals;
  }

  Future<ShoppingListModel?> createListFromMeals({
    required String title,
    required List<PlannedMeal> selectedMeals,
  }) async {
    final created = await ShoppingListModel.createFromMeals(
      title: title,
      selectedMeals: selectedMeals,
    );
    await fetchShoppingLists();
    return created;
  }

  Future<void> saveListItems(
    String listId,
    List<ShoppingListItem> items,
  ) async {
    await ShoppingListModel.updateItems(listId, items);
    await fetchShoppingLists();
  }

  Future<void> deleteShoppingList(String listId) async {
    await ShoppingListModel.deleteList(listId);
    await fetchShoppingLists();
  }

  void dispose() {
    _listsController.close();
  }
}