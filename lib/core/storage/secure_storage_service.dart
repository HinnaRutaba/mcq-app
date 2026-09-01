import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The keychain. Everything secret the handset holds lives here and nowhere
/// else — never in shared preferences, never on disk in plain text.
///
/// The bearer token is the whole of the officer's authority, on a device that
/// travels a bazaar all day, so the Apple items are pinned to
/// [KeychainAccessibility.first_unlock_this_device]: readable after the first
/// unlock following a restart (background refresh keeps working) but never
/// migrated to a new device by a backup restore.
///
/// The token is cached in memory after the first read so that a screen firing
/// several calls at once does not hit the keychain once per request; every
/// write and clear invalidates that cache.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
            mOptions: MacOsOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  static const String _tokenKey = 'mcq.auth.bearer_token';
  static const String _tokenExpiresAtKey = 'mcq.auth.token_expires_at';
  static const String _usernameKey = 'mcq.auth.username';
  static const String _deviceNameKey = 'mcq.device.name';

  final FlutterSecureStorage _storage;

  String? _cachedToken;
  bool _tokenRead = false;

  /// The bearer token for `Authorization: Bearer <token>`, or null when the
  /// officer is signed out.
  Future<String?> readToken() async {
    if (_tokenRead) return _cachedToken;
    _cachedToken = await _storage.read(key: _tokenKey);
    _tokenRead = true;
    return _cachedToken;
  }

  Future<bool> hasToken() async {
    final token = await readToken();
    return token != null && token.isNotEmpty;
  }

  /// Stores what a successful sign-in returned. [expiresAt] is nullable
  /// because the server may issue a token that does not expire.
  Future<void> saveSession({
    required String token,
    DateTime? expiresAt,
    String? username,
  }) async {
    _cachedToken = token;
    _tokenRead = true;
    await _storage.write(key: _tokenKey, value: token);
    if (expiresAt == null) {
      await _storage.delete(key: _tokenExpiresAtKey);
    } else {
      await _storage.write(
        key: _tokenExpiresAtKey,
        value: expiresAt.toUtc().toIso8601String(),
      );
    }
    if (username != null) {
      await _storage.write(key: _usernameKey, value: username);
    }
  }

  Future<DateTime?> readTokenExpiresAt() async {
    final raw = await _storage.read(key: _tokenExpiresAtKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  /// True only when an expiry is known and already past. A token with no
  /// stated expiry is not treated as expired — the server is the authority,
  /// and a 401 is what actually ends a session.
  Future<bool> isTokenExpired() async {
    final expiresAt = await readTokenExpiresAt();
    return expiresAt != null && expiresAt.isBefore(DateTime.now().toUtc());
  }

  /// Kept so the sign-in screen can pre-fill the username. Never the password.
  Future<String?> readUsername() => _storage.read(key: _usernameKey);

  /// The `device_name` sent at sign-in and shown to the officer in the
  /// server's device list. Stable across sessions on the same handset.
  Future<String?> readDeviceName() => _storage.read(key: _deviceNameKey);

  Future<void> saveDeviceName(String deviceName) =>
      _storage.write(key: _deviceNameKey, value: deviceName);

  /// Drops the token and its expiry, leaving the remembered username and
  /// device name. Called on sign-out, on a 401, and after a password change —
  /// which revokes every token the officer holds.
  Future<void> clearSession() async {
    _cachedToken = null;
    _tokenRead = true;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _tokenExpiresAtKey);
  }

  /// Wipes everything this app put in the keychain.
  Future<void> clearAll() async {
    _cachedToken = null;
    _tokenRead = true;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _tokenExpiresAtKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _deviceNameKey);
  }
}
