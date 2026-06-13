import 'dart:typed_data';

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

  // --- Nutrition (per serving) ---
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final int fiberG;
  final int servings;
  final String nutritionNote;

  /// AI-generated photo of the finished dish (PNG/JPEG bytes), if available.
  final Uint8List? imageBytes;

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
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.fiberG = 0,
    this.servings = 1,
    this.nutritionNote = '',
    this.imageBytes,
  });

  /// True once an AI dish photo has been attached.
  bool get hasImage => imageBytes != null && imageBytes!.isNotEmpty;

  /// Returns a copy with [imageBytes] replaced (used after image generation).
  Recipe copyWith({Uint8List? imageBytes}) => Recipe(
        id: id,
        title: title,
        ingredientsUsed: ingredientsUsed,
        missingOptional: missingOptional,
        steps: steps,
        cookTimeMin: cookTimeMin,
        difficulty: difficulty,
        substitutions: substitutions,
        safetyNotes: safetyNotes,
        savedAt: savedAt,
        calories: calories,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        fiberG: fiberG,
        servings: servings,
        nutritionNote: nutritionNote,
        imageBytes: imageBytes ?? this.imageBytes,
      );

  /// True when the model decided the pantry was not enough for a real meal.
  bool get isInsufficient =>
      title.trim().toLowerCase() == 'insufficient ingredients';

  /// True when the AI provided at least some nutrition data.
  bool get hasNutrition =>
      calories > 0 || proteinG > 0 || carbsG > 0 || fatG > 0;

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

    final nutrition = json['nutrition'];
    final n = nutrition is Map ? Map<String, dynamic>.from(nutrition) : json;

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
      calories: asInt(n['calories'] ?? n['calories_per_serving']),
      proteinG: asInt(n['protein_g'] ?? n['protein']),
      carbsG: asInt(n['carbs_g'] ?? n['carbohydrates_g'] ?? n['carbs']),
      fatG: asInt(n['fat_g'] ?? n['fat']),
      fiberG: asInt(n['fiber_g'] ?? n['fiber']),
      servings: asInt(json['servings']) == 0 ? 1 : asInt(json['servings']),
      nutritionNote: (n['nutrition_note'] ?? n['note'] ?? '').toString().trim(),
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
    int intOr(dynamic v, [int fallback = 0]) =>
        v is int ? v : (v is double ? v.round() : fallback);
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
      calories: intOr(map['calories']),
      proteinG: intOr(map['proteinG']),
      carbsG: intOr(map['carbsG']),
      fatG: intOr(map['fatG']),
      fiberG: intOr(map['fiberG']),
      servings: intOr(map['servings'], 1),
      nutritionNote: (map['nutritionNote'] ?? '').toString(),
      imageBytes: map['imageBytes'] is Uint8List
          ? map['imageBytes'] as Uint8List
          : (map['imageBytes'] is List
              ? Uint8List.fromList(
                  (map['imageBytes'] as List).cast<int>())
              : null),
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
      'calories': obj.calories,
      'proteinG': obj.proteinG,
      'carbsG': obj.carbsG,
      'fatG': obj.fatG,
      'fiberG': obj.fiberG,
      'servings': obj.servings,
      'nutritionNote': obj.nutritionNote,
      'imageBytes': obj.imageBytes,
    });
  }
}
