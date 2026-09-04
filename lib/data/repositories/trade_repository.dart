import '../../core/network/api_config.dart';
import '../../core/network/api_service.dart';
import '../../models/trade_application_request.dart';
import '../../models/trade_application.dart';
import '../../models/trade_beat.dart';
import '../../models/trade_licence.dart';
import '../../models/trade_tariff.dart';

/// Trade licences — the shops MCQ does not let.
///
/// A **different register** from everything in the enforcement module. Those
/// are MCQ's own shops, let under agreements; these are the businesses around
/// Quetta that MCQ licenses but is not landlord to. Same bazaar, second job.
///
/// Nothing here has an allotment, an allottee or a property: a licence is keyed
/// on a CNIC and a mobile number. Do not try to join the two registers in the
/// app — a shopkeeper who appears in both is two records that happen to share a
/// name, and merging them would assert an identity nobody verified.
abstract class TradeRepository {
  /// The licensing home screen: the officer's bazaars and the three queues.
  ///
  /// Route each tile from its `FieldQueue.endpoint`, which arrives absolute
  /// here (`/api/v1/trade/field/expiring`) rather than relative as on the
  /// enforcement beat. `ApiPaths.resolve` reads both.
  ///
  /// Cached, like the enforcement definitions: the bazaars on it are what both
  /// the licence picker and the capture form are drawn from, and an officer's
  /// postings change between shifts, not between screens. Concurrent callers
  /// share one call. Pass [refresh] for a pull-to-refresh.
  Future<TradeBeat> beat({bool refresh});

  /// The beat already in hand, without a call. Null before the first fetch, so
  /// a screen can draw its bazaar picker on the first frame when it is warm and
  /// tell "not asked yet" from "no bazaars".
  TradeBeat? get cachedBeat;

  /// Throws the beat away, for a sign-out: the next officer on this handset is
  /// posted to their own bazaars, not the last one's.
  void forgetBeat();

  /// Licences that ran out in the last 90 days and were not renewed — the
  /// round list.
  ///
  /// A shopkeeper who renewed early is already excluded. Do not filter again on
  /// the client: a second filter over the server's window is how a shop that
  /// has paid ends up being visited anyway.
  Future<List<TradeLicence>> lapsed();

  /// Licences running out inside 30 days.
  ///
  /// The same window that raises the renewal challan, so everybody on this list
  /// has already been sent a demand — the visit is a reminder, not news.
  Future<List<TradeLicence>> expiring();

  /// The doorway lookup, by CNIC, mobile, licence number or verification code.
  ///
  /// Deliberately **not** area-scoped: a licence issued in the next bazaar is
  /// still valid, and an officer standing in front of a shop needs the true
  /// answer rather than the one their posting allows.
  ///
  /// Read `TradeLicenceLookup.hasValidLicence`, never `found` alone.
  /// Found-and-lapsed is a renewal; never-licensed is a capture.
  Future<TradeLicenceLookup> lookup(String query);

  /// Every trade with its price in one bazaar, grouped for a picker.
  ///
  /// The bazaar is required — `tariff?area_id=` prices one, and the officer
  /// names it before anything can be quoted.
  ///
  /// Cache it — MCQ reprices a zone a few times a year. An unpriced trade comes
  /// back with a null fee and is counted in `TradeTariff.unpriced`; never
  /// render that as `0.00`. `TradeCategory.canQuote` is the flag to gate the
  /// picker on.
  Future<TradeTariff> tariff({required int areaId});

  /// The officer's own field captures that have not been paid.
  ///
  /// Scoped to them, not to the bazaar — somebody else's captures are not
  /// theirs to chase.
  Future<List<TradeApplication>> pending();

  /// Captures an unlicensed shop on the spot.
  ///
  /// The only write in this module, and it does four things at once: prices the
  /// licence, raises the challan, issues a payment link and texts the
  /// shopkeeper. Never *compute* the fee in the app — quote it off the tariff
  /// for (trade x zone) and send it back as `fee_amount`, which is the figure
  /// the officer stood in front of the shopkeeper and agreed.
  ///
  /// Unlike every enforcement write, this endpoint accepts no
  /// `client_action_uuid`, so a resend is **not** made safe by the server.
  /// After a timeout, check [pending] before sending again.
  Future<TradeApplication> submitApplication(TradeApplicationRequest request);
}

class ApiTradeRepository implements TradeRepository {
  ApiTradeRepository({required this._api});

  final ApiService _api;

  TradeBeat? _cachedBeat;

  /// The call in flight, so the licences screen and the capture form opening
  /// together wait on one call rather than starting two.
  Future<TradeBeat>? _beatInFlight;

  @override
  TradeBeat? get cachedBeat => _cachedBeat;

  @override
  Future<TradeBeat> beat({bool refresh = false}) {
    final TradeBeat? held = _cachedBeat;
    if (held != null && !refresh) return Future<TradeBeat>.value(held);
    return _beatInFlight ??= _fetchBeat();
  }

  Future<TradeBeat> _fetchBeat() async {
    try {
      final response = await _api.get(ApiPaths.tradeBeat);
      final TradeBeat beat = TradeBeat.fromJson(response.dataMap);
      _cachedBeat = beat;
      return beat;
    } finally {
      // Cleared whether or not it worked: a failed fetch must not leave a
      // rejected future behind for every later caller to trip over.
      _beatInFlight = null;
    }
  }

  @override
  void forgetBeat() {
    _cachedBeat = null;
    _beatInFlight = null;
  }

  @override
  Future<List<TradeLicence>> lapsed() => _licences(ApiPaths.tradeLapsed);

  @override
  Future<List<TradeLicence>> expiring() => _licences(ApiPaths.tradeExpiring);

  @override
  Future<TradeLicenceLookup> lookup(String query) async {
    final response = await _api.get(
      ApiPaths.tradeLookup,
      query: <String, dynamic>{'q': query},
    );
    return TradeLicenceLookup.fromJson(response.dataMap);
  }

  @override
  Future<TradeTariff> tariff({required int areaId}) async {
    final response = await _api.get(
      ApiPaths.tradeTariff,
      query: <String, dynamic>{'area_id': areaId},
    );
    return TradeTariff.fromJson(response.dataMap);
  }

  @override
  Future<List<TradeApplication>> pending() async {
    final response = await _api.get(ApiPaths.tradePending);
    return response.dataList.map(TradeApplication.fromJson).toList();
  }

  @override
  Future<TradeApplication> submitApplication(
    TradeApplicationRequest request,
  ) async {
    final response = await _api.post(
      ApiPaths.tradeApplications,
      body: request.toJson(),
    );
    return TradeApplication.fromJson(response.dataMap);
  }

  Future<List<TradeLicence>> _licences(String path) async {
    final response = await _api.get(path);
    return response.dataList.map(TradeLicence.fromJson).toList();
  }
}
