import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dvc_guide_mobile/core/providers/shared_preferences_provider.dart';
import '../../domain/repositories/my_cases_repository.dart';
import 'shared_pref_my_cases_repository.dart';

final myCasesRepositoryProvider = Provider<MyCasesRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SharedPrefMyCasesRepository(prefs);
});
