import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:dvc_guide_mobile/core/constants/app_constants.dart';
import 'package:dvc_guide_mobile/core/constants/app_strings.dart';
import 'package:dvc_guide_mobile/core/providers/shared_preferences_provider.dart';
import 'package:dvc_guide_mobile/features/auth/data/datasources/token_storage.dart';
import 'package:dvc_guide_mobile/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:dvc_guide_mobile/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:dvc_guide_mobile/features/auth/presentation/viewmodels/token_storage_provider.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/models/my_case_models.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/repositories/mock_my_cases_repository.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/repositories/my_cases_repository_provider.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/services/fake_reminder_service.dart';
import 'package:dvc_guide_mobile/features/my_cases/domain/services/reminder_service.dart';
import 'package:dvc_guide_mobile/features/my_cases/presentation/viewmodels/reminder_coordinator.dart';
import 'package:dvc_guide_mobile/features/procedure/data/mock/procedure_mock_data.dart';
import 'package:dvc_guide_mobile/features/settings/presentation/screens/settings_screen.dart';
import 'package:dvc_guide_mobile/shared/enums/procedure_enums.dart';

void main() {
  tz.initializeTimeZones();

  group('1. Unit Test computeReminderTimes', () {
    final location = tz.getLocation(AppConstants.kNotificationTimeZone);

    test('Hẹn xa (5 ngày nữa): trả về 2 mốc 08:00 ngày trước và 08:00 ngày đến hạn', () {
      final now = tz.TZDateTime(location, 2026, 11, 20, 9, 0);
      final ngayHen = tz.TZDateTime(location, 2026, 11, 25, 0, 0);

      final result = computeReminderTimes(
        ngayHen: ngayHen,
        now: now,
        trangThai: TrangThaiHoSo.dangXuLy,
      );

      expect(result.length, 2);
      expect(result[0].year, 2026);
      expect(result[0].month, 11);
      expect(result[0].day, 24);
      expect(result[0].hour, AppConstants.kReminderHour);
      expect(result[0].minute, AppConstants.kReminderMinute);

      expect(result[1].year, 2026);
      expect(result[1].month, 11);
      expect(result[1].day, 25);
      expect(result[1].hour, AppConstants.kReminderHour);
      expect(result[1].minute, AppConstants.kReminderMinute);
    });

    test('Hẹn ngày mai, now trước 08:00 hôm nay: đủ 2 mốc 08:00 hôm nay và 08:00 ngày mai', () {
      final now = tz.TZDateTime(location, 2026, 11, 20, 7, 0);
      final ngayHen = tz.TZDateTime(location, 2026, 11, 21, 0, 0);

      final result = computeReminderTimes(
        ngayHen: ngayHen,
        now: now,
        trangThai: TrangThaiHoSo.dangChuanBi,
      );

      expect(result.length, 2);
      expect(result[0].day, 20);
      expect(result[0].hour, 8);
      expect(result[1].day, 21);
      expect(result[1].hour, 8);
    });

    test('Hẹn ngày mai, now sau 08:00 hôm nay: chỉ còn mốc 08:00 ngày đến hạn (mốc hôm nay đã qua)', () {
      final now = tz.TZDateTime(location, 2026, 11, 20, 9, 30);
      final ngayHen = tz.TZDateTime(location, 2026, 11, 21, 0, 0);

      final result = computeReminderTimes(
        ngayHen: ngayHen,
        now: now,
        trangThai: TrangThaiHoSo.dangXuLy,
      );

      expect(result.length, 1);
      expect(result[0].day, 21);
      expect(result[0].hour, 8);
    });

    test('Hẹn hôm nay sau 08:00: trả về danh sách rỗng (cả 2 mốc đều đã qua)', () {
      final now = tz.TZDateTime(location, 2026, 11, 20, 10, 0);
      final ngayHen = tz.TZDateTime(location, 2026, 11, 20, 0, 0);

      final result = computeReminderTimes(
        ngayHen: ngayHen,
        now: now,
        trangThai: TrangThaiHoSo.daNop,
      );

      expect(result, isEmpty);
    });

    test('Hẹn đã qua: trả về danh sách rỗng', () {
      final now = tz.TZDateTime(location, 2026, 11, 20, 10, 0);
      final ngayHen = tz.TZDateTime(location, 2026, 11, 15, 0, 0);

      final result = computeReminderTimes(
        ngayHen: ngayHen,
        now: now,
        trangThai: TrangThaiHoSo.dangXuLy,
      );

      expect(result, isEmpty);
    });

    test('Trạng thái daNhanKetQua: luôn trả về danh sách rỗng', () {
      final now = tz.TZDateTime(location, 2026, 11, 20, 7, 0);
      final ngayHen = tz.TZDateTime(location, 2026, 11, 30, 0, 0);

      final result = computeReminderTimes(
        ngayHen: ngayHen,
        now: now,
        trangThai: TrangThaiHoSo.daNhanKetQua,
      );

      expect(result, isEmpty);
    });
  });

  group('2. Mã thông báo ổn định (FNV-1a 32-bit)', () {
    test('Cùng caseId sinh cùng số, hai slot khác nhau, số luôn dương trong int32', () {
      const caseId = 'case-test-12345';

      final idSlot0First = notificationIdForCase(caseId, 0);
      final idSlot0Second = notificationIdForCase(caseId, 0);
      final idSlot1 = notificationIdForCase(caseId, 1);

      // Cùng caseId sinh cùng số
      expect(idSlot0First, equals(idSlot0Second));

      // Hai slot khác nhau
      expect(idSlot0First, isNot(equals(idSlot1)));
      expect(idSlot1, equals(idSlot0First + 1));

      // Không âm và nhỏ hơn 2^31
      expect(idSlot0First, greaterThanOrEqualTo(0));
      expect(idSlot0First, lessThanOrEqualTo(0x7FFFFFFF));
      expect(idSlot1, greaterThanOrEqualTo(0));
      expect(idSlot1, lessThanOrEqualTo(0x7FFFFFFF));

      // Khác caseId sinh ra mã khác
      const otherCaseId = 'case-test-67890';
      final otherIdSlot0 = notificationIdForCase(otherCaseId, 0);
      expect(idSlot0First, isNot(equals(otherIdSlot0)));
    });
  });

  group('3. Điều phối viên (ReminderCoordinator)', () {
    late FakeReminderService fakeReminderService;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        AppConstants.kRemindScheduleKey: true,
      });
      final prefs = await SharedPreferences.getInstance();
      fakeReminderService = FakeReminderService();

      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          reminderServiceProvider.overrideWithValue(fakeReminderService),
          myCasesRepositoryProvider.overrideWithValue(MockMyCasesRepository()),
        ],
      );
    });

        tearDown(() async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      container.dispose();
    });

    test('Thêm hồ sơ có ngayHen thì scheduleForCase được gọi', () async {
      final coordinator = container.read(reminderCoordinatorProvider);
      final testCase = HoSoCuaToi(
        id: 'case-test-1',
        tenHoSo: 'Hồ sơ thử nghiệm',
        thuTuc: mockProcedureSummaries[0],
        ngayHen: DateTime.now().add(const Duration(days: 3)),
        trangThai: TrangThaiHoSo.dangXuLy,
      );

      await coordinator.sync([testCase]);

      expect(fakeReminderService.scheduledCases.containsKey('case-test-1'), isTrue);
      expect(fakeReminderService.scheduledCases['case-test-1']?.tenHoSo, 'Hồ sơ thử nghiệm');
    });

    test('Xóa ngày hẹn (ngayHen = null) thì cancelForCase được gọi', () async {
      final coordinator = container.read(reminderCoordinatorProvider);
      final testCase = HoSoCuaToi(
        id: 'case-test-2',
        tenHoSo: 'Hồ sơ xóa ngày hẹn',
        thuTuc: mockProcedureSummaries[0],
        ngayHen: DateTime.now().add(const Duration(days: 3)),
        trangThai: TrangThaiHoSo.dangXuLy,
      );

      // Đặt lịch trước
      await coordinator.sync([testCase]);
      expect(fakeReminderService.scheduledCases.containsKey('case-test-2'), isTrue);

      // Xóa ngày hẹn
      final caseWithoutHen = testCase.copyWith(ngayHen: null);
      await coordinator.sync([caseWithoutHen]);

      expect(fakeReminderService.cancelledCaseIds, contains('case-test-2'));
      expect(fakeReminderService.scheduledCases.containsKey('case-test-2'), isFalse);
    });

    test('Đổi sang daNhanKetQua thì cancelForCase được gọi', () async {
      final coordinator = container.read(reminderCoordinatorProvider);
      final testCase = HoSoCuaToi(
        id: 'case-test-3',
        tenHoSo: 'Hồ sơ nhận kết quả',
        thuTuc: mockProcedureSummaries[0],
        ngayHen: DateTime.now().add(const Duration(days: 3)),
        trangThai: TrangThaiHoSo.dangXuLy,
      );

      // Đặt lịch
      await coordinator.sync([testCase]);
      expect(fakeReminderService.scheduledCases.containsKey('case-test-3'), isTrue);

      // Chuyển sang đã nhận kết quả
      final completedCase = testCase.copyWith(trangThai: TrangThaiHoSo.daNhanKetQua);
      await coordinator.sync([completedCase]);

      expect(fakeReminderService.cancelledCaseIds, contains('case-test-3'));
      expect(fakeReminderService.scheduledCases.containsKey('case-test-3'), isFalse);
    });

    test('Tắt công tắc thì cancelAll được gọi', () async {
      final coordinator = container.read(reminderCoordinatorProvider);
      final testCase = HoSoCuaToi(
        id: 'case-test-4',
        tenHoSo: 'Hồ sơ test tắt switch',
        thuTuc: mockProcedureSummaries[0],
        ngayHen: DateTime.now().add(const Duration(days: 3)),
        trangThai: TrangThaiHoSo.dangXuLy,
      );

      await coordinator.sync([testCase]);
      expect(fakeReminderService.scheduledCases.isNotEmpty, isTrue);

      // Tắt công tắc
      await coordinator.onToggleChanged(false);

      expect(fakeReminderService.cancelAllCount, greaterThan(0));
      expect(fakeReminderService.scheduledCases, isEmpty);
    });

    test('Xóa toàn bộ dữ liệu cá nhân thì cancelAll được gọi', () async {
      final coordinator = container.read(reminderCoordinatorProvider);
      final testCase = HoSoCuaToi(
        id: 'case-test-5',
        tenHoSo: 'Hồ sơ test xóa hết',
        thuTuc: mockProcedureSummaries[0],
        ngayHen: DateTime.now().add(const Duration(days: 3)),
        trangThai: TrangThaiHoSo.dangXuLy,
      );

      await coordinator.sync([testCase]);
      expect(fakeReminderService.scheduledCases.isNotEmpty, isTrue);

      await coordinator.onAllDataCleared();

      expect(fakeReminderService.cancelAllCount, greaterThan(0));
      expect(fakeReminderService.scheduledCases, isEmpty);
    });
  });

  group('4. SettingsScreen - Widget Tests', () {
    testWidgets('Giao diện công tắc nhắc lịch hiển thị đủ thông tin và nút thử nghiệm ở debug mode',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.reset();
      });

      SharedPreferences.setMockInitialValues({
        AppConstants.kRemindScheduleKey: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final fakeReminderService = FakeReminderService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            reminderServiceProvider.overrideWithValue(fakeReminderService),
            tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
            authRepositoryProvider.overrideWithValue(MockAuthRepository(tokenStorage: FakeTokenStorage())),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề và phụ đề ghi chú
      expect(find.text(AppStrings.remindSchedule), findsOneWidget);
      expect(find.text(AppStrings.remindScheduleNote), findsOneWidget);
      expect(find.text(AppStrings.remindScheduleDetails), findsOneWidget);

      // Nút thử thông báo sau 10 giây (kDebugMode = true trong test runner)
      final testBtn = find.byKey(const ValueKey('test_notification_button'));
      expect(testBtn, findsOneWidget);

      // Thử nhấn nút test notification
      await tester.tap(testBtn);
      await tester.pumpAndSettle();

      expect(fakeReminderService.testNotifications, contains(const Duration(seconds: 10)));
      expect(find.text(AppStrings.testNotificationScheduled), findsOneWidget);

      // Gỡ cây trước khi kết thúc
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Bật công tắc mà quyền bị từ chối: công tắc tắt lại và hiện dialog giải thích',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.reset();
      });

      SharedPreferences.setMockInitialValues({
        AppConstants.kRemindScheduleKey: false, // ban đầu đang tắt
      });
      final prefs = await SharedPreferences.getInstance();
      final fakeReminderService = FakeReminderService()..permissionGranted = false; // Từ chối quyền

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            reminderServiceProvider.overrideWithValue(fakeReminderService),
            tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
            authRepositoryProvider.overrideWithValue(MockAuthRepository(tokenStorage: FakeTokenStorage())),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.byKey(const ValueKey('remind_schedule_switch'));
      expect(switchFinder, findsOneWidget);

      // Nhấn bật công tắc
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Kiểm tra gọi requestPermission
      expect(fakeReminderService.permissionRequestCount, 1);

      // Kiểm tra hiện dialog giải thích
      expect(find.text(AppStrings.notificationPermissionRequiredTitle), findsOneWidget);
      expect(find.text(AppStrings.notificationPermissionDialogContent), findsOneWidget);

      // Đóng dialog
      final closeBtn = find.text(AppStrings.closeAction);
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      // Kiểm tra công tắc vẫn ở trạng thái tắt và không schedule
      expect(prefs.getBool(AppConstants.kRemindScheduleKey), isFalse);
      expect(fakeReminderService.scheduledCases, isEmpty);

      // Gỡ cây
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
