import '../core/utils/json_parse.dart';
import 'field_write_request.dart';
import 'person_lookup.dart';

/// Imposes a fine — and, with [seal], seals the unit in the same request.
///
/// One call posts the receivable, raises a payable challan, issues a payment
/// link and texts the person fined. Two things follow from that:
///
/// * [fineAmount] is a string, like every other amount in this app. It is the
///   figure that will be printed on a challan and quoted at a counter.
/// * The fine stands even if the seal is refused. Show the fine as imposed and
///   the seal's refusal as a separate notice — never roll the whole call back
///   in the UI on the strength of a rejected seal.
///
/// There are three ways to send one, and they differ only in who is billed:
///
/// * **The holder of a unit** — the default constructor with [offender] left
///   null. `FineRepository.impose` posts it against the unit.
/// * **Somebody at a unit who is not on the register** — the default
///   constructor with [offender] set. The unit must still be one of MCQ's own;
///   the units search returns the vacant ones, and
///   `UnitCard.needsOffenderDetails` is the server saying which it must be.
/// * **Somebody with no MCQ unit at all** — [FineRequest.inArea], for a
///   hawker, a handcart, somebody blocking a road. `area_id` is the only
///   scoping there is, and the officer still cannot fine outside their own
///   postings.
class FineRequest extends FieldWriteRequest {
  FineRequest({
    required this.fineType,
    required this.fineAmount,
    required this.legalProvision,
    this.fineTypeId,
    this.imposedOn,
    this.areaId,
    this.allotmentId,
    this.enforcementCaseId,
    this.propertySealId,
    this.offender,
    this.seal,
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

  /// A fine on anybody in the city, against no MCQ property — a hawker, a
  /// handcart, somebody blocking a road.
  ///
  /// [areaId] is required and is the only scoping: the server still refuses a
  /// bazaar the officer is not posted to. [offender] is required too, because
  /// there is no agreement to fall back on for a name — and its three identity
  /// fields are required together, which is why `FineOffender` demands all
  /// three.
  ///
  /// Post it with `FineRepository.imposeInArea`, which goes to
  /// `POST enforcement/fines` rather than to a unit's own path.
  FineRequest.inArea({
    required int this.areaId,
    required FineOffender this.offender,
    required this.fineType,
    required this.fineAmount,
    required this.legalProvision,
    this.fineTypeId,
    this.imposedOn,
    this.enforcementCaseId,
    this.seal,
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
  }) : allotmentId = null,
       propertySealId = null;

  /// The kind of offence, e.g. `unauthorised_use`, `encroachment`.
  ///
  /// Read the codes from `GET enforcement/definitions` — see
  /// `EnforcementDefinitions.fineTypes` — and never hardcode a picker of them:
  /// they are rows MCQ can rename, reorder and switch off, and a hardcoded
  /// copy is a list that silently stops matching the register.
  final String fineType;

  /// `FineTypeDefinition.id` for the same offence. Optional — the server
  /// accepts either, and [fineType] alone is enough. Sending both is harmless
  /// and makes the record unambiguous if a code is ever renamed.
  final int? fineTypeId;

  /// The amount, as a string, e.g. `"3000.00"`. At least 1.
  ///
  /// `FineTypeDefinition.suggestedAmount` is what to pre-fill it with. The
  /// response tells you the officer's own field limit in `amounts.field_limit`,
  /// and sets `requires_approval` when the amount exceeds it.
  final String fineAmount;

  /// The law being applied, e.g. "Section 96, Balochistan Local Government Act
  /// 2010". Goes on the paperwork the shopkeeper receives, so pre-fill it from
  /// `FineTypeDefinition.defaultProvision` — which is null on `other`, the one
  /// offence where the officer has to name the section themselves.
  final String legalProvision;

  /// The date of the fine. Cannot be in the future.
  final DateTime? imposedOn;

  /// The bazaar. Required on [FineRequest.inArea] and unnecessary on a fine
  /// against a unit, which the server scopes from the unit itself.
  final int? areaId;

  /// The tenancy to bill, when the unit has more than one on record.
  final int? allotmentId;

  /// Ties the fine to an open enforcement case, so it lands on that timeline.
  final int? enforcementCaseId;

  /// An existing seal this fine relates to — the one that was broken, on a
  /// `seal_violation`. To apply a *new* seal with the fine, use [seal].
  final int? propertySealId;

  /// Who to bill when it is not the register's tenant.
  final FineOffender? offender;

  /// Seal the unit as part of the same transaction.
  final FineSealRequest? seal;

  /// `remarks` is capped at 500 characters on this endpoint, shorter than the
  /// 1000 the action endpoints allow.
  static const int remarksMaxLength = 500;

  /// `legal_provision` is capped at 150 characters — shorter than a full
  /// citation, so the form has to say so before it is typed.
  static const int legalProvisionMaxLength = 150;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(),
    'fine_type': fineType,
    'fine_type_id': fineTypeId,
    'fine_amount': fineAmount,
    'legal_provision': legalProvision,
    'imposed_on': Json.dateOnly(imposedOn),
    'area_id': areaId,
    'allotment_id': allotmentId,
    'enforcement_case_id': enforcementCaseId,
    'property_seal_id': propertySealId,
    ...?offender?.toJson(),
    if (seal != null) 'seal': seal!.toJson(),
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
    this.business,
    this.address,
  });

  /// Pre-fill this block from `PersonLookup.suggested` after a CNIC search —
  /// and read `PersonLookup.fineCount` first, because a first offence and a
  /// fifth are different conversations.
  factory FineOffender.fromSuggestion(
    PersonSuggestion suggestion, {
    String? cnic,
    String? business,
    String? address,
  }) => FineOffender(
    name: suggestion.name,
    fatherName: suggestion.fatherName ?? '',
    mobileNo: suggestion.mobileNo ?? '',
    cnic: cnic,
    business: business,
    address: address,
  );

  final String name;
  final String fatherName;
  final String mobileNo;

  /// e.g. `54400-1234567-1`. Up to 15 characters, so the dashed form fits —
  /// unlike a trade licence application, which wants 13 bare digits.
  final String? cnic;

  /// What they trade as, e.g. "Fruit stall, handcart".
  final String? business;

  /// Where they were found, e.g. "Footpath outside Shop 12, Liaquat Bazaar".
  final String? address;

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
    'offender_business': business,
    'offender_address': address,
  };
}

/// The seal half of a fine request, sent nested under `seal`.
class FineSealRequest {
  const FineSealRequest({
    required this.sealReason,
    this.sealedOn,
    this.sealPhotoPath,
  });

  /// Why the unit is being sealed. Required whenever a seal is sent at all,
  /// and capped at 300 characters.
  final String sealReason;

  final DateTime? sealedOn;

  /// Path returned by the evidence upload — the photograph of the applied seal.
  final String? sealPhotoPath;

  static const int reasonMaxLength = 300;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'seal_reason': sealReason,
    'sealed_on': Json.dateOnly(sealedOn),
    'seal_photo_path': sealPhotoPath,
  };
}
