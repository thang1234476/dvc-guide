import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/shared_preferences_provider.dart';

/// Key used to persist whether the user has seen onboarding.
const String kOnboardingSeenKey = 'onboarding_seen_v1';

/// Repository for reading and writing the onboarding-seen flag.
class OnboardingRepository {
  final SharedPreferences _prefs;

  const OnboardingRepository(this._prefs);

  bool hasSeenOnboarding() => _prefs.getBool(kOnboardingSeenKey) ?? false;

  Future<void> markOnboardingAsSeen() =>
      _prefs.setBool(kOnboardingSeenKey, true);
}

/// Provider for [OnboardingRepository].
final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingRepository(prefs);
});
