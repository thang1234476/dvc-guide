   import 'package:dvc_guide_mobile/features/auth/data/models/auth_user.dart';
   import '../models/dia_phuong.dart';

/// Abstract contract for authentication repository.
///
/// Sau này ứng với:
/// - POST /api/v1/auth/register
/// - POST /api/v1/auth/login
/// - POST /api/v1/auth/logout
/// - GET /me
/// - PUT /api/v1/auth/profile
/// - POST /api/v1/auth/change-password
/// - DELETE /api/v1/auth/account
/// - GET /api/v1/dia-phuong
abstract class AuthRepository {
  Future<AuthUser> register({
    required String tenHienThi,
    required String email,
    required String matKhau,
  });

  Future<AuthUser> login({
    required String email,
    required String matKhau,
  });

  Future<void> logout();

  Future<AuthUser?> currentUser();

  Future<List<DiaPhuong>> getDiaPhuongList();

  Future<AuthUser> updateProfile({
    required String tenHienThi,
    int? diaPhuongId,
  });

  Future<void> changePassword({
    required String matKhauHienTai,
    required String matKhauMoi,
  });

  Future<void> deleteAccount({
    String? matKhau,
    String? email,
  });
}
