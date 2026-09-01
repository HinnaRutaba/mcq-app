import '../core/utils/json_parse.dart';

/// The signed-in officer, as returned by sign-in and by the session check.
///
/// [permissions] is the server's list and the server enforces it regardless —
/// [can] exists so a screen can hide an action the officer cannot perform,
/// not as a security boundary.
class AuthUser {
  const AuthUser({
    this.id,
    required this.username,
    required this.name,
    this.employeeNo,
    this.designation,
    this.mobileNo,
    this.email,
    this.branchId,
    this.locale,
    this.avatarUrl,
    this.mustChangePassword = false,
    this.isActive = true,
    this.isLocked = false,
    this.lastLoginAt,
    this.passwordChangedAt,
    this.permissions = const <String>[],
    this.roles = const <String>[],
    this.createdAt,
  });

  final int? id;

  /// What they sign in with — not the email.
  final String username;
  final String name;
  final String? employeeNo;

  /// e.g. "Municipal Magistrate".
  final String? designation;
  final String? mobileNo;
  final String? email;
  final int? branchId;

  /// e.g. `ur`. The officer's own language preference.
  final String? locale;
  final String? avatarUrl;

  /// When true the officer must change their password before doing anything
  /// else. Doing so revokes every token they hold.
  final bool mustChangePassword;
  final bool isActive;
  final bool isLocked;
  final DateTime? lastLoginAt;
  final DateTime? passwordChangedAt;

  /// Dotted permission strings, e.g. `enforcement.fine.impose`.
  final List<String> permissions;

  /// e.g. `MAGISTRATE`.
  final List<String> roles;
  final DateTime? createdAt;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: Json.integer(json['id']),
    username: Json.stringOr(json['username']),
    name: Json.stringOr(json['name']),
    employeeNo: Json.string(json['employee_no']),
    designation: Json.string(json['designation']),
    mobileNo: Json.string(json['mobile_no']),
    email: Json.string(json['email']),
    branchId: Json.integer(json['branch_id']),
    locale: Json.string(json['locale']),
    avatarUrl: Json.string(json['avatar_url']),
    mustChangePassword: Json.booleanOr(json['must_change_password']),
    isActive: Json.booleanOr(json['is_active'], true),
    isLocked: Json.booleanOr(json['is_locked']),
    lastLoginAt: Json.dateTime(json['last_login_at']),
    passwordChangedAt: Json.dateTime(json['password_changed_at']),
    permissions: Json.stringList(json['permissions']),
    roles: Json.stringList(json['roles']),
    createdAt: Json.dateTime(json['created_at']),
  );

  bool can(String permission) => permissions.contains(permission);

  bool hasRole(String role) => roles.contains(role);
}
