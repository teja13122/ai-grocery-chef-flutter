import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/recipe.dart';

/// Thrown when the AI request fails for a reason worth showing the user.
class GeminiException implements Exception {
  final String message;
  GeminiException(this.message);
  @override
  String toString() => message;
}

/// Talks to the Google Gemini REST API to turn pantry input (text + an
/// optional photo) into a structured [Recipe].
class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Builds the documented system prompt and requests a recipe.
  ///
  /// [imageBytes] is optional JPEG/PNG data from a pantry photo. When present,
  /// the model is asked to also identify visible ingredients.
  Future<Recipe> generateRecipe({
    required List<String> ingredients,
    required String diet,
    required String allergies,
    required int maxCookTimeMin,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async {
    if (!ApiConfig.isConfigured) {
      throw GeminiException(
        'No Gemini API key set. Add a free key in lib/config/api_config.dart '
        'or pass --dart-define=GEMINI_API_KEY=your_key.',
      );
    }

    final prompt = _buildPrompt(
      ingredients: ingredients,
      diet: diet,
      allergies: allergies,
      maxCookTimeMin: maxCookTimeMin,
      hasPhoto: imageBytes != null,
    );

    final parts = <Map<String, dynamic>>[
      {'text': prompt},
    ];
    if (imageBytes != null) {
      parts.add({
        'inline_data': {
          'mime_type': imageMimeType ?? 'image/jpeg',
          'data': base64Encode(imageBytes),
        },
      });
    }

    final uri = Uri.parse(
      '$_baseUrl/${ApiConfig.model}:generateContent?key=${ApiConfig.geminiApiKey}',
    );

    final body = jsonEncode({
      'contents': [
        {'parts': parts},
      ],
      'generationConfig': {
        'temperature': 0.7,
        // Force clean JSON so Flutter parsing stays simple.
        'responseMimeType': 'application/json',
      },
    });

    http.Response response;
    try {
      response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 45));
    } catch (e) {
      throw GeminiException(
        'Could not reach the AI service. Check your internet connection.',
      );
    }

    if (response.statusCode == 429) {
      throw GeminiException('Rate limit reached. Wait a moment and try again.');
    }
    if (response.statusCode != 200) {
      throw GeminiException(
        'AI request failed (${response.statusCode}). ${_errorDetail(response.body)}',
      );
    }

    final text = _extractText(response.body);
    final Map<String, dynamic> recipeJson;
    try {
      recipeJson = jsonDecode(_stripCodeFences(text)) as Map<String, dynamic>;
    } catch (_) {
      throw GeminiException(
        'The AI returned an unexpected format. Please try again.',
      );
    }

    return Recipe.fromAi(recipeJson);
  }

  /// The system prompt documented in the project paper.
  String _buildPrompt({
    required List<String> ingredients,
    required String diet,
    required String allergies,
    required int maxCookTimeMin,
    required bool hasPhoto,
  }) {
    final ingredientList =
        ingredients.isEmpty ? '(none typed)' : ingredients.join(', ');
    final photoNote = hasPhoto
        ? 'A photo of the user\'s pantry/fridge is attached. Also use clearly '
            'visible ingredients from the photo, but never invent items you '
            'cannot see or that were not listed.'
        : '';

    return '''
You are a careful home cooking assistant.
Using ONLY these ingredients: $ingredientList
$photoNote
Respect these constraints:
- diet: ${diet.isEmpty ? 'no restriction' : diet}
- allergies to avoid: ${allergies.isEmpty ? 'none' : allergies}
- max cook time: $maxCookTimeMin minutes

Return ONLY valid JSON with exactly these fields:
{
  "title": string,
  "ingredients_used": string[],
  "missing_optional": string[],
  "steps": string[],
  "cook_time_min": number,
  "difficulty": "Easy" | "Medium" | "Hard",
  "substitutions": string[],
  "safety_notes": string
}

Rules:
- Never include any ingredient the user is allergic to.
- Honor the diet strictly (e.g. vegan = no animal products).
- Keep total time within the max cook time.
- In safety_notes, briefly cover allergen awareness, safe cooking temperatures,
  and cross-contamination where relevant.
- If the ingredients are insufficient for a complete meal, set "title" to
  "Insufficient ingredients" and explain what is missing in "safety_notes".
Do not add commentary outside the JSON.
''';
  }

  String _extractText(String responseBody) {
    try {
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw GeminiException(
          'The AI did not return a recipe (it may have refused the request).',
        );
      }
      final content = candidates.first['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List?;
      final text = parts?.first['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        throw GeminiException('The AI returned an empty response.');
      }
      return text;
    } on GeminiException {
      rethrow;
    } catch (_) {
      throw GeminiException('Could not read the AI response.');
    }
  }

  /// Removes ```json ... ``` fences if the model wraps its output anyway.
  String _stripCodeFences(String text) {
    var t = text.trim();
    if (t.startsWith('```')) {
      t = t.replaceFirst(RegExp(r'^```[a-zA-Z]*'), '').trim();
      if (t.endsWith('```')) t = t.substring(0, t.length - 3).trim();
    }
    return t;
  }

  String _errorDetail(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return (data['error']?['message'] ?? '').toString();
    } catch (_) {
      return '';
    }
  }
}
