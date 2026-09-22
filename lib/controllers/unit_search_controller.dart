import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/network/api_exception.dart';
import '../data/repositories/reporting_repository.dart';
import '../data/repositories/units_repository.dart';
import '../models/map_pins.dart';
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
  UnitSearchController({
    UnitsRepository? unitsRepository,
    ReportingRepository? reportingRepository,
  }) : _units = unitsRepository ?? Get.find<UnitsRepository>(),
       _reporting = reportingRepository ?? Get.find<ReportingRepository>();

  final UnitsRepository _units;

  /// The pins, which are a different endpoint from the rows: `reporting/map`
  /// places every unit in the officer's bazaars, where the search returns the
  /// ones that answer a term.
  final ReportingRepository _reporting;

  /// How many rows to ask for. The endpoint pages by nothing but this.
  static const int pageSize = 50;

  /// How many pins to ask for. Far more than rows: a pin is a dot, and a
  /// bazaar read as a map is meant to show the whole bazaar. The server says
  /// in `meta.truncated` when even this was not enough.
  static const int pinPageSize = 500;

  /// A box that fires per keystroke puts five calls on a bazaar's uplink to
  /// answer one question.
  static const Duration searchDebounce = Duration(milliseconds: 400);

  /// What came back, in the server's own order. Never re-sorted here.
  final RxList<UnitCard> units = RxList<UnitCard>();

  final RxString query = RxString('');

  final TextEditingController searchController = TextEditingController();

  final RxBool isLoading = RxBool(false);

  final RxnString errorMessage = RxnString();

  /// Whether the shops are being read as a map rather than as a list. The
  /// search box works the same either way — on the map it flies the camera to
  /// what it found instead of narrowing a list.
  final RxBool onMap = RxBool(false);

  final Rxn<MapPins> pins = Rxn<MapPins>();

  final RxBool isLoadingPins = RxBool(false);

  final RxnString pinsError = RxnString();

  /// The pin the card at the foot of the map is open on, and what the camera
  /// flies to whenever it changes.
  final Rxn<MapPin> selectedPin = Rxn<MapPin>();

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

  bool get hasPins => (pins.value?.pins.isNotEmpty ?? false);

  /// The pins to draw. Everything the map endpoint placed, in its own order.
  List<MapPin> get placed => pins.value?.pins ?? const <MapPin>[];

  /// Whether a term is narrowing the list — an empty screen means two very
  /// different things with and without one.
  bool get isSearching => query.value.isNotEmpty;

  /// Called per keystroke; the fetch behind it is debounced.
  void search(String term) => query.value = term.trim();

  /// Reads the shops as a map, or back as a list. The pins are fetched the
  /// first time they are asked for and then kept: the endpoint places a whole
  /// beat, and toggling twice should not read it twice.
  void showMap(bool on) {
    if (on == onMap.value) return;
    onMap.value = on;
    if (!on) {
      selectedPin.value = null;
      return;
    }
    if (pins.value == null && !isLoadingPins.value) {
      loadPins();
    } else {
      _focusSearched();
    }
  }

  /// Opens the card on [pin]. The camera follows it — see `UnitMap`.
  void selectPin(MapPin? pin) => selectedPin.value = pin;

  /// The row behind a pin, when the list in hand happens to hold it. The pin
  /// payload names no holder and carries no mobile number; the row does, and
  /// the card at the foot of the map is better for having them.
  UnitCard? unitFor(MapPin pin) {
    final int? id = pin.propertyId;
    if (id == null) return null;
    for (final UnitCard card in units) {
      if (card.propertyId == id) return card;
    }
    return null;
  }

  /// Whichever pin stands for [card]. The two lists come from different
  /// endpoints and meet on the property id; a unit the pin list never carried
  /// is placed from its own fix instead.
  MapPin? pinFor(UnitCard card) {
    final int? id = card.propertyId;
    if (id != null) {
      for (final MapPin pin in placed) {
        if (pin.propertyId == id && pin.hasFix) return pin;
      }
    }
    return card.asMapPin();
  }

  Future<void> loadPins() async {
    isLoadingPins.value = true;
    pinsError.value = null;
    try {
      pins.value = await _reporting.mapPins(limit: pinPageSize);
      _focusSearched();
    } on ApiException catch (error) {
      pinsError.value = error.message;
    } finally {
      isLoadingPins.value = false;
    }
  }

  /// What the officer searched for, put under the camera. Only ever the top
  /// match: the server ordered the rows, and second place is not an answer.
  void _focusSearched() {
    if (!onMap.value || query.value.isEmpty || units.isEmpty) return;
    final MapPin? found = pinFor(units.first);
    if (found != null) selectedPin.value = found;
  }

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
      // On the map, a search is a camera move rather than a shorter list.
      _focusSearched();
    } on ApiException catch (error) {
      if (ticket != _sequence) return;
      errorMessage.value = error.message;
    } finally {
      if (ticket == _sequence) isLoading.value = false;
    }
  }
}
