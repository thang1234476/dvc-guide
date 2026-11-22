import '../../app/router/app_router.dart';
import '../../features/auth/presentation/viewmodels/auth_state.dart';
import '../constants/app_constants.dart';

/// Pure function resolving the destination route on app launch or after onboarding.
///
/// Priority:
/// 1. `!onboardingSeen` -> [AppRoutes.onboarding]
/// 2. `status == AuthStatus.authenticated` -> [AppRoutes.home] ('/')
/// 3. `!authGateSeen` (or [showLoginGateEveryLaunch] is true) -> [AppRoutes.login]
/// 4. Otherwise -> [AppRoutes.home] ('/')
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
  if (showLoginGateEveryLaunch || !authGateSeen) {
    return AppRoutes.login;
  }
  return AppRoutes.home;
}
