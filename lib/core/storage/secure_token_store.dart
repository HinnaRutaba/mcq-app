import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The bearer token, and only the bearer token, in the OS keychain
/// (Keychain on iOS, Keystore-backed EncryptedSharedPreferences on
/// Android). Never `SharedPreferences`.
class SecureTokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'mcq.auth.token';
  static const String _expiresKey = 'mcq.auth.expires_at';

  String? _cachedToken;

  /// Kept in memory after the first read so the request interceptor does
  /// not hit the keychain on every call.
  String? get cachedToken => _cachedToken;

  Future<String?> read() async {
    _cachedToken ??= await _storage.read(key: _tokenKey);
    return _cachedToken;
  }

  Future<void> write(String token, {String? expiresAt}) async {
    _cachedToken = token;
    await _storage.write(key: _tokenKey, value: token);
    if (expiresAt != null) {
      await _storage.write(key: _expiresKey, value: expiresAt);
    }
  }

  Future<DateTime?> readExpiry() async {
    final raw = await _storage.read(key: _expiresKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> clear() async {
    _cachedToken = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _expiresKey);
  }
}
