import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Secure token and session storage implementation backed by Android Keystore / EncryptedSharedPreferences.
/// Replaces plaintext SharedPreferences XML storage for Supabase JWT tokens.
class SecureLocalStorage extends LocalStorage {
  final FlutterSecureStorage _storage;
  static const String _sessionKey = 'upajo_secure_session_v1';

  SecureLocalStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                resetOnError: true,
              ),
            );

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    try {
      final token = await _storage.read(key: _sessionKey);
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> accessToken() async {
    try {
      return await _storage.read(key: _sessionKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      await _storage.delete(key: _sessionKey);
    } catch (_) {}
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    try {
      await _storage.write(key: _sessionKey, value: persistSessionString);
    } catch (_) {}
  }
}
