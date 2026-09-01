import '../core/utils/json_parse.dart';
import 'field_write_request.dart';

/// What can be recorded against a case from the field.
///
/// A fine is not here: it is raised through the fines endpoint, which also
/// posts the receivable and issues a payment link. `fine_imposed` shows up on
/// the timeline afterwards, but it is not something the app posts as an action.
enum EnforcementActionType {
  /// Called at the shop.
  siteVisit('site_visit'),

  /// Told them in person.
  verbalWarning('verbal_warning'),

  /// The last warning before enforcement.
  finalWarning('final_warning'),

  /// They committed to a date — send `promised_payment_date` with it.
  paymentPromised('payment_promised'),

  /// The officer committed to coming back — send `next_visit_date` with it.
  reminderVisitSet('reminder_visit_set'),

  /// A written notice was handed over.
  noticeServed('notice_served');

  const EnforcementActionType(this.wireValue);

  /// What goes over the wire as `action_type`.
  final String wireValue;
}

/// Records a visit, a warning, a notice or a promise against one case.
///
/// Hold on to the instance for retries — see [FieldWriteRequest] on why a
/// rebuilt request is not the same write.
class EnforcementActionRequest extends FieldWriteRequest {
  EnforcementActionRequest({
    required this.actionType,
    this.promisedPaymentDate,
    this.nextVisitDate,
    super.actionDate,
    super.latitude,
    super.longitude,
    super.locationAccuracyM,
    super.recordedOffline,
    super.deviceRecordedAt,
    super.photoPath,
    super.signaturePath,
    super.witnessName,
    super.remarks,
    super.clientActionUuid,
  }) : assert(
         actionType != EnforcementActionType.paymentPromised ||
             promisedPaymentDate != null,
         'payment_promised needs the date they promised to pay by.',
       ),
       assert(
         actionType != EnforcementActionType.reminderVisitSet ||
             nextVisitDate != null,
         'reminder_visit_set needs the date of the return visit.',
       );

  final EnforcementActionType actionType;

  /// When the shopkeeper said they would pay. Today or later.
  final DateTime? promisedPaymentDate;

  /// When the officer will come back. Today or later.
  final DateTime? nextVisitDate;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(),
    'action_type': actionType.wireValue,
    'promised_payment_date': Json.dateOnly(promisedPaymentDate),
    'next_visit_date': Json.dateOnly(nextVisitDate),
  };
}
