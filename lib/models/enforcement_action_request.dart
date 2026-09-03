import '../core/utils/json_parse.dart';
import 'enforcement_definitions.dart';
import 'field_write_request.dart';

/// What can be recorded against a case from the field.
///
/// A fine is not here: it is raised through the fines endpoint, which also
/// posts the receivable and issues a payment link. `fine_imposed` shows up on
/// the timeline afterwards, but it is not something the app posts as an action
/// — and neither are `seal`, `unseal` and `case_closed`, which the server
/// writes itself when the matching thing happens.
///
/// This enum is the set the action endpoint documents. It is deliberately not
/// the whole of `EnforcementDefinitions.actionTypes`, which is the wider list
/// of everything that can *appear* on a timeline. For an action type MCQ adds
/// after this app shipped, use [EnforcementActionRequest.ofCode].
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

  /// What goes over the wire as `action_type`. The same string as the matching
  /// `ActionTypeDefinition.code`.
  final String wireValue;

  /// The member for a definitions row's code, or null when the server names
  /// one this app does not know — which is the case
  /// [EnforcementActionRequest.ofCode] exists for.
  static EnforcementActionType? fromCode(String code) {
    for (final type in EnforcementActionType.values) {
      if (type.wireValue == code) return type;
    }
    return null;
  }
}

/// Records a visit, a warning, a notice or a promise against one case.
///
/// Hold on to the instance for retries — see [FieldWriteRequest] on why a
/// rebuilt request is not the same write.
class EnforcementActionRequest extends FieldWriteRequest {
  EnforcementActionRequest({
    required EnforcementActionType actionType,
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
  }) : actionTypeCode = actionType.wireValue,
       assert(
         actionType != EnforcementActionType.paymentPromised ||
             promisedPaymentDate != null,
         'payment_promised needs the date they promised to pay by.',
       ),
       assert(
         actionType != EnforcementActionType.reminderVisitSet ||
             nextVisitDate != null,
         'reminder_visit_set needs the date of the return visit.',
       );

  /// Records an action by its definitions code, for a form drawn from
  /// `GET enforcement/definitions` rather than from this app's enum.
  ///
  /// Use it with [ActionTypeDefinition.fields], which is the server's own
  /// answer to which of the two dates the action wants — that is what the
  /// `fields` block is for, and it means an action type MCQ adds next year
  /// gets the right form without an app release.
  ///
  /// The dates go unchecked here on purpose: [ActionTypeFields] is the
  /// authority for an action this app has never heard of, so validate against
  /// it before building the request.
  EnforcementActionRequest.ofCode(
    this.actionTypeCode, {
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
  });

  /// What is sent as `action_type`.
  final String actionTypeCode;

  /// When the shopkeeper said they would pay. Today or later.
  final DateTime? promisedPaymentDate;

  /// When the officer will come back. Today or later.
  final DateTime? nextVisitDate;

  /// The enum member for [actionTypeCode], when this app knows it. Null on a
  /// request built through [EnforcementActionRequest.ofCode] for a type added
  /// since.
  EnforcementActionType? get actionType =>
      EnforcementActionType.fromCode(actionTypeCode);

  /// `remarks` is capped at 1000 characters on this endpoint, longer than the
  /// 500 a fine allows.
  static const int remarksMaxLength = 1000;

  /// Whether this request carries what [fields] says the action needs.
  ///
  /// Check it before sending an action built by code: the server rejects a
  /// `payment_promised` with no date, and the officer has by then walked away
  /// from the shop.
  bool satisfies(ActionTypeFields fields) =>
      (!fields.promiseDate || promisedPaymentDate != null) &&
      (!fields.visitDate || nextVisitDate != null);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(),
    'action_type': actionTypeCode,
    'promised_payment_date': Json.dateOnly(promisedPaymentDate),
    'next_visit_date': Json.dateOnly(nextVisitDate),
  };
}
