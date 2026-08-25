import 'package:get/get.dart';

import '../data/repositories/chalaan_repository.dart';
import '../models/chalaan.dart';

enum CollectionsFilter { all, overdue, upcoming }

extension CollectionsFilterLabel on CollectionsFilter {
  String get label => switch (this) {
        CollectionsFilter.all => 'All',
        CollectionsFilter.overdue => 'Overdue',
        CollectionsFilter.upcoming => 'Upcoming',
      };
}

/// Drives the Magistrate Collections screen: search + filter over every
/// tenant's outstanding chalaans/fines, plus the "mark collected" action.
class CollectionsController extends GetxController {
  CollectionsController({ChalaanRepository? chalaanRepository})
      : _chalaanRepository = chalaanRepository ?? Get.find<ChalaanRepository>();

  final ChalaanRepository _chalaanRepository;

  final RxList<Chalaan> _all = <Chalaan>[].obs;
  final RxString query = ''.obs;
  final Rx<CollectionsFilter> filter = CollectionsFilter.all.obs;
  final RxBool isProcessing = false.obs;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  void reload() => _all.assignAll(_chalaanRepository.getAll().where((c) => !c.isSettled));

  void setQuery(String value) => query.value = value;

  void setFilter(CollectionsFilter value) => filter.value = value;

  List<Chalaan> get filtered {
    var list = _all.toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    list = switch (filter.value) {
      CollectionsFilter.all => list,
      CollectionsFilter.overdue => list.where((c) => c.status == ChalaanStatus.overdue).toList(),
      CollectionsFilter.upcoming => list.where((c) => c.status == ChalaanStatus.upcoming).toList(),
    };

    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list
        .where(
          (c) =>
              c.tenantName.toLowerCase().contains(q) ||
              c.propertyName.toLowerCase().contains(q) ||
              c.propertyAddress.toLowerCase().contains(q) ||
              c.id.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> markCollected(String chalaanId) async {
    isProcessing.value = true;
    try {
      await _chalaanRepository.markCollected(chalaanId);
      reload();
    } finally {
      isProcessing.value = false;
    }
  }
}
