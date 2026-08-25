import 'package:get/get.dart';

import '../data/repositories/chalaan_repository.dart';
import '../data/repositories/seal_repository.dart';
import '../models/seal_record.dart';

enum SealFilter { active, readyToUnseal, removed }

extension SealFilterLabel on SealFilter {
  String get label => switch (this) {
        SealFilter.active => 'Active',
        SealFilter.readyToUnseal => 'Ready to Unseal',
        SealFilter.removed => 'Removed',
      };
}

/// Owns seal-record state for the whole Magistrate app.
///
/// Registered as a permanent singleton (see `dependency_injection.dart`) so
/// the "ready to unseal" badge on the shell's Sealed tab and the Home
/// screen's banner both read live state — not just the Sealed screen.
class SealController extends GetxController {
  SealController({SealRepository? sealRepository, ChalaanRepository? chalaanRepository})
      : _sealRepository = sealRepository ?? Get.find<SealRepository>(),
        _chalaanRepository = chalaanRepository ?? Get.find<ChalaanRepository>();

  final SealRepository _sealRepository;
  final ChalaanRepository _chalaanRepository;

  final RxList<SealRecord> seals = <SealRecord>[].obs;
  final Rx<SealFilter> filter = SealFilter.active.obs;
  final RxBool isProcessing = false.obs;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  /// Re-syncs "ready to unseal" derived state (a sealed record whose linked
  /// fine has since been paid) and reloads the list.
  void reload() {
    for (final seal in _sealRepository.getAll()) {
      if (seal.status == SealStatus.sealed) {
        final chalaan = _chalaanRepository.getById(seal.relatedChalaanId);
        if (chalaan.isSettled) seal.status = SealStatus.readyToUnseal;
      }
    }
    seals.assignAll(_sealRepository.getAll());
  }

  int get sealedCount => seals.where((s) => s.status == SealStatus.sealed).length;

  int get readyToUnsealCount =>
      seals.where((s) => s.status == SealStatus.readyToUnseal).length;

  List<SealRecord> get readyToUnseal =>
      seals.where((s) => s.status == SealStatus.readyToUnseal).toList();

  void setFilter(SealFilter value) => filter.value = value;

  List<SealRecord> get filtered {
    final sorted = seals.toList()..sort((a, b) => b.sealedDate.compareTo(a.sealedDate));
    switch (filter.value) {
      case SealFilter.active:
        return sorted.where((s) => s.status != SealStatus.removed).toList();
      case SealFilter.readyToUnseal:
        return sorted.where((s) => s.status == SealStatus.readyToUnseal).toList();
      case SealFilter.removed:
        return sorted.where((s) => s.status == SealStatus.removed).toList();
    }
  }

  Future<void> sealProperty({
    required String propertyId,
    required String propertyName,
    required String tenantName,
    required String reason,
    required String relatedChalaanId,
  }) async {
    isProcessing.value = true;
    try {
      await _sealRepository.sealProperty(
        propertyId: propertyId,
        propertyName: propertyName,
        tenantName: tenantName,
        reason: reason,
        relatedChalaanId: relatedChalaanId,
      );
      reload();
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> removeSeal(String sealId) async {
    isProcessing.value = true;
    try {
      await _sealRepository.removeSeal(sealId);
      reload();
    } finally {
      isProcessing.value = false;
    }
  }
}
