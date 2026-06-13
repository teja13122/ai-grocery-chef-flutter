# 🥗 AI Grocery Chef

> Turn what's in your kitchen into a meal — powered by AI.

A Flutter app that turns the ingredients you already have (typed **or** snapped in a
photo) into an AI-generated recipe, helping reduce food waste and meal-planning
decision fatigue.

Built with **Flutter + Provider + Hive + Google Gemini (free tier)**.

---

## ✨ Features

| Screen | What it does |
| --- | --- |
| **Pantry** | Add ingredients as chips, set diet / allergies / max cook time, optionally attach a fridge photo, then **Generate Recipe**. |
| **AI Recipe** | Title, ingredients used, missing items, numbered steps, cook time, difficulty, substitutions, and a safety/allergen note. **Save Recipe** button. |
| **Saved** | Locally stored recipes (Hive). Tap to view, swipe left to delete. |

- 🤖 **AI integration:** Google Gemini `gemini-2.5-flash`, multimodal (text + photo), JSON-mode output.
- 💾 **Local storage:** Hive (offline, no account needed).
- 🧠 **State management:** Provider.

---

## 🚀 Setup (first time)

### 1. Install Flutter
Follow https://docs.flutter.dev/get-started/install (Windows). Confirm with:
```powershell
flutter doctor
```

### 2. Get a FREE Gemini API key
1. Go to https://aistudio.google.com/app/apikey
2. Click **Create API key** (free tier — no billing required).
3. Copy the key.

### 3. Add your key
Open [lib/config/api_config.dart](lib/config/api_config.dart) and paste your key into
`_fallbackKey`, **or** pass it at run time (recommended — keeps it out of git):
```powershell
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

### 4. Generate the platform folders
This repo contains the Dart source (`lib/`) and `pubspec.yaml`. Generate the
`android/`, `ios/`, `web/` scaffolding (this will **not** overwrite existing files):
```powershell
flutter create . --project-name ai_grocery_chef
```

### 5. Install dependencies & run
```powershell
flutter pub get
flutter run
```

---

## 📷 Camera / photo permissions

`image_picker` needs platform permissions. After step 4 above, add:

**Android** — `android/app/src/main/AndroidManifest.xml` (inside `<manifest>`):
```xml
<uses-permission android:name="android.permission.CAMERA"/>
```

**iOS** — `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Take a photo of your pantry to generate recipes.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Pick a pantry photo to generate recipes.</string>
```

---

## 🗂 Project structure

```
lib/
├── main.dart                  # App entry, Hive init, Providers
├── config/
│   └── api_config.dart        # Gemini key + model config
├── models/
│   └── recipe.dart            # Recipe model + hand-written Hive adapter
├── services/
│   ├── gemini_service.dart    # Builds prompt, calls Gemini, parses JSON
│   └── storage_service.dart   # Hive box wrapper
├── providers/
│   ├── pantry_provider.dart   # Ingredients, diet, allergies, photo
│   └── recipe_provider.dart   # Generation + saved-recipe state
├── screens/
│   ├── home_screen.dart       # Bottom navigation shell
│   ├── pantry_screen.dart     # Screen 1
│   ├── recipe_screen.dart     # Screen 2
│   └── saved_recipes_screen.dart  # Screen 3
├── widgets/
│   └── recipe_view.dart       # Reusable recipe renderer
└── theme/
    └── app_theme.dart         # Material 3 theme
```

---

## 🧪 AI prompt (documented for the paper)

The app sends Gemini a structured prompt that locks the response to JSON with the
fields `title, ingredients_used, missing_optional, steps, cook_time_min,
difficulty, substitutions, safety_notes`. If ingredients are insufficient, the
model returns `title: "Insufficient ingredients"` and explains why in
`safety_notes`. See `_buildPrompt` in
[lib/services/gemini_service.dart](lib/services/gemini_service.dart).

---

## ⚠️ Notes & ethics

- Recipes are AI-generated — always verify **allergens** and **safe cooking
  temperatures** before eating. The app surfaces a safety note and a disclaimer.
- Your API key is a secret. Prefer the `--dart-define` method and keep it out of
  version control (`lib/config/secrets.dart` and `.env` are git-ignored).
