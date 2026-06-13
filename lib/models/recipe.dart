import 'package:hive/hive.dart';

/// A recipe produced by the AI, optionally persisted to Hive.
///
/// The Hive [TypeAdapter] is written by hand (see [RecipeAdapter]) so the
/// project does not need build_runner / code generation to compile.
class Recipe {
  final String id;
  final String title;
  final List<String> ingredientsUsed;
  final List<String> missingOptional;
  final List<String> steps;
  final int cookTimeMin;
  final String difficulty;
  final List<String> substitutions;
  final String safetyNotes;
  final DateTime savedAt;

  Recipe({
    required this.id,
    required this.title,
    required this.ingredientsUsed,
    required this.missingOptional,
    required this.steps,
    required this.cookTimeMin,
    required this.difficulty,
    required this.substitutions,
    required this.safetyNotes,
    required this.savedAt,
  });

  /// True when the model decided the pantry was not enough for a real meal.
  bool get isInsufficient =>
      title.trim().toLowerCase() == 'insufficient ingredients';

  /// Builds a [Recipe] from the JSON object returned by Gemini.
  factory Recipe.fromAi(Map<String, dynamic> json) {
    List<String> asStringList(dynamic value) {
      if (value is List) {
        return value
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      }
      if (value is String && value.trim().isNotEmpty) return [value.trim()];
      return <String>[];
    }

    int asInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return 0;
    }

    return Recipe(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: (json['title'] ?? 'Untitled recipe').toString().trim(),
      ingredientsUsed: asStringList(json['ingredients_used']),
      missingOptional: asStringList(json['missing_optional']),
      steps: asStringList(json['steps']),
      cookTimeMin: asInt(json['cook_time_min']),
      difficulty: (json['difficulty'] ?? 'Unknown').toString().trim(),
      substitutions: asStringList(json['substitutions']),
      safetyNotes: (json['safety_notes'] ?? '').toString().trim(),
      savedAt: DateTime.now(),
    );
  }
}

/// Hand-written Hive adapter. Persists the recipe as a single map record so the
/// schema is easy to evolve without regenerating code.
class RecipeAdapter extends TypeAdapter<Recipe> {
  @override
  final int typeId = 0;

  @override
  Recipe read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.readMap());
    List<String> list(dynamic v) =>
        (v as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    return Recipe(
      id: map['id'] as String,
      title: map['title'] as String,
      ingredientsUsed: list(map['ingredientsUsed']),
      missingOptional: list(map['missingOptional']),
      steps: list(map['steps']),
      cookTimeMin: map['cookTimeMin'] as int,
      difficulty: map['difficulty'] as String,
      substitutions: list(map['substitutions']),
      safetyNotes: map['safetyNotes'] as String,
      savedAt: DateTime.fromMillisecondsSinceEpoch(map['savedAt'] as int),
    );
  }

  @override
  void write(BinaryWriter writer, Recipe obj) {
    writer.writeMap(<String, dynamic>{
      'id': obj.id,
      'title': obj.title,
      'ingredientsUsed': obj.ingredientsUsed,
      'missingOptional': obj.missingOptional,
      'steps': obj.steps,
      'cookTimeMin': obj.cookTimeMin,
      'difficulty': obj.difficulty,
      'substitutions': obj.substitutions,
      'safetyNotes': obj.safetyNotes,
      'savedAt': obj.savedAt.millisecondsSinceEpoch,
    });
  }
}
