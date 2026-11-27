import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dvc_guide_mobile/app/theme/theme_provider.dart';
import 'package:dvc_guide_mobile/core/constants/app_strings.dart';
import 'package:dvc_guide_mobile/core/providers/shared_preferences_provider.dart';
import 'package:dvc_guide_mobile/core/utils/auth_validators.dart';
import 'package:dvc_guide_mobile/core/utils/redirect_utils.dart';
import 'package:dvc_guide_mobile/features/auth/data/datasources/token_storage.dart';
import 'package:dvc_guide_mobile/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:dvc_guide_mobile/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:dvc_guide_mobile/features/auth/domain/exceptions/auth_exception.dart';
import 'package:dvc_guide_mobile/features/auth/presentation/screens/account_screen.dart';
import 'package:dvc_guide_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:dvc_guide_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:dvc_guide_mobile/features/auth/presentation/viewmodels/auth_controller.dart';
import 'package:dvc_guide_mobile/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:dvc_guide_mobile/features/auth/presentation/viewmodels/token_storage_provider.dart';

void main() {
  group('1. Auth Validators Test', () {
    test('Email validator: valid and edge cases', () {
      // Valid
      expect(AuthValidators.validateEmail('user@test.com'), isNull);
      expect(AuthValidators.validateEmail('demo.user+tag@domain.co.uk'), isNull);
      expect(AuthValidators.validateEmail('  trimmed@domain.vn  '), isNull);

      // Empty / null
      expect(AuthValidators.validateEmail(null), AppStrings.errEmailEmpty);
      expect(AuthValidators.validateEmail(''), AppStrings.errEmailEmpty);
      expect(AuthValidators.validateEmail('   '), AppStrings.errEmailEmpty);

      // Invalid format
      expect(AuthValidators.validateEmail('usertest.com'), AppStrings.errEmailInvalid);
      expect(AuthValidators.validateEmail('user@'), AppStrings.errEmailInvalid);
      expect(AuthValidators.validateEmail('@domain.com'), AppStrings.errEmailInvalid);
      expect(AuthValidators.validateEmail('user@domain'), AppStrings.errEmailInvalid);
      expect(AuthValidators.validateEmail('user space@domain.com'), AppStrings.errEmailInvalid);
    });

    test('Password validator: minimum 8 chars, letters and numbers', () {
      // Valid
      expect(AuthValidators.validatePassword('Password123'), isNull);
      expect(AuthValidators.validatePassword('1234567a'), isNull);
      expect(AuthValidators.validatePassword('Abcd1234#\$%'), isNull);

      // Empty / null
      expect(AuthValidators.validatePassword(null), AppStrings.errPasswordEmpty);
      expect(AuthValidators.validatePassword(''), AppStrings.errPasswordEmpty);

      // Too short (< 8)
      expect(AuthValidators.validatePassword('Pass1'), AppStrings.errPasswordTooShort);

      // Only letters
      expect(AuthValidators.validatePassword('PasswordLong'), AppStrings.errPasswordMissingChar);

      // Only numbers
      expect(AuthValidators.validatePassword('123456789'), AppStrings.errPasswordMissingChar);
    });

    test('Confirm password validator', () {
      expect(AuthValidators.validateConfirmPassword('Pass1234', 'Pass1234'), isNull);
      expect(AuthValidators.validateConfirmPassword('', 'Pass1234'), AppStrings.errConfirmPasswordEmpty);
      expect(AuthValidators.validateConfirmPassword(null, 'Pass1234'), AppStrings.errConfirmPasswordEmpty);
      expect(AuthValidators.validateConfirmPassword('Diff1234', 'Pass1234'), AppStrings.errConfirmPasswordMismatch);
    });

    test('Display name validator: 2 - 50 characters', () {
      expect(AuthValidators.validateDisplayName('An'), isNull);
      expect(AuthValidators.validateDisplayName('Nguyễn Văn A'), isNull);
      expect(AuthValidators.validateDisplayName(null), AppStrings.errDisplayNameEmpty);
      expect(AuthValidators.validateDisplayName(''), AppStrings.errDisplayNameEmpty);
      expect(AuthValidators.validateDisplayName(' '), AppStrings.errDisplayNameEmpty);
      expect(AuthValidators.validateDisplayName('A'), AppStrings.errDisplayNameLength);
      expect(AuthValidators.validateDisplayName('A' * 51), AppStrings.errDisplayNameLength);
    });
  });

  group('2. Redirect URI sanitization', () {
    test('sanitizes from param correctly', () {
      expect(sanitizeRedirectUri('/my-cases'), '/my-cases');
      expect(sanitizeRedirectUri('/procedures/12'), '/procedures/12');
      expect(sanitizeRedirectUri(null), '/');
      expect(sanitizeRedirectUri(''), '/');
      // Must NOT start with '//'
      expect(sanitizeRedirectUri('//malicious.com'), '/');
      expect(sanitizeRedirectUri('//evil.com/phishing'), '/');
      // Relative without slash or external url
      expect(sanitizeRedirectUri('https://google.com'), '/');
      expect(sanitizeRedirectUri('javascript:alert(1)'), '/');
    });
  });

  group('3. MockAuthRepository & AuthController Flow', () {
    late FakeTokenStorage fakeStorage;
    late MockAuthRepository repo;

    setUp(() {
      fakeStorage = FakeTokenStorage();
      repo = MockAuthRepository(tokenStorage: fakeStorage);
    });

    test('register success then becomes authenticated', () async {
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(fakeStorage),
          authRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);

      final user = await controller.register(
        tenHienThi: 'Người dùng mới',
        email: 'newuser@example.com',
        matKhau: 'Password123',
      );

      expect(user.email, 'newuser@example.com');
      expect(user.tenHienThi, 'Người dùng mới');
      expect(container.read(authControllerProvider).status, AuthStatus.authenticated);
      expect(container.read(authControllerProvider).user?.id, user.id);

      // Verify token was stored
      final storedToken = await fakeStorage.readToken();
      expect(storedToken, isNotNull);
      expect(storedToken, contains(user.id));
    });

    test('register duplicate email throws emailDaTonTai', () async {
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(fakeStorage),
          authRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);

      // demo@dvcguide.vn is predefined
      expect(
        () => controller.register(
          tenHienThi: 'Trùng',
          email: 'demo@dvcguide.vn',
          matKhau: 'Password123',
        ),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', AuthErrorCode.emailDaTonTai)),
      );
    });

    test('login with wrong password throws saiThongTin', () async {
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(fakeStorage),
          authRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);

      expect(
        () => controller.login(
          email: 'demo@dvcguide.vn',
          matKhau: 'WrongPassword999',
        ),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', AuthErrorCode.saiThongTin)),
      );
    });

    test('login with email containing "loi" throws loiMang', () async {
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(fakeStorage),
          authRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);

      expect(
        () => controller.login(
          email: 'user_loi@example.com',
          matKhau: 'Password123',
        ),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', AuthErrorCode.loiMang)),
      );
    });

    test('session restore when opening app', () async {
      // Pre-populate storage with token and user info
      await fakeStorage.saveToken('existing_token_xyz');
      await fakeStorage.saveUserInfo(id: 'demo-user-uuid-1234-5678', email: 'demo@dvcguide.vn');

      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(fakeStorage),
          authRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      await controller.restoreSession();

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user?.email, 'demo@dvcguide.vn');
    });

    test('logout clears session and reverts to guest', () async {
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(fakeStorage),
          authRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);

      // Login first
      await controller.login(email: 'demo@dvcguide.vn', matKhau: 'Demo1234');
      expect(container.read(authControllerProvider).status, AuthStatus.authenticated);

      // Logout
      await controller.logout();
      expect(container.read(authControllerProvider).status, AuthStatus.guest);
      expect(container.read(authControllerProvider).user, isNull);

      final token = await fakeStorage.readToken();
      expect(token, isNull);
    });
  });

  group('4. Form UI & Error Display Widget Tests', () {
    testWidgets('LoginScreen shows validation errors and banner on bad credentials', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fakeStorage = FakeTokenStorage();
      final repo = MockAuthRepository(tokenStorage: fakeStorage);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tokenStorageProvider.overrideWithValue(fakeStorage),
            authRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Tap submit with empty fields
      await tester.tap(find.byKey(const ValueKey('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.errEmailEmpty), findsOneWidget);
      expect(find.text(AppStrings.errPasswordEmpty), findsOneWidget);

      // Enter invalid email format
      await tester.enterText(find.byKey(const ValueKey('login_email_input')), 'invalidemail');
      await tester.tap(find.byKey(const ValueKey('login_submit_button')));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.errEmailInvalid), findsOneWidget);

      // Enter valid format but wrong credentials
      await tester.enterText(find.byKey(const ValueKey('login_email_input')), 'demo@dvcguide.vn');
      await tester.enterText(find.byKey(const ValueKey('login_password_input')), 'WrongPass123');
      await tester.tap(find.byKey(const ValueKey('login_submit_button')));

      // In-flight progress
      await tester.pump(const Duration(milliseconds: 100));
      // Finish 800ms mock delay
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      // Banner should appear with saiThongTin message
      expect(find.byKey(const ValueKey('server_error_banner')), findsOneWidget);
      expect(find.text(AppStrings.authErrInvalidCredentialsBanner), findsOneWidget);
    });

    testWidgets('RegisterScreen shows validation and duplicate email error on email field', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fakeStorage = FakeTokenStorage();
      final repo = MockAuthRepository(tokenStorage: fakeStorage);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tokenStorageProvider.overrideWithValue(fakeStorage),
            authRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      // Tap submit without agreement or data
      final submitButton = find.byKey(const ValueKey('register_submit_button'));
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.errDisplayNameEmpty), findsOneWidget);
      expect(find.text(AppStrings.errEmailEmpty), findsOneWidget);
      expect(find.text(AppStrings.errPasswordEmpty), findsOneWidget);
      expect(find.text(AppStrings.errMustAgreeTerms), findsOneWidget);

      // Fill in duplicate demo account
      await tester.enterText(find.byKey(const ValueKey('register_name_input')), 'Test User');
      await tester.enterText(find.byKey(const ValueKey('register_email_input')), 'demo@dvcguide.vn');
      await tester.enterText(find.byKey(const ValueKey('register_password_input')), 'Pass123456');
      await tester.enterText(find.byKey(const ValueKey('register_confirm_password_input')), 'Pass123456');
      await tester.tap(find.byKey(const ValueKey('register_terms_checkbox')));
      await tester.pumpAndSettle();

      
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      // Duplicate email must be displayed at email field
      expect(find.text(AppStrings.authErrEmailExists), findsOneWidget);
    });
  });

  group('5. Account, Profile & Settings Tests (Pha 6C)', () {
    test('sửa tên hiển thị và địa phương', () async {
      final fakeStorage = FakeTokenStorage();
      final repo = MockAuthRepository(tokenStorage: fakeStorage);

      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(fakeStorage),
          authRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);

      // Login demo first
      await controller.login(email: 'demo@dvcguide.vn', matKhau: 'Demo1234');
      expect(container.read(authControllerProvider).user?.tenHienThi, 'Người dùng Demo');

      // Update profile
      final updated = await controller.updateProfile(
        tenHienThi: 'Nguyễn Văn Mới',
        diaPhuongId: 3,
      );

      expect(updated.tenHienThi, 'Nguyễn Văn Mới');
      expect(updated.diaPhuongId, 3);
      expect(container.read(authControllerProvider).user?.tenHienThi, 'Nguyễn Văn Mới');
      expect(container.read(authControllerProvider).user?.diaPhuongId, 3);
    });

    test('đổi mật khẩu sai ném lỗi saiMatKhauHienTai; đổi đúng thành công', () async {
      final fakeStorage = FakeTokenStorage();
      final repo = MockAuthRepository(tokenStorage: fakeStorage);

      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(fakeStorage),
          authRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);

      // Login
      await controller.login(email: 'demo@dvcguide.vn', matKhau: 'Demo1234');

      // Sai mật khẩu hiện tại
      expect(
        () => controller.changePassword(
          matKhauHienTai: 'SaiMatKhau1',
          matKhauMoi: 'NewPassword123',
        ),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', AuthErrorCode.saiMatKhauHienTai)),
      );

      // Đúng mật khẩu hiện tại
      await controller.changePassword(
        matKhauHienTai: 'Demo1234',
        matKhauMoi: 'NewPassword123',
      );

      // Đăng xuất và đăng nhập lại bằng mật khẩu cũ phải thất bại
      await controller.logout();
      expect(
        () => controller.login(email: 'demo@dvcguide.vn', matKhau: 'Demo1234'),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', AuthErrorCode.saiThongTin)),
      );

      // Đăng nhập lại bằng mật khẩu mới phải thành công
      final loggedIn = await controller.login(email: 'demo@dvcguide.vn', matKhau: 'NewPassword123');
      expect(loggedIn.email, 'demo@dvcguide.vn');
    });

    test('đổi chế độ giao diện được lưu vào SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      // Initial default is ThemeMode.system
      expect(container.read(themeModeProvider), ThemeMode.system);

      // Set to dark
      await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(prefs.getString('app_theme_mode'), 'dark');

      // Set to light
      await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(prefs.getString('app_theme_mode'), 'light');
    });

    test('xóa tài khoản cần xác nhận đúng email/mật khẩu', () async {
      final fakeStorage = FakeTokenStorage();
      final repo = MockAuthRepository(tokenStorage: fakeStorage);

      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(fakeStorage),
          authRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      await controller.login(email: 'demo@dvcguide.vn', matKhau: 'Demo1234');

      // Xác nhận sai
      expect(
        () => controller.deleteAccount(email: 'wrong@dvcguide.vn'),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', AuthErrorCode.saiThongTin)),
      );

      // Xác nhận đúng email
      await controller.deleteAccount(email: 'demo@dvcguide.vn');
      expect(container.read(authControllerProvider).status, AuthStatus.guest);
      expect(container.read(authControllerProvider).user, isNull);

      // Thử đăng nhập lại tài khoản đã xóa phải thất bại
      expect(
        () => controller.login(email: 'demo@dvcguide.vn', matKhau: 'Demo1234'),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', AuthErrorCode.saiThongTin)),
      );
    });

    testWidgets('AccountScreen hiển thị đúng ở chế độ khách và đã đăng nhập', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fakeStorage = FakeTokenStorage();
      final repo = MockAuthRepository(tokenStorage: fakeStorage);

      // 1. Chế độ khách
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tokenStorageProvider.overrideWithValue(fakeStorage),
            authRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: AccountScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.guestAccountPrompt), findsOneWidget);
      expect(find.text(AppStrings.guestAccountSubtitle), findsOneWidget);
      expect(find.byKey(const ValueKey('account_login_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('account_register_button')), findsOneWidget);

      // 2. Đăng nhập và mở lại AccountScreen
      final container = ProviderScope.containerOf(tester.element(find.byType(AccountScreen)));
            final loginFuture = container.read(authControllerProvider.notifier).login(
            email: 'demo@dvcguide.vn',
            matKhau: 'Demo1234',
          );
      await tester.pump(const Duration(milliseconds: 900)); // chạy hết độ trễ 0,8 giây của mock
      await loginFuture;
      await tester.pumpAndSettle();

      expect(find.text('demo@dvcguide.vn'), findsOneWidget);
      expect(find.byKey(const ValueKey('profile_name_input')), findsOneWidget);
      expect(find.byKey(const ValueKey('save_profile_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('account_logout_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('delete_account_button')), findsOneWidget);

      // Test đổi mật khẩu sai hiển thị lỗi tại ô mật khẩu hiện tại
      final currentPassField = find.byKey(const ValueKey('current_password_input'));
      await tester.ensureVisible(currentPassField);
      await tester.enterText(currentPassField, 'SaiPass123');
      await tester.enterText(find.byKey(const ValueKey('new_password_input')), 'NewPass123');
      await tester.enterText(find.byKey(const ValueKey('confirm_new_password_input')), 'NewPass123');

      final changePassButton = find.byKey(const ValueKey('change_password_button'));
      await tester.ensureVisible(changePassButton);
      await tester.tap(changePassButton);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.errWrongCurrentPassword), findsOneWidget);
    });
  });
}
