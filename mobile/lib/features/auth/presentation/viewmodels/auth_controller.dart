import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/auth_user.dart';
import '../../data/repositories/auth_repository_provider.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';
import 'token_storage_provider.dart';

class AuthController extends Notifier<AuthState> {
  late AuthRepository _repo;

  @override
  AuthState build() {
    _repo = ref.watch(authRepositoryProvider);
    // Khôi phục phiên khi khởi động
    Future.microtask(() => restoreSession());
    return const AuthState(status: AuthStatus.initial);
  }

  /// Khôi phục phiên làm việc từ TokenStorage khi mở app
    /// Khôi phục phiên khi mở app, gồm hai pha.
  Future<void> restoreSession() async {
    // Pha 1: có token và thông tin lưu sẵn thì vào luôn, không chờ mạng.
    final storage = ref.read(tokenStorageProvider);
    var restoredLocally = false;
    try {
      final token = await storage.readToken();
      final info = await storage.readUserInfo();
      if (token != null && token.isNotEmpty && info != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: () => AuthUser(id: info.id, email: info.email),
          isLoading: false,
          errorMessage: () => null,
        );
        restoredLocally = true;
      }
    } catch (_) {
      // đọc kho lưu trữ lỗi: để pha 2 quyết định
    }

    // Pha 2: hỏi server để lấy hồ sơ đầy đủ và phát hiện token hết hạn.
    try {
      final user = await _repo.currentUser();
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: () => user,
          isLoading: false,
          errorMessage: () => null,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.guest,
          user: () => null,
          isLoading: false,
          errorMessage: () => null,
        );
      }
    } catch (_) {
      // Lỗi bất ngờ: giữ phiên cục bộ nếu có, không thì coi như chưa đăng nhập.
      if (!restoredLocally) {
        state = state.copyWith(
          status: AuthStatus.guest,
          user: () => null,
          isLoading: false,
          errorMessage: () => null,
        );
      }
    }
  }

  /// Đăng nhập
  Future<AuthUser> login({
    required String email,
    required String matKhau,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final user = await _repo.login(email: email, matKhau: matKhau);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: () => user,
        isLoading: false,
        errorMessage: () => null,
      );
      return user;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
      rethrow;
    }
  }

  /// Đăng ký tài khoản mới
  Future<AuthUser> register({
    required String tenHienThi,
    required String email,
    required String matKhau,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final user = await _repo.register(
        tenHienThi: tenHienThi,
        email: email,
        matKhau: matKhau,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: () => user,
        isLoading: false,
        errorMessage: () => null,
      );
      return user;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
      rethrow;
    }
  }

  /// Đăng xuất: xóa token, trở về chế độ khách
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.logout();
    } finally {
      state = state.copyWith(
        status: AuthStatus.guest,
        user: () => null,
        isLoading: false,
        errorMessage: () => null,
      );
    }
  }

  /// Cập nhật thông tin hồ sơ (tên hiển thị, địa phương)
  Future<AuthUser> updateProfile({
    required String tenHienThi,
    int? diaPhuongId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final updatedUser = await _repo.updateProfile(
        tenHienThi: tenHienThi,
        diaPhuongId: diaPhuongId,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: () => updatedUser,
        isLoading: false,
        errorMessage: () => null,
      );
      return updatedUser;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
      rethrow;
    }
  }

  /// Đổi mật khẩu
  Future<void> changePassword({
    required String matKhauHienTai,
    required String matKhauMoi,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      await _repo.changePassword(
        matKhauHienTai: matKhauHienTai,
        matKhauMoi: matKhauMoi,
      );
      state = state.copyWith(isLoading: false, errorMessage: () => null);
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
      rethrow;
    }
  }

  /// Xóa tài khoản
  Future<void> deleteAccount({
    String? matKhau,
    String? email,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      await _repo.deleteAccount(
        matKhau: matKhau,
        email: email,
      );
      state = state.copyWith(
        status: AuthStatus.guest,
        user: () => null,
        isLoading: false,
        errorMessage: () => null,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
      rethrow;
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
