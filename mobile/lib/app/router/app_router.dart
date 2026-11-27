import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/account_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/chat/presentation/screens/chat_history_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/feedback/presentation/screens/feedback_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/my_cases/presentation/screens/my_case_check_screen.dart';
import '../../features/my_cases/presentation/screens/my_case_detail_screen.dart';
import '../../features/my_cases/presentation/screens/my_cases_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/procedure/presentation/screens/find_agency_screen.dart';
import '../../features/procedure/presentation/screens/procedure_detail_screen.dart';
import '../../features/settings/presentation/screens/delete_data_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../../core/utils/redirect_utils.dart';
import '../../features/auth/presentation/viewmodels/auth_controller.dart';
import '../../features/auth/presentation/viewmodels/auth_state.dart';

/// Route path constants and helper path builders
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String procedureDetail = '/procedures/:id';
  static const String chat = '/chat';
  static const String myCases = '/my-cases';
  static const String myCaseDetail = '/my-cases/:id';
  static const String myCaseCheck = '/my-cases/:id/check';
  static const String settings = '/settings';

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String account = '/account';
  static const String findAgency = '/find-agency';
  static const String chatHistory = '/chat-history';
  static const String deleteData = '/delete-data';
  static const String feedback = '/feedback';

  static String procedureDetailPath(int id) => '/procedures/$id';
  static String myCaseDetailPath(String id) => '/my-cases/$id';
  static String myCaseCheckPath(String id) => '/my-cases/$id/check';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Application router provider using go_router with StatefulShellRoute.
final appRouterProvider = Provider<GoRouter>((ref) {
  // Báo cho router đánh giá lại `redirect` mỗi khi trạng thái đăng nhập đổi.
  // Không dùng ref.watch ở đây: nó sẽ tạo lại GoRouter và mất ngăn xếp màn hình.
    final authRefresh = ValueNotifier<AuthStatus>(
    ref.read(authControllerProvider).status,
  );

  var sessionEnded = false; // true = vừa đăng xuất hoặc hết phiên
  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    if (previous?.isAuthenticated == true && !next.isAuthenticated) {
      sessionEnded = true;
    }
    if (next.isAuthenticated) sessionEnded = false;
    authRefresh.value = next.status;
  });
  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc == AppRoutes.splash) return null; // splash tự chờ rồi chuyển đi

      final loggedIn = ref.read(authControllerProvider).isAuthenticated;
      final isAuthPage = loc == AppRoutes.login || loc == AppRoutes.register;
      final isPublic = isAuthPage || loc == AppRoutes.onboarding;

      // Chưa đăng nhập: chỉ được ở onboarding / đăng nhập / đăng ký.
            if (!loggedIn) {
        if (isPublic) return null;
        // Vừa đăng xuất / hết phiên: về đăng nhập trơn.
        if (sessionEnded) return AppRoutes.login;
        // Mở app từ liên kết/thông báo: nhớ đích để đăng nhập xong đi tiếp.
        final from = Uri.encodeComponent(state.uri.toString());
        return '${AppRoutes.login}?from=$from';
      }

      // Đã đăng nhập mà còn đứng ở màn đăng nhập/đăng ký: đi tiếp tới đích.
      if (isAuthPage) {
        return sanitizeRedirectUri(state.uri.queryParameters['from']);
      }
      return null;
    },
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) {
          final from = state.uri.queryParameters['from'];
          return LoginScreen(from: from);
        },
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) {
          final from = state.uri.queryParameters['from'];
          return RegisterScreen(from: from);
        },
      ),
      GoRoute(
        path: AppRoutes.account,
        name: 'account',
        builder: (context, state) => const AccountScreen(),
      ),

      // Procedure Detail route (outside tab scaffold, uses root navigator key for proper back stack)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/procedures/:id',
        name: 'procedureDetail',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          final thIdStr = state.uri.queryParameters['truongHopId'];
          final truongHopId = thIdStr != null ? int.tryParse(thIdStr) : null;
          return ProcedureDetailScreen(id: id, initialTruongHopId: truongHopId);
        },
      ),

      // Find Agency route (outside tab scaffold, uses root navigator key)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/find-agency',
        name: 'findAgency',
        builder: (context, state) {
          final thuTucId =
              int.tryParse(state.uri.queryParameters['thuTucId'] ?? '') ?? 0;
          final caseId = state.uri.queryParameters['caseId'] ?? '';
          final slot = state.uri.queryParameters['slot'] ?? 'du_dinh';
          final from = state.uri.queryParameters['from'] ?? 'procedure';
          return FindAgencyScreen(
            thuTucId: thuTucId,
            caseId: caseId,
            slot: slot,
            from: from,
          );
        },
      ),

      // Chat History route (outside tab scaffold, uses root navigator key)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.chatHistory,
        name: 'chatHistory',
        builder: (context, state) => const ChatHistoryScreen(),
      ),

      // Delete Data route (outside tab scaffold, uses root navigator key)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.deleteData,
        name: 'deleteData',
        builder: (context, state) => const DeleteDataScreen(),
      ),

      // Feedback route (outside tab scaffold, uses root navigator key)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.feedback,
        name: 'feedback',
        builder: (context, state) => const FeedbackScreen(),
      ),

      // 4 Main Tabs StatefulShellRoute
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Home (Trang chủ)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder: (context, state) {
                  final q = state.uri.queryParameters['q'];
                  return HomeScreen(initialQuery: q);
                },
              ),
            ],
          ),

          // Branch 2: AI Assistant (Hỏi trợ lý AI)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chat,
                name: 'chat',
                builder: (context, state) {
                  return ChatScreen(extra: state.extra);
                },
              ),
            ],
          ),

          // Branch 3: My Cases (Hồ sơ của tôi)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.myCases,
                name: 'myCases',
                builder: (context, state) => const MyCasesScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: 'myCaseDetail',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return MyCaseDetailScreen(id: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'check',
                        name: 'myCaseCheck',
                        builder: (context, state) {
                          final id = state.pathParameters['id'] ?? '';
                          return MyCaseCheckScreen(id: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Branch 4: Settings (Cài đặt)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
