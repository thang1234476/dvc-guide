import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

/// Singleton Dio HTTP client with configured interceptors.
///
/// Usage via Riverpod:
/// ```dart
/// final dio = ref.read(apiClientProvider);
/// final response = await dio.get(ApiEndpoints.health);
/// ```
class ApiClient {
  ApiClient._();

  static Dio? _instance;

  /// Returns the configured Dio singleton.
  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        sendTimeout: AppConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors in order: auth first, then error handler
    dio.interceptors.addAll([
      AuthInterceptor(),
      ErrorInterceptor(),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        // Only log in debug mode
        logPrint: (obj) => _debugLog(obj.toString()),
      ),
    ]);

    return dio;
  }

  static void _debugLog(String message) {
    assert(() {
      // ignore: avoid_print
      print('[ApiClient] $message');
      return true;
    }());
  }
}

/// Riverpod provider for the Dio API client.
final apiClientProvider = Provider<Dio>((ref) {
  return ApiClient.instance;
});
