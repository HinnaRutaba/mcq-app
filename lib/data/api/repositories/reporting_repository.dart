import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/read_cache.dart';
import '../../../models/common/fetched.dart';
import '../../../models/property/property_summary.dart';
import '../../../models/reporting/dashboard.dart';
import '../../../models/reporting/defaulter_row.dart';

/// The `/reporting` module: the dashboard, the full defaulters register,
/// and a property's profile.
///
/// Reads here are cached. On a connection failure the last successful read
/// is returned with its own timestamp rather than an error, and the screen
/// shows the stamp — see [Fetched].
class ReportingRepository {
  ReportingRepository({required ApiClient client, required ReadCache cache})
      : _client = client,
        _cache = cache;

  final ApiClient _client;
  final ReadCache _cache;

  /// `GET /reporting/dashboard` — area-scoped. Compare `scope` and
  /// `receivable.owed` as a magistrate against an administrator: they must
  /// differ.
  Future<Fetched<DashboardSummary>> dashboard() async {
    try {
      final envelope = await _client.get(ApiConstants.dashboard);
      await _cache.write(ReadCache.dashboard, envelope.map);
      return Fetched(value: DashboardSummary.fromJson(envelope.map), fetchedAt: DateTime.now());
    } on ApiException catch (error) {
      final cached = error.isNetwork ? _cache.readMap(ReadCache.dashboard) : null;
      if (cached == null) rethrow;
      return Fetched(
        value: DashboardSummary.fromJson(cached.value),
        fetchedAt: cached.fetchedAt,
        fromCache: true,
      );
    }
  }

  /// `GET /reporting/reports/defaulters` — the working list, and the screen
  /// the app is built around.
  ///
  /// It returns the officer's whole scoped set with server-computed totals
  /// rather than a page, so no `page` parameter is sent and sorting and
  /// filtering happen on the device.
  Future<Fetched<DefaultersReport>> defaulters() async {
    try {
      final envelope = await _client.get(ApiConstants.defaultersReport);
      await _cache.write(ReadCache.defaulters, envelope.map);
      return Fetched(
        value: DefaultersReport.fromJson(envelope.map),
        fetchedAt: DateTime.now(),
      );
    } on ApiException catch (error) {
      final cached =
          error.isNetwork ? _cache.readMap(ReadCache.defaulters) : null;
      if (cached == null) rethrow;
      return Fetched(
        value: DefaultersReport.fromJson(cached.value),
        fetchedAt: cached.fetchedAt,
        fromCache: true,
      );
    }
  }

  /// `GET /reporting/properties/{property}/profile` — property, allotment,
  /// allottee, balance and history in one response.
  Future<PropertyProfile> propertyProfile(int propertyId) async {
    final envelope = await _client.get(ApiConstants.propertyProfile(propertyId));
    return PropertyProfile.fromJson(envelope.map);
  }
}
