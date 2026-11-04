import 'package:dio/dio.dart';
import '../../../core/error/app_exception.dart';

/// Error interceptor – transforms DioException into AppException.
///
/// Maps HTTP status codes to specific AppException types for consistent
/// error handling across the app.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final AppException appException;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        appException = NetworkException(
          message: 'Kết nối hết thời gian chờ. Vui lòng thử lại.',
          originalError: err,
        );
        break;

      case DioExceptionType.connectionError:
        appException = NetworkException(
          message: 'Không thể kết nối đến server. Kiểm tra kết nối mạng.',
          originalError: err,
        );
        break;

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode ?? 0;
        final serverMessage = _extractMessage(err.response);
        appException = switch (statusCode) {
          400 => ApiException(
              message: serverMessage ?? 'Yêu cầu không hợp lệ.',
              statusCode: statusCode,
              originalError: err,
            ),
          401 => UnauthorizedException(
              message: serverMessage ?? 'Phiên đăng nhập hết hạn.',
              originalError: err,
            ),
          403 => ApiException(
              message: serverMessage ?? 'Bạn không có quyền thực hiện thao tác này.',
              statusCode: statusCode,
              originalError: err,
            ),
          404 => ApiException(
              message: serverMessage ?? 'Không tìm thấy tài nguyên yêu cầu.',
              statusCode: statusCode,
              originalError: err,
            ),
          _ => ApiException(
              message: serverMessage ?? 'Lỗi server. Vui lòng thử lại sau.',
              statusCode: statusCode,
              originalError: err,
            ),
        };
        break;

      default:
        appException = UnexpectedException(
          message: 'Đã xảy ra lỗi không mong muốn.',
          originalError: err,
        );
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: appException,
        type: err.type,
        response: err.response,
      ),
    );
  }

  /// Extract error message from Spring Boot ApiResponse.
  String? _extractMessage(Response? response) {
    try {
      final data = response?.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String?;
      }
    } catch (_) {}
    return null;
  }
}
