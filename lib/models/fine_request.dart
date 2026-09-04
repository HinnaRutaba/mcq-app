import '../core/utils/client_action_uuid.dart';
import 'person_lookup.dart';

class FineRequest {
  FineRequest({
    required this.fineTypeId,
    required this.fineAmount,
    required this.legalProvision,
    this.areaId,
    this.allotmentId,
    this.offender,
    this.photoPath,
    this.remarks,
    String? clientActionUuid,
  }) : clientActionUuid = clientActionUuid ?? ClientActionUuid.generate();

  FineRequest.inArea({
    required int this.areaId,
    required FineOffender this.offender,
    required this.fineTypeId,
    required this.fineAmount,
    required this.legalProvision,
    this.photoPath,
    String? clientActionUuid,
  }) : allotmentId = null,
       remarks = null,
       clientActionUuid = clientActionUuid ?? ClientActionUuid.generate();

  final int? areaId;

  /// The tenancy the fine is billed to, on a fine raised from a unit's own
  /// profile. The unit itself travels in the path (`properties/{id}/fines`),
  /// so this is what tells the server which allotment on it to bill — a fine
  /// against a area names no allotment at all.
  final int? allotmentId;

  /// The offence, as `FineTypeDefinition.id` off the same call.
  ///
  /// Read it from the register and never hardcode a picker of these: they are
  /// rows MCQ can rename, reorder and switch off, and a copy written into the
  /// app is a list that silently stops matching.
  final int fineTypeId;

  /// The amount, as a string, e.g. `"3000.00"`. At least 1.
  ///
  /// `FineTypeDefinition.suggestedAmount` is what to pre-fill it with. The
  /// response tells you the officer's own field limit in `amounts.field_limit`,
  /// and sets `requires_approval` when the amount exceeds it.
  final String fineAmount;

  /// The law being applied, e.g. "Section 97, Balochistan Local Government Act
  /// 2010". Goes on the paperwork the shopkeeper receives, and is always
  /// `FineTypeDefinition.defaultProvision` for the offence — the field form
  /// does not type one, so an offence the register publishes without a
  /// provision cannot be fined at all.
  final String legalProvision;

  /// Who to bill when it is not the register's tenant.
  final FineOffender? offender;

  /// The path returned by `POST /enforcement/evidence`, never the handset's
  /// own. Upload the photograph first and send its path here: the image goes
  /// over a bazaar's uplink once, and the fine behind it can be retried
  /// without it.
  final String? photoPath;

  /// The officer's own words on the fine, e.g. "Refused to remove the display
  /// after two warnings." Optional, and only asked for on a unit's fine.
  final String? remarks;

  /// The idempotency key. Generated once, here, when the request is built, and
  /// reused on every retry — re-sending the same instance is what stops a fine
  /// sent twice on a weak signal becoming two fines.
  final String clientActionUuid;

  /// `legal_provision` is capped at 150 characters — shorter than a full
  /// citation, so a register row longer than this is refused by the server.
  static const int legalProvisionMaxLength = 150;

  /// The wire body. Nulls are dropped by the API service, so a field the
  /// officer left blank is simply not sent.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'area_id': areaId,
    'allotment_id': allotmentId,
    'fine_type_id': fineTypeId,
    'fine_amount': fineAmount,
    'legal_provision': legalProvision,
    ...?offender?.toJson(),
    'photo_path': photoPath,
    'remarks': remarks,
    'client_action_uuid': clientActionUuid,
  };
}

/// The person being fined, when they are not on the register — a handcart on
/// the footpath, somebody trading out of a vacant unit.
///
/// Name, father's name and mobile are required together: send one and the
/// server refuses the request naming the other two. That rule is why all three
/// are required here rather than left optional.
class FineOffender {
  const FineOffender({
    required this.name,
    required this.fatherName,
    required this.mobileNo,
    this.cnic,
  });

  /// Pre-fill this block from `PersonLookup.suggested` after a CNIC search —
  /// and read `PersonLookup.fineCount` first, because a first offence and a
  /// fifth are different conversations.
  factory FineOffender.fromSuggestion(
    PersonSuggestion suggestion, {
    String? cnic,
  }) => FineOffender(
    name: suggestion.name,
    fatherName: suggestion.fatherName ?? '',
    mobileNo: suggestion.mobileNo ?? '',
    cnic: cnic,
  );

  final String name;
  final String fatherName;
  final String mobileNo;

  /// e.g. `5440011223344`.
  final String? cnic;

  /// Whether the server will accept this block. All three identity fields have
  /// to be there together.
  bool get isComplete =>
      name.trim().isNotEmpty &&
      fatherName.trim().isNotEmpty &&
      mobileNo.trim().isNotEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'offender_name': name,
    'offender_father_name': fatherName,
    'offender_mobile_no': mobileNo,
    'offender_cnic': cnic,
  };
}
