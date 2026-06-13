import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/recipe_provider.dart';
import '../widgets/recipe_view.dart';

/// Screen 2 — shows the AI-generated recipe with a Save button.
class RecipeScreen extends StatelessWidget {
  const RecipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recipes = context.watch<RecipeProvider>();
    final recipe = recipes.current;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Recipe')),
      body: _buildBody(context, recipes),
      floatingActionButton: (recipe != null &&
              !recipe.isInsufficient &&
              !recipes.isLoading)
          ? FloatingActionButton.extended(
              onPressed: recipes.isCurrentSaved
                  ? null
                  : () async {
                      await recipes.saveCurrent();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Recipe saved!')),
                        );
                      }
                    },
              icon: Icon(
                recipes.isCurrentSaved ? Icons.check : Icons.bookmark_add,
              ),
              label: Text(recipes.isCurrentSaved ? 'Saved' : 'Save Recipe'),
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context, RecipeProvider recipes) {
    if (recipes.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cooking up a recipe…'),
          ],
        ),
      );
    }

    if (recipes.error != null && recipes.current == null) {
      return _EmptyState(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        message: recipes.error!,
      );
    }

    final recipe = recipes.current;
    if (recipe == null) {
      return const _EmptyState(
        icon: Icons.restaurant_menu,
        title: 'No recipe yet',
        message:
            'Add ingredients on the Pantry tab and tap "Generate Recipe".',
      );
    }

    return RecipeView(recipe: recipe, padding: const EdgeInsets.fromLTRB(16, 16, 16, 96));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
