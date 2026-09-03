import '../core/utils/json_parse.dart';
import 'api_refs.dart';

/// A fine that has been imposed — and billed.
///
/// The one call that created this posted the receivable, raised the [challan],
/// issued a payment link and texted the person fined. A fine is a debt of its
/// own: it never merges with the rent arrears on the same unit, and the two
/// payment links are never added into one figure.
///
/// [seal] carries the outcome of a seal requested alongside the fine. The fine
/// stands even when the seal was refused, so show the fine as imposed and
/// surface the seal separately.
class Fine {
  const Fine({
    this.id,
    this.fineNo,
    this.fineType,
    this.fineTypeId,
    this.status,
    this.photoPath,
    this.propertySealId,
    required this.amounts,
    this.imposedOn,
    this.legalProvision,
    this.remarks,
    this.requiresApproval = false,
    this.isEffective = false,
    this.canCancel = false,
    this.challanId,
    this.waiverAdjustmentId,
    this.payer,
    this.imposedBy,
    this.property,
    this.allotment,
    this.enforcementCase,
    this.challan,
    this.createdAt,
    this.seal,
  });

  final int? id;

  /// e.g. `MCQ-FN-2627-00008`.
  final String? fineNo;

  /// Labelled by the server, e.g. "Used the unit without permission".
  final LabelledValue? fineType;

  /// The definitions row behind [fineType] — `FineTypeDefinition.id`.
  final int? fineTypeId;

  /// e.g. "Added to a challan".
  final LabelledValue? status;

  /// The server-side path of the photograph filed with the fine, as returned
  /// by the evidence upload.
  final String? photoPath;

  /// The seal this fine is tied to, when one was applied alongside it or the
  /// fine was raised for breaking one.
  final int? propertySealId;

  final FineAmounts amounts;
  final DateTime? imposedOn;

  /// The provision applied, as it will appear on the paperwork.
  final String? legalProvision;

  final String? remarks;

  /// The amount exceeded the officer's field limit, so a senior has to approve
  /// it before it bites. Say so — the shopkeeper should not be told a fine is
  /// final when it is not.
  final bool requiresApproval;

  /// Whether the fine is live right now.
  final bool isEffective;

  final bool canCancel;

  final int? challanId;

  /// Set when part or all of the fine was waived.
  final int? waiverAdjustmentId;

  /// Who has to pay — the tenant on the register, or a named offender.
  final FinePayer? payer;

  final UserRef? imposedBy;
  final PropertyRef? property;

  /// Null when the fine was raised against somebody not on the register.
  final AllotmentRef? allotment;

  final EnforcementCaseRef? enforcementCase;

  /// The payable bill this fine raised, with its live payment link.
  final FineChallanRef? challan;

  final DateTime? createdAt;

  /// The seal applied alongside the fine, held as the raw payload: the
  /// published spec only ever captured this null, so its shape — including how
  /// a refusal is expressed — is not pinned down. Read [sealApplied] first, and
  /// model this properly once a populated response is available.
  final Map<String, dynamic>? seal;

  factory Fine.fromJson(Map<String, dynamic> json) => Fine(
    id: Json.integer(json['id']),
    fineNo: Json.string(json['fine_no']),
    fineType: LabelledValue.maybe(json['fine_type']),
    fineTypeId: Json.integer(json['fine_type_id']),
    status: LabelledValue.maybe(json['status']),
    photoPath: Json.string(json['photo_path']),
    propertySealId: Json.integer(json['property_seal_id']),
    amounts: FineAmounts.fromJson(Json.map(json['amounts'])),
    imposedOn: Json.dateTime(json['imposed_on']),
    legalProvision: Json.string(json['legal_provision']),
    remarks: Json.string(json['remarks']),
    requiresApproval: Json.booleanOr(json['requires_approval']),
    isEffective: Json.booleanOr(json['is_effective']),
    canCancel: Json.booleanOr(json['can_cancel']),
    challanId: Json.integer(json['challan_id']),
    waiverAdjustmentId: Json.integer(json['waiver_adjustment_id']),
    payer: FinePayer.maybe(json['payer']),
    imposedBy: UserRef.maybe(json['imposed_by']),
    property: PropertyRef.maybe(json['property']),
    allotment: AllotmentRef.maybe(json['allotment']),
    enforcementCase: EnforcementCaseRef.maybe(json['enforcement_case']),
    challan: FineChallanRef.maybe(json['challan']),
    createdAt: Json.dateTime(json['created_at']),
    seal: Json.mapOrNull(json['seal']),
  );

  /// Whether a seal came back with the fine. False both when no seal was asked
  /// for and when one was refused — the response is the only place that says
  /// which, so pair this with the server's `message`.
  bool get sealApplied => seal != null && seal!.isNotEmpty;
}

class FineAmounts {
  const FineAmounts({this.fineAmount, this.fieldLimit});

  /// The fine, as a string.
  final String? fineAmount;

  /// The most this officer may impose in the field without approval. Show it on
  /// the fine form so the limit is known before the amount is typed.
  final String? fieldLimit;

  factory FineAmounts.fromJson(Map<String, dynamic> json) => FineAmounts(
    fineAmount: Json.money(json['fine_amount']),
    fieldLimit: Json.money(json['field_limit']),
  );
}

/// Who the fine is billed to.
///
/// [kind] is `allottee` when the register's tenant is paying, and `named` when
/// the officer identified somebody who is not on the register — the extra
/// identity fields are only populated in that second case.
class FinePayer {
  const FinePayer({
    this.kind,
    this.allotteeId,
    required this.name,
    this.fatherName,
    this.mobileNo,
    this.cnic,
    this.business,
    this.address,
  });

  /// `allottee` | `named`.
  final String? kind;

  final int? allotteeId;
  final String name;
  final String? fatherName;
  final String? mobileNo;
  final String? cnic;
  final String? business;
  final String? address;

  factory FinePayer.fromJson(Map<String, dynamic> json) => FinePayer(
    kind: Json.string(json['kind']),
    allotteeId: Json.integer(json['allottee_id']),
    name: Json.stringOr(json['name']),
    fatherName: Json.string(json['father_name']),
    mobileNo: Json.string(json['mobile_no']),
    cnic: Json.string(json['cnic']),
    business: Json.string(json['business']),
    address: Json.string(json['address']),
  );

  static FinePayer? maybe(Object? source) =>
      source is Map ? FinePayer.fromJson(Json.map(source)) : null;

  /// Somebody who is not on the register.
  bool get isNamedOffender => kind == 'named';
}

/// The bill the fine raised, and how the shopkeeper can pay it.
class FineChallanRef {
  const FineChallanRef({
    this.id,
    this.challanNo,
    this.balanceAmount,
    this.dueDate,
    this.consumerNo,
    this.hasLiveLink = false,
  });

  final int? id;

  /// e.g. `MCQ-CH-2627-0000404`.
  final String? challanNo;

  /// Still owed on this bill, as a string.
  final String? balanceAmount;

  final DateTime? dueDate;

  /// What the shopkeeper quotes at a counter, e.g. `DRTRMNMD`.
  final String? consumerNo;

  /// Whether the payment link is live. Check before offering to share it.
  final bool hasLiveLink;

  factory FineChallanRef.fromJson(Map<String, dynamic> json) => FineChallanRef(
    id: Json.integer(json['id']),
    challanNo: Json.string(json['challan_no']),
    balanceAmount: Json.money(json['balance_amount']),
    dueDate: Json.dateTime(json['due_date']),
    consumerNo: Json.string(json['consumer_no']),
    hasLiveLink: Json.booleanOr(json['has_live_link']),
  );

  static FineChallanRef? maybe(Object? source) =>
      source is Map ? FineChallanRef.fromJson(Json.map(source)) : null;
}
