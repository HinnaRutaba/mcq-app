import '../../core/utils/json_reader.dart';
import '../common/money.dart';

/// Where a follow-up stands. Three states, and they call for three
/// different things — which is why they are drawn three different ways.
enum FollowUpState {
  /// He said he would pay and did not. Escalation belongs on this card:
  /// fine, seal, open a case.
  overdue,

  /// Promised today. Offer a call before anything heavier.
  dueToday,

  /// Just a note. Nothing to do yet.
  upcoming;

  static FollowUpState fromCode(String? code) {
    switch (code) {
      case 'overdue':
        return FollowUpState.overdue;
      case 'due_today':
        return FollowUpState.dueToday;
      default:
        return FollowUpState.upcoming;
    }
  }
}

/// One row of `GET /enforcement/field/follow-ups` — the chase queue that
/// did not exist before.
///
/// A promise taken and never chased is worse than no promise: the officer
/// has spent his authority and got nothing for it.
class FollowUp {
  const FollowUp({
    required this.actionId,
    required this.kind,
    required this.actionType,
    required this.state,
    required this.daysRemaining,
    required this.allotteeName,
    required this.propertyId,
    required this.propertyCode,
    required this.shopNo,
    required this.areaName,
    this.recordedOn,
    this.dueOn,
    this.remarks,
    this.caseId,
    this.caseNo,
    this.caseStatus,
    this.allotmentId,
    this.allotmentNo,
    this.allotteeId,
    this.mobileNo,
    this.outstandingAtPromise,
    this.outstandingNow,
  });

  final int actionId;

  /// `payment_promised` or `revisit`.
  final String kind;
  final String actionType;

  final FollowUpState state;

  /// Negative means overdue. The server's figure, not one computed here —
  /// the handset clock is not the authority on a due date.
  final int daysRemaining;

  final DateTime? recordedOn;
  final DateTime? dueOn;
  final String? remarks;

  final int? caseId;
  final String? caseNo;
  final String? caseStatus;

  final int propertyId;
  final String propertyCode;
  final String shopNo;
  final String areaName;

  final int? allotmentId;
  final String? allotmentNo;
  final int? allotteeId;
  final String allotteeName;
  final String? mobileNo;

  /// The two figures that make this queue useful. A balance that has come
  /// down means the promise was partly kept — a completely different
  /// conversation from one that has not moved at all.
  final Money? outstandingAtPromise;
  final Money? outstandingNow;

  factory FollowUp.fromJson(Map<String, dynamic> json) => FollowUp(
        actionId: json.intOr('action_id') ,
        kind: json.strOr('kind'),
        actionType: json.strOr('action_type'),
        state: FollowUpState.fromCode(json.str('state')),
        daysRemaining: json.intOr('days_remaining'),
        recordedOn: json.date('recorded_on'),
        dueOn: json.date('due_on'),
        remarks: json.str('remarks'),
        caseId: json.integer('case_id'),
        caseNo: json.str('case_no'),
        caseStatus: json.str('case_status'),
        propertyId: json.intOr('property_id'),
        propertyCode: json.strOr('property_code'),
        shopNo: json.strOr('shop_no'),
        areaName: json.strOr('area_name'),
        allotmentId: json.integer('allotment_id'),
        allotmentNo: json.str('allotment_no'),
        allotteeId: json.integer('allottee_id'),
        allotteeName: json.strOr('allottee_name'),
        mobileNo: json.str('mobile_no'),
        outstandingAtPromise: json.moneyOrNull('outstanding_at_promise'),
        outstandingNow: json.moneyOrNull('outstanding_now'),
      );

  static List<FollowUp> listFrom(List<dynamic> raw) => raw
      .whereType<Map<String, dynamic>>()
      .map(FollowUp.fromJson)
      .toList(growable: false);

  bool get isPromise => kind == 'payment_promised';
  bool get isCallable => (mobileNo ?? '').trim().isNotEmpty;
  int get daysOverdue => daysRemaining < 0 ? -daysRemaining : 0;

  String get unitLabel =>
      shopNo.isEmpty ? propertyCode : '$propertyCode · $shopNo';

  /// True when the balance has fallen since the promise was taken.
  ///
  /// Deliberately a yes/no and not an amount. The brief asks for *"Paid
  /// ₨3,000 since promising"* and that sentence quotes a figure at a
  /// counter — a figure this app is not allowed to compute, because
  /// subtracting two amounts in Dart is the same error as adding them. The
  /// app shows both server figures and says the balance moved; the exact
  /// difference needs a `paid_since_promise` field on the payload. Filed in
  /// QUESTIONS.md.
  bool get hasPaidSomething {
    final then = outstandingAtPromise;
    final now = outstandingNow;
    if (then == null || now == null) return false;
    return now.isLessThan(then);
  }

  /// True when the balance is exactly where it was. The promise bought MCQ
  /// nothing, and that is the sentence the officer needs.
  bool get hasNotMoved {
    final then = outstandingAtPromise;
    final now = outstandingNow;
    if (then == null || now == null) return false;
    return then == now;
  }
}
