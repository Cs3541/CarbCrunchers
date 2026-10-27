//import 'package:firebase_auth.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';

class SavedRecipe {
    final String name;
    final String? description;
    final int? calories;
    final List<String>? ingredients;
    final List<String>? steps;

    SavedRecipe({
        required this.name,
        this.description,
        this.calories,
        this.ingredients,
        this.steps,
    });

    static Future<void> createRecipe(String name, String? description)

}