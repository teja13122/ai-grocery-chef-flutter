import 'package:flutter/foundation.dart';

import '../models/recipe.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import 'pantry_provider.dart';

/// Drives recipe generation and the list of saved recipes.
class RecipeProvider extends ChangeNotifier {
  final GeminiService _gemini = GeminiService();

  bool _isLoading = false;
  bool _isGeneratingImage = false;
  String? _error;
  Recipe? _current;
  List<Recipe> _saved = [];

  bool get isLoading => _isLoading;
  bool get isGeneratingImage => _isGeneratingImage;
  String? get error => _error;
  Recipe? get current => _current;
  List<Recipe> get saved => List.unmodifiable(_saved);

  bool get isCurrentSaved =>
      _current != null && _saved.any((r) => r.id == _current!.id);

  /// Loads saved recipes from Hive into memory.
  void loadSaved() {
    _saved = StorageService.getAll();
    notifyListeners();
  }

  /// Calls Gemini with the current pantry input and stores the result.
  Future<bool> generate(PantryProvider pantry) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _current = await _gemini.generateRecipe(
        ingredients: pantry.ingredients,
        diet: pantry.diet.promptValue,
        allergies: pantry.allergies,
        maxCookTimeMin: pantry.maxCookTimeMin,
        minCalories: pantry.minCalories,
        maxCalories: pantry.maxCalories,
        imageBytes: pantry.photoBytes,
        imageMimeType: pantry.photoMimeType,
      );
      _isLoading = false;
      notifyListeners();

      // Generate an appetizing dish photo in the background so the recipe text
      // appears immediately. Failures are silent (image is optional).
      await _generateDishImage();
      return true;
    } on GeminiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Something went wrong while generating the recipe.';
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Asks the AI for a photo of the current dish and attaches it.
  Future<void> _generateDishImage() async {
    final recipe = _current;
    if (recipe == null || recipe.isInsufficient) return;

    _isGeneratingImage = true;
    notifyListeners();
    try {
      final bytes = await _gemini.generateDishImage(
        title: recipe.title,
        ingredients: recipe.ingredientsUsed,
      );
      if (bytes != null && _current?.id == recipe.id) {
        _current = _current!.copyWith(imageBytes: bytes);
      }
    } catch (_) {
      // Image generation is optional; ignore failures.
    } finally {
      _isGeneratingImage = false;
      notifyListeners();
    }
  }

  Future<void> saveCurrent() async {
    final recipe = _current;
    if (recipe == null || recipe.isInsufficient) return;
    await StorageService.save(recipe);
    loadSaved();
  }

  Future<void> deleteRecipe(String id) async {
    await StorageService.delete(id);
    loadSaved();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
