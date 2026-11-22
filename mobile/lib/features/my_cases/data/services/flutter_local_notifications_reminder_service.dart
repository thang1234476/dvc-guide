import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/enums/procedure_enums.dart';
import '../../data/models/my_case_models.dart';
import '../../domain/services/reminder_service.dart';

class FlutterLocalNotificationsReminderService implements ReminderService {
  FlutterLocalNotificationsReminderService({
    FlutterLocalNotificationsPlugin? plugin,
    void Function(String caseId)? onOpenCase,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _onOpenCase = onOpenCase;

  final FlutterLocalNotificationsPlugin _plugin;
  void Function(String caseId)? _onOpenCase;
  String? _pendingLaunchPayload;
  bool _isInitialized = false;

  @override
  void setOnOpenCase(void Function(String caseId) handler) {
    _onOpenCase = handler;
    if (_pendingLaunchPayload != null) {
      final payload = _pendingLaunchPayload!;
      _pendingLaunchPayload = null;
      handler(payload);
    }
  }

  @override
  String? consumePendingLaunchPayload() {
    final payload = _pendingLaunchPayload;
    _pendingLaunchPayload = null;
    return payload;
  }

  @override
  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize fixed timezone Asia/Ho_Chi_Minh
    try {
      tz.getLocation(AppConstants.kNotificationTimeZone);
    } catch (_) {
      tz.initializeTimeZones();
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

     await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty && payload != 'test') {
          _pendingLaunchPayload = payload;
          _onOpenCase?.call(payload);
        }
      },
    );

    // Handle when app was launched from a notification
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails != null &&
        launchDetails.didNotificationLaunchApp &&
        launchDetails.notificationResponse != null) {
      final payload = launchDetails.notificationResponse!.payload;
      if (payload != null && payload.isNotEmpty && payload != 'test') {
        _pendingLaunchPayload = payload;
        _onOpenCase?.call(payload);
      }
    }

    _isInitialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  @override
  Future<void> scheduleForCase(HoSoCuaToi caseItem) async {
    // Cancel existing reminders for this case first
    await cancelForCase(caseItem.id);

    if (caseItem.ngayHen == null ||
        caseItem.trangThai == TrangThaiHoSo.daNhanKetQua) {
      return;
    }

    final reminderTimes = computeReminderTimes(
      ngayHen: caseItem.ngayHen!,
      now: DateTime.now(),
      trangThai: caseItem.trangThai,
    );

    if (reminderTimes.isEmpty) return;

    final location = tz.getLocation(AppConstants.kNotificationTimeZone);
    final henLocal = tz.TZDateTime.from(caseItem.ngayHen!, location);

    const androidDetails = AndroidNotificationDetails(
      AppConstants.kReminderChannelId,
      AppStrings.reminderChannelName,
      channelDescription: AppStrings.reminderChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    for (final time in reminderTimes) {
      final tzTime = tz.TZDateTime.from(time, location);
      final isDueDay = tzTime.year == henLocal.year &&
          tzTime.month == henLocal.month &&
          tzTime.day == henLocal.day;
      final slot = isDueDay ? 1 : 0;
      final title = isDueDay
          ? AppStrings.reminderTitleDueDay
          : AppStrings.reminderTitleDayBefore;
      final notifId = notificationIdForCase(caseItem.id, slot);

      await _plugin.zonedSchedule(
        id: notifId,
        title: title,
        body: caseItem.tenHoSo,
        scheduledDate: tzTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: caseItem.id,
      );
    }
  }

  @override
  Future<void> cancelForCase(String caseId) async {
    await _plugin.cancel(id: notificationIdForCase(caseId, 0));
    await _plugin.cancel(id: notificationIdForCase(caseId, 1));
  }

  @override
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  @override
  Future<void> showTestIn(Duration duration) async {
    final location = tz.getLocation(AppConstants.kNotificationTimeZone);
    final testTime = tz.TZDateTime.now(location).add(duration);

    const androidDetails = AndroidNotificationDetails(
      AppConstants.kReminderChannelId,
      AppStrings.reminderChannelName,
      channelDescription: AppStrings.reminderChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id: 999999,
      title: AppStrings.testNotificationTitle,
      body: AppStrings.testNotificationBody,
      scheduledDate: testTime,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'test',
    );
  }
}
