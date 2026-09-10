import 'package:get/get.dart';

import '../core/network/api_exception.dart';
import '../data/repositories/enforcement_case_repository.dart';
import '../models/api_response.dart';
import '../models/enforcement_case.dart';

/// Which reading of the case register is on screen.
///
/// Both are a question for the server — `magistrate_id=me` is the only filter
/// `enforcement/cases` publishes — so switching costs a call and the chips
/// carry no counts: the rows for the list an officer is *not* looking at are
/// not in hand.
enum CaseFilter {
  /// Every case in the officer's bazaars.
  all('All cases'),

  /// The cases the taxation branch put in this officer's name.
  mine('Assigned to me');

  const CaseFilter(this.label);

  final String label;

  bool get assignedToMe => this == CaseFilter.mine;
}

/// The case register: every enforcement file open across the officer's beat,
/// in one place rather than found a shop at a time through a profile.
///
/// The endpoint is paged and takes no search, so this holds a cursor rather
/// than a query — [loadMore] walks it.
class CasesController extends GetxController {
  CasesController({EnforcementCaseRepository? caseRepository})
    : _cases = caseRepository ?? Get.find<EnforcementCaseRepository>();

  final EnforcementCaseRepository _cases;

  /// A page an officer can read before the next one is wanted, and small
  /// enough to land on a bazaar's uplink.
  static const int pageSize = 25;

  /// The filter [open] asked for before this controller existed, read once by
  /// [onInit]. Without it a home tile wanting "assigned to me" would fetch
  /// the whole register first and that list second.
  static CaseFilter? _wanted;

  /// Newest first, as the server ordered them. Never re-sorted here.
  final RxList<EnforcementCase> cases = RxList<EnforcementCase>();

  final Rx<CaseFilter> filter = Rx<CaseFilter>(CaseFilter.all);

  /// The last page's `meta` — where the cursor is and how many cases the
  /// current query has in total.
  final Rxn<PageMeta> page = Rxn<PageMeta>();

  final RxBool isLoading = RxBool(false);

  /// Kept apart from [isLoading]: the first page is a blank screen waiting,
  /// the next page is a footer under rows that are already readable.
  final RxBool isLoadingMore = RxBool(false);

  final RxnString errorMessage = RxnString();

  /// Bumped per fetch, so a slow answer to an old question cannot land on top
  /// of a newer one.
  int _sequence = 0;

  @override
  void onInit() {
    super.onInit();
    if (_wanted != null) {
      filter.value = _wanted!;
      _wanted = null;
    }
    load();
  }

  bool get hasData => cases.isNotEmpty;

  /// Whether the server has another page.
  bool get hasMore {
    final PageMeta? meta = page.value;
    return meta != null && meta.currentPage < meta.lastPage;
  }

  /// How many cases the current query has, all pages in. Null until the first
  /// page lands.
  int? get total => page.value?.total;

  /// Whether the list is short because of a filter rather than because there
  /// is nothing open.
  bool get isNarrowed => filter.value != CaseFilter.all;

  /// Opens the register on [which] — called from a home queue tile, which may
  /// be the first thing to ask for this controller at all.
  ///
  /// The filter is seeded before the find rather than set after it, so a tile
  /// that builds this controller fetches the list it means in one call. A
  /// controller that was already up never runs [onInit] again, and is left
  /// holding [_wanted] — which is how this knows to filter it by hand.
  static Future<void> open(CaseFilter which) async {
    _wanted = which;
    final CasesController controller = Get.find<CasesController>();
    if (_wanted == null) return;
    _wanted = null;
    await controller.showFilter(which);
  }

  /// The list from the top. Safe to call again — this is the pull-to-refresh.
  Future<void> load() => _fetch(pageNo: 1);

  /// Re-reads the list after a case was opened somewhere else — from a shop's
  /// profile, or from the seal form.
  ///
  /// Nothing to do until the screen has been opened: this controller is
  /// registered lazily and fetches when it is first built, so a list nobody
  /// has looked at is not stale.
  static Future<void> reloadIfOpened() async {
    if (!Get.isRegistered<CasesController>()) return;
    await Get.find<CasesController>().load();
  }

  /// Shows [which], from the top. Both readings are a different request.
  Future<void> showFilter(CaseFilter which) async {
    if (which == filter.value) return;
    filter.value = which;
    await _fetch(pageNo: 1);
  }

  /// The next page, appended. Ignored while one is in flight or when the
  /// server has said there is no more.
  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore) return;
    await _fetch(pageNo: page.value!.currentPage + 1);
  }

  Future<void> _fetch({required int pageNo}) async {
    final bool isFirst = pageNo == 1;
    final int ticket = ++_sequence;
    final bool mine = filter.value.assignedToMe;

    if (isFirst) {
      isLoading.value = true;
      errorMessage.value = null;
    } else {
      isLoadingMore.value = true;
    }

    try {
      final Paginated<EnforcementCase> result = await _cases.cases(
        page: pageNo,
        perPage: pageSize,
        assignedToMe: mine,
      );
      if (ticket != _sequence) return;
      cases.value = isFirst
          ? result.items
          : <EnforcementCase>[...cases, ...result.items];
      page.value = result.meta;
      errorMessage.value = null;
    } on ApiException catch (error) {
      if (ticket != _sequence) return;
      // A failed next page leaves the rows above it standing; the screen shows
      // this as a note under them rather than as a wall over them.
      errorMessage.value = error.message;
    } finally {
      if (ticket == _sequence) {
        isLoading.value = false;
        isLoadingMore.value = false;
      }
    }
  }
}
