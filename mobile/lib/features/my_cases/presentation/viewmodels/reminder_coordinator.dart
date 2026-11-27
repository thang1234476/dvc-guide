import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../../shared/enums/procedure_enums.dart';
import '../../data/models/my_case_models.dart';
import '../../data/repositories/my_cases_repository_provider.dart';
import '../../data/services/flutter_local_notifications_reminder_service.dart';
import '../../domain/services/reminder_service.dart';
import 'my_cases_viewmodel.dart';
import '../../../auth/presentation/viewmodels/auth_controller.dart';

/// Provider for the notification reminder service.
/// Can be overridden in tests with [FakeReminderService].
final reminderServiceProvider = Provider<ReminderService>((ref) {
  final service = FlutterLocalNotificationsReminderService(
    onOpenCase: (caseId) {
      try {
        ref.read(appRouterProvider).go(AppRoutes.myCaseDetailPath(caseId));
      } catch (_) {}
    },
  );
  return service;
});

/// Coordinator that synchronizes reminders between the schedule toggle and tracked cases.
class ReminderCoordinator {
  ReminderCoordinator(this._ref) {
    _initListener();
  }

  final Ref _ref;
  Set<String> _knownActiveCaseIds = {};
  bool _initialized = false;

  void _initListener() {
    _ref.listen<MyCasesState>(myCasesViewModelProvider, (previous, next) {
      // Bỏ qua khi đang tải hoặc tải lỗi (tránh hiểu nhầm là "hết hồ sơ").
      if (!next.isLoading && next.error == null) {
        sync(next.cases);
      }
    });
  }

  /// Initialize the coordinator and notification service, then run an initial synchronization.
  Future<void> init() async {
    if (_initialized) return;
    final service = _ref.read(reminderServiceProvider);
    await service.init();
    await sync();
    _initialized = true;
  }

  /// Synchronize all cases with scheduled notifications.
  /// If [cases] is not passed, loads from [myCasesRepositoryProvider].
  Future<void> sync([List<HoSoCuaToi>? cases]) async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final enabled = prefs.getBool(AppConstants.kRemindScheduleKey) ?? true;
      final service = _ref.read(reminderServiceProvider);

      if (!enabled) {
        await service.cancelAll();
        _knownActiveCaseIds.clear();
        return;
      }

      final List<HoSoCuaToi> currentCases;
      if (cases != null) {
        currentCases = cases;
      } else if (_ref.read(authControllerProvider).isAuthenticated) {
        currentCases = await _ref.read(myCasesRepositoryProvider).getMyCases();
      } else {
        // Chưa đăng nhập hoặc chưa khôi phục phiên: không gọi server,
        // giữ nguyên lịch hiện có.
        return;
      }

      final currentCaseMap = {for (final c in currentCases) c.id: c};

      // 1. Hủy lịch của hồ sơ đã bị xóa
      for (final oldId in _knownActiveCaseIds) {
        if (!currentCaseMap.containsKey(oldId)) {
          await service.cancelForCase(oldId);
        }
      }

      // 2. Đặt lịch cho hồ sơ hợp lệ, hủy lịch của hồ sơ không còn hợp lệ
      final newActiveIds = <String>{};
      for (final caseItem in currentCases) {
        if (caseItem.ngayHen != null &&
            caseItem.trangThai != TrangThaiHoSo.daNhanKetQua) {
          await service.scheduleForCase(caseItem);
          newActiveIds.add(caseItem.id);
        } else {
          await service.cancelForCase(caseItem.id);
        }
      }

      _knownActiveCaseIds = newActiveIds;
    } catch (_) {
      // Lỗi mạng hoặc 401: giữ lịch hiện có, lần tải sau sẽ đồng bộ lại.
    }
  }

  /// Called when the user toggles the reminder schedule switch.
  Future<void> onToggleChanged(bool enabled) async {
    final service = _ref.read(reminderServiceProvider);
    if (!enabled) {
      await service.cancelAll();
      _knownActiveCaseIds.clear();
    } else {
      await sync();
    }
  }

  /// Called when all personal data is deleted.
  Future<void> onAllDataCleared() async {
    final service = _ref.read(reminderServiceProvider);
    await service.cancelAll();
    _knownActiveCaseIds.clear();
  }
}

/// Provider for [ReminderCoordinator].
final reminderCoordinatorProvider = Provider<ReminderCoordinator>((ref) {
  return ReminderCoordinator(ref);
});
