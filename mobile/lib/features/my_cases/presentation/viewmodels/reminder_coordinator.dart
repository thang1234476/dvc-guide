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
    _ref.listen<MyCasesState>(
      myCasesViewModelProvider,
      (previous, next) {
        if (!next.isLoading) {
          sync(next.cases);
        }
      },
    );
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
    final prefs = _ref.read(sharedPreferencesProvider);
    final enabled = prefs.getBool(AppConstants.kRemindScheduleKey) ?? true;
    final service = _ref.read(reminderServiceProvider);

    if (!enabled) {
      await service.cancelAll();
      _knownActiveCaseIds.clear();
      return;
    }

    final currentCases = cases ?? await _ref.read(myCasesRepositoryProvider).getMyCases();
    final currentCaseMap = {for (final c in currentCases) c.id: c};

    // 1. Cancel cases that were deleted
    for (final oldId in _knownActiveCaseIds) {
      if (!currentCaseMap.containsKey(oldId)) {
        await service.cancelForCase(oldId);
      }
    }

    // 2. Schedule eligible cases, cancel ineligible ones
    final newActiveIds = <String>{};
    for (final caseItem in currentCases) {
      if (caseItem.ngayHen != null &&
          caseItem.trangThai != TrangThaiHoSo.daNhanKetQua) {
        await service.scheduleForCase(caseItem);
        newActiveIds.add(caseItem.id);
      } else {
        // Case without ngayHen or marked as daNhanKetQua
        await service.cancelForCase(caseItem.id);
      }
    }

    _knownActiveCaseIds = newActiveIds;
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
