import '../../core/utils/json_reader.dart';
import '../../l10n/app_localizations.dart';
import 'permissions.dart';

/// A role the officer holds, as the session endpoint reports it.
class UserRoleRef {
  const UserRoleRef({required this.code, required this.name});

  final String code;
  final String name;

  factory UserRoleRef.fromJson(Map<String, dynamic> json) => UserRoleRef(
        code: json.strOr('role_code'),
        name: json.str('name') ?? json.strOr('role_name'),
      );

  bool get isMagistrate => code.toUpperCase() == 'MAGISTRATE';
}

/// The signed-in officer.
///
/// `GET /auth/device/session` returns this and it is the authority on what
/// the app may offer. Permissions are rows resolved per request — a
/// transferred officer's authority changes without them signing in again —
/// so this object is refetched on launch and never cached past a session.
class SessionUser {
  const SessionUser({
    required this.id,
    required this.username,
    required this.name,
    required this.permissions,
    required this.roles,
    this.employeeNo,
    this.designation,
    this.mobileNo,
    this.email,
    this.localeCode = 'en',
    this.avatarUrl,
    this.mustChangePassword = false,
    this.isActive = true,
    this.isLocked = false,
    this.lastLoginAt,
  });

  final int id;

  /// Username, not email. MCQ staff email is optional and many officers do
  /// not have one — `users.email` is nullable.
  final String username;
  final String name;
  final List<String> permissions;
  final List<UserRoleRef> roles;
  final String? employeeNo;
  final String? designation;
  final String? mobileNo;
  final String? email;
  final String localeCode;
  final String? avatarUrl;
  final bool mustChangePassword;
  final bool isActive;
  final bool isLocked;
  final DateTime? lastLoginAt;

  factory SessionUser.fromJson(Map<String, dynamic> json) => SessionUser(
        id: json.intOr('id'),
        username: json.strOr('username'),
        name: json.strOr('name'),
        permissions: json.strings('permissions'),
        roles: json.children('roles').map(UserRoleRef.fromJson).toList(),
        employeeNo: json.str('employee_no'),
        designation: json.str('designation'),
        mobileNo: json.str('mobile_no'),
        email: json.str('email'),
        localeCode: json.str('locale') ?? 'en',
        avatarUrl: json.str('avatar_url'),
        mustChangePassword: json.boolean('must_change_password'),
        isActive: json.boolean('is_active', fallback: true),
        isLocked: json.boolean('is_locked'),
        lastLoginAt: json.date('last_login_at'),
      );

  /// The officer's own language preference, honoured on first launch and
  /// overridable in settings.
  AppLocale get locale => AppLocale.fromCode(localeCode);

  /// Hide or disable anything the officer cannot do: an affordance that
  /// leads to a 403 is worse than no affordance.
  bool can(String permission) =>
      permissions.contains(Permissions.all) || permissions.contains(permission);

  bool canAll(List<String> required) => required.every(can);
  bool canAny(List<String> any) => any.any(can);

  /// A locked or inactive account must not get past the launch screen even
  /// if the token still works.
  bool get isBlocked => !isActive || isLocked;
}

/// What `POST /auth/device/login` returns.
class SignInResult {
  const SignInResult({
    required this.token,
    required this.user,
    this.expiresAt,
  });

  final String token;
  final SessionUser user;
  final DateTime? expiresAt;

  factory SignInResult.fromJson(Map<String, dynamic> json) => SignInResult(
        token: json.strOr('token'),
        user: SessionUser.fromJson(json.child('user') ?? const {}),
        expiresAt: json.date('expires_at'),
      );
}
