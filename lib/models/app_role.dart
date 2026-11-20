/// The roles the server grants, as `user.roles` spells them.
///
/// Display and checks only: which workspace to open comes from the session's
/// `mobile` block, never from a role — an officer may hold several.
enum AppRole {
  mcqAdministrator('MCQ_ADMINISTRATOR', 'Administrator'),
  cmo('CMO', 'Chief Municipal Officer'),
  systemAdministrator('SYSTEM_ADMINISTRATOR', 'System administrator'),
  magistrate('MAGISTRATE', 'Magistrate');

  const AppRole(this.code, this.label);

  /// The server's value, e.g. `MCQ_ADMINISTRATOR`.
  final String code;
  final String label;

  /// Null for a role this build does not know.
  static AppRole? fromCode(String code) {
    final String wanted = code.trim().toUpperCase();
    for (final AppRole role in values) {
      if (role.code == wanted) return role;
    }
    return null;
  }
}
