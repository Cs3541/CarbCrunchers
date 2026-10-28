class StepModel {
  final List<String> ingredientIds;
  final bool is_passive;
  final String text;
  final int? timerSec;

  StepModel({
    required this.text,
    this.timerSec,
    this.ingredientIds = const [],
    this.is_passive = false,
  });

  factory StepModel.fromMap(Map<String, dynamic> map) {
    return StepModel(
      text: map['text'] as String? ?? '',
      is_passive: map['is_passive'] as bool? ?? false,
      timerSec: (map['timer_sec'] as num?)?.toInt(),
      ingredientIds: (map['ingredient_ids'] as List? ?? []).cast<String>(),
    );
  }
}
