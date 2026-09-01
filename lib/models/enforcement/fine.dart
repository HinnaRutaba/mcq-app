import '../../core/utils/json_reader.dart';
import '../common/api_enum.dart';
import '../common/can_flags.dart';
import '../common/entity_refs.dart';
import '../common/money.dart';
import '../billing/challan.dart';

/// A fine: a penalty under a named provision of law.
class Fine {
  const Fine({
    required this.id,
    required this.fineNo,
    required this.fineType,
    required this.amount,
    required this.status,
    required this.flags,
    required this.property,
    this.legalProvision,
    this.imposedOn,
    this.offenderName,
    this.offenderMobileNo,
    this.allottee = AllotteeRef.none,
    this.challan,
    this.remarks,
  });

  final int id;
  final String fineNo;
  final ApiEnum fineType;
  final Money amount;
  final ApiEnum status;
  final CanFlags flags;
  final PropertyRef property;

  /// The section of law. A fine with no provision named is unenforceable
  /// in front of a magistrate's own court.
  final String? legalProvision;

  final DateTime? imposedOn;

  /// Set when nobody held the unit — the officer named the person fined.
  final String? offenderName;
  final String? offenderMobileNo;

  /// Set when the unit had a live agreement and the holder was billed.
  final AllotteeRef allottee;

  /// The challan raised for this fine, with its own payment link.
  final Challan? challan;

  final String? remarks;

  factory Fine.fromJson(Map<String, dynamic> json) => Fine(
        id: json.intOr('id'),
        fineNo: json.str('fine_no') ?? json.strOr('reference_no'),
        fineType: json.apiEnum('fine_type'),
        amount: json.moneyOrNull('fine_amount') ?? json.money('amount'),
        status: json.apiEnum('status'),
        flags: CanFlags.fromJson(json),
        property: PropertyRef.fromJson(json.child('property')),
        legalProvision: json.str('legal_provision'),
        imposedOn: json.date('imposed_on') ?? json.date('created_at'),
        offenderName: json.str('offender_name'),
        offenderMobileNo: json.str('offender_mobile_no'),
        allottee: AllotteeRef.fromJson(json.child('allottee')),
        challan: json.child('challan') == null
            ? null
            : Challan.fromJson(json.child('challan')!),
        remarks: json.str('remarks'),
      );

  /// Who will be asked to pay. There is no such thing as a fine imposed on
  /// a shop and nobody — the database refuses it under
  /// `chk_fine_has_a_payer`.
  String get payerName =>
      allottee.exists ? allottee.name : (offenderName ?? '');

  String? get payerMobile =>
      allottee.exists ? allottee.mobileNo : offenderMobileNo;

  /// Not yet effective. Say so on the row; do not show it as imposed.
  bool get notYetEffective => flags.requiresApproval || flags.awaitingApproval;
}

/// What comes back from `POST /enforcement/properties/{property}/fines`.
///
/// In one transaction the fine is posted to the ledger, a challan of type
/// `fine` is raised for it, that challan gets its own payment link and
/// Consumer Number, and an SMS goes out with the amount, the challan number
/// and the link. The app does not render the payment page — it tells the
/// officer the link went out so they can say "check your phone".
class FineOutcome {
  const FineOutcome({
    required this.fine,
    required this.wasCreated,
    this.challan,
    this.message,
    this.smsSentTo,
  });

  final Fine fine;

  /// 201 created, versus 200 "you already sent that" — a replay of the same
  /// `client_action_uuid`. The UI must not announce the fine twice.
  final bool wasCreated;

  final Challan? challan;
  final String? message;
  final String? smsSentTo;

  factory FineOutcome.fromJson(
    Map<String, dynamic> json, {
    required bool wasCreated,
    String? message,
  }) {
    final fineJson = json.child('fine') ?? json;
    final challanJson = json.child('challan') ?? fineJson.child('challan');
    return FineOutcome(
      fine: Fine.fromJson(fineJson),
      wasCreated: wasCreated,
      challan: challanJson == null ? null : Challan.fromJson(challanJson),
      message: message,
      smsSentTo: json.str('sms_sent_to') ??
          json.str('notified_mobile_no') ??
          challanJson?.str('payer_mobile_no'),
    );
  }

  /// Whether a payment link actually went out. If it did not, the officer
  /// needs to know before they leave the shop.
  bool get linkDispatched =>
      (smsSentTo ?? '').isNotEmpty && (challan?.payUrl ?? '').isNotEmpty;
}
