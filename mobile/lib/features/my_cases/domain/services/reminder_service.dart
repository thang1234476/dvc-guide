import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/enums/procedure_enums.dart';
import '../../data/models/my_case_models.dart';

/// Pure function to generate a stable non-negative 32-bit int notification ID from [caseId] and [slot].
/// Uses FNV-1a (32-bit) hashing without String.hashCode.
/// Slot 0: "ngày trước" (day before)
/// Slot 1: "ngày đến hạn" (due day)
int notificationIdForCase(String caseId, int slot) {
  const int fnvPrime = 0x01000193; // 16777619
  int hash = 0x811c9dc5; // 2166136261

  for (int i = 0; i < caseId.length; i++) {
    final codeUnit = caseId.codeUnitAt(i);
    hash ^= (codeUnit & 0xFF);
    hash = (hash * fnvPrime) & 0xFFFFFFFF;
    if (codeUnit > 0xFF) {
      hash ^= ((codeUnit >> 8) & 0xFF);
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
  }

  // Ensure positive int in signed 31-bit range (0 <= id <= 0x7FFFFFFF)
  // Clear the least significant bit so baseId is always even (0, 2, 4...)
  // and baseId + 1 won't overflow 0x7FFFFFFF.
  final baseId = (hash & 0x7FFFFFFF) & ~1;
  return baseId + (slot & 1);
}

/// Pure function to compute reminder times for a case.
/// Returns a list of reminder times in Asia/Ho_Chi_Minh:
/// - 08:00 on the DAY BEFORE [ngayHen]
/// - 08:00 on the DUE DATE ([ngayHen])
/// Any time that has already passed (relative to [now]) is omitted.
/// If [trangThai] is [TrangThaiHoSo.daNhanKetQua], returns an empty list.
List<DateTime> computeReminderTimes({
  required DateTime ngayHen,
  required DateTime now,
  required TrangThaiHoSo trangThai,
}) {
  if (trangThai == TrangThaiHoSo.daNhanKetQua) {
    return const [];
  }

  try {
    tz.getLocation(AppConstants.kNotificationTimeZone);
  } catch (_) {
    tz.initializeTimeZones();
  }

  final location = tz.getLocation(AppConstants.kNotificationTimeZone);
  final henLocal = tz.TZDateTime.from(ngayHen, location);
  final nowLocal = tz.TZDateTime.from(now, location);

  // 08:00 on the day before the due date
  final dayBefore = tz.TZDateTime(
    location,
    henLocal.year,
    henLocal.month,
    henLocal.day - 1,
    AppConstants.kReminderHour,
    AppConstants.kReminderMinute,
  );

  // 08:00 on the due date
  final dueDay = tz.TZDateTime(
    location,
    henLocal.year,
    henLocal.month,
    henLocal.day,
    AppConstants.kReminderHour,
    AppConstants.kReminderMinute,
  );

  final reminders = <DateTime>[];
  if (dayBefore.isAfter(nowLocal)) {
    reminders.add(dayBefore);
  }
  if (dueDay.isAfter(nowLocal)) {
    reminders.add(dueDay);
  }

  return reminders;
}

/// Abstract reminder service interface for scheduling and managing local notifications.
abstract class ReminderService {
  /// Initialize the notification service.
  Future<void> init();

  /// Request notification permission (POST_NOTIFICATIONS on Android 13+).
  /// Returns true if granted, false otherwise.
  Future<bool> requestPermission();

  /// Schedule reminders for a case: cancels old reminders for this case, then sets new ones.
  Future<void> scheduleForCase(HoSoCuaToi caseItem);

  /// Cancel reminders for a specific case ID.
  Future<void> cancelForCase(String caseId);

  /// Cancel all scheduled reminders.
  Future<void> cancelAll();

  /// Show a test reminder after [duration].
  Future<void> showTestIn(Duration duration);

  /// Get and clear any pending case ID if the app was launched by tapping a notification.
  String? consumePendingLaunchPayload();

  /// Set callback to navigate when user taps a notification.
  void setOnOpenCase(void Function(String caseId) handler);
}
