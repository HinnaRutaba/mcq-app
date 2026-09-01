/// Every URL the app talks to, in one place, grouped by API module.
///
/// Paths are relative to [ApiConstants.baseUrl] (which already ends in
/// `/api/v1`), so a repository writes `ApiConstants.dashboard`, never a
/// literal. Note the doubled segment in the property module — the module is
/// `property` and the resource is `properties`; getting that wrong is a 404
/// that looks like an auth problem and is not.
class ApiConstants {
  ApiConstants._();

  /// Host, without a trailing slash. Defaults to MCQ's staging instance;
  /// override per build:
  ///
  /// ```
  /// flutter run --dart-define=MCQ_API_HOST=https://mcq.example
  /// ```
  ///
  /// Verified against staging: no token on `/auth/device/session` is a 401
  /// with `{"message","code":"unauthenticated"}`, and a bad login body is a
  /// 422 with an `errors` map — both shapes this client already handles.
  /// The test-account passwords are still an open question — see
  /// QUESTIONS.md.
  static const String host = String.fromEnvironment(
    'MCQ_API_HOST',
    defaultValue: 'https://stag.planmycrew.com',
  );

  static const String baseUrl = '$host/api/v1';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 60);

  /// GETs are retried twice on a connection timeout. A POST is never
  /// retried by the transport — `POST .../seal` is not idempotent at the
  /// HTTP layer and a double-seal is a real problem. Replays happen only
  /// through the offline queue, which carries `client_action_uuid`.
  static const int getRetryCount = 2;
  static const Duration getRetryBackoff = Duration(milliseconds: 800);

  // --- auth -------------------------------------------------------------
  static const String login = '/auth/device/login';
  static const String session = '/auth/device/session';
  static const String logout = '/auth/device/logout';
  static const String changePassword = '/auth/password';

  // --- enforcement: the field module ------------------------------------
  // Seven endpoints built for this handset. Every one of them answers a
  // whole screen in a single request, because five requests on a weak
  // bazaar signal is a screen that never finishes painting.

  /// The entire home screen in one call. Get this working first — if it
  /// works, everything else follows.
  static const String fieldBeat = '/enforcement/field/beat';

  /// Today's round: the officer's defaulters grouped by market and ordered
  /// by what is worth walking to.
  static const String fieldRound = '/enforcement/field/round';

  /// The working list. Rich enough that a card decides without opening
  /// anything.
  static const String fieldDefaulters = '/enforcement/field/defaulters';

  /// Promises to chase and revisits set. `?state=due|upcoming`, or
  /// everything.
  static const String fieldFollowUps = '/enforcement/field/follow-ups';

  /// One list, two readings: everything sealed, and — with `?ready=1` —
  /// the ones now settled and waiting to be opened again.
  static const String fieldSeals = '/enforcement/field/seals';

  /// Every unit in the officer's areas, **including vacant ones**, in the
  /// same card shape as a defaulter. An encroachment has no agreement and
  /// is the commonest field offence there is.
  static const String fieldUnits = '/enforcement/field/units';

  /// "My work" — what this officer has actually done, over a period.
  static const String fieldActivity = '/enforcement/field/activity';

  // --- reporting --------------------------------------------------------
  static const String dashboard = '/reporting/dashboard';

  /// Every unit with coordinates, for the map.
  static const String reportingMap = '/reporting/map';
  static const String defaultersReport = '/reporting/reports/defaulters';
  static String propertyProfile(int propertyId) =>
      '/reporting/properties/$propertyId/profile';

  // --- enforcement: cases ----------------------------------------------
  static const String cases = '/enforcement/cases';
  static String caseById(int caseId) => '/enforcement/cases/$caseId';
  static String caseActions(int caseId) => '/enforcement/cases/$caseId/actions';
  static String caseSeal(int caseId) => '/enforcement/cases/$caseId/seal';
  static String caseClose(int caseId) => '/enforcement/cases/$caseId/close';
  static String openCaseForAllotment(int allotmentId) =>
      '/enforcement/allotments/$allotmentId/cases';

  // --- enforcement: seals ----------------------------------------------
  static const String seals = '/enforcement/seals';
  static String sealById(int sealId) => '/enforcement/seals/$sealId';
  static String sealRelease(int sealId) => '/enforcement/seals/$sealId/release';

  // --- enforcement: fines ----------------------------------------------
  static const String fines = '/enforcement/fines';
  static String propertyFines(int propertyId) =>
      '/enforcement/properties/$propertyId/fines';

  // --- enforcement: evidence -------------------------------------------
  /// Upload first, get a path back, then send the path with the action.
  /// Throttled to 60 uploads a minute.
  static const String evidence = '/enforcement/evidence';

  // --- property ---------------------------------------------------------
  static const String properties = '/property/properties';
  static String propertyById(int propertyId) =>
      '/property/properties/$propertyId';
  static String propertyDocuments(int propertyId) =>
      '/property/properties/$propertyId/documents';
  static const String inspections = '/property/inspections';
  static String inspectionById(int inspectionId) =>
      '/property/inspections/$inspectionId';
  static String propertyInspections(int propertyId) =>
      '/property/properties/$propertyId/inspections';
  static String inspectionPhoto(int inspectionId) =>
      '/property/inspections/$inspectionId/photo';
  static String inspectionResolve(int inspectionId) =>
      '/property/inspections/$inspectionId/resolve';

  // --- allotment --------------------------------------------------------
  static const String allotments = '/allotment/allotments';
  static String allotmentById(int allotmentId) =>
      '/allotment/allotments/$allotmentId';
  static const String allottees = '/allotment/allottees';
  static String allotteeById(int allotteeId) =>
      '/allotment/allottees/$allotteeId';

  // --- billing ----------------------------------------------------------
  static const String challans = '/billing/challans';
  static String allotteeChallans(int allotteeId) =>
      '/billing/allottees/$allotteeId/challans';

  // --- payment ----------------------------------------------------------
  static const String payments = '/payment/payments';

  /// Unauthenticated — the per-challan token *is* the credential. The app
  /// does not render this page; it only tells the officer the link went out.
  static String publicPayment(String token) => '/payment/public/$token';

  // --- legal (read-only for a magistrate) ------------------------------
  static const String legalCases = '/legal/cases';
  static String legalCaseById(int caseId) => '/legal/cases/$caseId';
  static String legalCaseHearings(int caseId) =>
      '/legal/cases/$caseId/hearings';
  static const String legalDiary = '/legal/cases/diary';

  // --- location ---------------------------------------------------------
  static const String postings = '/location/postings';
  static const String areas = '/location/areas';

  // --- notification -----------------------------------------------------
  static const String notifications = '/notification/notifications';

  // --- query parameter names -------------------------------------------
  static const String qPerPage = 'per_page';
  static const String qPage = 'page';
  static const String qSearch = 'q';
  static const String qSort = 'sort';
  static const String qStatus = 'status';
  static const String qUserId = 'user_id';
  static const String qAllotmentId = 'allotment_id';
  static const String qAreaId = 'area_id';
  static const String qPropertyId = 'property_id';
  static const String qLimit = 'limit';
  static const String qDays = 'days';
  static const String qState = 'state';
  static const String qReady = 'ready';
  static const String qNeverPaid = 'never_paid';
  static const String qDefaultersOnly = 'defaulters_only';

  /// The magistrate module's search parameter is `search`, not the `q` the
  /// older list endpoints take. Both exist; do not mix them up.
  static const String qFieldSearch = 'search';

  /// `?magistrate_id=me` — the cases the taxation branch assigned to this
  /// officer. The server resolves "me" from the token.
  static const String qMagistrateId = 'magistrate_id';
  static const String magistrateMe = 'me';

  /// A field list is fetched whole rather than paged — a magistrate's beat
  /// is tens of rows, not thousands, and a second request on bazaar data
  /// costs more than the extra bytes.
  static const int fieldListLimit = 100;

  /// Keep pages modest on a bazaar connection.
  static const int defaultPerPage = 25;
}
