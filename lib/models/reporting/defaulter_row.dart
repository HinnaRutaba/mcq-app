import '../../core/utils/json_reader.dart';
import '../common/money.dart';
import 'area_scope.dart';

/// One row of `GET /reporting/reports/defaulters` — the working list, and
/// the screen the app is built around.
///
/// The endpoint returns the officer's whole scoped set with totals rather
/// than a page (tens of rows for a magistrate), so sorting and filtering
/// happen on the device.
class DefaulterRow {
  const DefaulterRow({
    required this.propertyId,
    required this.propertyCode,
    required this.shopNo,
    required this.areaName,
    required this.allotteeName,
    required this.monthlyRent,
    required this.currentDue,
    required this.arrearsDue,
    required this.surchargeDue,
    required this.outstanding,
    required this.unpaidMonths,
    required this.sealed,
    this.marketName,
    this.mobileNo,
    this.allotmentNo,
    this.allotmentId,
    this.caseId,
    this.lastPaymentDate,
  });

  final int propertyId;
  final String propertyCode;
  final String shopNo;
  final String areaName;
  final String allotteeName;
  final Money monthlyRent;

  /// [currentDue], [arrearsDue] and [surchargeDue] decompose
  /// [outstanding]. Show the parts, not just the total: an allottee who
  /// owes one month's rent and one whose debt is mostly accumulated
  /// surcharge need different conversations, and the total hides which is
  /// which.
  final Money currentDue;
  final Money arrearsDue;
  final Money surchargeDue;
  final Money outstanding;

  final int unpaidMonths;

  /// The shop is already closed. Show it, and do not offer to seal it again.
  final bool sealed;

  final String? marketName;
  final String? mobileNo;
  final String? allotmentNo;
  final int? allotmentId;
  final int? caseId;
  final DateTime? lastPaymentDate;

  factory DefaulterRow.fromJson(Map<String, dynamic> json) => DefaulterRow(
        propertyId: json.intOr('property_id'),
        propertyCode: json.strOr('property_code'),
        shopNo: json.strOr('shop_no'),
        areaName: json.strOr('area_name'),
        allotteeName: json.strOr('allottee_name'),
        monthlyRent: json.money('monthly_rent'),
        currentDue: json.money('current_due'),
        arrearsDue: json.money('arrears_due'),
        surchargeDue: json.money('surcharge_due'),
        outstanding: json.money('outstanding'),
        unpaidMonths: json.intOr('unpaid_months'),
        sealed: json.boolean('sealed'),
        marketName: json.str('market_name'),
        mobileNo: json.str('mobile_no'),
        allotmentNo: json.str('allotment_no'),
        allotmentId: json.integer('allotment_id'),
        caseId: json.integer('enforcement_case_id') ?? json.integer('case_id'),
        lastPaymentDate: json.date('last_payment_date'),
      );

  bool get neverPaid => lastPaymentDate == null;
  bool get isCallable => (mobileNo ?? '').trim().isNotEmpty;

  /// `monthly_rent` against `outstanding` is the fastest read of how far
  /// gone an account is — twenty times the rent is a different problem
  /// from twice.
  ///
  /// This is a *ratio*, not an amount: it is derived from the two figures
  /// for ordering and for a "20× the rent" caption only, and no amount is
  /// ever computed from it. Amounts stay strings, always.
  double? get rentMultiple {
    final rent = double.tryParse(monthlyRent.raw);
    final owed = double.tryParse(outstanding.raw);
    if (rent == null || owed == null || rent <= 0) return null;
    return owed / rent;
  }

  /// Sort key for "largest owed". Same rule as [rentMultiple]: ordering
  /// only, never displayed as money.
  double get outstandingSortKey => double.tryParse(outstanding.raw) ?? 0;
}

/// The whole scoped register plus its server-computed totals.
class DefaultersReport {
  const DefaultersReport({
    required this.rows,
    required this.totalDefaulters,
    required this.totalOutstanding,
    required this.scope,
  });

  final List<DefaulterRow> rows;

  /// Both totals come from the server. Never add the rows up on the device.
  final int totalDefaulters;
  final Money totalOutstanding;

  final AreaScope scope;

  static const DefaultersReport empty = DefaultersReport(
    rows: [],
    totalDefaulters: 0,
    totalOutstanding: Money.zero,
    scope: AreaScope.unknown,
  );

  factory DefaultersReport.fromJson(Map<String, dynamic> json) {
    final totals = json.child('totals');
    return DefaultersReport(
      rows: json.children('rows').map(DefaulterRow.fromJson).toList(),
      totalDefaulters: totals?.intOr('defaulters') ?? 0,
      totalOutstanding: totals?.money('outstanding') ?? Money.zero,
      scope: AreaScope.fromJson(json.child('scope')),
    );
  }
}
