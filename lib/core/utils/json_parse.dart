/// Tolerant readers shared by every model in `lib/models`.
///
/// The MCQ API is not uniformly typed: the same conceptual field arrives as a
/// string on one endpoint and a number on another (`user.id` is `"5"`, a case's
/// `magistrate.id` is `5`), and the same concept is spelled differently across
/// resources (`area.code` on a challan, `area.area_code` on a case). Rather
/// than repeat that tolerance in every `fromJson`, models read through here —
/// so one malformed field yields `null` instead of throwing halfway down a
/// 55-row list.
///
/// **Money is never parsed.** [money] hands back the server's string
/// untouched; there is no `double` anywhere in the money path. Amounts are
/// ledger figures quoted to a shopkeeper at a counter, so a rounding error is
/// a wrong figure, not a rounding error.
class Json {
  Json._();

  static Map<String, dynamic> map(Object? value) => value is Map
      ? Map<String, dynamic>.from(value)
      : const <String, dynamic>{};

  static Map<String, dynamic>? mapOrNull(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;

  static List<Map<String, dynamic>> list(Object? value) => value is List
      ? value
            .whereType<Map>()
            .map((Map e) => Map<String, dynamic>.from(e))
            .toList()
      : const <Map<String, dynamic>>[];

  /// Non-empty strings only — the API sends `""` where it means "nothing".
  static String? string(Object? value) {
    if (value == null) return null;
    if (value is String) return value.trim().isEmpty ? null : value;
    return value.toString();
  }

  static String stringOr(Object? value, [String fallback = '']) =>
      string(value) ?? fallback;

  /// A ledger amount such as `"263100.00"`, kept as text end to end. Never
  /// call `double.parse` on the result and never add two of them together in
  /// Dart — a fine and a rent balance are separate debts.
  static String? money(Object? value) =>
      value is String ? value : value?.toString();

  static String moneyOr(Object? value, [String fallback = '0.00']) =>
      money(value) ?? fallback;

  static int? integer(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static int integerOr(Object? value, [int fallback = 0]) =>
      integer(value) ?? fallback;

  /// A measurement (GPS accuracy in metres, a coordinate) — not money.
  static double? decimal(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static bool? boolean(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      switch (value.trim().toLowerCase()) {
        case 'true':
        case '1':
          return true;
        case 'false':
        case '0':
          return false;
      }
    }
    return null;
  }

  static bool booleanOr(Object? value, [bool fallback = false]) =>
      boolean(value) ?? fallback;

  /// Reads `2026-08-31` and `2026-08-31T23:48:34+00:00` alike.
  static DateTime? dateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is! String) return null;
    final raw = value.trim();
    return raw.isEmpty ? null : DateTime.tryParse(raw);
  }

  static List<String> stringList(Object? value) => value is List
      ? value.map(string).whereType<String>().toList()
      : const <String>[];

  /// A keyed tally such as the beat activity's `by_action_type`, where the keys
  /// are server-defined and new ones may appear without an app release.
  static Map<String, int> counts(Object? value) {
    if (value is! Map) return const <String, int>{};
    final result = <String, int>{};
    value.forEach((Object? key, Object? entry) {
      final count = integer(entry);
      if (count != null) result['$key'] = count;
    });
    return result;
  }

  /// The first key that carries a value, for fields the API spells differently
  /// per resource.
  static Object? pick(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) return value;
    }
    return null;
  }

  /// `yyyy-MM-dd` — the only date format the write endpoints accept.
  static String? dateOnly(DateTime? value) {
    if (value == null) return null;
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year.toString().padLeft(4, '0')}-$month-$day';
  }

  /// ISO-8601 UTC, for `device_recorded_at` on an offline write.
  static String? timestamp(DateTime? value) => value?.toUtc().toIso8601String();
}
