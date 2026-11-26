import '../core/utils/json_parse.dart';
import 'api_refs.dart';

/// `GET allotment/intakes/dashboard`. Every figure counts cases, and every
/// tile carries the list `scope` that opens exactly the cases it counted.
class AgreementDashboard {
  const AgreementDashboard({
    this.waitingTotal = 0,
    this.waitingScope = IntakeScope.awaitingMe,
    this.queues = const <IntakeTile>[],
    this.returnedByMe,
    this.myActions = const <IntakeTile>[],
    this.register,
    this.generatedAt,
  });

  /// Waiting for this officer now — ignores the dates.
  final int waitingTotal;
  final String waitingScope;

  /// The same, split by the queues this officer works.
  final List<IntakeTile> queues;

  /// Cases whose latest act is this officer's return or query.
  final IntakeTile? returnedByMe;

  /// What this officer did, bounded by the day of the act.
  final List<IntakeTile> myActions;

  /// Every case the officer may list, bounded by the day of last submission.
  final IntakeRegister? register;
  final DateTime? generatedAt;

  factory AgreementDashboard.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> waiting = Json.map(json['waiting']);
    final Object? returned = json['returned_by_me'];
    return AgreementDashboard(
      waitingTotal: _count(Json.pick(waiting, <String>['total', 'count'])),
      waitingScope: Json.stringOr(waiting['scope'], IntakeScope.awaitingMe),
      queues: Json.list(waiting['queues'])
          .map(
            (Map<String, dynamic> q) => IntakeTile.fromJson(
              q,
              keyField: 'key',
              defaultScope: Json.string(q['key']),
            ),
          )
          .toList(),
      returnedByMe: returned == null
          ? null
          : IntakeTile(
              key: IntakeScope.returnedByMe,
              count: _count(returned),
              scope: returned is Map
                  ? Json.stringOr(returned['scope'], IntakeScope.returnedByMe)
                  : IntakeScope.returnedByMe,
            ),
      myActions: Json.list(json['my_actions'])
          .map(
            (Map<String, dynamic> a) => IntakeTile.fromJson(
              a,
              keyField: 'action',
              countField: 'cases',
              defaultScope: 'acted:${Json.stringOr(a['action'])}',
            ),
          )
          .toList(),
      register: json['register'] is Map
          ? IntakeRegister.fromJson(Json.map(json['register']))
          : null,
      generatedAt: Json.dateTime(
        Json.pick(json, <String>['generated_at', 'as_of']),
      ),
    );
  }

  /// The register's cancelled cases — a reviewer cannot cancel, so this is
  /// not one of [myActions]. Zero, opening that list, when not sent.
  IntakeTile get cancelled =>
      register?.byStatus
          .where((IntakeTile t) => t.status == 'cancelled')
          .firstOrNull ??
      IntakeTile(
        key: 'cancelled',
        count: 0,
        scope: register?.scope ?? IntakeScope.all,
        status: 'cancelled',
      );

  /// "Nothing is waiting for you" — every figure that is about now is nought.
  bool get nothingWaiting =>
      waitingTotal == 0 && (returnedByMe?.count ?? 0) == 0;
}

/// One tile: a count, and the list that answers it.
class IntakeTile {
  const IntakeTile({
    required this.key,
    required this.count,
    required this.scope,
    this.label,
    this.acts,
    this.status,
  });

  /// The queue key or the action, e.g. `review`, `endorsed`.
  final String key;

  /// Distinct cases.
  final int count;
  final String scope;
  final String? label;

  /// Times the act was taken — `my_actions` only.
  final int? acts;

  /// The status filter a register tile adds to its scope.
  final String? status;

  factory IntakeTile.fromJson(
    Map<String, dynamic> json, {
    required String keyField,
    String countField = 'count',
    String? defaultScope,
  }) {
    final LabelledValue? key = LabelledValue.maybe(json[keyField]);
    return IntakeTile(
      key: key?.value ?? '',
      label:
          Json.string(json['label']) ??
          (key != null && key.label != key.value ? key.label : null),
      count: _count(Json.pick(json, <String>[countField, 'count'])),
      acts: Json.integer(json['acts']),
      scope: Json.stringOr(json['scope'], defaultScope ?? IntakeScope.all),
    );
  }

  bool get isEmpty => count == 0;
}

class IntakeRegister {
  const IntakeRegister({
    this.byStatus = const <IntakeTile>[],
    this.inProgress = 0,
    this.activatedCases = 0,
    this.agreementsLive = 0,
    this.scope = IntakeScope.all,
  });

  /// Every status, zeroes included.
  final List<IntakeTile> byStatus;
  final int inProgress;
  final int activatedCases;

  /// Activated cases whose agreement is still active or suspended.
  final int agreementsLive;
  final String scope;

  factory IntakeRegister.fromJson(Map<String, dynamic> json) {
    final String scope = Json.stringOr(json['scope'], IntakeScope.all);
    return IntakeRegister(
      scope: scope,
      byStatus: Json.list(json['by_status']).map((Map<String, dynamic> row) {
        final LabelledValue? status = LabelledValue.maybe(row['status']);
        return IntakeTile(
          key: status?.value ?? '',
          // A bare status string carries no label of its own.
          label: status != null && status.label != status.value
              ? status.label
              : null,
          count: _count(row['count']),
          scope: Json.stringOr(row['scope'], scope),
          status: status?.value,
        );
      }).toList(),
      inProgress: _count(json['in_progress']),
      activatedCases: _count(json['activated_cases']),
      agreementsLive: _count(json['agreements_live']),
    );
  }

  int get total =>
      byStatus.fold<int>(0, (int sum, IntakeTile t) => sum + t.count);
}

/// The `scope` values the list publishes.
class IntakeScope {
  IntakeScope._();

  static const String awaitingMe = 'awaiting_me';
  static const String returnedByMe = 'returned_by_me';
  static const String decidedByMe = 'decided_by_me';
  static const String history = 'history';
  static const String all = 'all';

  /// Waiting queues — the list ignores `from`/`to` for these.
  static const Set<String> undated = <String>{
    awaitingMe,
    'review',
    'queries',
    'dispatch',
    'decision',
    'execution_handoff',
    returnedByMe,
  };

  static bool isDated(String scope) => !undated.contains(scope);
}

/// A figure sent bare or as `{count, scope}`.
int _count(Object? source) =>
    source is Map ? Json.integerOr(source['count']) : Json.integerOr(source);
