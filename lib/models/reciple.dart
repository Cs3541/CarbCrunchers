enum RecipeSource { imported, user }

class Ingredient {
  final String raw;
  final double? quantity;
  final String? unit;
  final String? name;

  const Ingredient({required this.raw, this.quantity, this.unit, this.name});

  String get displayName => name ?? raw;

  Map<String, dynamic> toMap() {
    return {'raw': raw, 'quantity': quantity, 'unit': unit, 'name': name};
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      raw: map['raw'] as String,
      quantity: map['quantity'] as double?,
      unit: map['unit'] as String?,
      name: map['name'] as String?,
    );
  }
}

class StepTimer {
  final String? label;
  final Duration duration;
  final Duration? maxDuration;

  const StepTimer({this.label, required this.duration, this.maxDuration});
}

class RecipeStep {
  final String id;
  final String text;
  final Duration? timer;
  final bool isPassive;

  const RecipeStep({
    required this.id,
    required this.text,
    this.timer,
    this.isPassive = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'timer': timer?.inSeconds,
      'isPassive': isPassive,
    };
  }

  factory RecipeStep.fromMap(Map<String, dynamic> map) {
    return RecipeStep(
      id: map['id'] as String,
      text: map['text'] as String,
      timer: map['timer'] != null
          ? Duration(seconds: map['timer'] as int)
          : null,
      isPassive: map['isPassive'] as bool? ?? false,
    );
  }
}

class Recipe {
  final String id;
  final List<String>? keywords;
  final String externalId;
  final RecipeSource source;
  final String? ownerId;
  final String? forked_from_id;
  final String title;
  final List<RecipeStep> steps;
  final List<Ingredient> ingredients;

  Recipe({
    required this.id,
    this.keywords,
    required this.externalId,
    required this.source,
    this.ownerId,
    this.forked_from_id,
    required this.title,
    required this.steps,
    required this.ingredients,
  });

  bool canEdit(String userId) {
    return ownerId == userId;
  }

  Duration get totalTime {
    return steps.fold(Duration.zero, (total, step) {
      if (step.timer != null) {
        return total + step.timer!;
      }
      return total;
    });

    //List<Ingredient> ingredientsFor(RecipeStep )
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'keywords': keywords,
      'externalId': externalId,
      'source': source.toString().split('.').last,
      'ownerId': ownerId,
      'forked_from_id': forked_from_id,
      'title': title,
      'steps': steps.map((step) => step.toMap()).toList(),
      'ingredients': ingredients
          .map((ingredient) => ingredient.toMap())
          .toList(),
    };
  }
}
