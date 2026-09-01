import '../core/utils/json_parse.dart';
import 'field_write_request.dart';

/// Imposes a fine on a unit — and, with [seal], seals it in the same request.
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
/// Set [offender] when fining somebody who is not on the register (the unit is
/// vacant, or somebody else is trading there). Leave it null to bill the person
/// holding the unit — `UnitCard.needsOffenderDetails` is the server telling you
/// which it must be.
class FineRequest extends FieldWriteRequest {
  FineRequest({
    required this.fineType,
    required this.fineAmount,
    required this.legalProvision,
    this.imposedOn,
    this.allotmentId,
    this.enforcementCaseId,
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

  /// The kind of offence, e.g. `unauthorised_use`, `encroachment`. The server
  /// validates against an enum whose full set is not published, so this stays a
  /// string — see [knownFineTypes] for the ones the API documents by example.
  final String fineType;

  /// The amount, as a string, e.g. `"3000.00"`. At least 1. The response tells
  /// you the officer's own field limit in `amounts.field_limit`, and sets
  /// `requires_approval` when the amount exceeds it.
  final String fineAmount;

  /// The law being applied, e.g. "Section 12(3) of the Local Government Act".
  /// Goes on the paperwork the shopkeeper receives.
  final String legalProvision;

  /// The date of the fine. Cannot be in the future.
  final DateTime? imposedOn;

  /// The tenancy to bill, when the unit has more than one on record.
  final int? allotmentId;

  /// Ties the fine to an open enforcement case, so it lands on that timeline.
  final int? enforcementCaseId;

  /// Who to bill when it is not the register's tenant.
  final FineOffender? offender;

  /// Seal the unit as part of the same transaction.
  final FineSealRequest? seal;

  /// The fine types the published API uses by example. Not exhaustive — the
  /// server's enum is the authority.
  static const List<String> knownFineTypes = <String>[
    'unauthorised_use',
    'encroachment',
  ];

  /// `remarks` is capped at 500 characters on this endpoint, shorter than the
  /// 1000 the action endpoints allow.
  static const int remarksMaxLength = 500;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(),
    'fine_type': fineType,
    'fine_amount': fineAmount,
    'legal_provision': legalProvision,
    'imposed_on': Json.dateOnly(imposedOn),
    'allotment_id': allotmentId,
    'enforcement_case_id': enforcementCaseId,
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

  final String name;
  final String fatherName;
  final String mobileNo;

  /// e.g. `54400-1234567-1`.
  final String? cnic;

  /// What they trade as, e.g. "Fruit stall, handcart".
  final String? business;

  /// Where they were found, e.g. "Footpath outside Shop 12, Liaquat Bazaar".
  final String? address;

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

  /// Why the unit is being sealed. Required whenever a seal is sent at all.
  final String sealReason;

  final DateTime? sealedOn;

  /// Path returned by the evidence upload — the photograph of the applied seal.
  final String? sealPhotoPath;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'seal_reason': sealReason,
    'sealed_on': Json.dateOnly(sealedOn),
    'seal_photo_path': sealPhotoPath,
  };
}
