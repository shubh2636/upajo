import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Hardware-backed secure token and credential storage for Upajo Android app.
/// Uses Android Keystore (AES-256 GCM) to prevent credential extraction from rooted devices.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                resetOnError: true,
              ),
            );

  static const _keyAccessToken = 'upajo_access_token';
  static const _keyRefreshToken = 'upajo_refresh_token';
  static const _keyUserPhone = 'upajo_user_phone';
  static const _keyUserRole = 'upajo_user_role';
  static const _keyUserId = 'upajo_user_id';

  Future<void> saveAuthSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String phone,
    required String role,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyUserPhone, value: phone);
    await _storage.write(key: _keyUserRole, value: role);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  Future<String?> getUserPhone() async {
    return await _storage.read(key: _keyUserPhone);
  }

  Future<String?> getUserRole() async {
    return await _storage.read(key: _keyUserRole);
  }

  Future<void> updateUserRole(String role) async {
    await _storage.write(key: _keyUserRole, value: role);
  }

  Future<void> clearAuthSession() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyUserPhone);
    await _storage.delete(key: _keyUserRole);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
