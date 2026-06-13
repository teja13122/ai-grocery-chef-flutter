import 'package:flutter/foundation.dart';

import '../services/gemini_service.dart';

/// Diet options offered on the Pantry screen.
enum Diet { any, vegetarian, vegan, nonVeg }

extension DietLabel on Diet {
  String get label => switch (this) {
        Diet.any => 'Any',
        Diet.vegetarian => 'Vegetarian',
        Diet.vegan => 'Vegan',
        Diet.nonVeg => 'Non-veg',
      };

  /// Empty for [Diet.any] so the prompt says "no restriction".
  String get promptValue => this == Diet.any ? '' : label;
}

/// Holds the user's pantry input: ingredients, dietary preferences and an
/// optional pantry photo. Shared across screens via Provider.
class PantryProvider extends ChangeNotifier {
  final GeminiService _gemini = GeminiService();

  final List<String> _ingredients = [];
  Diet _diet = Diet.any;
  String _allergies = '';
  int _maxCookTimeMin = 30;

  // Target calories per serving (range the user wants the meal to fall in).
  int _minCalories = 300;
  int _maxCalories = 700;

  Uint8List? _photoBytes;
  String? _photoMimeType;

  bool _isDetecting = false;
  String? _detectError;
  List<String> _detectedItems = [];

  List<String> get ingredients => List.unmodifiable(_ingredients);
  Diet get diet => _diet;
  String get allergies => _allergies;
  int get maxCookTimeMin => _maxCookTimeMin;
  int get minCalories => _minCalories;
  int get maxCalories => _maxCalories;
  Uint8List? get photoBytes => _photoBytes;
  String? get photoMimeType => _photoMimeType;
  bool get hasPhoto => _photoBytes != null;

  /// True while the AI is identifying items in the most recent photo.
  bool get isDetecting => _isDetecting;

  /// Error from the last photo identification attempt, if any.
  String? get detectError => _detectError;

  /// Ingredient names found in the most recent photo.
  List<String> get detectedItems => List.unmodifiable(_detectedItems);

  bool get canGenerate => _ingredients.isNotEmpty || hasPhoto;

  void addIngredient(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return;
    final exists =
        _ingredients.any((e) => e.toLowerCase() == clean.toLowerCase());
    if (exists) return;
    _ingredients.add(clean);
    notifyListeners();
  }

  void removeIngredient(String value) {
    _ingredients.remove(value);
    notifyListeners();
  }

  void setDiet(Diet diet) {
    _diet = diet;
    notifyListeners();
  }

  void setAllergies(String value) {
    _allergies = value.trim();
    notifyListeners();
  }

  void setMaxCookTime(int minutes) {
    _maxCookTimeMin = minutes;
    notifyListeners();
  }

  void setCalorieRange(int min, int max) {
    _minCalories = min;
    _maxCalories = max;
    notifyListeners();
  }

  void setPhoto(Uint8List? bytes, {String? mimeType}) {
    _photoBytes = bytes;
    _photoMimeType = mimeType;
    notifyListeners();
  }

  void clearPhoto() {
    _photoBytes = null;
    _photoMimeType = null;
    _detectError = null;
    _detectedItems = [];
    notifyListeners();
  }

  /// Identifies food items in the current photo and adds the new ones to the
  /// ingredient list. Returns the items found (empty if none/failure).
  Future<List<String>> identifyItemsFromPhoto() async {
    final bytes = _photoBytes;
    if (bytes == null) return const [];

    _isDetecting = true;
    _detectError = null;
    notifyListeners();

    try {
      final found = await _gemini.detectIngredients(
        imageBytes: bytes,
        imageMimeType: _photoMimeType,
      );
      _detectedItems = found;
      for (final item in found) {
        final exists =
            _ingredients.any((e) => e.toLowerCase() == item.toLowerCase());
        if (!exists) _ingredients.add(item);
      }
      return found;
    } on GeminiException catch (e) {
      _detectError = e.message;
      _detectedItems = [];
      return const [];
    } catch (_) {
      _detectError = 'Could not identify items in the photo.';
      _detectedItems = [];
      return const [];
    } finally {
      _isDetecting = false;
      notifyListeners();
    }
  }
}
