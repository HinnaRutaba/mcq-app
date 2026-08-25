/// Route path constants used with [GoRouter].
///
/// Screens and controllers should always navigate through these constants
/// (never a raw string literal) so paths stay in one place.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';

  // --- Tenant shell branches ------------------------------------------
  static const String tenantHome = '/tenant/home';
  static const String tenantPayments = '/tenant/payments';
  static const String tenantProfile = '/tenant/profile';

  // --- Magistrate shell branches ---------------------------------------
  static const String magistrateHome = '/magistrate/home';
  static const String magistrateCollections = '/magistrate/collections';
  static const String magistrateSealed = '/magistrate/sealed';
  static const String magistrateProfile = '/magistrate/profile';

  // --- Pushed full-screen routes (appear above the shell/bottom nav) ---
  static const String createChalaan = '/magistrate/chalaan/new';
  static const String collectionDetail = '/magistrate/collections/:id';

  static String collectionDetailPath(String chalaanId) =>
      '/magistrate/collections/$chalaanId';
}
