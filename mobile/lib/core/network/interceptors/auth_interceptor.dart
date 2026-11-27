import 'package:dio/dio.dart';
import '../../../features/auth/data/datasources/token_storage.dart';

/// Auth interceptor – adds Authorization header to requests.
/// Reads JWT token from [TokenStorage] and adds `Authorization: Bearer <token>` when present.
class AuthInterceptor extends Interceptor {
  final TokenStorage? _tokenStorage;

  AuthInterceptor({TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final storage = _tokenStorage ?? SecureTokenStorage();
    final token = await storage.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
