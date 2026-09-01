import 'package:get/get.dart';

import '../../core/network/api_constants.dart';
import '../../models/offline/queued_write.dart';
import 'field_write_controller.dart';

/// Sealing a shop, or releasing a seal. One form, two directions.
enum SealMode { seal, release }

/// Sealing closes somebody's livelihood; releasing one that should not be
/// released loses MCQ its leverage. Both are confirmed before this
/// controller is called, and the confirmation names the shop and the
/// allottee.
class SealFormController extends FieldWriteController {
  SealFormController({
    required this.mode,
    required this.shopLabel,
    required this.allotteeName,
    required super.enforcement,
    required super.photos,
    required super.location,
    required super.queue,
    this.caseId,
    this.sealId,
  }) : assert(
          (mode == SealMode.seal && caseId != null) ||
              (mode == SealMode.release && sealId != null),
          'Sealing needs a case; releasing needs a seal.',
        );

  factory SealFormController.resolve({
    required SealMode mode,
    required String shopLabel,
    required String allotteeName,
    int? caseId,
    int? sealId,
  }) =>
      SealFormController(
        mode: mode,
        shopLabel: shopLabel,
        allotteeName: allotteeName,
        caseId: caseId,
        sealId: sealId,
        enforcement: Get.find(),
        photos: Get.find(),
        location: Get.find(),
        queue: Get.find(),
      );

  final SealMode mode;
  final String shopLabel;
  final String allotteeName;
  final int? caseId;
  final int? sealId;

  /// Why the shop is being sealed, or why the seal is coming off.
  ///
  /// Required on both. A release with no reason is a shutter that opened
  /// and no record of who decided it should — and the usual reason,
  /// "Fine paid in full, receipt MCQ-RC-…", is the one sentence that
  /// settles the argument six months later.
  final RxString reason = ''.obs;

  /// A photograph is **mandatory** here, unlike on a plain action: sealing
  /// is the most consequential thing an officer can do from a phone, and a
  /// release that is later questioned needs the same proof. The shutter in
  /// the frame is the record.
  bool get isValid {
    if (photo.value == null) return false;
    return reason.value.trim().isNotEmpty;
  }

  /// The request body, built once so the live write and the queued copy
  /// cannot drift apart.
  ///
  /// Two documents name these fields two ways — the contract-derived
  /// client sent `reason` and `action_date`; the build brief names
  /// `seal_reason`, `sealed_on` and `seal_photo_path`. Both go until MCQ
  /// says which is real: a seal refused by a 422 on a field name is an
  /// officer standing at a shutter with nothing to show for it. Filed in
  /// QUESTIONS.md.
  Map<String, dynamic> _sealBody({required bool offline}) {
    final evidence = buildEvidence(recordedOffline: offline).toJson();
    return {
      'reason': reason.value.trim(),
      'seal_reason': reason.value.trim(),
      'sealed_on': evidence['action_date'],
      if (evidence['photo_path'] != null)
        'seal_photo_path': evidence['photo_path'],
      ...evidence,
    };
  }

  Map<String, dynamic> _releaseBody({required bool offline}) {
    final evidence = buildEvidence(recordedOffline: offline).toJson();
    return {
      'unseal_reason': reason.value.trim(),
      'unsealed_on': evidence['action_date'],
      ...evidence,
    };
  }

  Future<FieldWriteResult> submit() =>
      mode == SealMode.seal ? _seal() : _release();

  Future<FieldWriteResult> _seal() => runWrite(
        successKey: 'seal.done',
        send: () async {
          final outcome = await enforcementRepository.sealShop(
            caseId: caseId!,
            reason: reason.value.trim(),
            evidence: buildEvidence(),
          );
          return outcome.wasCreated;
        },
        queueItem: () => QueuedWrite(
          clientActionUuid: clientActionUuid,
          kind: QueuedWriteKind.seal,
          path: ApiConstants.caseSeal(caseId!),
          body: _sealBody(offline: true),
          recordedAt: DateTime.now(),
          shopLabel: shopLabel,
          allotteeLabel: allotteeName,
          localPhotoPath: photo.value?.path,
          localSignaturePath: signature.value?.path,
          caseId: caseId,
        ),
      );

  /// A release is refused with a 409 while dues stand — the officer sees
  /// the server's sentence in a dialog, not a toast.
  Future<FieldWriteResult> _release() => runWrite(
        successKey: 'seal.releaseDone',
        send: () async {
          final outcome = await enforcementRepository.releaseSeal(
            sealId: sealId!,
            evidence: buildEvidence(),
            unsealReason: reason.value.trim(),
          );
          return outcome.wasCreated;
        },
        queueItem: () => QueuedWrite(
          clientActionUuid: clientActionUuid,
          kind: QueuedWriteKind.release,
          path: ApiConstants.sealRelease(sealId!),
          body: _releaseBody(offline: true),
          recordedAt: DateTime.now(),
          shopLabel: shopLabel,
          allotteeLabel: allotteeName,
          localPhotoPath: photo.value?.path,
          localSignaturePath: signature.value?.path,
          sealId: sealId,
        ),
      );
}
