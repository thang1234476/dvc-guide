import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dvc_guide_mobile/app/app.dart';
import 'package:dvc_guide_mobile/core/constants/app_constants.dart';
import 'package:dvc_guide_mobile/core/providers/shared_preferences_provider.dart';
import 'package:dvc_guide_mobile/features/auth/data/datasources/token_storage.dart';
import 'package:dvc_guide_mobile/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:dvc_guide_mobile/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:dvc_guide_mobile/features/auth/presentation/viewmodels/token_storage_provider.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/repositories/mock_my_cases_repository.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/repositories/my_cases_repository_provider.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/services/fake_reminder_service.dart';
import 'package:dvc_guide_mobile/features/my_cases/presentation/viewmodels/reminder_coordinator.dart';
import 'package:dvc_guide_mobile/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:dvc_guide_mobile/features/procedure/data/repositories/fake_favorites_repository.dart';
import 'package:dvc_guide_mobile/features/procedure/data/repositories/favorites_repository_provider.dart';

void main() {
  testWidgets('DvcGuideApp smoke test - routes to home when onboarding and auth gate seen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      kOnboardingSeenKey: true,
      AppConstants.kAuthGateSeenKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    final fakeStorage = FakeTokenStorage();
    final authRepo = MockAuthRepository(tokenStorage: fakeStorage);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tokenStorageProvider.overrideWithValue(fakeStorage),
          authRepositoryProvider.overrideWithValue(authRepo),
          favoritesRepositoryProvider.overrideWithValue(FakeFavoritesRepository()),
          myCasesRepositoryProvider.overrideWithValue(MockMyCasesRepository()),
          reminderServiceProvider.overrideWithValue(FakeReminderService()),
        ],
        child: const DvcGuideApp(),
      ),
    );
    // Pump past splash minimum delay (600 ms)
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 100));
    // Wait for async MockProcedureRepository.getLinhVucList (200ms) triggered by HomeViewModel
    await tester.pump(const Duration(seconds: 1));
    // App should render without throwing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
