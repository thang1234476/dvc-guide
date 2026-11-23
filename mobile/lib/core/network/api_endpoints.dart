/// API endpoint path constants.
/// All paths are relative to [AppConstants.apiBaseUrl].
class ApiEndpoints {
  ApiEndpoints._();

  // ── Health ───────────────────────────────────────────────────────────────────
  static const String health = '/api/v1/health';

    // ── Auth & account ───────────────────────────────────────────────────────────
  static const String login = '/api/v1/auth/login';
  static const String register = '/api/v1/auth/register';
  static const String logout = '/api/v1/auth/logout';
  static const String me = '/api/v1/users/me';

  // ── Catalog ──────────────────────────────────────────────────────────────────
  static const String localities = '/api/v1/catalog/localities';
}
