import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/shared_preferences_provider.dart';

/// Repository for reading and writing the auth-gate-seen flag in [SharedPreferences].
class AuthGateRepository {
  final SharedPreferences _prefs;

  const AuthGateRepository(this._prefs);

  bool hasSeenAuthGate() =>
      _prefs.getBool(AppConstants.kAuthGateSeenKey) ?? false;

  Future<void> markAuthGateAsSeen() =>
      _prefs.setBool(AppConstants.kAuthGateSeenKey, true);
}

/// Provider for [AuthGateRepository].
final authGateRepositoryProvider = Provider<AuthGateRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthGateRepository(prefs);
});
