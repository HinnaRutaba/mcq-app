import 'package:get/get.dart';

import '../data/mock/mock_seed.dart';
import '../data/repositories/chalaan_repository.dart';
import '../models/chalaan.dart';

enum TenantPaymentsFilter { all, unpaid, past }

extension TenantPaymentsFilterLabel on TenantPaymentsFilter {
  String get label => switch (this) {
    TenantPaymentsFilter.all => 'All',
    TenantPaymentsFilter.unpaid => 'Unpaid',
    TenantPaymentsFilter.past => 'Past',
  };
}

/// Drives the Tenant Payments screen: search + status filter over the
/// tenant's full chalaan history.
class TenantPaymentsController extends GetxController {
  TenantPaymentsController({ChalaanRepository? chalaanRepository})
    : _chalaanRepository = chalaanRepository ?? Get.find<ChalaanRepository>();

  final ChalaanRepository _chalaanRepository;

  final RxList<Chalaan> _all = <Chalaan>[].obs;
  final RxString query = ''.obs;
  final Rx<TenantPaymentsFilter> filter = TenantPaymentsFilter.all.obs;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  void reload() =>
      _all.assignAll(_chalaanRepository.getByTenant(DemoIdentity.tenantId));

  void setQuery(String value) => query.value = value;

  void setFilter(TenantPaymentsFilter value) => filter.value = value;

  List<Chalaan> get filtered {
    var list = _all.toList()..sort((a, b) => b.dueDate.compareTo(a.dueDate));

    list = switch (filter.value) {
      TenantPaymentsFilter.all => list,
      TenantPaymentsFilter.unpaid =>
        list
            .where(
              (c) =>
                  c.status == ChalaanStatus.upcoming ||
                  c.status == ChalaanStatus.overdue,
            )
            .toList(),
      TenantPaymentsFilter.past =>
        list
            .where(
              (c) =>
                  c.isSettled || c.status == ChalaanStatus.pendingVerification,
            )
            .toList(),
    };

    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list
        .where(
          (c) =>
              (c.description ?? '').toLowerCase().contains(q) ||
              c.id.toLowerCase().contains(q) ||
              c.propertyName.toLowerCase().contains(q),
        )
        .toList();
  }
}
