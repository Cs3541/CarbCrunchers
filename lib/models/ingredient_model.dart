
class IngredientModel {

  final String id;
  final String name;
  final double quantity;
  final String raw;
  final String unit;

  IngredientModel({
    required this.name,
    required this.id,
    required this.quantity,
    required this.raw,
    required this.unit,
  });
}