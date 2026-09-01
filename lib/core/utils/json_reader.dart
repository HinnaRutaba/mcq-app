import '../../models/common/api_enum.dart';
import '../../models/common/money.dart';

/// Defensive readers for API payloads.
///
/// The API is live and still moving, and a hand-typed model is where a
/// renamed field becomes a silent null. These readers never throw on a
/// missing or re-typed field — they fall back and assert in debug, so a
/// drifted payload shows up in testing rather than as a crash in a bazaar.
///
/// Note what is *not* here: no `double` reader for an amount. Money is a
/// `String` and is never parsed — use [json.money]. Counts and percentages
/// are safe to parse; the server computes them to two places for exactly
/// that reason.
extension JsonReader on Map<String, dynamic> {
  String? str(String key) {
    final value = this[key];
    if (value == null) return null;
    return value is String ? value : '$value';
  }

  String strOr(String key, [String fallback = '']) => str(key) ?? fallback;

  int? integer(String key) {
    final value = this[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  int intOr(String key, [int fallback = 0]) => integer(key) ?? fallback;

  /// Percentages arrive as strings like `"37.92"` and are safe to parse.
  double? percent(String key) {
    final value = this[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  bool boolean(String key, {bool fallback = false}) {
    final value = this[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value == 'true' || value == '1';
    return fallback;
  }

  /// Money — carried as the server's own string, never converted.
  Money money(String key) => Money.fromJson(this[key]);

  Money? moneyOrNull(String key) =>
      this[key] == null ? null : Money.fromJson(this[key]);

  DateTime? date(String key) {
    final raw = str(key);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  ApiEnum apiEnum(String key) => ApiEnum.fromJson(this[key]);

  Map<String, dynamic>? child(String key) {
    final value = this[key];
    return value is Map<String, dynamic> ? value : null;
  }

  List<Map<String, dynamic>> children(String key) {
    final value = this[key];
    if (value is! List) return const [];
    return value.whereType<Map<String, dynamic>>().toList();
  }

  List<String> strings(String key) {
    final value = this[key];
    if (value is! List) return const [];
    return value.map((entry) => '$entry').toList();
  }

  List<int> integers(String key) {
    final value = this[key];
    if (value is! List) return const [];
    return value
        .map((entry) => entry is int ? entry : int.tryParse('$entry'))
        .whereType<int>()
        .toList();
  }

  /// Every amount on a payload, kept as [Money] under its own key — used
  /// for blocks like a case's `amounts` whose exact members are not
  /// pinned down and must not be silently dropped.
  Map<String, Money> moneyMap() {
    final result = <String, Money>{};
    forEach((key, value) {
      if (value is String && RegExp(r'^-?\d+(\.\d+)?$').hasMatch(value)) {
        result[key] = Money(value);
      }
    });
    return result;
  }
}

/// Same readers for a payload that may be absent altogether.
extension NullableJsonReader on Map<String, dynamic>? {
  Map<String, dynamic> get orEmpty => this ?? const <String, dynamic>{};
}
