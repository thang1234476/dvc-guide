/// Application-wide constants.
/// API URLs and timeouts are configurable via --dart-define at build time.
class AppConstants {
  AppConstants._();

  // ── API Configuration ────────────────────────────────────────────────────────
  /// Base URL for the Spring Boot API server.
  /// Override with: flutter run --dart-define=API_URL=http://your-server:8080
  /// Android Emulator: http://10.0.2.2:8080
  /// Physical device: http://YOUR_MACHINE_IP:8080
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  /// AI Service base URL (Python FastAPI)
  static const String aiServiceUrl = String.fromEnvironment(
    'AI_SERVICE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  // ── Network Timeouts ─────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ── API Versioning ───────────────────────────────────────────────────────────
  static const String apiVersion = 'v1';
  static const String apiPrefix = '/api/$apiVersion';

  // ── App Info ─────────────────────────────────────────────────────────────────
  static const String appName = 'DVC Guide';
  static const String appVersion = '0.1.0';
}
