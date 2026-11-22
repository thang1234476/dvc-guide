import '../datasources/token_storage.dart';
import '../models/auth_user.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../../domain/models/dia_phuong.dart';
import '../../domain/repositories/auth_repository.dart';

/// Danh sách địa phương mẫu (tỉnh / thành phố) dùng cho việc chọn nơi ở hiện tại.
/// Dữ liệu mẫu gồm 10 tỉnh/thành phố tiêu biểu.
const List<DiaPhuong> mockDiaPhuongList = [
  DiaPhuong(id: 1, ten: 'TP. Hà Nội', loai: 'Thành phố trực thuộc TW'),
  DiaPhuong(id: 2, ten: 'TP. Hồ Chí Minh', loai: 'Thành phố trực thuộc TW'),
  DiaPhuong(id: 3, ten: 'TP. Đà Nẵng', loai: 'Thành phố trực thuộc TW'),
  DiaPhuong(id: 4, ten: 'TP. Hải Phòng', loai: 'Thành phố trực thuộc TW'),
  DiaPhuong(id: 5, ten: 'TP. Cần Thơ', loai: 'Thành phố trực thuộc TW'),
  DiaPhuong(id: 6, ten: 'Thừa Thiên Huế', loai: 'Tỉnh'),
  DiaPhuong(id: 7, ten: 'Quảng Ninh', loai: 'Tỉnh'),
  DiaPhuong(id: 8, ten: 'Nghệ An', loai: 'Tỉnh'),
  DiaPhuong(id: 9, ten: 'Bình Dương', loai: 'Tỉnh'),
  DiaPhuong(id: 10, ten: 'Đồng Nai', loai: 'Tỉnh'),
];

/// In-memory user account record for mock repository.
/// Note: Passwords are kept in memory only for the lifetime of the mock instance
/// to verify credentials during testing / demo. Never logged or persisted to disk.
class _MockUserAccount {
  final AuthUser user;
  final String password;

  _MockUserAccount({
    required this.user,
    required this.password,
  });
}

class MockAuthRepository implements AuthRepository {
  final TokenStorage tokenStorage;

  // In-memory accounts for this runtime session
  final Map<String, _MockUserAccount> _accounts = {};

  MockAuthRepository({required this.tokenStorage}) {
    // Demo account: demo@dvcguide.vn / Demo1234
    const demoUser = AuthUser(
      id: 'demo-user-uuid-1234-5678',
      email: 'demo@dvcguide.vn',
      tenHienThi: 'Người dùng Demo',
      diaPhuongId: 1,
    );
    _accounts[demoUser.email.toLowerCase()] = _MockUserAccount(
      user: demoUser,
      password: 'Demo1234',
    );
  }

  @override
  Future<AuthUser> register({
    required String tenHienThi,
    required String email,
    required String matKhau,
  }) async {
    // 0.8s artificial delay
    await Future.delayed(const Duration(milliseconds: 800));

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.contains('loi')) {
      throw const AuthException(
        AuthErrorCode.loiMang,
        'Lỗi kết nối mạng, vui lòng thử lại',
      );
    }

    if (_accounts.containsKey(normalizedEmail)) {
      throw const AuthException(
        AuthErrorCode.emailDaTonTai,
        'Email đã được đăng ký trong hệ thống',
      );
    }

    // Create new user in session memory
    final newUser = AuthUser(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim(),
      tenHienThi: tenHienThi.trim(),
      diaPhuongId: null,
    );

    _accounts[normalizedEmail] = _MockUserAccount(
      user: newUser,
      password: matKhau,
    );

    // Save fake token and user info
    final fakeToken = 'mock_jwt_token_${newUser.id}';
    await tokenStorage.saveToken(fakeToken);
    await tokenStorage.saveUserInfo(id: newUser.id, email: newUser.email);

    return newUser;
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String matKhau,
  }) async {
    // 0.8s artificial delay
    await Future.delayed(const Duration(milliseconds: 800));

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.contains('loi')) {
      throw const AuthException(
        AuthErrorCode.loiMang,
        'Lỗi kết nối mạng, vui lòng thử lại',
      );
    }

    final account = _accounts[normalizedEmail];
    if (account == null || account.password != matKhau) {
      throw const AuthException(
        AuthErrorCode.saiThongTin,
        'Email hoặc mật khẩu không chính xác',
      );
    }

    // Save fake token and user info
    final fakeToken = 'mock_jwt_token_${account.user.id}';
    await tokenStorage.saveToken(fakeToken);
    await tokenStorage.saveUserInfo(id: account.user.id, email: account.user.email);

    return account.user;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    await tokenStorage.clear();
  }

  @override
  Future<AuthUser?> currentUser() async {
    final token = await tokenStorage.readToken();
    if (token == null) return null;

    final info = await tokenStorage.readUserInfo();
    if (info == null) return null;

    final account = _accounts[info.email.toLowerCase()];
    if (account != null) {
      return account.user;
    }

    // Fallback if session persisted user details
    return AuthUser(
      id: info.id,
      email: info.email,
      tenHienThi: null,
      diaPhuongId: null,
    );
  }

  @override
  Future<List<DiaPhuong>> getDiaPhuongList() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return mockDiaPhuongList;
  }

  @override
  Future<AuthUser> updateProfile({
    required String tenHienThi,
    int? diaPhuongId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final info = await tokenStorage.readUserInfo();
    if (info == null) {
      throw const AuthException(AuthErrorCode.khac, 'Chưa đăng nhập');
    }
    final normalizedEmail = info.email.toLowerCase();
    final account = _accounts[normalizedEmail];
    if (account == null) {
      throw const AuthException(AuthErrorCode.khac, 'Không tìm thấy tài khoản');
    }

    final updatedUser = account.user.copyWith(
      tenHienThi: tenHienThi.trim(),
      diaPhuongId: diaPhuongId,
    );

    _accounts[normalizedEmail] = _MockUserAccount(
      user: updatedUser,
      password: account.password,
    );

    return updatedUser;
  }

  @override
  Future<void> changePassword({
    required String matKhauHienTai,
    required String matKhauMoi,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final info = await tokenStorage.readUserInfo();
    if (info == null) {
      throw const AuthException(AuthErrorCode.khac, 'Chưa đăng nhập');
    }
    final normalizedEmail = info.email.toLowerCase();
    final account = _accounts[normalizedEmail];
    if (account == null) {
      throw const AuthException(AuthErrorCode.khac, 'Không tìm thấy tài khoản');
    }

    if (account.password != matKhauHienTai) {
      throw const AuthException(
        AuthErrorCode.saiMatKhauHienTai,
        'Mật khẩu hiện tại không đúng',
      );
    }

    _accounts[normalizedEmail] = _MockUserAccount(
      user: account.user,
      password: matKhauMoi,
    );
  }

  @override
  Future<void> deleteAccount({
    String? matKhau,
    String? email,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final info = await tokenStorage.readUserInfo();
    if (info == null) {
      throw const AuthException(AuthErrorCode.khac, 'Chưa đăng nhập');
    }
    final normalizedEmail = info.email.toLowerCase();
    final account = _accounts[normalizedEmail];
    if (account == null) {
      throw const AuthException(AuthErrorCode.khac, 'Không tìm thấy tài khoản');
    }

    final inputMatchesEmail = email != null && email.trim().toLowerCase() == normalizedEmail;
    final inputMatchesPassword = matKhau != null && matKhau == account.password;

    if (!inputMatchesEmail && !inputMatchesPassword) {
      throw const AuthException(
        AuthErrorCode.saiThongTin,
        'Email hoặc mật khẩu xác nhận không chính xác',
      );
    }

    _accounts.remove(normalizedEmail);
    await tokenStorage.clear();
  }
}
