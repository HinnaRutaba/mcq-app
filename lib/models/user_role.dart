/// The two roles supported by the app.
///
/// Each role gets its own dashboard and set of features; the login screen
/// is shared, and the role checkbox on it decides which one is used.
enum UserRole {
  magistrate,
  tenant;

  String get label => switch (this) {
        UserRole.magistrate => 'Magistrate',
        UserRole.tenant => 'Tenant',
      };
}
