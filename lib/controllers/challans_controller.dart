import 'package:get/get.dart';

import '../core/network/api_exception.dart';
import '../data/repositories/challan_repository.dart';
import '../models/api_response.dart';
import '../models/challan.dart';

/// Which bills are on screen.
///
/// Only [fines] is a question the server can be asked — `challan_type=fine` is
/// the one value the API publishes. [rent] shares [all]'s query and is narrowed
/// here, because guessing at the enum's other half would silently return
/// nothing.
enum ChallanFilter {
  all('All'),

  /// A month's rent, with its arrears and surcharge.
  rent('Rent'),

  /// A penalty. One charge, one label, and a debt of its own.
  fines('Fines');

  const ChallanFilter(this.label);

  final String label;

  /// The `challan_type` to send. Null asks for everything.
  String? get challanType =>
      this == ChallanFilter.fines ? ChallanRepository.typeFine : null;
}

/// The challan list: every bill an officer's shopkeepers owe, in one place
/// rather than found a shop at a time through a profile.
///
/// The endpoint is paged and takes no search, so this holds a cursor rather
/// than a query — [loadMore] walks it. Nothing here totals anything: a rent
/// bill's balance and a fine's are separate debts with separate payment links,
/// so the strip over the list counts bills and the rows carry the money.
class ChallansController extends GetxController {
  ChallansController({ChallanRepository? challanRepository})
    : _challans = challanRepository ?? Get.find<ChallanRepository>();

  final ChallanRepository _challans;

  /// A page an officer can read before the next one is wanted, and small
  /// enough to land on a bazaar's uplink.
  static const int pageSize = 25;

  /// Newest first, as the server ordered them. Never re-sorted here.
  final RxList<Challan> challans = RxList<Challan>();

  final Rx<ChallanFilter> filter = Rx<ChallanFilter>(ChallanFilter.all);

  /// The last page's `meta` — where the cursor is and how many bills the
  /// current query has in total.
  final Rxn<PageMeta> page = Rxn<PageMeta>();

  final RxBool isLoading = RxBool(false);

  /// Kept apart from [isLoading]: the first page is a blank screen waiting,
  /// the next page is a footer under rows that are already readable.
  final RxBool isLoadingMore = RxBool(false);

  final RxnString errorMessage = RxnString();

  /// What the rows in hand were asked for. Switching between [ChallanFilter.all]
  /// and [ChallanFilter.rent] does not change it, so that switch costs no call.
  String? _loadedType;

  /// Bumped per fetch, so a slow answer to an old question cannot land on top
  /// of a newer one.
  int _sequence = 0;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// The rows to draw. Rent is the everything-list minus the penalties; see
  /// [ChallanFilter].
  List<Challan> get visible => filter.value == ChallanFilter.rent
      ? challans.where((Challan challan) => !challan.isFine).toList()
      : challans.toList();

  bool get hasData => challans.isNotEmpty;

  /// Whether the server has another page. Asked of [page] rather than counted
  /// off the rows — a narrowed view holds fewer than were fetched.
  bool get hasMore {
    final PageMeta? meta = page.value;
    return meta != null && meta.currentPage < meta.lastPage;
  }

  /// How many bills the current query has, all pages in. Null until the first
  /// page lands.
  int? get total => page.value?.total;

  /// Whether the list is short because of a filter rather than because there
  /// is nothing to pay.
  bool get isNarrowed => filter.value != ChallanFilter.all;

  /// The list from the top. Safe to call again — this is the pull-to-refresh.
  Future<void> load() => _fetch(pageNo: 1);

  /// Shows [which]. Only a change of server query fetches; rent and all are
  /// the same request.
  Future<void> showFilter(ChallanFilter which) async {
    if (which == filter.value) return;
    filter.value = which;
    if (which.challanType != _loadedType) await _fetch(pageNo: 1);
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
    final String? type = filter.value.challanType;

    if (isFirst) {
      isLoading.value = true;
      errorMessage.value = null;
    } else {
      isLoadingMore.value = true;
    }

    try {
      final Paginated<Challan> result = await _challans.challans(
        page: pageNo,
        perPage: pageSize,
        challanType: type,
      );
      if (ticket != _sequence) return;
      challans.value = isFirst
          ? result.items
          : <Challan>[...challans, ...result.items];
      page.value = result.meta;
      _loadedType = type;
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
