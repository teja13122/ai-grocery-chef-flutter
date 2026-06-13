import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/recipe.dart';
import 'providers/pantry_provider.dart';
import 'providers/recipe_provider.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local storage setup.
  await Hive.initFlutter();
  Hive.registerAdapter(RecipeAdapter());
  await StorageService.init();

  runApp(const AiGroceryChefApp());
}

class AiGroceryChefApp extends StatelessWidget {
  const AiGroceryChefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PantryProvider()),
        ChangeNotifierProvider(create: (_) => RecipeProvider()..loadSaved()),
      ],
      child: MaterialApp(
        title: 'AI Grocery Chef',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomeScreen(),
      ),
    );
  }
}
