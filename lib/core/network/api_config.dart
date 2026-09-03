/// Where the API lives and every path the magistrate handset calls.
///
/// Paths are complete — they already carry `/api/v1`, exactly as published.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://stag.planmycrew.com';

  /// Version prefix every documented path shares. Used by [ApiPaths.resolve]
  /// when routing from an endpoint the server handed us.
  static const String apiPrefix = '/api/v1';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Generous, because evidence photographs go up over a bazaar's signal.
  static const Duration sendTimeout = Duration(minutes: 2);
}

class ApiPaths {
  ApiPaths._();

  // 0. Master data — fetched once at sign-in and cached
  static const String definitions =
      '${ApiConfig.apiPrefix}/enforcement/definitions';

  // 1. Signing in
  static const String login = '${ApiConfig.apiPrefix}/auth/device/login';
  static const String session = '${ApiConfig.apiPrefix}/auth/device/session';
  static const String logout = '${ApiConfig.apiPrefix}/auth/device/logout';
  static const String password = '${ApiConfig.apiPrefix}/auth/password';

  // 2. Home
  static const String beat = '${ApiConfig.apiPrefix}/enforcement/field/beat';
  static const String activity =
      '${ApiConfig.apiPrefix}/enforcement/field/activity';

  // 3. Defaulters, and today's round
  static const String defaulters =
      '${ApiConfig.apiPrefix}/enforcement/field/defaulters';
  static const String round = '${ApiConfig.apiPrefix}/enforcement/field/round';
  static const String followUps =
      '${ApiConfig.apiPrefix}/enforcement/field/follow-ups';

  // 4. Search — every unit, not only defaulters
  static const String units = '${ApiConfig.apiPrefix}/enforcement/field/units';
  static const String map = '${ApiConfig.apiPrefix}/reporting/map';

  // 5. The shopkeeper profile
  static String propertyProfile(int propertyId) =>
      '${ApiConfig.apiPrefix}/reporting/properties/$propertyId/profile';
  static const String cases = '${ApiConfig.apiPrefix}/enforcement/cases';
  static String caseActions(int caseId) =>
      '${ApiConfig.apiPrefix}/enforcement/cases/$caseId/actions';

  // 7. Imposing a fine
  /// Who is this? — the CNIC search made before writing a fine.
  static const String person =
      '${ApiConfig.apiPrefix}/enforcement/field/person';

  /// A fine on a unit MCQ lets, or on somebody trading at one.
  static String propertyFines(int propertyId) =>
      '${ApiConfig.apiPrefix}/enforcement/properties/$propertyId/fines';

  /// A fine on anybody in the city, against no MCQ property. Scoped by
  /// `area_id` alone.
  static const String fines = '${ApiConfig.apiPrefix}/enforcement/fines';

  /// Opening a case from the handset.
  static const String fieldCases =
      '${ApiConfig.apiPrefix}/enforcement/field/cases';

  static const String evidence = '${ApiConfig.apiPrefix}/enforcement/evidence';

  // 8. Seals and the unseal queue
  static const String seals = '${ApiConfig.apiPrefix}/enforcement/field/seals';
  static String caseSeal(int caseId) =>
      '${ApiConfig.apiPrefix}/enforcement/cases/$caseId/seal';
  static String sealRelease(int sealId) =>
      '${ApiConfig.apiPrefix}/enforcement/seals/$sealId/release';

  // 9. Challans
  static const String challans = '${ApiConfig.apiPrefix}/billing/challans';

  // 10. Trade licences — a different register from everything above
  static const String tradeBeat = '${ApiConfig.apiPrefix}/trade/field/beat';
  static const String tradeLapsed = '${ApiConfig.apiPrefix}/trade/field/lapsed';
  static const String tradeExpiring =
      '${ApiConfig.apiPrefix}/trade/field/expiring';
  static const String tradeLookup = '${ApiConfig.apiPrefix}/trade/field/lookup';
  static const String tradeTariff = '${ApiConfig.apiPrefix}/trade/field/tariff';
  static const String tradePending =
      '${ApiConfig.apiPrefix}/trade/field/pending';
  static const String tradeApplications =
      '${ApiConfig.apiPrefix}/trade/applications/field';

  /// Turns an endpoint the server handed us — a home-screen queue's
  /// `endpoint`, e.g. `enforcement/field/seals?ready=1` — into a path and a
  /// query map, so a queue tile can be opened by routing from the payload
  /// rather than by matching its `key` against a hard-coded path.
  static ({String path, Map<String, dynamic> query}) resolve(String endpoint) {
    final uri = Uri.parse(endpoint.trim());
    final path = uri.path.startsWith('/')
        ? uri.path
        : '${ApiConfig.apiPrefix}/${uri.path}';
    return (
      path: path.startsWith(ApiConfig.apiPrefix)
          ? path
          : '${ApiConfig.apiPrefix}$path',
      query: Map<String, dynamic>.from(uri.queryParameters),
    );
  }
}
