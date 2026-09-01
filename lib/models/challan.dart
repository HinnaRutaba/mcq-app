import '../core/utils/json_parse.dart';
import 'api_refs.dart';

/// A challan — a bill the shopkeeper pays.
///
/// A fine challan is not a rent bill. When [isSingleCharge] is true, draw one
/// charge with one label and no rent breakdown; and never add a rent challan's
/// balance to a fine challan's, however tempting a single "total owed" looks.
/// They are separate debts with separate payment links.
///
/// Every figure in [amounts] is a string. Nothing here is ever parsed into a
/// number in Dart.
class Challan {
  const Challan({
    this.id,
    this.challanNo,
    this.challanType,
    this.isSingleCharge = false,
    this.surchargeExempt = false,
    this.surchargeExemptReason,
    this.status,
    this.issueDate,
    this.dueDate,
    this.isOverdue = false,
    this.daysOverdue = 0,
    required this.amounts,
    this.isProrated = false,
    this.prorationDays,
    this.isEdited = false,
    this.remarks,
    this.consumerNumber,
    this.linkShortCode,
    this.linkExpiresAt,
    this.hasLiveLink = false,
    this.canDefer = false,
    this.dispatchedAt,
    this.firstPaidAt,
    this.settledAt,
    this.supersededByChallanId,
    this.billingPeriod,
    this.allotment,
    this.allottee,
    this.property,
    this.area,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String? challanNo;

  /// `fine` for a penalty, otherwise a rent bill.
  final LabelledValue? challanType;

  /// One charge, one label — a fine, not a month's rent with arrears and
  /// surcharge.
  final bool isSingleCharge;

  final bool surchargeExempt;
  final String? surchargeExemptReason;

  /// e.g. "Sent out", "Paid".
  final LabelledValue? status;

  final DateTime? issueDate;
  final DateTime? dueDate;
  final bool isOverdue;
  final int daysOverdue;

  final ChallanAmounts amounts;

  final bool isProrated;
  final int? prorationDays;
  final bool isEdited;

  /// The server's own note on the bill, e.g. which fine it came from.
  final String? remarks;

  /// What the shopkeeper quotes at a payment counter.
  final String? consumerNumber;

  /// The short code in the payment link.
  final String? linkShortCode;

  final DateTime? linkExpiresAt;

  /// Whether the payment link still works — check this before offering to
  /// share it.
  final bool hasLiveLink;

  final bool canDefer;
  final DateTime? dispatchedAt;
  final DateTime? firstPaidAt;
  final DateTime? settledAt;

  /// Set when this bill was replaced by a corrected one.
  final int? supersededByChallanId;

  final BillingPeriod? billingPeriod;

  /// Null on a fine raised against somebody who is not on the register.
  final AllotmentRef? allotment;
  final AllotteeRef? allottee;

  final PropertyRef? property;
  final AreaRef? area;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Challan.fromJson(Map<String, dynamic> json) => Challan(
    id: Json.integer(json['id']),
    challanNo: Json.string(json['challan_no']),
    challanType: LabelledValue.maybe(json['challan_type']),
    isSingleCharge: Json.booleanOr(json['is_single_charge']),
    surchargeExempt: Json.booleanOr(json['surcharge_exempt']),
    surchargeExemptReason: Json.string(json['surcharge_exempt_reason']),
    status: LabelledValue.maybe(json['status']),
    issueDate: Json.dateTime(json['issue_date']),
    dueDate: Json.dateTime(json['due_date']),
    isOverdue: Json.booleanOr(json['is_overdue']),
    daysOverdue: Json.integerOr(json['days_overdue']),
    amounts: ChallanAmounts.fromJson(Json.map(json['amounts'])),
    isProrated: Json.booleanOr(json['is_prorated']),
    prorationDays: Json.integer(json['proration_days']),
    isEdited: Json.booleanOr(json['is_edited']),
    remarks: Json.string(json['remarks']),
    consumerNumber: Json.string(json['consumer_number']),
    linkShortCode: Json.string(json['link_short_code']),
    linkExpiresAt: Json.dateTime(json['link_expires_at']),
    hasLiveLink: Json.booleanOr(json['has_live_link']),
    canDefer: Json.booleanOr(json['can_defer']),
    dispatchedAt: Json.dateTime(json['dispatched_at']),
    firstPaidAt: Json.dateTime(json['first_paid_at']),
    settledAt: Json.dateTime(json['settled_at']),
    supersededByChallanId: Json.integer(json['superseded_by_challan_id']),
    billingPeriod: BillingPeriod.maybe(json['billing_period']),
    allotment: AllotmentRef.maybe(json['allotment']),
    allottee: AllotteeRef.maybe(json['allottee']),
    property: PropertyRef.maybe(json['property']),
    area: AreaRef.maybe(json['area']),
    createdAt: Json.dateTime(json['created_at']),
    updatedAt: Json.dateTime(json['updated_at']),
  );

  bool get isFine => challanType?.value == 'fine';

  bool get isSettled => settledAt != null;
}

/// Every figure on a challan, all of them strings.
///
/// [payableNow] is the one to quote at a counter — it is what the server says
/// is due today, after any deferral.
class ChallanAmounts {
  const ChallanAmounts({
    this.previousBalance,
    this.currentAmount,
    this.arrearsAmount,
    this.surchargeAmount,
    this.otherAmount,
    this.adjustmentAmount,
    this.totalAmount,
    this.paidAmount,
    this.balanceAmount,
    this.deferredAmount,
    this.payableNow,
  });

  final String? previousBalance;
  final String? currentAmount;
  final String? arrearsAmount;
  final String? surchargeAmount;

  /// Where a fine lands on an otherwise rent-shaped bill.
  final String? otherAmount;

  final String? adjustmentAmount;
  final String? totalAmount;
  final String? paidAmount;
  final String? balanceAmount;
  final String? deferredAmount;
  final String? payableNow;

  factory ChallanAmounts.fromJson(Map<String, dynamic> json) => ChallanAmounts(
    previousBalance: Json.money(json['previous_balance']),
    currentAmount: Json.money(json['current_amount']),
    arrearsAmount: Json.money(json['arrears_amount']),
    surchargeAmount: Json.money(json['surcharge_amount']),
    otherAmount: Json.money(json['other_amount']),
    adjustmentAmount: Json.money(json['adjustment_amount']),
    totalAmount: Json.money(json['total_amount']),
    paidAmount: Json.money(json['paid_amount']),
    balanceAmount: Json.money(json['balance_amount']),
    deferredAmount: Json.money(json['deferred_amount']),
    payableNow: Json.money(json['payable_now']),
  );
}

class BillingPeriod {
  const BillingPeriod({this.id, this.periodCode, this.fiscalYear});

  final int? id;

  /// e.g. `2026-08`.
  final String? periodCode;

  /// e.g. `2026-2027`.
  final String? fiscalYear;

  factory BillingPeriod.fromJson(Map<String, dynamic> json) => BillingPeriod(
    id: Json.integer(json['id']),
    periodCode: Json.string(json['period_code']),
    fiscalYear: Json.string(json['fiscal_year']),
  );

  static BillingPeriod? maybe(Object? source) =>
      source is Map ? BillingPeriod.fromJson(Json.map(source)) : null;
}
