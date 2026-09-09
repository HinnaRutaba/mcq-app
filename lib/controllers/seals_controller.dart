import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/network/api_exception.dart';
import '../data/repositories/field_seal_repository.dart';
import '../models/field_seal.dart';

/// Which reading of the seal list is on screen.
///
/// Two lists rather than two filters over one: the unseal queue is the
/// server's own judgement of what is settled, asked for with `ready=1`, and it
/// is never recomputed here from the rows.
enum SealQueue {
  /// Everything this officer has sealed.
  all('Sealed'),

  /// Clear to come off: no fine on the unit outstanding, and at least one of
  /// them actually paid.
  ready('Ready to release');

  const SealQueue(this.label);

  final String label;
}

/// The seal register: every shop this officer has shut, and the ones the
/// server says may be opened again.
class SealsController extends GetxController {
  SealsController({FieldSealRepository? sealRepository})
    : _seals = sealRepository ?? Get.find<FieldSealRepository>();

  final FieldSealRepository _seals;

  final RxList<FieldSeal> sealed = RxList<FieldSeal>();

  final RxList<FieldSeal> ready = RxList<FieldSeal>();

  final Rx<SealQueue> queue = Rx<SealQueue>(SealQueue.all);

  final RxString query = RxString('');

  final TextEditingController searchController = TextEditingController();

  final RxBool isLoading = RxBool(false);

  final RxnString errorMessage = RxnString();

  /// The ids the unseal queue came back with. A row on the full list carries
  /// its own `ready_to_release`, but that key was captured off an empty list
  /// and may simply be absent; membership of the queue is the answer that
  /// cannot be missing. See [isReady].
  Set<int> _readyIds = <int>{};

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

  /// The rows to draw: the chosen queue, narrowed to the search box.
  List<FieldSeal> get visible => _matching(_rowsOf(queue.value));

  /// How many rows are in [which] under the current search — the figure on its
  /// chip, and therefore what tapping it would show.
  int countOf(SealQueue which) => _matching(_rowsOf(which)).length;

  bool get hasData => sealed.isNotEmpty || ready.isNotEmpty;

  /// Whether the seal may come off. The server's own judgement and nothing
  /// else: either the row says so, or the unseal queue returned it.
  ///
  /// The empty check is a short circuit and the read that registers this with
  /// the `Obx` drawing the badge — [_readyIds] is a plain field, and on the
  /// full list nothing else here touches [ready].
  bool isReady(FieldSeal seal) =>
      seal.readyToRelease ||
      (ready.isNotEmpty && seal.id != null && _readyIds.contains(seal.id));

  /// Whether anything is narrowing the list. Drives the "clear" offer on an
  /// empty screen — a search that emptied the list has to be undoable from the
  /// list it emptied.
  bool get isSearching => query.value.isNotEmpty;

  /// Both readings of the list. Safe to call again — this is the
  /// pull-to-refresh.
  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    await Future.wait(<Future<void>>[_loadSealed(), _loadReady()]);
    isLoading.value = false;
  }

  /// Called per keystroke, and no call goes out: the whole register is already
  /// in hand, and the endpoint takes no search term of its own.
  void search(String term) => query.value = term.trim();

  /// No call either — the rows for both queues arrived together.
  void showQueue(SealQueue which) => queue.value = which;

  void clearSearch() {
    searchController.clear();
    query.value = '';
  }

  List<FieldSeal> _rowsOf(SealQueue which) =>
      which == SealQueue.ready ? ready : sealed;

  List<FieldSeal> _matching(List<FieldSeal> rows) {
    final String term = query.value.toLowerCase();
    if (term.isEmpty) return rows.toList();
    return rows
        .where((FieldSeal seal) => _searchable(seal).contains(term))
        .toList();
  }

  /// Everything on a row worth typing at it: the holder, the unit, the seal
  /// and the case it belongs to.
  String _searchable(FieldSeal seal) => <String?>[
    seal.allotteeName,
    seal.shopNo,
    seal.propertyCode,
    seal.allotmentNo,
    seal.sealNo,
    seal.caseNo,
    seal.marketName,
    seal.areaName,
    seal.mobileNo,
  ].whereType<String>().join(' ').toLowerCase();

  Future<void> _loadSealed() async {
    try {
      sealed.value = await _seals.seals();
    } on ApiException catch (error) {
      _report(error);
    }
  }

  Future<void> _loadReady() async {
    try {
      final List<FieldSeal> rows = await _seals.seals(readyOnly: true);
      _readyIds = rows
          .map((FieldSeal seal) => seal.id)
          .whereType<int>()
          .toSet();
      // Assigned after the ids, and always assigned: the list the badges are
      // read through is what tells the screen to draw them again.
      ready.value = rows;
    } on ApiException catch (error) {
      _report(error);
    }
  }

  /// The first failure wins. Two calls go out together and one dead radio
  /// fails both; the same sentence twice is not two problems.
  void _report(ApiException error) => errorMessage.value ??= error.message;
}
