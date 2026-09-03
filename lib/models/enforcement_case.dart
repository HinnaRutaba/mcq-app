import '../core/utils/json_parse.dart';
import 'api_refs.dart';

/// An enforcement case: the file that runs from the first visit to a closed
/// matter, with the visit timeline hanging off it.
class EnforcementCase {
  const EnforcementCase({
    this.id,
    this.caseNo,
    this.status,
    this.priority,
    this.openedOn,
    this.closedOn,
    this.nextVisitDate,
    required this.amounts,
    required this.position,
    this.unpaidMonths,
    this.closingRemarks,
    this.isLive = false,
    this.isSealed = false,
    this.visitOverdue = false,
    this.canSeal = false,
    this.canClose = false,
    this.property,
    this.allotment,
    this.allottee,
    this.offender,
    this.isConductCase = false,
    this.area,
    this.magistrate,
    this.isAssigned = false,
    this.actionCount = 0,
    this.fineCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;

  /// e.g. `MCQ-EC-2627-00011`.
  final String? caseNo;

  /// e.g. "Warned".
  final LabelledValue? status;

  /// e.g. "Normal".
  final LabelledValue? priority;

  final DateTime? openedOn;
  final DateTime? closedOn;

  /// The visit the officer has committed to next.
  final DateTime? nextVisitDate;

  final CaseAmounts amounts;

  /// Where the debt stands now against where it stood when the case opened —
  /// the point of the case, in one field.
  final CasePosition position;

  final int? unpaidMonths;
  final String? closingRemarks;

  final bool isLive;
  final bool isSealed;

  /// The committed next visit has passed without one being recorded.
  final bool visitOverdue;

  /// Whether the server will accept a seal on this case. Respect it rather
  /// than deciding locally — sealing has preconditions the app cannot see.
  final bool canSeal;

  final bool canClose;

  final PropertyRef? property;
  final AllotmentRef? allotment;
  final AllotteeRef? allottee;

  /// Somebody the case names who is not on the register. Set instead of
  /// [allottee] on a case about conduct at a unit MCQ has not let.
  final OffenderRef? offender;

  /// Whether this case is about what is happening at the unit rather than
  /// about arrears. Recovery cases are opened against a tenancy, conduct cases
  /// against the unit — see `FieldCaseRequest`.
  final bool isConductCase;

  final AreaRef? area;

  /// The magistrate the taxation branch assigned.
  final UserRef? magistrate;

  final bool isAssigned;

  /// How many actions are on the timeline, so a list row can say so without
  /// fetching it.
  final int actionCount;

  final int fineCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory EnforcementCase.fromJson(Map<String, dynamic> json) =>
      EnforcementCase(
        id: Json.integer(json['id']),
        caseNo: Json.string(json['case_no']),
        status: LabelledValue.maybe(json['status']),
        priority: LabelledValue.maybe(json['priority']),
        openedOn: Json.dateTime(json['opened_on']),
        closedOn: Json.dateTime(json['closed_on']),
        nextVisitDate: Json.dateTime(json['next_visit_date']),
        amounts: CaseAmounts.fromJson(Json.map(json['amounts'])),
        position: CasePosition.fromJson(Json.map(json['position'])),
        unpaidMonths: Json.integer(json['unpaid_months']),
        closingRemarks: Json.string(json['closing_remarks']),
        isLive: Json.booleanOr(json['is_live']),
        isSealed: Json.booleanOr(json['is_sealed']),
        visitOverdue: Json.booleanOr(json['visit_overdue']),
        canSeal: Json.booleanOr(json['can_seal']),
        canClose: Json.booleanOr(json['can_close']),
        property: PropertyRef.maybe(json['property']),
        allotment: AllotmentRef.maybe(json['allotment']),
        allottee: AllotteeRef.maybe(json['allottee']),
        offender: OffenderRef.maybe(json['offender']),
        isConductCase: Json.booleanOr(json['is_conduct_case']),
        area: AreaRef.maybe(json['area']),
        magistrate: UserRef.maybe(json['magistrate']),
        isAssigned: Json.booleanOr(json['is_assigned']),
        actionCount: Json.integerOr(json['action_count']),
        fineCount: Json.integerOr(json['fine_count']),
        createdAt: Json.dateTime(json['created_at']),
        updatedAt: Json.dateTime(json['updated_at']),
      );
}

class CaseAmounts {
  const CaseAmounts({this.outstandingAtOpen});

  /// What was owed the day the case was opened, as a string.
  final String? outstandingAtOpen;

  factory CaseAmounts.fromJson(Map<String, dynamic> json) =>
      CaseAmounts(outstandingAtOpen: Json.money(json['outstanding_at_open']));
}

/// The debt now, and which way it has moved since the case opened.
class CasePosition {
  const CasePosition({this.outstandingNow, this.direction});

  final String? outstandingNow;

  /// The server's own reading: `level`, and the directions it uses for a debt
  /// that has grown or shrunk. Never computed in the app — that would mean
  /// subtracting two money strings.
  final String? direction;

  factory CasePosition.fromJson(Map<String, dynamic> json) => CasePosition(
    outstandingNow: Json.money(json['outstanding_now']),
    direction: Json.string(json['direction']),
  );
}
