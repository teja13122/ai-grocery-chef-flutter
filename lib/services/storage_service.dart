import 'package:hive_flutter/hive_flutter.dart';

import '../models/recipe.dart';

/// Thin wrapper around the Hive box that stores saved recipes locally.
class StorageService {
  static const String _boxName = 'saved_recipes';
  static late Box<Recipe> _box;

  /// Opens the recipes box. Call once after registering [RecipeAdapter].
  static Future<void> init() async {
    _box = await Hive.openBox<Recipe>(_boxName);
  }

  /// All saved recipes, newest first.
  static List<Recipe> getAll() {
    final items = _box.values.toList();
    items.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return items;
  }

  static Future<void> save(Recipe recipe) async {
    await _box.put(recipe.id, recipe);
  }

  static Future<void> delete(String id) async {
    await _box.delete(id);
  }

  static bool contains(String id) => _box.containsKey(id);
}
