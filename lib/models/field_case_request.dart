import '../core/utils/json_parse.dart';

/// Opens an enforcement case from the handset.
///
/// There are two kinds, and the server refuses to guess between them: send
/// `allotment_id` for a **recovery** case (somebody is behind on rent) or
/// `property_id` for a case about **conduct** (what is happening at the unit).
/// Sending both is rejected rather than resolved, because either precedence
/// would open a different kind of case from the one the officer meant.
///
/// The two named constructors are why this class has no assertion: pick
/// [FieldCaseRequest.recovery] or [FieldCaseRequest.conduct] and the wrong
/// combination cannot be built.
class FieldCaseRequest {
  /// A case about arrears, opened against the tenancy that owes the money.
  ///
  /// The server derives [priority] from what is owed here, so leaving it null
  /// is usually right — an officer's guess is a worse signal than the ledger.
  const FieldCaseRequest.recovery({
    required int this.allotmentId,
    this.caseReason,
    this.caseType,
    this.priority,
    this.magistrateId,
    this.nextVisitDate,
    this.billingPeriodId,
    this.triggerChallanId,
  }) : propertyId = null;

  /// A case about what is happening at a unit — trading outside the
  /// agreement, a broken seal, an encroachment. Opened against the unit
  /// itself, because the conduct is the unit's whether or not rent is owed.
  const FieldCaseRequest.conduct({
    required int this.propertyId,
    required String this.caseType,
    this.caseReason,
    this.priority,
    this.magistrateId,
    this.nextVisitDate,
    this.billingPeriodId,
    this.triggerChallanId,
  }) : allotmentId = null;

  /// The tenancy in arrears. Set on a recovery case only.
  final int? allotmentId;

  /// The unit. Set on a conduct case only.
  final int? propertyId;

  /// What the case is about, e.g. `unauthorised_use`. Drawn from the same
  /// vocabulary as a fine — `EnforcementDefinitions.fineTypes` codes — so read
  /// it from `definitions` rather than hardcoding a picker.
  final String? caseType;

  /// The officer's own words on why the case is being opened, e.g. "Trading in
  /// goods the agreement does not permit."
  final String? caseReason;

  /// `low` | `normal` | `high` | `critical`, from
  /// `EnforcementDefinitions.casePriorities`. Derived by the server on a
  /// recovery case.
  final String? priority;

  /// The magistrate to assign it to. Omit to leave the taxation branch's own
  /// assignment alone.
  final int? magistrateId;

  /// A first visit to commit to. Today or later.
  final DateTime? nextVisitDate;

  /// The billing period the arrears sit in, when the case is opened off a
  /// specific month rather than a running balance.
  final int? billingPeriodId;

  /// The challan whose non-payment set this off, when there is one.
  final int? triggerChallanId;

  /// True for a case about conduct rather than arrears — the distinction the
  /// case list echoes back as `is_conduct_case`.
  bool get isConductCase => propertyId != null;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'allotment_id': allotmentId,
    'property_id': propertyId,
    'case_type': caseType,
    'case_reason': caseReason,
    'priority': priority,
    'magistrate_id': magistrateId,
    'next_visit_date': Json.dateOnly(nextVisitDate),
    'billing_period_id': billingPeriodId,
    'trigger_challan_id': triggerChallanId,
  };
}
