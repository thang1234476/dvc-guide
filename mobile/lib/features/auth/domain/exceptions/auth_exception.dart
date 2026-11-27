/// Error codes for authentication exceptions.
enum AuthErrorCode {
  emailDaTonTai,
  saiThongTin,
  saiMatKhauHienTai,
  taiKhoanBiKhoa,
  loiMang,
  khac,
}

/// Domain exception for authentication failures.
class AuthException implements Exception {
  final AuthErrorCode code;
  final String message;

  const AuthException(this.code, this.message);

  @override
  String toString() => 'AuthException($code): $message';
}
