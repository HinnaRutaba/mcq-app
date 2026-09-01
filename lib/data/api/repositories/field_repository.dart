import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/read_cache.dart';
import '../../../models/common/fetched.dart';
import '../../../models/field/beat.dart';
import '../../../models/field/field_activity.dart';
import '../../../models/field/field_card.dart';
import '../../../models/field/field_seal.dart';
import '../../../models/field/follow_up.dart';
import '../../../models/field/map_unit.dart';
import '../../../models/field/round.dart';

/// The `/enforcement/field` module — the seven endpoints built for this
/// handset, plus the map.
///
/// Every one of them answers a whole screen in a single request. That is
/// the point of the module and it is why nothing here fans out into three
/// calls to assemble a page: five requests on a weak bazaar signal is a
/// screen that never finishes painting.
///
/// Reads that an officer opens first thing in the morning are cached. A
/// cached figure is never allowed to look live — the [Fetched] wrapper
/// carries `fromCache` and the stamp all the way to the banner.
class FieldRepository {
  FieldRepository({required ApiClient client, required ReadCache cache})
      : _client = client,
        _cache = cache;

  final ApiClient _client;
  final ReadCache _cache;

  // --- The home screen ---------------------------------------------------

  /// `GET /enforcement/field/beat` — who he is, where he is posted, and the
  /// six queues. One call, the whole home screen.
  Future<Fetched<FieldBeat>> beat() async {
    try {
      final envelope = await _client.get(ApiConstants.fieldBeat);
      await _cache.write(ReadCache.beat, envelope.map);
      return Fetched(
        value: FieldBeat.fromJson(envelope.map),
        fetchedAt: DateTime.now(),
      );
    } on ApiException catch (error) {
      final cached = error.isNetwork ? _cache.readMap(ReadCache.beat) : null;
      if (cached == null) rethrow;
      return Fetched(
        value: FieldBeat.fromJson(cached.value),
        fetchedAt: cached.fetchedAt,
        fromCache: true,
      );
    }
  }

  // --- Today's round -----------------------------------------------------

  /// `GET /enforcement/field/round`, already ordered by broken promises
  /// first. **Do not re-sort it here** — the order is the endpoint's whole
  /// argument.
  Future<Fetched<List<RoundMarket>>> round() =>
      _cachedList(
        path: ApiConstants.fieldRound,
        cacheName: ReadCache.round,
        parse: RoundMarket.listFrom,
      );

  // --- The working list --------------------------------------------------

  /// `GET /enforcement/field/defaulters` — sorted by amount owed, largest
  /// first, by the server.
  ///
  /// [search] matches allottee name, property code, agreement number, shop
  /// number and mobile. Only the first, unfiltered page is cached: a cached
  /// *search* would answer a different question than the one asked.
  Future<Fetched<List<FieldCard>>> defaulters({
    int? areaId,
    String? search,
    bool? neverPaid,
    int limit = ApiConstants.fieldListLimit,
  }) {
    final filtered =
        areaId != null || (search ?? '').isNotEmpty || neverPaid == true;
    return _cachedList(
      path: ApiConstants.fieldDefaulters,
      cacheName: filtered ? null : ReadCache.fieldDefaulters,
      parse: FieldCard.listFrom,
      query: {
        ApiConstants.qAreaId: areaId,
        ApiConstants.qFieldSearch: (search ?? '').isEmpty ? null : search,
        ApiConstants.qNeverPaid: neverPaid == true ? 1 : null,
        ApiConstants.qLimit: limit,
      },
    );
  }

  // --- Search, including the units nobody holds --------------------------

  /// `GET /enforcement/field/units` — the same card shape as a defaulter,
  /// with the tenancy fields null where there is no agreement.
  ///
  /// **Vacant units are included deliberately.** A shop that is fully paid
  /// up does not appear in the defaulter list at all, and it is exactly the
  /// one the officer is standing in front of; an encroachment or a hawker
  /// has no agreement at all, and a fine against one is the commonest field
  /// offence there is.
  Future<List<FieldCard>> units({
    String? search,
    int? areaId,
    int limit = 50,
  }) async {
    final envelope = await _client.get(
      ApiConstants.fieldUnits,
      query: {
        ApiConstants.qFieldSearch: (search ?? '').isEmpty ? null : search,
        ApiConstants.qAreaId: areaId,
        ApiConstants.qLimit: limit,
      },
    );
    return FieldCard.listFrom(envelope.list);
  }

  // --- The chase queue ---------------------------------------------------

  /// `GET /enforcement/field/follow-ups`. [state] is `due` (overdue and
  /// today) or `upcoming`; null returns everything.
  Future<Fetched<List<FollowUp>>> followUps({String? state}) => _cachedList(
        path: ApiConstants.fieldFollowUps,
        cacheName: state == null ? ReadCache.followUps : null,
        parse: FollowUp.listFrom,
        query: {ApiConstants.qState: state},
      );

  // --- Seals, and the unseal queue ---------------------------------------

  /// `GET /enforcement/field/seals`, or `?ready=1` for the ones now
  /// settled. One list, two readings — see [FieldSeal].
  Future<Fetched<List<FieldSeal>>> seals({bool readyOnly = false}) =>
      _cachedList(
        path: ApiConstants.fieldSeals,
        cacheName: readyOnly ? null : ReadCache.fieldSeals,
        parse: FieldSeal.listFrom,
        query: {ApiConstants.qReady: readyOnly ? 1 : null},
      );

  // --- My work -----------------------------------------------------------

  /// `GET /enforcement/field/activity?days=30`.
  Future<Fetched<FieldActivity>> activity({int days = 30}) async {
    final canCache = days == 30;
    try {
      final envelope = await _client.get(
        ApiConstants.fieldActivity,
        query: {ApiConstants.qDays: days},
      );
      if (canCache) await _cache.write(ReadCache.activity, envelope.map);
      return Fetched(
        value: FieldActivity.fromJson(envelope.map),
        fetchedAt: DateTime.now(),
      );
    } on ApiException catch (error) {
      final cached = error.isNetwork && canCache
          ? _cache.readMap(ReadCache.activity)
          : null;
      if (cached == null) rethrow;
      return Fetched(
        value: FieldActivity.fromJson(cached.value),
        fetchedAt: cached.fetchedAt,
        fromCache: true,
      );
    }
  }

  // --- The map -----------------------------------------------------------

  /// `GET /reporting/map`. Units without coordinates are counted rather
  /// than dropped, so the screen can say how many are missing.
  Future<MapUnits> mapUnits({bool defaultersOnly = true}) async {
    final envelope = await _client.get(
      ApiConstants.reportingMap,
      query: {ApiConstants.qDefaultersOnly: defaultersOnly ? 1 : null},
    );
    // Some deployments wrap the pins under `units`; take either shape.
    final rows = envelope.data is List
        ? envelope.list
        : (envelope.map['units'] as List? ?? const []);
    return MapUnits.fromList(rows);
  }

  // --- Following the server's own route ----------------------------------

  /// Fetches whatever list a beat tile's `endpoint` names.
  ///
  /// MCQ was explicit that no number on the dashboard may be a dead end,
  /// and the server hands the route over in the payload precisely so the
  /// app does not hard-code paths. Tiles the app has a designed screen for
  /// open that screen; anything the server adds later still opens, through
  /// here, as a list of cards.
  Future<List<FieldCard>> listAtEndpoint(String endpoint) async {
    final uri = Uri.parse(endpoint);
    final path = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
    final envelope = await _client.get(
      path,
      query: {for (final entry in uri.queryParameters.entries) entry.key: entry.value},
    );
    return FieldCard.listFrom(envelope.list);
  }

  // --- Shared plumbing ---------------------------------------------------

  /// A list read that falls back to the last good copy when — and only
  /// when — the network is the thing that failed.
  ///
  /// A 403 or a 500 must **not** serve a cached list: the first is a
  /// refusal the officer needs to see and the second is a server the
  /// officer needs to know about. Quietly showing yesterday's rows for
  /// either is how an app lies.
  Future<Fetched<List<T>>> _cachedList<T>({
    required String path,
    required String? cacheName,
    required List<T> Function(List<dynamic> raw) parse,
    Map<String, dynamic>? query,
  }) async {
    try {
      final envelope = await _client.get(path, query: query);
      if (cacheName != null) {
        await _cache.write(cacheName, envelope.list);
      }
      return Fetched(value: parse(envelope.list), fetchedAt: DateTime.now());
    } on ApiException catch (error) {
      final cached = error.isNetwork && cacheName != null
          ? _cache.readList(cacheName)
          : null;
      if (cached == null) rethrow;
      return Fetched(
        value: parse(cached.value),
        fetchedAt: cached.fetchedAt,
        fromCache: true,
      );
    }
  }
}
