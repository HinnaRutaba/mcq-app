import 'dart:async';

import 'package:get/get.dart';

import '../../data/api/repositories/field_repository.dart';
import '../../models/field/beat.dart';
import '../../models/field/field_card.dart';
import '../api/async_state.dart';

/// The chips across the top of the defaulters list.
enum DefaulterFilter { all, neverPaid, promiseBroken, sealed }

/// The defaulters list — the heart of the app.
///
/// Two rules shape this controller and neither is negotiable:
///
/// * **The rows stay on screen during a refresh and on an error.** A list
///   that empties itself because a request timed out is indistinguishable
///   from "nobody owes anything", which is a false statement about the
///   register and one an officer might repeat to a shopkeeper.
/// * **The server's order is kept.** It sorts by amount owed, largest
///   first. The app filters; it does not re-rank.
class FieldDefaultersController extends GetxController with AsyncState {
  FieldDefaultersController({required FieldRepository field}) : _field = field;

  factory FieldDefaultersController.resolve() =>
      FieldDefaultersController(field: Get.find());

  final FieldRepository _field;

  /// Everything the last successful request returned. Never cleared by a
  /// failure — see the class comment.
  final RxList<FieldCard> rows = <FieldCard>[].obs;

  final Rx<DefaulterFilter> filter = DefaulterFilter.all.obs;
  final Rx<BeatArea?> area = Rx<BeatArea?>(null);
  final RxString search = ''.obs;

  /// The officer's areas, for the area chips. Filled from the beat — the
  /// scope is a server control and this is only a convenience on top of it.
  final RxList<BeatArea> areas = <BeatArea>[].obs;

  final RxBool isFirstLoad = true.obs;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  /// 300ms, so a search does not fire a request per keystroke on bazaar
  /// mobile data.
  void searchChanged(String value) {
    search.value = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), reload);
  }

  void filterChanged(DefaulterFilter value) {
    final previous = filter.value;
    if (previous == value) return;
    filter.value = value;
    // `never_paid` is a server filter and the other two narrow what is
    // already here — so a round trip is needed both when entering that
    // chip and when leaving it. Leaving it without refetching would show a
    // still-server-filtered list under a chip that says "All", which is a
    // shorter list than the register and looks like an answer.
    if (value == DefaulterFilter.neverPaid ||
        previous == DefaulterFilter.neverPaid) {
      reload();
    }
  }

  void areaChanged(BeatArea? value) {
    area.value = value;
    reload();
  }

  Future<void> reload({bool refreshing = false}) => load(
        () async {
          final fetched = await _field.defaulters(
            areaId: area.value?.id,
            search: search.value.trim(),
            neverPaid: filter.value == DefaulterFilter.neverPaid ? true : null,
          );
          rows.assignAll(fetched.value);
          markFetched(fetched.fetchedAt, fromCache: fetched.fromCache);
          isFirstLoad.value = false;
        },
        refreshing: refreshing,
      );

  /// The rows after the two chips the server does not carry.
  ///
  /// `promise_broken` and `sealed` are not documented query parameters, so
  /// they narrow the list already fetched rather than being invented as
  /// URL filters the server would ignore — an ignored filter that looks
  /// applied is worse than no filter at all. If MCQ adds them, move them up
  /// into the request.
  List<FieldCard> get visible {
    switch (filter.value) {
      case DefaulterFilter.promiseBroken:
        return rows.where((row) => row.promiseBroken).toList();
      case DefaulterFilter.sealed:
        return rows.where((row) => row.isSealed).toList();
      case DefaulterFilter.all:
      case DefaulterFilter.neverPaid:
        return rows;
    }
  }

  bool get isSearching => search.value.trim().isNotEmpty;

  bool get isFiltered =>
      isSearching || filter.value != DefaulterFilter.all || area.value != null;

  void clearFilters() {
    search.value = '';
    filter.value = DefaulterFilter.all;
    area.value = null;
    reload();
  }
}
