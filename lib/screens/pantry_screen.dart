import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/pantry_provider.dart';
import '../providers/recipe_provider.dart';

/// Screen 1 — users build their pantry: ingredient chips, dietary
/// preferences and an optional fridge/pantry photo.
class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key, required this.onRecipeGenerated});

  /// Called after a recipe is generated so the parent can switch tabs.
  final VoidCallback onRecipeGenerated;

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final TextEditingController _ingredientController = TextEditingController();
  final TextEditingController _allergyController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _ingredientController.dispose();
    _allergyController.dispose();
    super.dispose();
  }

  void _addIngredient(PantryProvider pantry) {
    pantry.addIngredient(_ingredientController.text);
    _ingredientController.clear();
  }

  Future<void> _pickPhoto(PantryProvider pantry, ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final mime = file.mimeType ??
          (file.path.toLowerCase().endsWith('.png')
              ? 'image/png'
              : 'image/jpeg');
      pantry.setPhoto(bytes, mimeType: mime);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the image.')),
        );
      }
    }
  }

  void _showPhotoOptions(PantryProvider pantry) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(pantry, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(pantry, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generate(
    PantryProvider pantry,
    RecipeProvider recipes,
  ) async {
    // Make sure any text left in the box is captured.
    if (_ingredientController.text.trim().isNotEmpty) {
      _addIngredient(pantry);
    }
    pantry.setAllergies(_allergyController.text);

    FocusScope.of(context).unfocus();
    final ok = await recipes.generate(pantry);
    if (!mounted) return;
    if (ok) {
      widget.onRecipeGenerated();
    } else if (recipes.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(recipes.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pantry = context.watch<PantryProvider>();
    final recipes = context.watch<RecipeProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Grocery Chef')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            "What's in your kitchen?",
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Add ingredients, set preferences, and let AI cook up a recipe.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          // --- Ingredient input ---
          const _SectionLabel('Ingredients'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ingredientController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'e.g. chicken, rice, eggs',
                    prefixIcon: Icon(Icons.add_shopping_cart_outlined),
                  ),
                  onSubmitted: (_) => _addIngredient(pantry),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: () => _addIngredient(pantry),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(56, 56),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (pantry.ingredients.isEmpty)
            Text(
              'No ingredients yet.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.grey.shade500),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in pantry.ingredients)
                  Chip(
                    label: Text(item),
                    onDeleted: () => pantry.removeIngredient(item),
                    deleteIcon: const Icon(Icons.close, size: 18),
                  ),
              ],
            ),

          const SizedBox(height: 24),

          // --- Photo input ---
          const _SectionLabel('Pantry photo (optional)'),
          const SizedBox(height: 8),
          _PhotoPicker(
            pantry: pantry,
            onTap: () => _showPhotoOptions(pantry),
          ),

          const SizedBox(height: 24),

          // --- Diet ---
          const _SectionLabel('Diet'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final diet in Diet.values)
                ChoiceChip(
                  label: Text(diet.label),
                  selected: pantry.diet == diet,
                  onSelected: (_) => pantry.setDiet(diet),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // --- Allergies ---
          const _SectionLabel('Allergies to avoid'),
          const SizedBox(height: 8),
          TextField(
            controller: _allergyController,
            decoration: const InputDecoration(
              hintText: 'e.g. peanuts, shellfish',
              prefixIcon: Icon(Icons.health_and_safety_outlined),
            ),
            onChanged: pantry.setAllergies,
          ),

          const SizedBox(height: 24),

          // --- Max cook time ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionLabel('Max cook time'),
              Text(
                '${pantry.maxCookTimeMin} min',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          Slider(
            value: pantry.maxCookTimeMin.toDouble(),
            min: 10,
            max: 120,
            divisions: 11,
            label: '${pantry.maxCookTimeMin} min',
            onChanged: (v) => pantry.setMaxCookTime(v.round()),
          ),

          const SizedBox(height: 16),

          // --- Generate ---
          FilledButton.icon(
            onPressed: (recipes.isLoading || !pantry.canGenerate)
                ? null
                : () => _generate(pantry, recipes),
            icon: recipes.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              recipes.isLoading ? 'Generating…' : 'Generate Recipe',
            ),
          ),
          if (!pantry.canGenerate)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Add at least one ingredient or a photo to begin.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey.shade500),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.pantry, required this.onTap});

  final PantryProvider pantry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (pantry.hasPhoto) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              pantry.photoBytes!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: pantry.clearPhoto,
              ),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            const Text('Add a photo of your fridge or pantry'),
          ],
        ),
      ),
    );
  }
}
