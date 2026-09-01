/// Route path constants used with [GoRouter].
///
/// Screens and controllers should always navigate through these constants
/// (never a raw string literal) so paths stay in one place.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';

  // --- Officer app (API-backed) ----------------------------------------
  static const String login = '/officer/login';
  static const String changePassword = '/officer/password';

  /// Shell branches — the five things an officer does, in the order he
  /// does them: see the beat, work the list, walk the round, find the unit
  /// in front of him, everything else.
  static const String today = '/officer/today';
  static const String defaulters = '/officer/defaulters';
  static const String round = '/officer/round';
  static const String find = '/officer/find';
  static const String more = '/officer/more';

  // --- The field module ------------------------------------------------
  static const String followUps = '/officer/follow-ups';
  static const String activity = '/officer/activity';
  static const String map = '/officer/map';
  static const String cases = '/officer/cases';

  /// The fallback behind a beat tile the app has no designed screen for.
  /// The server's own `endpoint` travels in `extra`, so a queue MCQ adds
  /// later still opens rather than dead-ending.
  static const String queueList = '/officer/queue-list';

  /// The result of imposing a fine — the fine number, the challan, the
  /// Consumer Number and the payment link.
  static const String fineResult = '/officer/fine-result';

  // --- Pushed full-screen routes ---------------------------------------
  static const String caseDetail = '/officer/case/:caseId';
  static const String recordAction = '/officer/case/:caseId/action';
  static const String sealCase = '/officer/case/:caseId/seal';
  static const String releaseSeal = '/officer/seal/:sealId/release';
  static const String seals = '/officer/seals';
  static const String fines = '/officer/fines';
  static const String propertyProfile = '/officer/property/:propertyId';

  /// The older unit-detail screen, kept reachable for the prototype
  /// screens that predate the field module.
  static const String unitProfile = '/officer/unit/:propertyId';
  static const String imposeFine = '/officer/property/:propertyId/fine';
  static const String recordInspection =
      '/officer/property/:propertyId/inspection';
  static const String legal = '/officer/legal';
  static const String queue = '/officer/queue';
  static const String settings = '/officer/settings';

  /// `?state=due` — the home screen's "Promises to chase" tile.
  static String followUpsPath({String? state}) =>
      state == null ? followUps : '$followUps?state=$state';

  /// `?ready=1` — the home screen's "Ready to unseal" tile.
  static String sealsPath({bool readyOnly = false}) =>
      readyOnly ? '$seals?ready=1' : seals;

  /// `?assigned=me` — the cases the taxation branch sent this officer.
  static String casesPath({bool assignedToMe = false}) =>
      assignedToMe ? '$cases?assigned=me' : cases;

  static String caseDetailPath(int caseId) => '/officer/case/$caseId';
  static String recordActionPath(int caseId) => '/officer/case/$caseId/action';
  static String sealCasePath(int caseId) => '/officer/case/$caseId/seal';
  static String releaseSealPath(int sealId) => '/officer/seal/$sealId/release';
  /// [from] names the list the officer tapped, so the profile can carry
  /// the same [Hero] tags and the card visibly expands into the page
  /// instead of cutting to it.
  /// Encoded, because a market name has spaces in it and an unencoded
  /// space in a location string is a route that does not parse.
  static String propertyProfilePath(
    int propertyId, {
    String from = 'defaulters',
  }) =>
      '/officer/property/$propertyId?from=${Uri.encodeComponent(from)}';
  static String unitProfilePath(int propertyId) =>
      '/officer/unit/$propertyId';
  static String imposeFinePath(int propertyId) =>
      '/officer/property/$propertyId/fine';
  static String recordInspectionPath(int propertyId) =>
      '/officer/property/$propertyId/inspection';

  // --- Demo screens that predate the API layer -------------------------
  // Kept so the earlier prototype screens still compile. They are not
  // reachable from the officer app; the API-backed screens above replaced
  // them.
  static const String tenantHome = '/tenant/home';
  static const String tenantPayments = '/tenant/payments';
  static const String tenantProfile = '/tenant/profile';
  static const String magistrateHome = '/magistrate/home';
  static const String magistrateCollections = '/magistrate/collections';
  static const String magistrateSealed = '/magistrate/sealed';
  static const String magistrateProfile = '/magistrate/profile';
  static const String createChalaan = '/magistrate/chalaan/new';
  static const String collectionDetail = '/magistrate/collections/:id';

  static String collectionDetailPath(String chalaanId) =>
      '/magistrate/collections/$chalaanId';
}
