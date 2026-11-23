import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dvc_guide_mobile/core/network/api_endpoints.dart';

import '../../domain/exceptions/auth_exception.dart';
import '../../domain/models/dia_phuong.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/token_storage.dart';
import '../models/auth_user.dart';

/// Bản thật của [AuthRepository], gọi Spring Boot qua Dio.
/// Backend bọc mọi response dạng { success, message, data, timestamp }.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({
    required Dio dio,
    required TokenStorage tokenStorage,
  })  : _dio = dio,
        _tokenStorage = tokenStorage;

  final Dio _dio;
  final TokenStorage _tokenStorage;

  static const String _device = 'dvc_guide_mobile';

  // ── Đăng ký / đăng nhập ─────────────────────────────────────────────────────

  @override
  Future<AuthUser> register({
    required String tenHienThi,
    required String email,
    required String matKhau,
  }) {
    return _guard(() async {
      final name = tenHienThi.trim();
      final res = await _dio.post(ApiEndpoints.register, data: {
        'email': email.trim(),
        'password': matKhau,
        if (name.isNotEmpty) 'displayName': name,
        'device': _device,
      });
      return _saveSession(_data(res));
    });
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String matKhau,
  }) {
    return _guard(
      () async {
        final res = await _dio.post(ApiEndpoints.login, data: {
          'email': email.trim(),
          'password': matKhau,
          'device': _device,
        });
        return _saveSession(_data(res));
      },
      unauthorized: AuthErrorCode.saiThongTin,
    );
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (_) {
      // Lỗi mạng vẫn phải đăng xuất cục bộ.
    }
    await _tokenStorage.clear();
  }

  // ── Người dùng hiện tại ─────────────────────────────────────────────────────

  @override
  Future<AuthUser?> currentUser() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) return null;

    try {
      final res = await _dio.get(ApiEndpoints.me);
      return _userFromProfile(_data(res));
    } catch (e) {
      // Token hết hạn / bị thu hồi -> coi như chưa đăng nhập.
      if (e is DioException && e.response?.statusCode == 401) {
        await _tokenStorage.clear();
        return null;
      }
      // Lỗi mạng: dùng thông tin đã lưu để app vẫn mở được.
      final info = await _tokenStorage.readUserInfo();
      if (info == null) return null;
      return AuthUser(id: info.id, email: info.email);
    }
  }

  @override
  Future<AuthUser> updateProfile({
    required String tenHienThi,
    int? diaPhuongId,
  }) {
    return _guard(() async {
      // Backend bắt buộc gửi remindersEnabled nên lấy giá trị hiện tại.
      final current = _data(await _dio.get(ApiEndpoints.me));
      final res = await _dio.put(ApiEndpoints.me, data: {
        'displayName': tenHienThi.trim(),
        'localityId': diaPhuongId,
        'remindersEnabled': current['remindersEnabled'] as bool? ?? true,
      });
      return _userFromProfile(_data(res));
    });
  }

  @override
  Future<void> changePassword({
    required String matKhauHienTai,
    required String matKhauMoi,
  }) async {
    // Backend chưa có endpoint đổi mật khẩu.
    throw const AuthException(
      AuthErrorCode.khac,
      'Chức năng đổi mật khẩu chưa được hỗ trợ.',
    );
  }

  @override
  Future<void> deleteAccount({String? matKhau, String? email}) {
    // Backend không kiểm tra mật khẩu; UI đã xác nhận trước khi gọi.
    return _guard(() async {
      await _dio.delete(ApiEndpoints.me);
      await _tokenStorage.clear();
    });
  }

  // ── Địa phương ──────────────────────────────────────────────────────────────

  @override
  Future<List<DiaPhuong>> getDiaPhuongList() {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.localities);
      return _dataList(res)
          // Chỉ lấy cấp cao nhất (tỉnh/thành), như bản mock.
          .where((m) => m['parentId'] == null)
          .map((m) => DiaPhuong(
                id: (m['id'] as num).toInt(),
                ten: m['name'] as String,
                loai: _loai(m['level'] as String?),
              ))
          .toList();
    });
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<AuthUser> _saveSession(Map<String, dynamic> data) async {
    final user = _userFromProfile(data['user'] as Map<String, dynamic>);
    final session = data['session'] as Map<String, dynamic>;
    await _tokenStorage.saveToken(session['token'] as String);
    await _tokenStorage.saveUserInfo(id: user.id, email: user.email);
    return user;
  }

  AuthUser _userFromProfile(Map<String, dynamic> p) => AuthUser(
        id: p['id'] as String,
        email: p['email'] as String,
        tenHienThi: p['displayName'] as String?,
        diaPhuongId: (p['localityId'] as num?)?.toInt(),
      );

  String _loai(String? level) => switch (level) {
        'trung_uong' => 'Trung ương',
        'tinh' => 'Tỉnh',
        'huyen' => 'Huyện',
        'xa' => 'Xã',
        _ => '',
      };

  Map<String, dynamic> _body(Response res) {
    final raw = res.data;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String) return jsonDecode(raw) as Map<String, dynamic>;
    throw const FormatException('Response không phải JSON object');
  }

  Map<String, dynamic> _data(Response res) =>
      _body(res)['data'] as Map<String, dynamic>;

  List<Map<String, dynamic>> _dataList(Response res) =>
      (_body(res)['data'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();

  /// Bọc lời gọi API, đổi mọi lỗi thành [AuthException] cho UI.
  Future<T> _guard<T>(
    Future<T> Function() body, {
    AuthErrorCode unauthorized = AuthErrorCode.khac,
  }) async {
    try {
      return await body();
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e, unauthorized);
    } catch (_) {
      throw const AuthException(
        AuthErrorCode.khac,
        'Dữ liệu từ server không đúng định dạng.',
      );
    }
  }

  AuthException _mapDio(DioException e, AuthErrorCode unauthorized) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const AuthException(
          AuthErrorCode.loiMang,
          'Lỗi kết nối mạng, vui lòng thử lại',
        );
      case DioExceptionType.badResponse:
        {
          final status = e.response?.statusCode;
          final serverMsg = _serverMessage(e.response);
          if (status == 401) {
            return AuthException(
              unauthorized,
              serverMsg ??
                  (unauthorized == AuthErrorCode.saiThongTin
                      ? 'Email hoặc mật khẩu không chính xác'
                      : 'Phiên đăng nhập đã hết hạn'),
            );
          }
          if (status == 409) {
            return const AuthException(
              AuthErrorCode.emailDaTonTai,
              'Email đã được đăng ký trong hệ thống',
            );
          }
          return AuthException(
            AuthErrorCode.khac,
            serverMsg ?? 'Đã xảy ra lỗi (mã $status)',
          );
        }
      default:
        return const AuthException(
          AuthErrorCode.khac,
          'Đã xảy ra lỗi không mong muốn',
        );
    }
  }

  String? _serverMessage(Response? res) {
    final d = res?.data;
    if (d is Map<String, dynamic>) return d['message'] as String?;
    return null;
  }
}