import '../../core/utils/json_reader.dart';
import '../common/api_enum.dart';
import '../common/can_flags.dart';
import '../common/entity_refs.dart';
import '../common/money.dart';

/// An enforcement case: a file opened against a property whose allottee is
/// behind.
class EnforcementCase {
  const EnforcementCase({
    required this.id,
    required this.caseNo,
    required this.status,
    required this.priority,
    required this.flags,
    required this.amounts,
    required this.unpaidMonths,
    required this.property,
    required this.allotment,
    required this.allottee,
    this.openedOn,
    this.closedOn,
    this.nextVisitDate,
    this.closingRemarks,
    this.sealId,
  });

  final int id;
  final String caseNo;
  final ApiEnum status;
  final ApiEnum priority;

  /// The server telling the app what is possible *right now*. Buttons are
  /// enabled from here, never from [status].
  final CanFlags flags;

  /// Kept keyed as the server sent it — every member is a [Money] string
  /// and none of them is ever added up on the device.
  final Map<String, Money> amounts;

  final int unpaidMonths;
  final PropertyRef property;
  final AllotmentRef allotment;
  final AllotteeRef allottee;
  final DateTime? openedOn;
  final DateTime? closedOn;

  /// Drives the local visit reminder — there is no server push.
  final DateTime? nextVisitDate;

  final String? closingRemarks;
  final int? sealId;

  factory EnforcementCase.fromJson(Map<String, dynamic> json) =>
      EnforcementCase(
        id: json.intOr('id'),
        caseNo: json.strOr('case_no'),
        status: json.apiEnum('status'),
        priority: json.apiEnum('priority'),
        flags: CanFlags.fromJson(json),
        amounts: (json.child('amounts') ?? const {}).moneyMap(),
        unpaidMonths: json.intOr('unpaid_months'),
        property: PropertyRef.fromJson(json.child('property')),
        allotment: AllotmentRef.fromJson(json.child('allotment')),
        allottee: AllotteeRef.fromJson(json.child('allottee')),
        openedOn: json.date('opened_on'),
        closedOn: json.date('closed_on'),
        nextVisitDate: json.date('next_visit_date'),
        closingRemarks: json.str('closing_remarks'),
        sealId: json.integer('seal_id') ?? json.child('seal')?.integer('id'),
      );

  /// The field officer's queue: sort by this.
  bool get visitOverdue => flags.visitOverdue;
  bool get isSealed => flags.isSealed;
  bool get isLive => flags.isLive;

  /// The headline amount, whichever key the server used for it. Displayed
  /// only — never combined with another figure.
  Money? get outstanding =>
      amounts['outstanding'] ?? amounts['owed'] ?? amounts['total'];
}

/// One entry on a case's timeline.
class CaseAction {
  const CaseAction({
    required this.id,
    required this.actionType,
    required this.actionDate,
    this.remarks,
    this.witnessName,
    this.photoPath,
    this.signaturePath,
    this.latitude,
    this.longitude,
    this.locationAccuracyM,
    this.recordedOffline = false,
    this.recordedBy,
    this.deviceRecordedAt,
    this.createdAt,
  });

  final int id;
  final ApiEnum actionType;
  final DateTime? actionDate;
  final String? remarks;
  final String? witnessName;
  final String? photoPath;
  final String? signaturePath;
  final double? latitude;
  final double? longitude;
  final double? locationAccuracyM;
  final bool recordedOffline;
  final String? recordedBy;
  final DateTime? deviceRecordedAt;
  final DateTime? createdAt;

  factory CaseAction.fromJson(Map<String, dynamic> json) => CaseAction(
        id: json.intOr('id'),
        actionType: json.apiEnum('action_type'),
        actionDate: json.date('action_date'),
        remarks: json.str('remarks'),
        witnessName: json.str('witness_name'),
        photoPath: json.str('photo_path'),
        signaturePath: json.str('signature_path'),
        latitude: json.percent('latitude'),
        longitude: json.percent('longitude'),
        locationAccuracyM: json.percent('location_accuracy_m'),
        recordedOffline: json.boolean('recorded_offline'),
        recordedBy: json.child('recorded_by')?.str('name') ??
            json.str('recorded_by_name'),
        deviceRecordedAt: json.date('device_recorded_at'),
        createdAt: json.date('created_at'),
      );

  bool get hasCoordinates => latitude != null && longitude != null;
  bool get hasPhoto => (photoPath ?? '').isNotEmpty;
}
