import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/storage/secure_token_store.dart';
import '../../../models/auth/session_user.dart';

/// The `/auth` module.
///
/// Sign-in is by **username, not email** — MCQ staff email is optional and
/// many officers do not have one. `device_name` is required: the officer
/// sees it when revoking a lost handset, and it is the key the server uses
/// to replace that device's previous token on re-login. Do not send a UUID.
class AuthRepository {
  AuthRepository({required ApiClient client, required SecureTokenStore tokens})
      : _client = client,
        _tokens = tokens;

  final ApiClient _client;
  final SecureTokenStore _tokens;

  /// `POST /auth/device/login`. Stores the token in the keychain and
  /// nothing else.
  ///
  /// Every failure — wrong password, unknown username, deactivated or
  /// locked account — comes back as one 422 with the same message, so the
  /// client cannot be used to test which usernames exist. Show it as given
  /// and do not try to guess which case it was.
  Future<SignInResult> signIn({
    required String username,
    required String password,
    required String deviceName,
  }) async {
    final envelope = await _client.post(
      ApiConstants.login,
      body: {
        'username': username.trim(),
        'password': password,
        'device_name': deviceName.trim(),
      },
    );
    final result = SignInResult.fromJson(envelope.map);
    await _tokens.write(
      result.token,
      expiresAt: result.expiresAt?.toIso8601String(),
    );
    return result;
  }

  /// `GET /auth/device/session` — call this before rendering anything.
  ///
  /// 200 means the stored token is still good and gives the current user
  /// and permissions. 401 means clear the keychain and show login. Do not
  /// skip it and discover the token is dead three screens in.
  Future<SessionUser> session() async {
    final envelope = await _client.get(ApiConstants.session);
    final userJson = envelope.map['user'];
    return SessionUser.fromJson(
      userJson is Map<String, dynamic> ? userJson : envelope.map,
    );
  }

  /// `POST /auth/device/logout` — revokes only this device's token. The
  /// officer's other devices stay signed in.
  Future<void> signOut() async {
    try {
      await _client.post(ApiConstants.logout);
    } finally {
      // The local token goes whatever the server said: an officer who
      // tapped sign out must not be left holding a live credential.
      await _tokens.clear();
    }
  }

  /// `PUT /auth/password`. Every one of the officer's tokens is revoked on
  /// success, so they sign in again afterwards — by design.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    final envelope = await _client.put(
      ApiConstants.changePassword,
      body: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': confirmation,
      },
    );
    await _tokens.clear();
    return envelope.message;
  }

  Future<void> forgetToken() => _tokens.clear();

  /// Whether this handset is holding a token at all — asked at launch
  /// before the session check, so a first run goes straight to login
  /// instead of making a request that is bound to 401.
  Future<bool> hasToken() async {
    final token = await _tokens.read();
    return token != null && token.isNotEmpty;
  }

  Future<DateTime?> tokenExpiry() => _tokens.readExpiry();
}
