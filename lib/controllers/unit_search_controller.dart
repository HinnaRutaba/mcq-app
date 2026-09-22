import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/network/api_exception.dart';
import '../data/repositories/units_repository.dart';
import '../models/unit_card.dart';

/// The search behind Home's search box: `enforcement/field/units`.
///
/// Every unit on the register, not only the defaulters — a shop that is fully
/// paid up never appears on the defaulter list, and it is exactly the one the
/// officer is standing in front of. Vacant units come back too, with their
/// tenancy fields null.
///
/// Built when the search page opens and dropped when it closes: a search is
/// one question asked in front of one shop, not a list to come back to.
class UnitSearchController extends GetxController {
  UnitSearchController({UnitsRepository? unitsRepository})
    : _units = unitsRepository ?? Get.find<UnitsRepository>();

  final UnitsRepository _units;

  /// How many rows to ask for. The endpoint pages by nothing but this.
  static const int pageSize = 50;

  /// A box that fires per keystroke puts five calls on a bazaar's uplink to
  /// answer one question.
  static const Duration searchDebounce = Duration(milliseconds: 400);

  /// What came back, in the server's own order. Never re-sorted here.
  final RxList<UnitCard> units = RxList<UnitCard>();

  final RxString query = RxString('');

  final TextEditingController searchController = TextEditingController();

  final RxBool isLoading = RxBool(false);

  final RxnString errorMessage = RxnString();

  /// Bumped per fetch, so a slow answer to an old term cannot land on top of a
  /// newer one — which on a search box is the whole list flipping back to what
  /// was typed three letters ago.
  int _sequence = 0;

  @override
  void onInit() {
    super.onInit();
    debounce<String>(query, (_) => _fetch(), time: searchDebounce);
    // The officer opens this in front of a shop, so the beat's own units are
    // already worth showing before a word is typed.
    load();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  bool get hasData => units.isNotEmpty;

  /// Whether a term is narrowing the list — an empty screen means two very
  /// different things with and without one.
  bool get isSearching => query.value.isNotEmpty;

  /// Called per keystroke; the fetch behind it is debounced.
  void search(String term) => query.value = term.trim();

  /// Safe to call again — this is the pull to refresh, and the retry.
  Future<void> load() => _fetch();

  Future<void> _fetch() async {
    final int ticket = ++_sequence;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final List<UnitCard> rows = await _units.units(
        search: query.value.isEmpty ? null : query.value,
        limit: pageSize,
      );
      if (ticket != _sequence) return;
      units.value = rows;
    } on ApiException catch (error) {
      if (ticket != _sequence) return;
      errorMessage.value = error.message;
    } finally {
      if (ticket == _sequence) isLoading.value = false;
    }
  }
}
