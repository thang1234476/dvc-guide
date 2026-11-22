import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides the [SharedPreferences] instance initialized before [runApp].
///
/// Must be overridden via [ProviderScope.overrides] in [main].
/// See main.dart for the override pattern.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main() via ProviderScope.overrides.',
  );
});
