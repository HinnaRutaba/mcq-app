import '../core/utils/json_parse.dart';

/// The whole home screen in one payload: who the officer is, which bazaars
/// they are posted to, and the work queues waiting for them.
class FieldBeat {
  const FieldBeat({
    required this.officer,
    required this.scope,
    required this.queues,
    this.generatedAt,
  });

  final FieldOfficer officer;

  /// Which bazaars the figures cover. Show [FieldScope.areaNames] on the
  /// screen — without it a reader assumes the totals are city-wide.
  final FieldScope scope;

  final List<FieldQueue> queues;

  /// When the server built these figures.
  final DateTime? generatedAt;

  factory FieldBeat.fromJson(Map<String, dynamic> json) => FieldBeat(
    officer: FieldOfficer.fromJson(Json.map(json['officer'])),
    scope: FieldScope.fromJson(Json.map(json['scope'])),
    queues: Json.list(json['queues']).map(FieldQueue.fromJson).toList(),
    generatedAt: Json.dateTime(json['generated_at']),
  );

  /// The queue with this key, or null when the server did not send it.
  FieldQueue? queue(String key) {
    for (final queue in queues) {
      if (queue.key == key) return queue;
    }
    return null;
  }
}

class FieldOfficer {
  const FieldOfficer({
    this.id,
    required this.name,
    this.designation,
    this.mobileNo,
  });

  final int? id;
  final String name;
  final String? designation;
  final String? mobileNo;

  factory FieldOfficer.fromJson(Map<String, dynamic> json) => FieldOfficer(
    id: Json.integer(json['id']),
    name: Json.stringOr(json['name']),
    designation: Json.string(json['designation']),
    mobileNo: Json.string(json['mobile_no']),
  );
}

/// The bazaars this officer may see. The server enforces the restriction; this
/// is here so the app can say out loud what the figures cover.
class FieldScope {
  const FieldScope({
    this.restricted = true,
    this.areas = const <FieldArea>[],
    this.areaNames = const <String>[],
    this.zoneNames = const <String>[],
  });

  /// False only for an officer who can see the whole city.
  final bool restricted;

  final List<FieldArea> areas;

  /// The bazaar names, ready to print, e.g. "Jinnah Road, Prince Road".
  final List<String> areaNames;

  final List<String> zoneNames;

  factory FieldScope.fromJson(Map<String, dynamic> json) => FieldScope(
    restricted: Json.booleanOr(json['restricted'], true),
    areas: Json.list(json['areas']).map(FieldArea.fromJson).toList(),
    areaNames: Json.stringList(json['area_names']),
    zoneNames: Json.stringList(json['zone_names']),
  );
}

class FieldArea {
  const FieldArea({
    this.id,
    required this.areaName,
    this.areaCode,
    this.zoneId,
    this.zoneName,
  });

  final int? id;
  final String areaName;
  final String? areaCode;
  final int? zoneId;
  final String? zoneName;

  factory FieldArea.fromJson(Map<String, dynamic> json) => FieldArea(
    id: Json.integer(json['id']),
    areaName: Json.stringOr(json['area_name']),
    areaCode: Json.string(json['area_code']),
    zoneId: Json.integer(json['zone_id']),
    zoneName: Json.string(json['zone_name']),
  );
}

/// One work queue on the home screen.
///
/// [endpoint] is the list this tile opens, e.g.
/// `enforcement/field/seals?ready=1`. Route from it rather than matching [key]
/// against a hard-coded path — see `ApiPaths.resolve`.
class FieldQueue {
  const FieldQueue({
    required this.key,
    required this.count,
    required this.endpoint,
    this.amount,
    this.tone,
  });

  /// Server-defined. Known keys: `defaulters`, `follow_ups_due`,
  /// `awaiting_unseal`, `sealed_shops`, `open_cases`, `assigned_to_me`.
  final String key;

  final int count;

  /// The relative path this queue opens, without the `/api/v1` prefix.
  final String endpoint;

  /// Total owed across the queue, as a string. Null on the queues that are a
  /// count of work rather than a sum of money.
  final String? amount;

  /// `danger` | `warning` | `info` | `neutral` | `primary`.
  final String? tone;

  factory FieldQueue.fromJson(Map<String, dynamic> json) => FieldQueue(
    key: Json.stringOr(json['key']),
    count: Json.integerOr(json['count']),
    endpoint: Json.stringOr(json['endpoint']),
    amount: Json.money(json['amount']),
    tone: Json.string(json['tone']),
  );

  bool get isEmpty => count == 0;

  bool get hasAmount => amount != null;
}
