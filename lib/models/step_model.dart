
class StepModel {

  final List<int> ingredientIds;
  final bool is_passive;
  final String text;
  final int timer;

  StepModel({
    required this.ingredientIds,
    required this.is_passive,
    required this.text,
    required this.timer,
  });
}