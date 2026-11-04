import 'package:dio/dio.dart';

/// Auth interceptor – adds Authorization header to requests.
///
/// Currently a placeholder. Will be implemented when JWT authentication is added.
/// Future implementation:
/// 1. Read JWT token from flutter_secure_storage
/// 2. Add `Authorization: Bearer <token>` header
/// 3. Handle 401 responses by refreshing the token
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    // TODO: Add JWT token when authentication is implemented
    // final token = await _secureStorage.read(key: 'access_token');
    // if (token != null) {
    //   options.headers['Authorization'] = 'Bearer $token';
    // }
    handler.next(options);
  }
}
