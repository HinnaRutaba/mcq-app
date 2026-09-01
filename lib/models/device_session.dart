import '../core/utils/json_parse.dart';
import 'auth_user.dart';

/// The result of signing in, and of the launch-time session check.
///
/// Sign-in returns the bearer token; the session check returns only the
/// officer, because the handset already holds the token — so [token] is null
/// there and [hasToken] is how you tell the two apart.
class DeviceSession {
  const DeviceSession({required this.user, this.token, this.tokenExpiresAt});

  final AuthUser user;

  /// The bearer token. Belongs in the keychain and nowhere else — the auth
  /// repository writes it there on sign-in.
  final String? token;

  /// Null for a token the server did not put an expiry on.
  final DateTime? tokenExpiresAt;

  /// Reads both the login and the session payload. The token key is read
  /// leniently because the login response was not captured in the published
  /// spec, only described.
  factory DeviceSession.fromJson(Map<String, dynamic> json) => DeviceSession(
    user: AuthUser.fromJson(Json.map(json['user'])),
    token: Json.string(
      Json.pick(json, <String>[
        'token',
        'access_token',
        'bearer_token',
        'plain_text_token',
      ]),
    ),
    tokenExpiresAt: Json.dateTime(
      Json.pick(json, <String>['token_expires_at', 'expires_at']),
    ),
  );

  bool get hasToken => token != null && token!.isNotEmpty;

  /// The officer has to change their password before the app is usable.
  bool get mustChangePassword => user.mustChangePassword;
}
