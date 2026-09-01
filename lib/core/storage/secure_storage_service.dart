import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The keychain. Everything secret the handset holds belongs here — never in
/// shared preferences, never on disk in plain text.
///
/// "Keychain" is Apple's name for it, and the one this codebase uses for all
/// platforms. On iOS and macOS it is the real thing, so the items are pinned to
/// [KeychainAccessibility.first_unlock_this_device]: readable after the first
/// unlock following a restart (background refresh keeps working) but never
/// migrated to a new device by a backup restore. On Android the same call goes
/// to the Keystore, which holds an AES key the app cannot extract and encrypts
/// each value with it.
///
/// Every value is cached in memory, so a screen firing several calls at once
/// does not hit the platform store once per request.
///
/// **Nothing here throws.** A handset whose store will not answer — a keystore
/// the OS has invalidated, a plugin missing from the build — must not be a
/// handset the officer cannot sign in on. The memory cache is written first and
/// read from when the platform store fails, so the session stays usable for as
/// long as the app is running; it is lost on the next launch, and the officer
/// signs in again. [isPersistent] says which of the two is happening, and the
/// first failure is logged in debug with the real error.
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

  /// The in-memory copy of every value written or read this session. Doubles
  /// as the cache and as the fallback when the platform store will not answer.
  final Map<String, String> _memory = <String, String>{};

  /// Keys already fetched from the platform store, so a miss is not retried.
  final Set<String> _loaded = <String>{};

  bool _isPersistent = true;

  /// False once the platform store has refused a call, meaning whatever is
  /// held will not survive the app being restarted. Nothing in the app is
  /// blocked by this — it is for a diagnostics screen or a log line.
  bool get isPersistent => _isPersistent;

  /// The bearer token for `Authorization: Bearer <token>`, or null when the
  /// officer is signed out.
  Future<String?> readToken() => _read(_tokenKey);

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
    await _write(_tokenKey, token);
    if (expiresAt == null) {
      await _delete(_tokenExpiresAtKey);
    } else {
      await _write(_tokenExpiresAtKey, expiresAt.toUtc().toIso8601String());
    }
    if (username != null) {
      await _write(_usernameKey, username);
    }
  }

  Future<DateTime?> readTokenExpiresAt() async {
    final raw = await _read(_tokenExpiresAtKey);
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
  Future<String?> readUsername() => _read(_usernameKey);

  /// The `device_name` sent at sign-in and shown to the officer in the
  /// server's device list. Stable across sessions on the same handset.
  Future<String?> readDeviceName() => _read(_deviceNameKey);

  Future<void> saveDeviceName(String deviceName) =>
      _write(_deviceNameKey, deviceName);

  /// Drops the token and its expiry, leaving the remembered username and
  /// device name. Called on sign-out, on a 401, and after a password change —
  /// which revokes every token the officer holds.
  Future<void> clearSession() async {
    await _delete(_tokenKey);
    await _delete(_tokenExpiresAtKey);
  }

  /// Wipes everything this app put in the keychain.
  Future<void> clearAll() async {
    await clearSession();
    await _delete(_usernameKey);
    await _delete(_deviceNameKey);
  }

  Future<String?> _read(String key) async {
    if (_loaded.contains(key)) return _memory[key];
    try {
      final value = await _storage.read(key: key);
      if (value != null) _memory[key] = value;
    } catch (error, stackTrace) {
      _noteFailure('read', key, error, stackTrace);
    }
    _loaded.add(key);
    return _memory[key];
  }

  /// Memory first, on purpose: whatever the platform store then does, the
  /// caller can read back what it just wrote.
  Future<void> _write(String key, String value) async {
    _memory[key] = value;
    _loaded.add(key);
    try {
      await _storage.write(key: key, value: value);
    } catch (error, stackTrace) {
      _noteFailure('write', key, error, stackTrace);
    }
  }

  Future<void> _delete(String key) async {
    _memory.remove(key);
    _loaded.add(key);
    try {
      await _storage.delete(key: key);
    } catch (error, stackTrace) {
      _noteFailure('delete', key, error, stackTrace);
    }
  }

  /// Logged once per run in debug only. A swallowed exception with no name is
  /// how a missing plugin gets mistaken for a broken keystore.
  void _noteFailure(
    String operation,
    String key,
    Object error,
    StackTrace stackTrace,
  ) {
    final wasPersistent = _isPersistent;
    _isPersistent = false;
    if (kDebugMode && wasPersistent) {
      debugPrint(
        'SecureStorageService: $operation of "$key" failed, falling back to '
        'memory for the rest of this run. $error',
      );
      debugPrintStack(stackTrace: stackTrace, maxFrames: 8);
    }
  }
}
