import '../../data/models/my_case_models.dart';
import '../../domain/services/reminder_service.dart';

/// Fake implementation of [ReminderService] for unit and widget testing.
/// Records all calls and enables simulating notification interactions.
class FakeReminderService implements ReminderService {
  bool isInitialized = false;
  bool permissionGranted = true;
  int permissionRequestCount = 0;

  final Map<String, HoSoCuaToi> scheduledCases = {};
  final List<String> cancelledCaseIds = [];
  int cancelAllCount = 0;
  final List<Duration> testNotifications = [];

  void Function(String caseId)? _onOpenCase;
  String? _pendingLaunchPayload;

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

  void setPendingLaunchPayload(String payload) {
    _pendingLaunchPayload = payload;
  }

  void simulateNotificationTap(String caseId) {
    _onOpenCase?.call(caseId);
  }

  @override
  Future<void> init() async {
    isInitialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    permissionRequestCount++;
    return permissionGranted;
  }

  @override
  Future<void> scheduleForCase(HoSoCuaToi caseItem) async {
    scheduledCases[caseItem.id] = caseItem;
  }

  @override
  Future<void> cancelForCase(String caseId) async {
    cancelledCaseIds.add(caseId);
    scheduledCases.remove(caseId);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCount++;
    scheduledCases.clear();
  }

  @override
  Future<void> showTestIn(Duration duration) async {
    testNotifications.add(duration);
  }
}
