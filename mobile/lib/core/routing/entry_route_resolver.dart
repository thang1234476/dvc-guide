import '../../app/router/app_router.dart';
import '../../features/auth/presentation/viewmodels/auth_state.dart';
import '../constants/app_constants.dart';

/// Chọn màn hình đầu tiên khi mở app hoặc sau onboarding.
///
/// 1. Chưa xem onboarding -> [AppRoutes.onboarding]
/// 2. Đã đăng nhập        -> [AppRoutes.home]
/// 3. Còn lại             -> [AppRoutes.login] (bắt buộc đăng nhập, không có chế độ khách)
///
/// [authGateSeen] và [showLoginGateEveryLaunch] được giữ lại cho khỏi sửa
/// các nơi gọi, nhưng không còn ảnh hưởng kết quả.
String resolveEntryRoute({
  required bool onboardingSeen,
  required bool authGateSeen,
  required AuthStatus status,
  bool showLoginGateEveryLaunch = AppConstants.kShowLoginGateEveryLaunch,
}) {
  if (!onboardingSeen) {
    return AppRoutes.onboarding;
  }
  if (status == AuthStatus.authenticated) {
    return AppRoutes.home;
  }
  return AppRoutes.login;
}