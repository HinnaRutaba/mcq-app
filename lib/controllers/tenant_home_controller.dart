import 'package:get/get.dart';

import '../data/mock/mock_seed.dart';
import '../data/repositories/chalaan_repository.dart';
import '../models/chalaan.dart';
import '../widgets/charts/app_bar_chart.dart';
import '../core/utils/formatters.dart';

/// Drives the Tenant Home dashboard: summary stats, the payment
/// visualization chart, the nearest-due chalaan, and recent activity.
class TenantHomeController extends GetxController {
  TenantHomeController({ChalaanRepository? chalaanRepository})
      : _chalaanRepository = chalaanRepository ?? Get.find<ChalaanRepository>();

  final ChalaanRepository _chalaanRepository;

  final RxList<Chalaan> chalaans = <Chalaan>[].obs;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  void reload() {
    chalaans.assignAll(_chalaanRepository.getByTenant(DemoIdentity.tenantId));
  }

  List<Chalaan> get _unpaid =>
      chalaans.where((c) => !c.isSettled && c.status != ChalaanStatus.pendingVerification).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  Chalaan? get nextDue => _unpaid.isEmpty ? null : _unpaid.first;

  List<Chalaan> get recentActivity {
    final settled = chalaans
        .where((c) => c.status == ChalaanStatus.paid || c.status == ChalaanStatus.pendingVerification)
        .toList()
      ..sort((a, b) => (b.paidDate ?? b.issueDate).compareTo(a.paidDate ?? a.issueDate));
    return settled.take(5).toList();
  }

  double get totalDue => _unpaid.fold(0.0, (sum, c) => sum + c.amount);

  int get overdueCount => chalaans.where((c) => c.status == ChalaanStatus.overdue).length;

  int get paidCount => chalaans.where((c) => c.status == ChalaanStatus.paid).length;

  List<ChartPoint> get monthlyChartData {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final offset = 5 - i;
      final month = DateTime(now.year, now.month - offset, 1);
      final paid = chalaans
          .where((c) => c.paidDate != null && c.paidDate!.year == month.year && c.paidDate!.month == month.month)
          .fold(0.0, (sum, c) => sum + c.amount);
      final due = chalaans
          .where((c) => c.dueDate.year == month.year && c.dueDate.month == month.month)
          .fold(0.0, (sum, c) => sum + c.amount);
      return ChartPoint(label: Formatters.month(month), paid: paid, due: due);
    });
  }
}
