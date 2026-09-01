import '../../core/network/api_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/api_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../models/device_session.dart';

abstract class AuthRepository {
  Future<DeviceSession> signIn({
    required String username,
    required String password,
    required String deviceName,
  });

  Future<DeviceSession> currentSession();

  Future<void> signOut();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });

  /// Whether a token is on the device at all — the cheap check a splash screen
  /// makes before deciding whether [currentSession] is worth calling.
  Future<bool> hasStoredSession();

  /// The last username signed in with, for pre-filling the form. Never the
  /// password.
  Future<String?> rememberedUsername();

  /// The device name last signed in with, so a re-sign-in on the same handset
  /// does not create a second device entry.
  Future<String?> rememberedDeviceName();
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({required this._api, required this._storage});

  final ApiService _api;
  final SecureStorageService _storage;

  @override
  Future<DeviceSession> signIn({
    required String username,
    required String password,
    required String deviceName,
  }) async {
    final response = await _api.post(
      ApiPaths.login,
      // The one call with no token to send. Its 401 means "wrong password",
      // not "session over", so it must not trip the sign-out handling.
      requiresAuth: false,
      body: <String, dynamic>{
        'username': username,
        'password': password,
        'device_name': deviceName,
      },
    );

    final session = DeviceSession.fromJson(response.dataMap);
    if (!session.hasToken) {
      throw const ApiException(
        message: 'Signed in, but no token came back. Please try again.',
        failure: ApiFailure.unknown,
      );
    }

    await _storage.saveSession(
      token: session.token!,
      expiresAt: session.tokenExpiresAt,
      username: username,
    );
    await _storage.saveDeviceName(deviceName);
    return session;
  }

  @override
  Future<DeviceSession> currentSession() async {
    final response = await _api.get(ApiPaths.session);
    return DeviceSession.fromJson(response.dataMap);
  }

  @override
  Future<void> signOut() async {
    try {
      await _api.post(ApiPaths.logout);
    } finally {
      // The officer asked to be signed out. A failed call is no reason to leave
      // a live token on a handset that is about to change hands.
      await _storage.clearSession();
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _api.put(
      ApiPaths.password,
      body: <String, dynamic>{
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': confirmPassword,
      },
    );
    // Success revokes every token, including the one we just used.
    await _storage.clearSession();
  }

  @override
  Future<bool> hasStoredSession() => _storage.hasToken();

  @override
  Future<String?> rememberedUsername() => _storage.readUsername();

  @override
  Future<String?> rememberedDeviceName() => _storage.readDeviceName();
}
