import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/providers/shared_preferences_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Provide the already-initialized SharedPreferences instance
        // so all providers can read it synchronously.
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const DvcGuideApp(),
    ),
  );
}
