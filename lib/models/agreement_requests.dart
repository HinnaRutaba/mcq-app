import '../core/network/api_file.dart';
import '../core/utils/json_parse.dart';
import 'agreement_dashboard.dart';

/// One reading of `GET allotment/intakes`: a scope plus its filters.
///
/// A dashboard tile hands over its own scope and the dashboard's dates, so the
/// list it opens counts the same cases the tile did.
class IntakeListQuery {
  const IntakeListQuery({
    required this.scope,
    required this.label,
    this.status,
    this.from,
    this.to,
  });

  final String scope;

  /// What the chip over the list says.
  final String label;
  final String? status;
  final DateTime? from;
  final DateTime? to;

  static const IntakeListQuery awaitingMe = IntakeListQuery(
    scope: IntakeScope.awaitingMe,
    label: 'Waiting',
  );
  static const IntakeListQuery returnedByMe = IntakeListQuery(
    scope: IntakeScope.returnedByMe,
    label: 'Returned',
  );
  static const IntakeListQuery decidedByMe = IntakeListQuery(
    scope: IntakeScope.decidedByMe,
    label: 'Decided',
  );
  static const IntakeListQuery all = IntakeListQuery(
    scope: IntakeScope.all,
    label: 'All',
  );

  /// The tabs the list always offers.
  static const List<IntakeListQuery> standard = <IntakeListQuery>[
    awaitingMe,
    returnedByMe,
    decidedByMe,
    all,
  ];

  bool get isStandard => standard.contains(this);

  Map<String, dynamic> toQuery({String? search, int? page, int? perPage}) =>
      <String, dynamic>{
        'scope': scope,
        'status': status,
        // The server ignores dates on a waiting queue; not sending them keeps
        // the request honest about what it asks.
        if (IntakeScope.isDated(scope)) 'from': Json.dateOnly(from),
        if (IntakeScope.isDated(scope)) 'to': Json.dateOnly(to),
        if (search != null && search.trim().isNotEmpty) 'q': search.trim(),
        'page': page,
        'per_page': perPage,
      };

  @override
  bool operator ==(Object other) =>
      other is IntakeListQuery &&
      other.scope == scope &&
      other.status == status &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(scope, status, from, to);
}

/// The body of a review act. Built once per tap and re-sent as-is on retry:
/// the same [clientUuid] is what makes a retried act land once.
class IntakeDecisionRequest {
  const IntakeDecisionRequest({
    required this.clientUuid,
    this.lockVersion,
    this.remarks,
    this.destination,
    this.attachments = const <String>[],
  });

  final String clientUuid;

  /// From the case that was on screen. Another officer acting in between is
  /// `409 intake.changed_since_viewed`.
  final int? lockVersion;
  final String? remarks;

  /// `estate`, `taxation`, `cmo` — return only, from the act's destinations.
  final String? destination;

  /// Local paths. Up to [maxAttachments]; PDF, JPEG, PNG, WebP; 12 MB each.
  final List<String> attachments;

  static const int maxAttachments = 5;
  static const int remarksMin = 10;
  static const int remarksMax = 2000;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'client_uuid': clientUuid,
    'lock_version': lockVersion,
    'remarks': remarks,
    'destination': destination,
  };

  List<ApiFile> get files => <ApiFile>[
    for (final String path in attachments)
      ApiFile(path: path, field: 'attachments[]'),
  ];
}
