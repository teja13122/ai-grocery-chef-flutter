import 'package:flutter/foundation.dart';

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
  final List<String> _ingredients = [];
  Diet _diet = Diet.any;
  String _allergies = '';
  int _maxCookTimeMin = 30;

  Uint8List? _photoBytes;
  String? _photoMimeType;

  List<String> get ingredients => List.unmodifiable(_ingredients);
  Diet get diet => _diet;
  String get allergies => _allergies;
  int get maxCookTimeMin => _maxCookTimeMin;
  Uint8List? get photoBytes => _photoBytes;
  String? get photoMimeType => _photoMimeType;
  bool get hasPhoto => _photoBytes != null;

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

  void setPhoto(Uint8List? bytes, {String? mimeType}) {
    _photoBytes = bytes;
    _photoMimeType = mimeType;
    notifyListeners();
  }

  void clearPhoto() => setPhoto(null);
}
