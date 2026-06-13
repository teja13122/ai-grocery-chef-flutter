/// Configuration for the Google Gemini API.
///
/// Get a FREE API key at: https://aistudio.google.com/app/apikey
///
/// Two ways to provide the key:
/// 1) Quick start — paste your key into [_fallbackKey] below.
/// 2) Safer — pass it at run time and keep it out of source control:
///      flutter run --dart-define=GEMINI_API_KEY=your_key_here
class ApiConfig {
  ApiConfig._();

  /// Paste your key here for a quick local start (do not commit a real key).
  static const String _fallbackKey = 'PASTE_YOUR_GEMINI_API_KEY_HERE';

  /// Resolved API key. Prefers the --dart-define value when supplied.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: _fallbackKey,
  );

  /// Free-tier, multimodal model (accepts text + images).
  static const String model = 'gemini-2.5-flash';

  static bool get isConfigured =>
      geminiApiKey.isNotEmpty &&
      geminiApiKey != 'PASTE_YOUR_GEMINI_API_KEY_HERE';
}
