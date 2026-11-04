/// API endpoint path constants.
/// All paths are relative to [AppConstants.apiBaseUrl].
class ApiEndpoints {
  ApiEndpoints._();

  // ── Health ───────────────────────────────────────────────────────────────────
  static const String health = '/api/v1/health';

  // ── Future endpoints (add as features are built) ─────────────────────────────
  // static const String login = '/api/v1/auth/login';
  // static const String register = '/api/v1/auth/register';
  // static const String refreshToken = '/api/v1/auth/refresh';
  // static const String procedures = '/api/v1/procedures';
  // static const String procedureById = '/api/v1/procedures/{id}';
  // static const String chat = '/api/v1/chat';
  // static const String userProfile = '/api/v1/users/me';
}
