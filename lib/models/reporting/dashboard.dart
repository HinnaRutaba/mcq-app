import '../../core/utils/json_reader.dart';
import '../common/money.dart';
import 'area_scope.dart';

/// `data.receivable` — the whole register, scoped to the officer's areas.
///
/// [arrearsPending] and [notYetDue] sum to [owed]. **Do not label [owed] as
/// "arrears"**: on the demo register that overstates the problem by 2.7
/// million rupees. Show whichever figure you show with its own label.
///
/// Note also that the dashboard's period-scoped headline figures and these
/// receivable figures answer different questions — receivable is the whole
/// register, a headline is one billing month. Never mix them in one tile.
class Receivable {
  const Receivable({
    required this.owed,
    required this.arrearsPending,
    required this.notYetDue,
    required this.accountsInArrears,
    required this.accountsTotal,
    required this.recoveryPct,
  });

  final Money owed;
  final Money arrearsPending;
  final Money notYetDue;
  final int accountsInArrears;
  final int accountsTotal;
  final double? recoveryPct;

  static const Receivable empty = Receivable(
    owed: Money.zero,
    arrearsPending: Money.zero,
    notYetDue: Money.zero,
    accountsInArrears: 0,
    accountsTotal: 0,
    recoveryPct: null,
  );

  factory Receivable.fromJson(Map<String, dynamic>? json) {
    if (json == null) return empty;
    return Receivable(
      owed: json.money('owed'),
      arrearsPending: json.money('arrears_pending'),
      notYetDue: json.money('not_yet_due'),
      accountsInArrears: json.intOr('accounts_in_arrears'),
      accountsTotal: json.intOr('accounts_total'),
      recoveryPct: json.percent('recovery_pct'),
    );
  }
}

/// `data.never_paid` — accounts that have paid *nothing*.
///
/// A different problem from "behind": an allottee who pays late needs a
/// reminder, one who has never paid needs a visit.
class NeverPaid {
  const NeverPaid({
    required this.accounts,
    required this.amount,
    required this.sharePct,
  });

  final int accounts;
  final Money amount;
  final double? sharePct;

  static const NeverPaid empty =
      NeverPaid(accounts: 0, amount: Money.zero, sharePct: null);

  factory NeverPaid.fromJson(Map<String, dynamic>? json) {
    if (json == null) return empty;
    return NeverPaid(
      accounts: json.intOr('accounts'),
      amount: json.money('amount'),
      sharePct: json.percent('share_pct'),
    );
  }
}

/// One tile in `data.attention[]` — a work queue.
///
/// Filter each by its own [permission] before showing it; a tile the
/// officer cannot open is an affordance that leads to a 403.
class AttentionQueue {
  const AttentionQueue({
    required this.key,
    required this.label,
    required this.count,
    required this.amount,
    required this.permission,
    this.tone,
  });

  final String key;
  final String label;
  final int count;
  final Money amount;
  final String? permission;
  final String? tone;

  factory AttentionQueue.fromJson(Map<String, dynamic> json) => AttentionQueue(
        key: json.strOr('key'),
        // The server labels its own queues; fall back to the key rather
        // than inventing a translated string that would drift.
        label: json.str('label') ?? json.strOr('title', ''),
        count: json.intOr('count'),
        amount: json.money('amount'),
        permission: json.str('permission'),
        tone: json.str('tone'),
      );

  String get display => label.isNotEmpty ? label : key;
}

/// One row of `data.areas[]` — per-area recovery.
class AreaRecovery {
  const AreaRecovery({
    required this.areaName,
    required this.owed,
    this.areaId,
    this.recoveryPct,
    this.accounts,
  });

  final String areaName;
  final Money owed;
  final int? areaId;
  final double? recoveryPct;
  final int? accounts;

  factory AreaRecovery.fromJson(Map<String, dynamic> json) => AreaRecovery(
        areaName: json.str('area_name') ?? json.strOr('name'),
        owed: json.moneyOrNull('owed') ??
            json.moneyOrNull('outstanding') ??
            Money.zero,
        areaId: json.integer('area_id') ?? json.integer('id'),
        recoveryPct: json.percent('recovery_pct'),
        accounts: json.integer('accounts'),
      );
}

/// One row of `data.defaulters[]` — the dashboard's top ten. The working
/// list is the full register; see `DefaulterRow`.
class DashboardDefaulter {
  const DashboardDefaulter({
    required this.allotmentId,
    required this.propertyId,
    required this.propertyCode,
    required this.shopNo,
    required this.areaName,
    required this.allotteeName,
    required this.outstanding,
    required this.monthsBehind,
    required this.neverPaid,
    this.mobileNo,
    this.lastPaymentDate,
  });

  final int allotmentId;
  final int propertyId;
  final String propertyCode;
  final String shopNo;
  final String areaName;
  final String allotteeName;
  final Money outstanding;

  /// The triage signal — measured from the last payment, or from the first
  /// challan raised for an account that has never paid.
  final int monthsBehind;

  /// `true` is a different problem, not a worse degree of the same one.
  /// Distinguish it in words, not by colour alone: this app is used in
  /// bright sunlight by people who may be colour-blind.
  final bool neverPaid;

  final String? mobileNo;
  final DateTime? lastPaymentDate;

  factory DashboardDefaulter.fromJson(Map<String, dynamic> json) =>
      DashboardDefaulter(
        allotmentId: json.intOr('allotment_id'),
        propertyId: json.intOr('property_id'),
        propertyCode: json.strOr('property_code'),
        shopNo: json.strOr('shop_no'),
        areaName: json.strOr('area_name'),
        allotteeName: json.strOr('allottee_name'),
        outstanding: json.money('outstanding'),
        monthsBehind: json.intOr('months_behind'),
        neverPaid: json.boolean('never_paid'),
        mobileNo: json.str('mobile_no'),
        lastPaymentDate: json.date('last_payment_date'),
      );

  bool get isCallable => (mobileNo ?? '').trim().isNotEmpty;
}

/// `GET /reporting/dashboard` — the field officer's home.
class DashboardSummary {
  const DashboardSummary({
    required this.scope,
    required this.receivable,
    required this.neverPaid,
    required this.defaulters,
    required this.attention,
    required this.areas,
  });

  final AreaScope scope;
  final Receivable receivable;
  final NeverPaid neverPaid;
  final List<DashboardDefaulter> defaulters;
  final List<AttentionQueue> attention;
  final List<AreaRecovery> areas;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      DashboardSummary(
        scope: AreaScope.fromJson(json.child('scope')),
        receivable: Receivable.fromJson(json.child('receivable')),
        neverPaid: NeverPaid.fromJson(json.child('never_paid')),
        defaulters:
            json.children('defaulters').map(DashboardDefaulter.fromJson).toList(),
        attention:
            json.children('attention').map(AttentionQueue.fromJson).toList(),
        areas: json.children('areas').map(AreaRecovery.fromJson).toList(),
      );

  /// Work queues the officer actually holds the permission for.
  List<AttentionQueue> queuesFor(bool Function(String permission) can) =>
      attention
          .where((queue) =>
              queue.permission == null || can(queue.permission!))
          .toList();
}
