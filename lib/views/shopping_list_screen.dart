import 'package:flutter/material.dart';
import '../models/shopping_list_model.dart';
import '../presenters/shopping_list_presenter.dart';
import '../models/meal_plan_model.dart';


class ShoppingListsScreen extends StatefulWidget {
  const ShoppingListsScreen({super.key});

  @override
  State<ShoppingListsScreen> createState() => _ShoppingListsScreenState();
}

class _ShoppingListsScreenState extends State<ShoppingListsScreen> {
  late final ShoppingListPresenter _presenter;

  @override
  void initState() {
    super.initState();
    _presenter = ShoppingListPresenter();
    _presenter.fetchShoppingLists();
  }

  @override
  void dispose() {
    _presenter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 231, 206),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F5DA8),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Shopping Lists',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F5DA8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text(
                  'Create New List from Meal Plan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final newList = await Navigator.push<ShoppingListModel>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CreateShoppingListScreen(presenter: _presenter),
                    ),
                  );
                  if (newList != null && mounted) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShoppingListDetailScreen(
                          shoppingList: newList,
                          presenter: _presenter,
                        ),
                      ),
                    );
                    _presenter.fetchShoppingLists();
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ShoppingListModel>>(
              stream: _presenter.listsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final lists = snapshot.data ?? [];
                if (lists.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'No shopping lists yet.\nTap the button above to generate one from your meal plan!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: lists.length,
                  itemBuilder: (context, index) {
                    final list = lists[index];
                    final checkedCount =
                        list.items.where((item) => item.isChecked).length;
                    final totalCount = list.items.length;
                    final isDone = totalCount > 0 && checkedCount == totalCount;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDone
                              ? Colors.green
                              : const Color(0xFFB45309).withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: isDone
                              ? Colors.green.withOpacity(0.15)
                              : const Color(0xFF1F5DA8).withOpacity(0.12),
                          child: Icon(
                            isDone ? Icons.check_circle : Icons.receipt_long,
                            color: isDone
                                ? Colors.green
                                : const Color(0xFF1F5DA8),
                          ),
                        ),
                        title: Text(
                          list.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${list.createdAt.month}/${list.createdAt.day}/${list.createdAt.year}  •  $checkedCount / $totalCount items checked',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () =>
                              _presenter.deleteShoppingList(list.id),
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShoppingListDetailScreen(
                                shoppingList: list,
                                presenter: _presenter,
                              ),
                            ),
                          );
                          _presenter.fetchShoppingLists();
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class CreateShoppingListScreen extends StatefulWidget {
  final ShoppingListPresenter presenter;

  const CreateShoppingListScreen({super.key, required this.presenter});

  @override
  State<CreateShoppingListScreen> createState() =>
      _CreateShoppingListScreenState();
}

class _CreateShoppingListScreenState extends State<CreateShoppingListScreen> {
  final TextEditingController _titleController = TextEditingController();
  List<PlannedMeal> _meals = [];
  final Set<String> _selectedMealIds = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _titleController.text = 'Groceries (${now.month}/${now.day})';
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    final meals = await widget.presenter.fetchSelectableMeals();
    if (!mounted) return;
    setState(() {
      _meals = meals;
      _isLoading = false;
    });
  }

  void _selectThisWeek() {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday % 7));
    final weekEnd = weekStart.add(const Duration(days: 7));

    setState(() {
      _selectedMealIds.clear();
      for (final meal in _meals) {
        if (!meal.date.isBefore(weekStart) && meal.date.isBefore(weekEnd)) {
          _selectedMealIds.add(meal.id);
        }
      }
    });
  }

  Future<void> _generateList() async {
    if (_selectedMealIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one meal first')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final selectedMeals =
        _meals.where((m) => _selectedMealIds.contains(m.id)).toList();
    final title = _titleController.text.trim().isEmpty
        ? 'Shopping List'
        : _titleController.text.trim();

    final createdList = await widget.presenter.createListFromMeals(
      title: title,
      selectedMeals: selectedMeals,
    );

    if (!mounted) return;
    Navigator.pop(context, createdList);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 231, 206),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F5DA8),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Select Meals',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _meals.isEmpty ? null : _selectThisWeek,
            child: const Text(
              'This Week',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'List Name',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Text(
                  'Tap meals to include their ingredients:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selectedMealIds.length} selected',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F5DA8),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _meals.isEmpty
                    ? const Center(
                        child: Text(
                          'No scheduled meals found in your Meal Plan.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _meals.length,
                        itemBuilder: (context, index) {
                          final meal = _meals[index];
                          final isSelected = _selectedMealIds.contains(meal.id);
                          final dayStr = dayNames[meal.date.weekday % 7];
                          final dateStr =
                              '$dayStr, ${meal.date.month}/${meal.date.day}';
                          final ingredientCount =
                              meal.recipe?.ingredients.length ?? 0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            color: isSelected
                                ? const Color(0xFF1F5DA8).withOpacity(0.1)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF1F5DA8)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: CheckboxListTile(
                              activeColor: const Color(0xFF1F5DA8),
                              value: isSelected,
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedMealIds.add(meal.id);
                                  } else {
                                    _selectedMealIds.remove(meal.id);
                                  }
                                });
                              },
                              title: Text(
                                meal.recipe?.title ?? 'Unknown Meal',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '$dateStr • ${meal.mealType} ($ingredientCount ingredients)',
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F5DA8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isSaving ? null : _generateList,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Build List (${_selectedMealIds.length} Meals)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class ShoppingListDetailScreen extends StatefulWidget {
  final ShoppingListModel shoppingList;
  final ShoppingListPresenter presenter;

  const ShoppingListDetailScreen({
    super.key,
    required this.shoppingList,
    required this.presenter,
  });

  @override
  State<ShoppingListDetailScreen> createState() =>
      _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState extends State<ShoppingListDetailScreen> {
  late List<ShoppingListItem> _items;
  final TextEditingController _customItemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = List<ShoppingListItem>.from(widget.shoppingList.items);
  }

  Future<void> _toggleItem(int index, bool? value) async {
    setState(() {
      _items[index].isChecked = value ?? false;
    });
    await widget.presenter.saveListItems(widget.shoppingList.id, _items);
  }

  Future<void> _addCustomItem() async {
    final text = _customItemController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _items.insert(
        0,
        ShoppingListItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: text,
          raw: text,
        ),
      );
      _customItemController.clear();
    });

    await widget.presenter.saveListItems(widget.shoppingList.id, _items);
  }

  Future<void> _removeItem(int index) async {
    setState(() {
      _items.removeAt(index);
    });
    await widget.presenter.saveListItems(widget.shoppingList.id, _items);
  }

  @override
  void dispose() {
    _customItemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 231, 206),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F5DA8),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.shoppingList.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Quick-add bar for extra non-recipe items (e.g., "Paper towels")
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customItemController,
                    onSubmitted: (_) => _addCustomItem(),
                    decoration: InputDecoration(
                      hintText: 'Add extra item...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F5DA8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _addCustomItem,
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? const Center(
                    child: Text(
                      'This shopping list is empty.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _removeItem(index),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: item.isChecked
                              ? Colors.white.withOpacity(0.65)
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CheckboxListTile(
                            activeColor: const Color(0xFF1F5DA8),
                            controlAffinity: ListTileControlAffinity.leading,
                            value: item.isChecked,
                            onChanged: (val) => _toggleItem(index, val),
                            title: Text(
                              item.displayLabel,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                decoration: item.isChecked
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: item.isChecked
                                    ? Colors.grey
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}