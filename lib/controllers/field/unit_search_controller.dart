import 'dart:async';

import 'package:get/get.dart';

import '../../core/storage/key_value_store.dart';
import '../../data/api/repositories/field_repository.dart';
import '../../models/field/beat.dart';
import '../../models/field/field_card.dart';
import '../api/async_state.dart';

/// Which list the search is looking at.
enum UnitSearchScope {
  /// Only those owing — `field/defaulters`.
  behind,

  /// Every unit in his areas, **including vacant ones** —`field/units`.
  allUnits,
}

/// Search.
///
/// MCQ's second flow, in their words: *"magistrate went to a shop and its
/// fine is paid but he still finds it in some illegal and unlawful
/// activity, so he searches for that property in his area and gives a
/// warning."*
///
/// A shop that is fully paid up does not appear in the defaulter list at
/// all, and it is exactly the one he is standing in front of — so the "all
/// units" tab exists, and it deliberately includes vacant units, because an
/// encroachment or a hawker has no agreement and a fine against one is the
/// commonest field offence there is.
class UnitSearchController extends GetxController with AsyncState {
  UnitSearchController({
    required FieldRepository field,
    required KeyValueStore store,
  })  : _field = field,
        _store = store;

  factory UnitSearchController.resolve() =>
      UnitSearchController(field: Get.find(), store: Get.find());

  final FieldRepository _field;
  final KeyValueStore _store;

  static const String _recentKey = 'field_recent_searches';
  static const int _maxRecent = 6;

  final Rx<UnitSearchScope> scope = UnitSearchScope.behind.obs;
  final RxString query = ''.obs;
  final Rx<BeatArea?> area = Rx<BeatArea?>(null);
  final RxList<BeatArea> areas = <BeatArea>[].obs;

  final RxList<FieldCard> results = <FieldCard>[].obs;
  final RxList<String> recent = <String>[].obs;

  /// True before the officer has typed anything — the screen shows recent
  /// searches rather than an empty-results illustration, which would be a
  /// wrong answer to a question nobody asked.
  bool get isIdle => query.value.trim().isEmpty;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    recent.assignAll(
      (_store.getJsonList(_recentKey) ?? const [])
          .map((entry) => '$entry')
          .where((entry) => entry.isNotEmpty)
          .toList(),
    );
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  void queryChanged(String value) {
    query.value = value;
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      results.clear();
      failure.value = null;
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), search);
  }

  void scopeChanged(UnitSearchScope value) {
    if (scope.value == value) return;
    scope.value = value;
    if (!isIdle) search();
  }

  void areaChanged(BeatArea? value) {
    area.value = value;
    if (!isIdle) search();
  }

  /// Runs the search the officer typed, and remembers it.
  Future<void> search({bool refreshing = false}) async {
    final term = query.value.trim();
    if (term.isEmpty) return;
    await load(
      () async {
        if (scope.value == UnitSearchScope.allUnits) {
          results.assignAll(
            await _field.units(search: term, areaId: area.value?.id),
          );
        } else {
          final fetched = await _field.defaulters(
            search: term,
            areaId: area.value?.id,
          );
          results.assignAll(fetched.value);
          markFetched(fetched.fetchedAt, fromCache: fetched.fromCache);
        }
      },
      refreshing: refreshing,
    );
    if (!hasFailed) await _remember(term);
  }

  void useRecent(String term) {
    query.value = term;
    search();
  }

  Future<void> clearRecent() async {
    recent.clear();
    await _store.setJson(_recentKey, const <String>[]);
  }

  Future<void> _remember(String term) async {
    recent
      ..removeWhere((entry) => entry.toLowerCase() == term.toLowerCase())
      ..insert(0, term);
    if (recent.length > _maxRecent) recent.removeRange(_maxRecent, recent.length);
    await _store.setJson(_recentKey, recent.toList());
  }
}
