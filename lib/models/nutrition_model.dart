class Nutrition {
  final double calories;
  final double carbs;
  final double fat;
  final double fiber;
  final double protein;
  final double sodiumMg;
  final double sugar;

  Nutrition({
    required this.calories,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.protein,
    required this.sodiumMg,
    required this.sugar,
  });

  factory Nutrition.fromMap(Map<String, dynamic> map) {
    double read(String key) => (map[key] as num?)?.toDouble() ?? 0;

    return Nutrition(
      calories: read('calories'),
      carbs: read('carbs'),
      fat: read('fat'),
      fiber: read('fiber'),
      protein: read('protein'),
      sodiumMg: read('sodium_mg'),
      sugar: read('sugar'),
    );
  }
}
