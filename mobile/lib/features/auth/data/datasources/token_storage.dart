import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstract storage for authentication tokens and session info.
abstract class TokenStorage {
  Future<void> saveToken(String token);
  Future<String?> readToken();
  Future<void> deleteToken();

  Future<void> saveUserInfo({required String id, required String email});
  Future<({String id, String email})?> readUserInfo();
  Future<void> deleteUserInfo();

  Future<void> clear();
}

/// Production implementation of [TokenStorage] using [FlutterSecureStorage].
class SecureTokenStorage implements TokenStorage {
  final FlutterSecureStorage _storage;

  static const _keyToken = 'auth_token';
  static const _keyUserId = 'auth_user_id';
  static const _keyUserEmail = 'auth_user_email';

  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  @override
  Future<String?> readToken() async {
    return await _storage.read(key: _keyToken);
  }

  @override
  Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  @override
  Future<void> saveUserInfo({required String id, required String email}) async {
    await _storage.write(key: _keyUserId, value: id);
    await _storage.write(key: _keyUserEmail, value: email);
  }

  @override
  Future<({String id, String email})?> readUserInfo() async {
    final id = await _storage.read(key: _keyUserId);
    final email = await _storage.read(key: _keyUserEmail);
    if (id != null && email != null) {
      return (id: id, email: email);
    }
    return null;
  }

  @override
  Future<void> deleteUserInfo() async {
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyUserEmail);
  }

  @override
  Future<void> clear() async {
    await deleteToken();
    await deleteUserInfo();
  }
}

/// In-memory fake [TokenStorage] for tests.
class FakeTokenStorage implements TokenStorage {
  String? _token;
  String? _userId;
  String? _userEmail;

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }

  @override
  Future<String?> readToken() async {
    return _token;
  }

  @override
  Future<void> deleteToken() async {
    _token = null;
  }

  @override
  Future<void> saveUserInfo({required String id, required String email}) async {
    _userId = id;
    _userEmail = email;
  }

  @override
  Future<({String id, String email})?> readUserInfo() async {
    if (_userId != null && _userEmail != null) {
      return (id: _userId!, email: _userEmail!);
    }
    return null;
  }

  @override
  Future<void> deleteUserInfo() async {
    _userId = null;
    _userEmail = null;
  }

  @override
  Future<void> clear() async {
    _token = null;
    _userId = null;
    _userEmail = null;
  }
}
