class IngredientModel {
  final String id;
  final double? quantity;
  final String? unit;
  final String? name;
  final String raw;

  IngredientModel({
    this.name,
    required this.id,
    this.quantity,
    required this.raw,
    this.unit,
  });

  factory IngredientModel.fromMap(Map<String, dynamic> map) {
    return IngredientModel(
      id: map['id'] as String? ?? '',
      raw: map['raw'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble(),
      unit: map['unit'] as String?,
      name: map['name'] as String?,
    );
  }
}
