/// Base exception class for all application errors.
sealed class AppException implements Exception {
  final String message;
  final Object? originalError;

  const AppException({
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message';
}

/// Network connectivity errors (timeout, no internet).
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.originalError,
  });
}

/// HTTP API errors with status codes.
class ApiException extends AppException {
  final int statusCode;

  const ApiException({
    required super.message,
    required this.statusCode,
    super.originalError,
  });
}

/// HTTP 401 Unauthorized – session expired or not authenticated.
class UnauthorizedException extends AppException {
  const UnauthorizedException({
    required super.message,
    super.originalError,
  });
}

/// Unexpected errors not covered by other exception types.
class UnexpectedException extends AppException {
  const UnexpectedException({
    required super.message,
    super.originalError,
  });
}
