import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/network/api_exception.dart';
import '../data/repositories/trade_repository.dart';
import '../models/field_beat.dart';
import '../models/trade_application.dart';
import '../models/trade_beat.dart';
import '../models/trade_licence.dart';

/// Which licensing queue is on screen.
///
/// Three lists, not three filters over one: the licence queues come off
/// `trade/field/{expiring,lapsed}` and the captures off `trade/field/pending`,
/// which is scoped to the officer rather than to the bazaar.
enum TradeQueue {
  /// Running out inside 30 days. Everybody here has already been sent a
  /// renewal demand, so the visit is a reminder rather than news.
  expiring('Expiring'),

  /// Ran out in the last 90 days and was not renewed.
  lapsed('Lapsed'),

  /// This officer's own field captures, still unpaid.
  captures('My captures');

  const TradeQueue(this.label);

  final String label;
}

/// The licensing screen: the officer's bazaars, the three queues behind them,
/// and the doorway lookup.
///
/// Five of the module's seven calls live here — `beat`, `expiring`, `lapsed`,
/// `pending` and `lookup`. The tariff and the capture write belong to the
/// form, see [TradeCaptureController].
///
/// The lookup is not a filter over the lists: it is a different question, asked
/// of the whole city rather than the beat, so a query puts the screen into an
/// answer rather than narrowing what is already on it.
class TradeLicencesController extends GetxController {
  TradeLicencesController({TradeRepository? tradeRepository})
    : _trade = tradeRepository ?? Get.find<TradeRepository>();

  final TradeRepository _trade;

  /// The area filter's "everywhere" entry. A sentinel rather than null, so the
  /// picker always has an item to show; real area ids are positive.
  static const int allAreas = 0;

  static const Duration searchDebounce = Duration(milliseconds: 400);

  /// A licence is looked up by a whole CNIC, mobile, licence number or
  /// verification code — never by a prefix. Below this the box is somebody
  /// mid-type, and a call would answer "not on the register" about it.
  static const int minQueryLength = 4;

  /// Seeded from the repository's cache, so a screen opened after the beat has
  /// been warmed draws its bazaar picker on the first frame instead of over a
  /// spinner. See [TradeBeatController], which warms it at sign-in.
  late final Rxn<TradeBeat> beat = Rxn<TradeBeat>(_trade.cachedBeat);

  final RxList<TradeLicence> expiring = RxList<TradeLicence>();
  final RxList<TradeLicence> lapsed = RxList<TradeLicence>();
  final RxList<TradeApplication> captures = RxList<TradeApplication>();

  final Rx<TradeQueue> queue = Rx<TradeQueue>(TradeQueue.expiring);

  final RxInt areaId = RxInt(allAreas);

  final RxString query = RxString('');

  final TextEditingController searchController = TextEditingController();

  final Rxn<TradeLicenceLookup> answer = Rxn<TradeLicenceLookup>();

  final RxBool isLooking = RxBool(false);

  /// Kept apart from [errorMessage]: a lookup that would not go through is a
  /// failed question, not a failed screen, and the queues behind it are still
  /// good.
  final RxnString lookupError = RxnString();

  final RxBool isLoading = RxBool(false);

  final RxnString errorMessage = RxnString();

  /// Bumped per lookup, so a slow answer to an old question cannot land on top
  /// of a newer one.
  int _lookupTicket = 0;

  @override
  void onInit() {
    super.onInit();
    debounce<String>(query, (_) => _lookup(), time: searchDebounce);
    load(refreshBeat: false);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // --- The beat ---------------------------------------------------------

  /// The bazaars these queues cover, said out loud. [TradeBeat] carries no
  /// city-wide figure to fall back on, so without this a reader takes the
  /// counts for the whole of Quetta.
  String? get scopeSentence {
    final FieldScope? scope = beat.value?.scope;
    if (scope == null || !scope.hasAreas) return null;
    return scope.areaSentence;
  }

  /// How many licences are live in those bazaars — the one figure the beat
  /// carries that no list here repeats.
  int? get liveCount => beat.value?.queue('live')?.count;

  DateTime? get generatedAt => beat.value?.generatedAt;

  List<FieldArea> get areas => beat.value?.scope.areas ?? const <FieldArea>[];

  /// The picker's entries: everywhere, then each bazaar on the beat.
  List<int> get areaOptions => <int>[
    allAreas,
    for (final FieldArea area in areas)
      if (area.id != null) area.id!,
  ];

  /// Whether there is anything to pick between — nothing is, until the beat
  /// has landed. Asked here rather than counted off [areaOptions] twice: the
  /// filter bar's height turns on it as well as the picker itself.
  bool get hasAreaChoice => areaOptions.length > 1;

  String areaLabel(int id) {
    if (id == allAreas) return 'All bazaars';
    for (final FieldArea area in areas) {
      if (area.id == id) return area.areaName;
    }
    return 'Bazaar $id';
  }

  // --- What the list shows ----------------------------------------------

  /// The licence rows for the chosen queue, narrowed to the chosen bazaar.
  ///
  /// The bazaar is narrowed here because neither list endpoint takes an
  /// `area_id` — both are already scoped to the officer's postings, and this
  /// is the officer choosing one of them. The server's own 30- and 90-day
  /// windows are never re-applied: a shop that has paid must not be visited
  /// because the handset recomputed a date.
  List<TradeLicence> get visibleLicences => _inArea<TradeLicence>(
    queue.value == TradeQueue.lapsed ? lapsed : expiring,
    (TradeLicence licence) => licence.areaName,
  );

  List<TradeApplication> get visibleCaptures => _inArea<TradeApplication>(
    captures,
    (TradeApplication capture) => capture.areaName,
  );

  /// How many rows are in [queue] under the current bazaar — the figure on its
  /// chip.
  int countOf(TradeQueue which) => switch (which) {
    TradeQueue.expiring => _inArea<TradeLicence>(
      expiring,
      (TradeLicence l) => l.areaName,
    ).length,
    TradeQueue.lapsed => _inArea<TradeLicence>(
      lapsed,
      (TradeLicence l) => l.areaName,
    ).length,
    TradeQueue.captures => visibleCaptures.length,
  };

  bool get hasData =>
      beat.value != null ||
      expiring.isNotEmpty ||
      lapsed.isNotEmpty ||
      captures.isNotEmpty;

  /// Whether the screen is answering the doorway question rather than showing
  /// a queue. True the moment anything is typed — the box takes over the body,
  /// and a short query says so instead of calling.
  bool get isLookingUp => query.value.isNotEmpty;

  /// Whether the query is long enough to be a whole record.
  bool get hasFullQuery => query.value.length >= minQueryLength;

  /// Whether a filter is narrowing the queues. Drives the "clear" offer on an
  /// empty screen — a filter that emptied the list has to be undoable from the
  /// list it emptied.
  bool get isNarrowed =>
      areaId.value != allAreas || queue.value != TradeQueue.expiring;

  List<T> _inArea<T>(List<T> rows, String? Function(T row) areaOf) {
    final String? name = _chosenAreaName;
    if (name == null) return rows.toList();
    return rows.where((T row) => areaOf(row) == name).toList();
  }

  /// The chosen bazaar by name, which is all a licence carries — this register
  /// is not the property register and its rows have no `area_id`.
  String? get _chosenAreaName {
    if (areaId.value == allAreas) return null;
    for (final FieldArea area in areas) {
      if (area.id == areaId.value) return area.areaName;
    }
    return null;
  }

  // --- What the officer does --------------------------------------------

  /// Everything the screen shows. Safe to call again — this is the
  /// pull-to-refresh, which is the one place the bazaars are asked for again.
  ///
  /// Never blocks on the beat: with it already in hand [hasData] is true from
  /// the first frame, so the queues land under the thin bar on the filter row
  /// rather than behind a full-screen spinner.
  Future<void> load({bool refreshBeat = true}) async {
    isLoading.value = true;
    errorMessage.value = null;
    await Future.wait(<Future<void>>[
      _loadBeat(refresh: refreshBeat),
      _loadExpiring(),
      _loadLapsed(),
      _loadCaptures(),
    ]);
    isLoading.value = false;
  }

  /// Called per keystroke; the lookup behind it is debounced.
  void search(String term) => query.value = term.trim();

  void clearSearch() {
    searchController.clear();
    query.value = '';
  }

  /// No call: the rows for every queue are already in hand.
  void showQueue(TradeQueue which) => queue.value = which;

  void setArea(int? id) => areaId.value = id ?? allAreas;

  void clearFilters() {
    queue.value = TradeQueue.expiring;
    areaId.value = allAreas;
    clearSearch();
  }

  /// Asks the doorway question again after it failed to go through.
  Future<void> retryLookup() => _lookup();

  /// Re-reads the officer's own captures after one has been written. The
  /// capture endpoint carries no `client_action_uuid`, so this list is also how
  /// an officer finds out whether a submission that timed out actually landed.
  Future<void> reloadCaptures() => _loadCaptures();

  Future<void> _loadBeat({bool refresh = false}) async {
    try {
      beat.value = await _trade.beat(refresh: refresh);
    } on ApiException catch (error) {
      _report(error);
    }
  }

  Future<void> _loadExpiring() async {
    try {
      expiring.value = await _trade.expiring();
    } on ApiException catch (error) {
      _report(error);
    }
  }

  Future<void> _loadLapsed() async {
    try {
      lapsed.value = await _trade.lapsed();
    } on ApiException catch (error) {
      _report(error);
    }
  }

  Future<void> _loadCaptures() async {
    try {
      captures.value = await _trade.pending();
    } on ApiException catch (error) {
      _report(error);
    }
  }

  Future<void> _lookup() async {
    if (!hasFullQuery) {
      // Abandons whatever is in flight: an answer about a longer query is not
      // an answer about what is in the box now.
      _lookupTicket++;
      answer.value = null;
      lookupError.value = null;
      isLooking.value = false;
      return;
    }

    final int ticket = ++_lookupTicket;
    isLooking.value = true;
    lookupError.value = null;
    try {
      final TradeLicenceLookup found = await _trade.lookup(query.value);
      if (ticket != _lookupTicket) return;
      answer.value = found;
    } on ApiException catch (error) {
      if (ticket != _lookupTicket) return;
      lookupError.value = error.message;
      answer.value = null;
    } finally {
      if (ticket == _lookupTicket) isLooking.value = false;
    }
  }

  /// The first failure wins. Four calls go out together and one dead radio
  /// fails all of them; four copies of the same sentence is not four problems.
  void _report(ApiException error) => errorMessage.value ??= error.message;
}
