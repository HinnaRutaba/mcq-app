import 'package:get/get.dart';

import '../../core/network/api_constants.dart';
import '../../models/enforcement/field_evidence.dart';
import '../../models/offline/queued_write.dart';
import 'field_write_controller.dart';

/// Recording a visit, a warning, a **promise to pay** or a **revisit** —
/// the app's first write, and the pattern the other three follow.
///
/// The promise and the revisit were missing entirely from the first
/// version, and they are what makes the app worth carrying: a promise taken
/// here appears on the shopkeeper's card and in the follow-ups queue
/// automatically, so the next officer to walk that bazaar can tell somebody
/// he spoke to last week from somebody nobody has ever visited.
class RecordActionController extends FieldWriteController {
  RecordActionController({
    required this.caseId,
    required this.shopLabel,
    required this.allotteeName,
    required super.enforcement,
    required super.photos,
    required super.location,
    required super.queue,
  });

  factory RecordActionController.resolve({
    required int caseId,
    required String shopLabel,
    required String allotteeName,
  }) =>
      RecordActionController(
        caseId: caseId,
        shopLabel: shopLabel,
        allotteeName: allotteeName,
        enforcement: Get.find(),
        photos: Get.find(),
        location: Get.find(),
        queue: Get.find(),
      );

  final int caseId;

  /// Carried so a queued record can say which shop it belongs to without a
  /// round trip.
  final String shopLabel;
  final String allotteeName;

  /// The value the API validates `action_type` against. The values the
  /// build brief names are in [FieldWriteEnums.actionTypes]; the full enum
  /// is still unconfirmed against the live API — see QUESTIONS.md.
  final RxString actionType = ''.obs;

  /// `payment_promised` carries the date the shopkeeper named.
  final Rx<DateTime?> promisedPaymentDate = Rx<DateTime?>(null);

  /// `reminder_visit_set` carries the date the officer will come back.
  final Rx<DateTime?> nextVisitDate = Rx<DateTime?>(null);

  bool get needsPromiseDate =>
      FieldWriteEnums.needsPromiseDate(actionType.value);

  bool get needsVisitDate => FieldWriteEnums.needsVisitDate(actionType.value);

  /// A promise with no date is a note, not a promise, and a revisit with no
  /// date never reaches the follow-ups queue. Refused here rather than
  /// letting the server 422 an officer standing in a bazaar.
  bool get isValid {
    if (actionType.value.isEmpty) return false;
    if (needsPromiseDate && promisedPaymentDate.value == null) return false;
    if (needsVisitDate && nextVisitDate.value == null) return false;
    return true;
  }

  /// The extra field this action type carries, if any — kept in one place
  /// so the live write and the queued copy cannot drift apart.
  Map<String, dynamic> get _extraFields => {
        if (needsPromiseDate && promisedPaymentDate.value != null)
          'promised_payment_date':
              FieldEvidence.apiDate(promisedPaymentDate.value!),
        if (needsVisitDate && nextVisitDate.value != null)
          'next_visit_date': FieldEvidence.apiDate(nextVisitDate.value!),
      };

  Future<FieldWriteResult> submit() => runWrite(
        successKey: 'action.saved',
        send: () async {
          final outcome = await enforcementRepository.recordAction(
            caseId: caseId,
            actionType: actionType.value,
            evidence: buildEvidence(),
            promisedPaymentDate:
                needsPromiseDate ? promisedPaymentDate.value : null,
            nextVisitDate: needsVisitDate ? nextVisitDate.value : null,
          );
          return outcome.wasCreated;
        },
        queueItem: () => QueuedWrite(
          clientActionUuid: clientActionUuid,
          kind: QueuedWriteKind.action,
          path: ApiConstants.caseActions(caseId),
          body: {
            'action_type': actionType.value,
            ..._extraFields,
            ...buildEvidence(recordedOffline: true).toJson(),
          },
          recordedAt: DateTime.now(),
          shopLabel: shopLabel,
          allotteeLabel: allotteeName,
          localPhotoPath: photo.value?.path,
          localSignaturePath: signature.value?.path,
          caseId: caseId,
        ),
      );
}
