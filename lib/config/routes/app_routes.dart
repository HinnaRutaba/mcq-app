/// Route path constants used with [GoRouter].
///
/// Screens and controllers should always navigate through these constants
/// (never a raw string literal) so paths stay in one place.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String magistrateDashboard = '/magistrate';
  static const String tenantDashboard = '/tenant';
}
