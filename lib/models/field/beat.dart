import '../../core/utils/json_reader.dart';
import '../common/money.dart';

/// `GET /enforcement/field/beat` — the whole home screen in one request.
///
/// This endpoint was built for this handset. It carries who the officer is,
/// where he is posted, and the six queues of work he holds, so the home
/// screen makes one call rather than five on a weak bazaar signal.
class FieldBeat {
  const FieldBeat({
    required this.officer,
    required this.scope,
    required this.queues,
    this.generatedAt,
  });

  final BeatOfficer officer;
  final BeatScope scope;
  final List<BeatQueue> queues;

  /// When the server built this. Shown beside a cached copy so a figure
  /// from this morning never looks live.
  final DateTime? generatedAt;

  static const FieldBeat empty = FieldBeat(
    officer: BeatOfficer.unknown,
    scope: BeatScope.unknown,
    queues: [],
  );

  factory FieldBeat.fromJson(Map<String, dynamic> json) => FieldBeat(
        officer: BeatOfficer.fromJson(json.child('officer')),
        scope: BeatScope.fromJson(json.child('scope')),
        queues: json.children('queues').map(BeatQueue.fromJson).toList(),
        generatedAt: json.date('generated_at'),
      );

  BeatQueue? queue(String key) {
    for (final entry in queues) {
      if (entry.key == key) return entry;
    }
    return null;
  }
}

/// The officer, as the beat reports him. Not the same object as the session
/// user — this one carries the designation MCQ wants printed under his name.
class BeatOfficer {
  const BeatOfficer({
    required this.id,
    required this.name,
    this.designation,
    this.mobileNo,
  });

  final String id;
  final String name;
  final String? designation;
  final String? mobileNo;

  static const BeatOfficer unknown = BeatOfficer(id: '', name: '');

  factory BeatOfficer.fromJson(Map<String, dynamic>? json) {
    if (json == null) return unknown;
    return BeatOfficer(
      // The server sends this as a string on this endpoint and an int on
      // others. Kept as text because nothing here does arithmetic on it.
      id: json.strOr('id'),
      name: json.strOr('name'),
      designation: json.str('designation'),
      mobileNo: json.str('mobile_no'),
    );
  }
}

/// One of the officer's areas, with the zone above it.
class BeatArea {
  const BeatArea({
    required this.id,
    required this.areaName,
    this.areaCode,
    this.zoneId,
    this.zoneName,
  });

  final int id;
  final String areaName;
  final String? areaCode;
  final int? zoneId;
  final String? zoneName;

  factory BeatArea.fromJson(Map<String, dynamic> json) => BeatArea(
        id: json.intOr('id'),
        areaName: json.strOr('area_name'),
        areaCode: json.str('area_code'),
        zoneId: json.integer('zone_id'),
        zoneName: json.str('zone_name'),
      );
}

/// Where the officer is posted.
///
/// Area scoping is enforced inside a database view, so no request can widen
/// it — but the app must **display** the fact on every screen of figures.
/// An officer reading his beat's arrears as the city's makes decisions on a
/// fraction of the register. MCQ asked for this specifically.
class BeatScope {
  const BeatScope({
    required this.restricted,
    required this.areas,
    required this.areaNames,
    required this.zoneNames,
  });

  final bool restricted;
  final List<BeatArea> areas;
  final List<String> areaNames;
  final List<String> zoneNames;

  static const BeatScope unknown =
      BeatScope(restricted: true, areas: [], areaNames: [], zoneNames: []);

  factory BeatScope.fromJson(Map<String, dynamic>? json) {
    if (json == null) return unknown;
    final areas = json.children('areas').map(BeatArea.fromJson).toList();
    final names = json.strings('area_names');
    return BeatScope(
      restricted: json.boolean('restricted', fallback: true),
      areas: areas,
      // `area_names` is the authority; fall back to the objects so a
      // trimmed payload still prints where the officer is posted.
      areaNames:
          names.isNotEmpty ? names : [for (final area in areas) area.areaName],
      zoneNames: json.strings('zone_names'),
    );
  }

  /// An officer with no posting sees nothing, correctly. That is an
  /// explanation to put on screen, not an empty list.
  bool get hasPosting => areaNames.isNotEmpty;
}

/// One tile on the home screen.
///
/// **No number on that dashboard may be a dead end.** The server hands the
/// route over in [endpoint]; the app opens the list behind it rather than
/// hard-coding a path, so a queue MCQ adds later needs no release.
class BeatQueue {
  const BeatQueue({
    required this.key,
    required this.count,
    required this.endpoint,
    required this.tone,
    this.amount,
  });

  /// `defaulters`, `follow_ups_due`, `awaiting_unseal`, `sealed_shops`,
  /// `open_cases`, `assigned_to_me`. Never rendered raw — the app carries
  /// a plain-language label for each.
  final String key;

  final int count;

  /// **Null means this queue is not measured in money**, and null renders
  /// as nothing at all. `0.00` would say "nothing is at stake" where the
  /// truth is "rupees are not the unit".
  final Money? amount;

  /// Relative to `/api/v1`, e.g. `enforcement/field/defaulters` or
  /// `enforcement/cases?magistrate_id=me`.
  final String endpoint;

  /// `danger | warning | info | neutral | primary`.
  final String tone;

  factory BeatQueue.fromJson(Map<String, dynamic> json) => BeatQueue(
        key: json.strOr('key'),
        count: json.intOr('count'),
        amount: json.moneyOrNull('amount'),
        endpoint: json.strOr('endpoint'),
        tone: json.strOr('tone', 'neutral'),
      );

  /// A zero queue is good news and has to look like it. A tile that stays
  /// red at zero teaches the officer that the colours mean nothing.
  bool get isClear => count == 0;
}
