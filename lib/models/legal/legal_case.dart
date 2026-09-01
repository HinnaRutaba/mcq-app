import '../../core/utils/json_reader.dart';
import '../common/api_enum.dart';
import '../common/entity_refs.dart';

/// A court case. Read-only for a magistrate — the Legal branch maintains
/// these records.
class LegalCase {
  const LegalCase({
    required this.id,
    required this.caseNo,
    required this.status,
    required this.property,
    this.court,
    this.subject,
    this.filedOn,
    this.nextHearingDate,
    this.hasLiveStay = false,
  });

  final int id;
  final String caseNo;
  final ApiEnum status;
  final PropertyRef property;
  final String? court;
  final String? subject;
  final DateTime? filedOn;
  final DateTime? nextHearingDate;

  /// A stay order stops enforcement on that property.
  final bool hasLiveStay;

  factory LegalCase.fromJson(Map<String, dynamic> json) => LegalCase(
        id: json.intOr('id'),
        caseNo: json.strOr('case_no'),
        status: json.apiEnum('status'),
        property: PropertyRef.fromJson(json.child('property')),
        court: json.str('court') ?? json.str('court_name'),
        subject: json.str('subject') ?? json.str('title'),
        filedOn: json.date('filed_on'),
        nextHearingDate: json.date('next_hearing_date'),
        hasLiveStay: json.boolean('has_live_stay') ||
            json.boolean('stay_order_active') ||
            json.boolean('is_stayed'),
      );
}

/// One hearing on a court case.
class Hearing {
  const Hearing({
    required this.id,
    required this.hearingDate,
    this.purpose,
    this.outcome,
    this.status = ApiEnum.unknown,
    this.caseNo,
  });

  final int id;
  final DateTime? hearingDate;
  final String? purpose;
  final String? outcome;
  final ApiEnum status;
  final String? caseNo;

  factory Hearing.fromJson(Map<String, dynamic> json) => Hearing(
        id: json.intOr('id'),
        hearingDate: json.date('hearing_date') ?? json.date('scheduled_on'),
        purpose: json.str('purpose'),
        outcome: json.str('outcome'),
        status: json.apiEnum('status'),
        caseNo: json.str('case_no') ?? json.child('case')?.str('case_no'),
      );
}
