import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/network/api_exception.dart';
import '../data/repositories/dashboard_repository.dart';
import '../data/repositories/defaulters_repository.dart';
import '../models/defaulter_card.dart';
import '../models/field_beat.dart';

enum DefaulterState {
  everyone('Everyone'),

  /// Has never paid anything at all — a different problem from having fallen
  /// behind.
  neverPaid('Never paid'),

  /// A promise to pay is on record.
  promised('Promised'),

  sealed('Sealed'),

  /// A live enforcement case on the unit.
  openCase('Open case');

  const DefaulterState(this.label);

  final String label;

  bool matches(DefaulterCard card) => switch (this) {
    DefaulterState.everyone => true,
    DefaulterState.neverPaid => card.neverPaid,
    DefaulterState.promised => card.hasCommitment,
    DefaulterState.sealed => card.isSealed,
    DefaulterState.openCase => card.hasOpenCase,
  };
}

class DefaultersController extends GetxController {
  DefaultersController({
    DefaultersRepository? defaultersRepository,
    DashboardRepository? dashboardRepository,
  }) : _defaulters = defaultersRepository ?? Get.find<DefaultersRepository>(),
       _dashboard = dashboardRepository ?? Get.find<DashboardRepository>();

  final DefaultersRepository _defaulters;

  /// Only for the beat's `scope`, which is the published list of bazaars this
  /// officer is posted to — there is no areas endpoint of its own, and the
  /// defaulter rows only name the bazaars that happen to owe something.
  final DashboardRepository _dashboard;

  /// The area filter's "everywhere" entry. A sentinel rather than null, so the
  /// picker always has an item to show; real area ids are positive.
  static const int allAreas = 0;

  /// How many rows to ask for. The API pages by nothing but this, and the
  /// state chips count what came back, so the officer's whole beat has to
  /// arrive in one call.
  static const int pageSize = 200;

  /// A search box that fires per keystroke puts five calls on a bazaar's
  /// uplink to answer one question.
  static const Duration searchDebounce = Duration(milliseconds: 400);

  /// Worst first, as the server ordered them. Never re-sorted here.
  final RxList<DefaulterCard> defaulters = RxList<DefaulterCard>();

  /// The bazaars this officer may filter by.
  final RxList<FieldArea> areas = RxList<FieldArea>();

  final RxInt areaId = RxInt(allAreas);

  /// Which slice of [defaulters] is on screen. Named for the filter rather
  /// than called `state`, which on a controller reads as its own lifecycle.
  final Rx<DefaulterState> stateFilter = Rx<DefaulterState>(
    DefaulterState.everyone,
  );

  final RxString query = RxString('');

  final TextEditingController searchController = TextEditingController();

  final RxBool isLoading = RxBool(false);

  final RxnString errorMessage = RxnString();

  /// Bumped per fetch, so a slow answer to an old question cannot land on top
  /// of a newer one.
  int _sequence = 0;

  @override
  void onInit() {
    super.onInit();
    debounce<String>(query, (_) => _fetch(), time: searchDebounce);
    load();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// The rows to draw: what the server sent, narrowed to the chosen state.
  List<DefaulterCard> get visible =>
      defaulters.where(stateFilter.value.matches).toList();

  /// How many of the rows in hand are in [state] — the figure on its chip.
  int countOf(DefaulterState state) => state == DefaulterState.everyone
      ? defaulters.length
      : defaulters.where(state.matches).length;

  bool get hasData => defaulters.isNotEmpty;

  /// Whether anything is narrowing the list. Drives the "clear" offer on an
  /// empty screen — a filter that emptied the list has to be undoable from
  /// the list it emptied.
  bool get isNarrowed =>
      areaId.value != allAreas ||
      query.value.isNotEmpty ||
      stateFilter.value != DefaulterState.everyone;

  /// The picker's entries: everywhere, then each bazaar on the beat.
  List<int> get areaOptions => <int>[
    allAreas,
    for (final FieldArea area in areas)
      if (area.id != null) area.id!,
  ];

  String areaLabel(int id) {
    if (id == allAreas) return 'All bazaars';
    for (final FieldArea area in areas) {
      if (area.id == id) return area.areaName;
    }
    return 'Bazaar $id';
  }

  /// The list and the bazaars to filter it by. Safe to call again — this is
  /// the pull-to-refresh.
  Future<void> load() async {
    await Future.wait(<Future<void>>[_loadAreas(), _fetch()]);
  }

  /// Called per keystroke; the fetch behind it is debounced.
  void search(String term) => query.value = term.trim();

  Future<void> setArea(int? id) async {
    final int chosen = id ?? allAreas;
    if (chosen == areaId.value) return;
    areaId.value = chosen;
    await _fetch();
  }

  /// No call: the rows for every state are already in hand.
  void showState(DefaulterState state) => stateFilter.value = state;

  Future<void> clearFilters() async {
    stateFilter.value = DefaulterState.everyone;
    searchController.clear();
    final bool hadQuery = query.value.isNotEmpty;
    final bool hadArea = areaId.value != allAreas;
    query.value = '';
    areaId.value = allAreas;
    // Emptying the search box fires the debounce, which fetches with the
    // cleared area too. Only an area-alone change needs a call of its own.
    if (!hadQuery && hadArea) await _fetch();
  }

  Future<void> _fetch() async {
    final int ticket = ++_sequence;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final List<DefaulterCard> rows = await _defaulters.defaulters(
        areaId: areaId.value == allAreas ? null : areaId.value,
        search: query.value.isEmpty ? null : query.value,
        limit: pageSize,
      );
      if (ticket != _sequence) return;
      defaulters.value = rows;
    } on ApiException catch (error) {
      if (ticket != _sequence) return;
      errorMessage.value = error.message;
    } finally {
      if (ticket == _sequence) isLoading.value = false;
    }
  }

  Future<void> _loadAreas() async {
    try {
      final beat = await _dashboard.beat();
      areas.value = beat.scope.areas;
    } on ApiException catch (error) {
      // The picker simply has nothing to offer; the list is the screen, and
      // its own failure is the one worth reporting.
      errorMessage.value ??= error.message;
    }
  }
}
