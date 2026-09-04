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
///
/// Shared with the licensing beat, which sends the same block with fewer keys:
/// [areaNames] and [zoneNames] are derived from [areas] when the server does
/// not send them separately, so a screen can always print which bazaars it is
/// talking about.
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

  factory FieldScope.fromJson(Map<String, dynamic> json) {
    final areas = Json.list(json['areas']).map(FieldArea.fromJson).toList();
    final areaNames = Json.stringList(json['area_names']);
    final zoneNames = Json.stringList(json['zone_names']);
    return FieldScope(
      restricted: Json.booleanOr(json['restricted'], true),
      areas: areas,
      areaNames: areaNames.isEmpty ? _names(areas, _areaName) : areaNames,
      zoneNames: zoneNames.isEmpty ? _names(areas, _zoneName) : zoneNames,
    );
  }

  /// The bazaar names as one phrase, e.g. "Jinnah Road and Prince Road" — the
  /// line a screen puts under a figure so nobody reads it as city-wide.
  String get areaSentence => _sentence(areaNames);

  String get zoneSentence => _sentence(zoneNames);

  bool get hasAreas => areas.isNotEmpty || areaNames.isNotEmpty;

  static String? _areaName(FieldArea area) =>
      area.areaName.isEmpty ? null : area.areaName;

  static String? _zoneName(FieldArea area) => area.zoneName;

  /// Distinct, in the order the server listed them — several bazaars share a
  /// zone, and repeating its name reads as a mistake.
  static List<String> _names(
    List<FieldArea> areas,
    String? Function(FieldArea area) of,
  ) {
    final names = <String>[];
    for (final area in areas) {
      final name = of(area);
      if (name != null && !names.contains(name)) names.add(name);
    }
    return names;
  }

  static String _sentence(List<String> names) => switch (names.length) {
    0 => '',
    1 => names.first,
    _ => '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}',
  };
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

  /// Read from the beat's `scope` and from `GET enforcement/definitions`,
  /// which name the same bazaar with and without the `area_` prefix.
  factory FieldArea.fromJson(Map<String, dynamic> json) => FieldArea(
    id: Json.integer(json['id']),
    areaName: Json.stringOr(Json.pick(json, <String>['area_name', 'name'])),
    areaCode: Json.string(Json.pick(json, <String>['area_code', 'code'])),
    zoneId: Json.integer(json['zone_id']),
    zoneName: Json.string(json['zone_name']),
  );
}

/// One work queue on a home screen — enforcement's or licensing's.
///
/// [endpoint] is the list this tile opens, e.g.
/// `enforcement/field/seals?ready=1`. Route from it rather than matching [key]
/// against a hard-coded path — see `ApiPaths.resolve`, which reads both the
/// relative form the enforcement beat sends and the absolute one the licensing
/// beat sends.
class FieldQueue {
  const FieldQueue({
    required this.key,
    required this.count,
    required this.endpoint,
    this.amount,
    this.tone,
    this.areaScoped,
  });

  /// Server-defined. Known keys: `defaulters`, `follow_ups_due`,
  /// `awaiting_unseal`, `sealed_shops`, `open_cases`, `assigned_to_me` on the
  /// enforcement beat; `expiring`, `lapsed`, `live` on the licensing one.
  final String key;

  final int count;

  /// The path this queue opens. Relative on the enforcement beat, absolute and
  /// already carrying `/api/v1` on the licensing beat.
  final String endpoint;

  /// Total owed across the queue, as a string. Null on the queues that are a
  /// count of work rather than a sum of money — which is all of the licensing
  /// ones.
  final String? amount;

  /// `danger` | `warning` | `info` | `neutral` | `primary`. Null on the
  /// licensing beat, which tones nothing.
  final String? tone;

  /// Whether the count covers the officer's bazaars only. Sent by the
  /// licensing beat; null on the enforcement beat, where the whole payload is
  /// area-scoped and saying so per queue would be noise.
  final bool? areaScoped;

  factory FieldQueue.fromJson(Map<String, dynamic> json) => FieldQueue(
    key: Json.stringOr(json['key']),
    count: Json.integerOr(json['count']),
    endpoint: Json.stringOr(json['endpoint']),
    amount: Json.money(json['amount']),
    tone: Json.string(json['tone']),
    areaScoped: Json.boolean(json['area_scoped']),
  );

  bool get isEmpty => count == 0;

  bool get hasAmount => amount != null;
}
