import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/network/api_exception.dart';
import '../data/repositories/defaulters_repository.dart';
import '../models/defaulter_card.dart';
import '../models/round_group.dart';

/// Today's walking order: `enforcement/field/round`. Its own endpoint, not a
/// sort of the defaulter list, and the server's order is the walking order —
/// never re-sorted here.
class RoundController extends GetxController {
  RoundController({DefaultersRepository? defaultersRepository})
    : _defaulters = defaultersRepository ?? Get.find<DefaultersRepository>();

  final DefaultersRepository _defaulters;

  /// The bazaar chips' "everywhere" entry. A sentinel rather than null, so the
  /// bar always has a chip to show; real area ids are positive.
  static const int allAreas = 0;

  /// One entry per market, as the server ordered them.
  final RxList<RoundGroup> groups = RxList<RoundGroup>();

  final RxInt areaId = RxInt(allAreas);

  /// What the officer typed. Answered from the payload in hand — the round
  /// endpoint takes no search term, and the whole beat arrives in one call —
  /// so there is nothing to debounce.
  final RxString query = RxString('');

  final TextEditingController searchController = TextEditingController();

  /// The markets folded shut, by [RoundGroup.key]. Kept here rather than in
  /// the head's own state so a market stays folded across a refresh — an
  /// officer who has walked a bazaar has finished with it.
  final RxSet<String> collapsed = RxSet<String>();

  final RxBool isLoading = RxBool(false);

  final RxnString errorMessage = RxnString();

  /// Bumped per fetch, so a slow answer to an old question cannot land on top
  /// of a newer one.
  int _sequence = 0;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// The markets to draw: what the server sent, narrowed to the chosen bazaar
  /// and to what was typed.
  ///
  /// A bazaar whose own name matches keeps all of its stops — the officer
  /// asked for the market, not for a shop in it. Otherwise the market keeps
  /// only the stops that match, and drops out when none do.
  /// The markets to draw: what the server sent, narrowed to the chosen bazaar
  /// and to what was typed, in the server's order.
  ///
  /// A market whose own name matches the search keeps all of its stops — the
  /// officer asked for the market, not for a shop in it. Otherwise it keeps
  /// only the stops that match and drops out when none do. A market the server
  /// sent no stops for survives, because "7 behind, none picked out yet" is a
  /// fact about the round worth showing.
  List<RoundGroup> get visible {
    final int area = areaId.value;
    final String term = query.value.trim().toLowerCase();
    final bool searching = term.isNotEmpty;

    final List<RoundGroup> matched = <RoundGroup>[];
    for (final RoundGroup group in groups) {
      if (area != allAreas && group.areaId != area) continue;
      if (!searching || _placeMatches(group, term)) {
        matched.add(group);
        continue;
      }
      final List<DefaulterCard> stops = group.stops
          .where((DefaulterCard stop) => _stopMatches(stop, term))
          .toList();
      if (stops.isNotEmpty) matched.add(group.withStops(stops));
    }
    return matched;
  }

  bool get hasData => groups.isNotEmpty;

  /// Whether a chip or the search box is what emptied the screen — the way out
  /// of a dead end belongs in the dead end.
  bool get isNarrowed =>
      areaId.value != allAreas || query.value.isNotEmpty;

  /// How many shops the round would have the officer call at, over the markets
  /// on screen. The stops the server picked out, not the markets' shop counts.
  int get stopCount =>
      visible.fold<int>(0, (int total, RoundGroup g) => total + g.stops.length);

  /// The bazaars to filter by, read off the groups themselves: every entry
  /// names its area, so the chips need no second call for a picker.
  ///
  /// Taken from the whole round rather than from [visible], so a chip does not
  /// disappear from under the officer's thumb as they type. Distinct, and in
  /// the order the server listed them — several markets share a bazaar, and
  /// repeating its name reads as a mistake.
  List<int> get areaOptions {
    final List<int> ids = <int>[allAreas];
    for (final RoundGroup group in groups) {
      final int? id = group.areaId;
      if (id != null && id != allAreas && !ids.contains(id)) ids.add(id);
    }
    return ids;
  }

  String areaLabel(int id) {
    if (id == allAreas) return 'All bazaars';
    for (final RoundGroup group in groups) {
      if (group.areaId == id && group.areaName != null) return group.areaName!;
    }
    return 'Bazaar $id';
  }

  /// How many markets [id] has left after the search — the figure on its chip.
  /// It counts what the chip would actually show, so a chip reading 2 never
  /// opens onto nothing.
  int marketsIn(int id) {
    final String term = query.value.trim().toLowerCase();
    return groups
        .where((RoundGroup group) => id == allAreas || group.areaId == id)
        .where(
          (RoundGroup group) =>
              term.isEmpty ||
              _placeMatches(group, term) ||
              group.stops.any((DefaulterCard s) => _stopMatches(s, term)),
        )
        .length;
  }

  /// Whether there is anything to pick between. Two, because [areaOptions]
  /// always leads with "everywhere" — a beat with one bazaar would otherwise
  /// offer two chips holding the same markets.
  bool get hasAreaChoice => areaOptions.length > 2;

  /// Safe to call again — this is the pull-to-refresh.
  Future<void> load() => _fetch();

  /// Re-reads the round after something was written to a shop on it — a seal
  /// applied, a case opened or a promise taken from that shop's own profile,
  /// all of which change the badges on its stop.
  ///
  /// Nothing to do until the tab has been opened: this controller is
  /// registered lazily and fetches when it is first built, so a round nobody
  /// has looked at is not stale. `isRegistered` alone will not say that — a
  /// `lazyPut` factory answers true before it has ever been built, and `find`
  /// would then build it, fetch through `onInit`, and fetch again below.
  /// `isPrepared` is what tells the two apart.
  static Future<void> reloadIfOpened() async {
    if (!Get.isRegistered<RoundController>()) return;
    if (Get.isPrepared<RoundController>()) return;
    await Get.find<RoundController>().load();
  }

  /// Whether [group] is folded shut.
  bool isCollapsed(RoundGroup group) => collapsed.contains(group.key);

  /// Folds a market away once it has been walked, or opens it again.
  void toggleCollapsed(RoundGroup group) {
    final String key = group.key;
    if (!collapsed.remove(key)) collapsed.add(key);
  }

  /// No call: every market arrived in one payload, and the chip is a slice of
  /// what is already in hand.
  void showArea(int? id) => areaId.value = id ?? allAreas;

  /// Called per keystroke, and no call goes out either.
  void search(String term) => query.value = term.trim();

  void clearFilters() {
    areaId.value = allAreas;
    searchController.clear();
    query.value = '';
  }

  /// The bazaar and the market it sits in — what an officer types when they
  /// mean "take me to Baldia Plaza".
  static bool _placeMatches(RoundGroup group, String term) => <String?>[
    group.marketName,
    group.areaName,
  ].any((String? field) => field?.toLowerCase().contains(term) ?? false);

  /// The holder, the shop and the two numbers that identify a person at a
  /// counter — the same fields the defaulter search covers, plus the mobile,
  /// which is what a caller ID leaves an officer holding.
  static bool _stopMatches(DefaulterCard stop, String term) => <String?>[
    stop.allotteeName,
    stop.shopNo,
    stop.propertyCode,
    stop.allotmentNo,
    stop.cnic,
    stop.mobileNo,
  ].any((String? field) => field?.toLowerCase().contains(term) ?? false);

  Future<void> _fetch() async {
    final int ticket = ++_sequence;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final List<RoundGroup> rows = await _defaulters.round();
      if (ticket != _sequence) return;
      groups.value = rows;
      // A bazaar that is no longer on the round would otherwise leave the
      // screen narrowed to nothing, with a chip for it gone from the bar.
      if (!areaOptions.contains(areaId.value)) areaId.value = allAreas;
    } on ApiException catch (error) {
      if (ticket != _sequence) return;
      errorMessage.value = error.message;
    } finally {
      if (ticket == _sequence) isLoading.value = false;
    }
  }
}
