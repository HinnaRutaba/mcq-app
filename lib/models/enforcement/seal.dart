import '../../core/utils/json_reader.dart';
import '../common/api_enum.dart';
import '../common/can_flags.dart';
import '../common/entity_refs.dart';

/// A seal: physically closing a shop. The severest step short of court.
class Seal {
  const Seal({
    required this.id,
    required this.status,
    required this.flags,
    required this.property,
    required this.allottee,
    this.sealNo,
    this.caseId,
    this.reason,
    this.sealedOn,
    this.releasedOn,
    this.releaseRemarks,
  });

  final int id;
  final ApiEnum status;

  /// `can_release` (documented in one place as `can_unseal`) turns true
  /// when the server is satisfied. Do not compute it from a balance: a
  /// walk-in payment does not authorise an unseal, and a fine paid by a
  /// stranger settles nothing of the allottee's arrears.
  final CanFlags flags;

  final PropertyRef property;
  final AllotteeRef allottee;
  final String? sealNo;
  final int? caseId;
  final String? reason;
  final DateTime? sealedOn;
  final DateTime? releasedOn;
  final String? releaseRemarks;

  factory Seal.fromJson(Map<String, dynamic> json) => Seal(
        id: json.intOr('id'),
        status: json.apiEnum('status'),
        flags: CanFlags.fromJson(json),
        property: PropertyRef.fromJson(json.child('property')),
        allottee: AllotteeRef.fromJson(json.child('allottee')),
        sealNo: json.str('seal_no'),
        caseId: json.integer('enforcement_case_id') ?? json.integer('case_id'),
        reason: json.str('reason'),
        sealedOn: json.date('sealed_on') ?? json.date('sealed_at'),
        releasedOn: json.date('released_on') ?? json.date('released_at'),
        releaseRemarks: json.str('release_remarks'),
      );

  bool get isReleased => releasedOn != null;
  bool get canRelease => flags.canRelease;
}
