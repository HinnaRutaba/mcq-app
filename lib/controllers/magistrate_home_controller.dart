import 'package:get/get.dart';

import '../data/repositories/chalaan_repository.dart';
import '../models/chalaan.dart';
import '../models/seal_record.dart';
import 'seal_controller.dart';

/// Drives the Magistrate Home dashboard: pending-collection summary and
/// the "ready to unseal" banner. Seal data itself is owned by
/// [SealController] (a permanent singleton) so the banner here and the
/// Sealed tab's badge always agree.
class MagistrateHomeController extends GetxController {
  MagistrateHomeController({ChalaanRepository? chalaanRepository})
      : _chalaanRepository = chalaanRepository ?? Get.find<ChalaanRepository>();

  final ChalaanRepository _chalaanRepository;
  SealController get _sealController => Get.find<SealController>();

  final RxList<Chalaan> pending = <Chalaan>[].obs;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  void reload() {
    _sealController.reload();
    pending.assignAll(_chalaanRepository.getAll().where((c) => !c.isSettled));
  }

  double get totalPendingAmount => pending.fold(0.0, (sum, c) => sum + c.amount);

  int get overdueCount => pending.where((c) => c.status == ChalaanStatus.overdue).length;

  /// Shopkeepers who haven't paid a fine yet — highest priority: unlike a
  /// missed rent chalaan, an unpaid fine is often tied to a seal.
  List<Chalaan> get unpaidFines {
    final fines = pending.where((c) => c.isFine).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return fines;
  }

  /// Regular (non-fine) chalaans coming due — the day-to-day collection
  /// round, lower priority than an unpaid fine.
  List<Chalaan> get pendingCollections {
    final collections = pending.where((c) => !c.isFine).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return collections;
  }

  int get sealedCount => _sealController.sealedCount;

  /// Seals whose fine has since been paid — ready for the magistrate to go
  /// remove in person.
  List<SealRecord> get readyToUnseal => _sealController.readyToUnseal;
}
