import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'meal_plan_model.dart';

class ShoppingListItem {
  final String id;
  final String name;
  final double? quantity;
  final String? unit;
  final String raw;
  bool isChecked;

  ShoppingListItem({
    required this.id,
    required this.name,
    this.quantity,
    this.unit,
    required this.raw,
    this.isChecked = false,
  });

  /// Formats the item
  String get displayLabel {
    if (name.trim().isEmpty) return raw;
    final parts = <String>[];
    if (quantity != null && quantity! > 0) {
      // Remove trailing ".0" for whole numbers
      final qStr = quantity! % 1 == 0
          ? quantity!.toInt().toString()
          : quantity!.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
      parts.add(qStr);
    }
    if (unit != null && unit!.trim().isNotEmpty) {
      parts.add(unit!.trim());
    }
    parts.add(name.trim());
    return parts.join(' ');
  }

  factory ShoppingListItem.fromMap(Map<String, dynamic> map) {
    return ShoppingListItem(
      id: map['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: map['name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble(),
      unit: map['unit'] as String?,
      raw: map['raw'] as String? ?? '',
      isChecked: map['isChecked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'raw': raw,
      'isChecked': isChecked,
    };
  }
}

class ShoppingListModel {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<ShoppingListItem> items;

  ShoppingListModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.items,
  });

  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Fetch all shopping lists for the logged-in user (newest first)
  static Future<List<ShoppingListModel>> fetchListsForUser() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final snapshot = await _firestore
        .collection('shopping_lists')
        .where('userId', isEqualTo: userId)
        .get();

    final lists = snapshot.docs.map((doc) {
      final data = doc.data();
      final rawItems = data['items'] as List<dynamic>? ?? [];
      return ShoppingListModel(
        id: doc.id,
        title: data['title'] as String? ?? 'Shopping List',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        items: rawItems
            .map((e) => ShoppingListItem.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
      );
    }).toList();

    lists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return lists;
  }

  /// Combines ingredients from selected meals and saves a new list to Firestore
  static Future<ShoppingListModel?> createFromMeals({
    required String title,
    required List<PlannedMeal> selectedMeals,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    final Map<String, ShoppingListItem> merged = {};
    int counter = 0;

    for (final meal in selectedMeals) {
      final recipe = meal.recipe;
      if (recipe == null) continue;

      for (final ing in recipe.ingredients) {
        final normName = (ing.name ?? '').trim().toLowerCase();
        final normUnit = (ing.unit ?? '').trim().toLowerCase();

        // Key by name + unit if structured, otherwise by raw string
        final key = normName.isNotEmpty
            ? '$normName|$normUnit'
            : ing.raw.trim().toLowerCase();

        if (key.isEmpty) continue;

        if (merged.containsKey(key)) {
          final existing = merged[key]!;
          final updatedQty = (existing.quantity != null || ing.quantity != null)
              ? (existing.quantity ?? 0) + (ing.quantity ?? 0)
              : null;

          merged[key] = ShoppingListItem(
            id: existing.id,
            name: existing.name,
            quantity: updatedQty,
            unit: existing.unit,
            raw: '${existing.raw} + ${ing.raw}',
          );
        } else {
          counter++;
          merged[key] = ShoppingListItem(
            id: '${DateTime.now().millisecondsSinceEpoch}_$counter',
            name: ing.name ?? '',
            quantity: ing.quantity,
            unit: ing.unit,
            raw: ing.raw,
          );
        }
      }
    }

    final itemsList = merged.values.toList();
    final now = DateTime.now();

    final docRef = await _firestore.collection('shopping_lists').add({
      'userId': userId,
      'title': title,
      'createdAt': Timestamp.fromDate(now),
      'items': itemsList.map((e) => e.toMap()).toList(),
    });

    return ShoppingListModel(
      id: docRef.id,
      title: title,
      createdAt: now,
      items: itemsList,
    );
  }

  /// Updates the items array in Firestore
  static Future<void> updateItems(
    String listId,
    List<ShoppingListItem> items,
  ) async {
    await _firestore.collection('shopping_lists').doc(listId).update({
      'items': items.map((e) => e.toMap()).toList(),
    });
  }

  /// Deletes a shopping list
  static Future<void> deleteList(String listId) async {
    await _firestore.collection('shopping_lists').doc(listId).delete();
  }
}