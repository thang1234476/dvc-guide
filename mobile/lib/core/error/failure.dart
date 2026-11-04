/// Failure types for the UI layer.
/// Failures are derived from AppException but are UI-friendly.
///
/// Use these in ViewModel state to represent error states.
/// The UI uses pattern matching to display appropriate messages.
sealed class Failure {
  final String message;
  const Failure(this.message);
}

/// Network connectivity failure.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Không có kết nối mạng.']);
}

/// Server-side API failure.
class ApiFailure extends Failure {
  final int? statusCode;
  const ApiFailure(super.message, {this.statusCode});
}

/// Authentication failure (401).
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Phiên đăng nhập hết hạn.']);
}

/// Unexpected/unknown failure.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Đã xảy ra lỗi không mong muốn.']);
}
