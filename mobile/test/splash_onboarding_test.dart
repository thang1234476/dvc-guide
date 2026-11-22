import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dvc_guide_mobile/app/app.dart';
import 'package:dvc_guide_mobile/app/router/app_router.dart';
import 'package:dvc_guide_mobile/core/constants/app_constants.dart';
import 'package:dvc_guide_mobile/core/constants/app_strings.dart';
import 'package:dvc_guide_mobile/core/providers/shared_preferences_provider.dart';
import 'package:dvc_guide_mobile/core/routing/entry_route_resolver.dart';
import 'package:dvc_guide_mobile/features/auth/data/datasources/token_storage.dart';
import 'package:dvc_guide_mobile/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:dvc_guide_mobile/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:dvc_guide_mobile/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:dvc_guide_mobile/features/auth/presentation/viewmodels/token_storage_provider.dart';
import 'package:dvc_guide_mobile/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/services/fake_reminder_service.dart';
import 'package:dvc_guide_mobile/features/my_cases/presentation/viewmodels/reminder_coordinator.dart';

Widget _buildApp(SharedPreferences prefs, {FakeTokenStorage? fakeStorage}) {
  final storage = fakeStorage ?? FakeTokenStorage();
  final repo = MockAuthRepository(tokenStorage: storage);
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      tokenStorageProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(repo),
      reminderServiceProvider.overrideWithValue(FakeReminderService()),
    ],
    child: const DvcGuideApp(),
  );
}

void main() {
  group('resolveEntryRoute unit tests', () {
    test('1. !onboardingSeen -> /onboarding always', () {
      expect(
        resolveEntryRoute(
          onboardingSeen: false,
          authGateSeen: false,
          status: AuthStatus.guest,
        ),
        AppRoutes.onboarding,
      );
      expect(
        resolveEntryRoute(
          onboardingSeen: false,
          authGateSeen: true,
          status: AuthStatus.authenticated,
        ),
        AppRoutes.onboarding,
      );
      expect(
        resolveEntryRoute(
          onboardingSeen: false,
          authGateSeen: false,
          status: AuthStatus.guest,
          showLoginGateEveryLaunch: true,
        ),
        AppRoutes.onboarding,
      );
    });

    test('2. status == authenticated -> / (Trang chu)', () {
      expect(
        resolveEntryRoute(
          onboardingSeen: true,
          authGateSeen: false,
          status: AuthStatus.authenticated,
        ),
        AppRoutes.home,
      );
      expect(
        resolveEntryRoute(
          onboardingSeen: true,
          authGateSeen: true,
          status: AuthStatus.authenticated,
        ),
        AppRoutes.home,
      );
      expect(
        resolveEntryRoute(
          onboardingSeen: true,
          authGateSeen: false,
          status: AuthStatus.authenticated,
          showLoginGateEveryLaunch: true,
        ),
        AppRoutes.home,
      );
    });

    test('3. !authGateSeen -> /login', () {
      expect(
        resolveEntryRoute(
          onboardingSeen: true,
          authGateSeen: false,
          status: AuthStatus.guest,
          showLoginGateEveryLaunch: false,
        ),
        AppRoutes.login,
      );
    });

    test('3b. showLoginGateEveryLaunch == true -> /login even if authGateSeen == true', () {
      expect(
        resolveEntryRoute(
          onboardingSeen: true,
          authGateSeen: true,
          status: AuthStatus.guest,
          showLoginGateEveryLaunch: true,
        ),
        AppRoutes.login,
      );
    });

    test('4. otherwise -> / (Trang chu)', () {
      expect(
        resolveEntryRoute(
          onboardingSeen: true,
          authGateSeen: true,
          status: AuthStatus.guest,
          showLoginGateEveryLaunch: false,
        ),
        AppRoutes.home,
      );
    });
  });

  group('Splash → destination', () {
    testWidgets('first launch: navigates to onboarding', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildApp(prefs));
      // After splash delay
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();

      // Should show onboarding page 1 title
      expect(find.text('Tra cứu thủ tục'), findsOneWidget);
    });

    testWidgets('onboarding seen, but auth gate not seen (guest): navigates to login', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({kOnboardingSeenKey: true});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildApp(prefs));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();

      // Should navigate to login screen
      expect(find.byKey(const ValueKey('login_submit_button')), findsOneWidget);
      expect(find.text(AppStrings.continueAsGuest), findsOneWidget);
    });

    testWidgets('onboarding seen and auth gate seen: navigates to home', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({
        kOnboardingSeenKey: true,
        AppConstants.kAuthGateSeenKey: true,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildApp(prefs));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1)); // dọn timer Trang chủ

      // Should NOT show onboarding or login
      expect(find.text('Tra cứu thủ tục'), findsNothing);
      expect(find.text(AppStrings.loginSubtitle), findsNothing);
      // Should show home
      expect(find.text(AppStrings.navHome), findsOneWidget);
    });

    testWidgets('returning authenticated user (session restored): navigates to home', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({kOnboardingSeenKey: true});
      final prefs = await SharedPreferences.getInstance();

      final fakeStorage = FakeTokenStorage();
      await fakeStorage.saveToken('mock_jwt_token_demo-user-uuid-1234-5678');
      await fakeStorage.saveUserInfo(
        id: 'demo-user-uuid-1234-5678',
        email: 'demo@dvcguide.vn',
      );

      await tester.pumpWidget(_buildApp(prefs, fakeStorage: fakeStorage));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1)); // dọn timer Trang chủ

      expect(find.text(AppStrings.navHome), findsOneWidget);
    });
  });

  group('Onboarding screen', () {
    Future<void> pumpOnboarding(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(_buildApp(prefs));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();
    }

    testWidgets('shows 3 pages', (tester) async {
      await pumpOnboarding(tester);

      expect(find.text('Tra cứu thủ tục'), findsOneWidget);

      await tester.tap(find.text(AppStrings.onboardingNext));
      await tester.pumpAndSettle();
      expect(find.text('Hỏi trợ lý AI'), findsOneWidget);

      await tester.tap(find.text(AppStrings.onboardingNext));
      await tester.pumpAndSettle();
      expect(find.text('Theo dõi hồ sơ'), findsOneWidget);
    });

    testWidgets('last page shows "Bắt đầu" button', (tester) async {
      await pumpOnboarding(tester);

      // Navigate to last page
      await tester.tap(find.text(AppStrings.onboardingNext));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.onboardingNext));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.onboardingStart), findsOneWidget);
      expect(find.text(AppStrings.onboardingNext), findsNothing);
    });

    testWidgets('"Bỏ qua" writes seen flag and goes to login gate', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(_buildApp(prefs));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle(); // đợi hiệu ứng chuyển trang xong

      await tester.tap(find.text(AppStrings.onboardingSkip));
      await tester.pumpAndSettle();

      expect(prefs.getBool(kOnboardingSeenKey), isTrue);
      // Mới qua onboarding chưa đăng nhập -> ra màn đăng nhập thay vì Trang chủ
      expect(find.byKey(const ValueKey('login_submit_button')), findsOneWidget);
      expect(find.text(AppStrings.continueAsGuest), findsOneWidget);
    });

    testWidgets('"Bắt đầu" on last page writes seen flag and goes to login gate', (tester) async {
      await pumpOnboarding(tester);

      // Navigate to last page
      await tester.tap(find.text(AppStrings.onboardingNext));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.onboardingNext));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      await tester.tap(find.text(AppStrings.onboardingStart));
      await tester.pumpAndSettle();

      expect(prefs.getBool(kOnboardingSeenKey), isTrue);
      expect(find.byKey(const ValueKey('login_submit_button')), findsOneWidget);
      expect(find.text(AppStrings.continueAsGuest), findsOneWidget);
    });

    testWidgets('"Bỏ qua" hidden on last page', (tester) async {
      await pumpOnboarding(tester);

      // Navigate to last page
      await tester.tap(find.text(AppStrings.onboardingNext));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.onboardingNext));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.onboardingSkip), findsNothing);
      expect(find.text(AppStrings.onboardingLoginLink), findsOneWidget);
    });
  });

  group('Auth gate flow', () {
    testWidgets('tap "Tiếp tục với tư cách khách" at gate -> goes to home and marks authGateSeen; relaunch goes straight to home', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({kOnboardingSeenKey: true});
      final prefs = await SharedPreferences.getInstance();

      // Launch app -> goes to login gate
      await tester.pumpWidget(_buildApp(prefs));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();

      expect(find.byKey(const ValueKey('login_submit_button')), findsOneWidget);
      final guestButton = find.byKey(const ValueKey('login_guest_button'));
      expect(guestButton, findsOneWidget);

      // Tap "Tiếp tục với tư cách khách"
      await tester.tap(guestButton);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 1)); // Trang chủ pump 1s

      // Cờ authGateSeen phải được ghi
      expect(prefs.getBool(AppConstants.kAuthGateSeenKey), isTrue);
      // Hiển thị Trang chủ
      expect(find.text(AppStrings.navHome), findsOneWidget);

      // Relaunch app with same SharedPreferences
      await tester.pumpWidget(_buildApp(prefs));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1)); // Trang chủ pump 1s

      // Vào thẳng Trang chủ mà không dừng ở /login
      expect(find.text(AppStrings.navHome), findsOneWidget);
      expect(find.text(AppStrings.loginSubtitle), findsNothing);
    });
  });
}
