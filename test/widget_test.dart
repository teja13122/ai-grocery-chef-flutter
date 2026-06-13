import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ai_grocery_chef/models/recipe.dart';
import 'package:ai_grocery_chef/providers/pantry_provider.dart';

void main() {
  group('PantryProvider', () {
    test('adds and de-duplicates ingredients (case-insensitive)', () {
      final pantry = PantryProvider();
      pantry.addIngredient('Chicken');
      pantry.addIngredient('chicken'); // duplicate
      pantry.addIngredient('Rice');

      expect(pantry.ingredients, ['Chicken', 'Rice']);
    });

    test('removes ingredients', () {
      final pantry = PantryProvider();
      pantry.addIngredient('Eggs');
      pantry.removeIngredient('Eggs');

      expect(pantry.ingredients, isEmpty);
    });

    test('canGenerate is true once an ingredient is added', () {
      final pantry = PantryProvider();
      expect(pantry.canGenerate, isFalse);
      pantry.addIngredient('Tomato');
      expect(pantry.canGenerate, isTrue);
    });
  });

  group('Recipe.fromAi', () {
    test('parses a well-formed JSON map', () {
      final recipe = Recipe.fromAi({
        'title': 'Tomato Rice',
        'ingredients_used': ['rice', 'tomato'],
        'missing_optional': ['onion'],
        'steps': ['Boil rice', 'Add tomato'],
        'cook_time_min': 25,
        'difficulty': 'Easy',
        'substitutions': ['use quinoa instead of rice'],
        'safety_notes': 'Wash vegetables well.',
      });

      expect(recipe.title, 'Tomato Rice');
      expect(recipe.ingredientsUsed.length, 2);
      expect(recipe.cookTimeMin, 25);
      expect(recipe.isInsufficient, isFalse);
    });

    test('detects the insufficient-ingredients case', () {
      final recipe = Recipe.fromAi({
        'title': 'Insufficient ingredients',
        'safety_notes': 'Add a protein or grain.',
      });

      expect(recipe.isInsufficient, isTrue);
    });

    test('coerces messy numeric and list values', () {
      final recipe = Recipe.fromAi({
        'title': 'Test',
        'cook_time_min': '30 minutes',
        'ingredients_used': 'single string',
        'steps': null,
      });

      expect(recipe.cookTimeMin, 30);
      expect(recipe.ingredientsUsed, ['single string']);
      expect(recipe.steps, isEmpty);
    });
  });

  testWidgets('ingredient chips render for pantry state', (tester) async {
    final pantry = PantryProvider()..addIngredient('Chicken');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: pantry,
        child: MaterialApp(
          home: Scaffold(
            body: Consumer<PantryProvider>(
              builder: (_, p, __) => Wrap(
                children: [for (final i in p.ingredients) Chip(label: Text(i))],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Chicken'), findsOneWidget);
  });
}
