import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/network/api_exception.dart';
import '../data/repositories/agreement_repository.dart';
import '../models/agreement_case.dart';
import '../models/agreement_requests.dart';
import '../models/api_response.dart';

/// The reviewer's case lists: one scope at a time, paged, searchable.
///
/// A dashboard tile opens its own scope through [open], which may be the call
/// that builds this controller — so the query is seeded first and the arrival
/// is one request, not the default tab followed by the tile's.
class AgreementCasesController extends GetxController {
  AgreementCasesController({AgreementRepository? agreementRepository})
    : _agreements = agreementRepository ?? Get.find<AgreementRepository>();

  final AgreementRepository _agreements;

  static const int pageSize = 25;

  static IntakeListQuery? _wanted;

  final Rx<IntakeListQuery> query = Rx<IntakeListQuery>(IntakeListQuery.all);

  final TextEditingController searchController = TextEditingController();
  final RxString search = RxString('');

  final RxList<AgreementCase> cases = RxList<AgreementCase>();
  final Rxn<PageMeta> page = Rxn<PageMeta>();

  final RxBool isLoading = RxBool(false);
  final RxBool isLoadingMore = RxBool(false);
  final RxnString errorMessage = RxnString();

  int _sequence = 0;

  @override
  void onInit() {
    super.onInit();
    if (_wanted != null) {
      query.value = _wanted!;
      _wanted = null;
    }
    // Typed into a box at a desk or a counter: wait for the officer to pause.
    debounce<String>(
      search,
      (_) => load(),
      time: const Duration(milliseconds: 400),
    );
    load();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  bool get hasData => cases.isNotEmpty;

  bool get hasMore {
    final PageMeta? meta = page.value;
    return meta != null && meta.currentPage < meta.lastPage;
  }

  int? get total => page.value?.total;

  bool get isSearching => search.value.trim().isNotEmpty;

  /// The chips: the four standard tabs, plus the one a tile opened when it is
  /// none of them.
  List<IntakeListQuery> get tabs => <IntakeListQuery>[
    ...IntakeListQuery.standard,
    if (!query.value.isStandard) query.value,
  ];

  /// Opens the list on [which], from a dashboard tile.
  static Future<void> open(IntakeListQuery which) async {
    _wanted = which;
    final AgreementCasesController controller =
        Get.find<AgreementCasesController>();
    if (_wanted == null) return;
    _wanted = null;
    await controller.showQuery(which);
  }

  /// Back to All when Cases is picked from the nav bar, if the list is built.
  static Future<void> showAllIfOpened() async {
    if (!Get.isRegistered<AgreementCasesController>() ||
        Get.isPrepared<AgreementCasesController>()) {
      return;
    }
    await Get.find<AgreementCasesController>().showQuery(IntakeListQuery.all);
  }

  /// Re-reads after an act, if the list has been built at all. A lazy factory
  /// counts as registered, so it is told apart by `isPrepared`.
  static Future<void> reloadIfOpened() async {
    if (!Get.isRegistered<AgreementCasesController>() ||
        Get.isPrepared<AgreementCasesController>()) {
      return;
    }
    await Get.find<AgreementCasesController>().load();
  }

  Future<void> load() => _fetch(pageNo: 1);

  Future<void> showQuery(IntakeListQuery which) async {
    if (which == query.value) return;
    query.value = which;
    await _fetch(pageNo: 1);
  }

  void setSearch(String value) => search.value = value;

  void clearSearch() {
    searchController.clear();
    search.value = '';
  }

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore) return;
    await _fetch(pageNo: page.value!.currentPage + 1);
  }

  Future<void> _fetch({required int pageNo}) async {
    final bool isFirst = pageNo == 1;
    final int ticket = ++_sequence;

    if (isFirst) {
      isLoading.value = true;
      errorMessage.value = null;
    } else {
      isLoadingMore.value = true;
    }

    try {
      final Paginated<AgreementCase> result = await _agreements.cases(
        query.value,
        search: search.value,
        page: pageNo,
        perPage: pageSize,
      );
      if (ticket != _sequence) return;
      cases.value = isFirst
          ? result.items
          : <AgreementCase>[...cases, ...result.items];
      page.value = result.meta;
      errorMessage.value = null;
    } on ApiException catch (error) {
      if (ticket != _sequence) return;
      // Old rows stay up; the screen shows a retry bar over them.
      errorMessage.value = error.message;
    } finally {
      if (ticket == _sequence) {
        isLoading.value = false;
        isLoadingMore.value = false;
      }
    }
  }
}
