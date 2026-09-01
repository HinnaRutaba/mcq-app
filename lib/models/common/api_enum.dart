/// An enum value as the API sends it: `{"value","label","tone"}`.
///
/// Use [label] for display — it arrives already translated into the
/// request's language. Use [value] for logic and for filter query
/// parameters. Use [tone] for colour. Never map [value] to your own
/// strings: that is a second source of truth and it drifts from the web
/// application.
class ApiEnum {
  const ApiEnum({required this.value, required this.label, this.tone});

  final String value;
  final String label;
  final String? tone;

  static const ApiEnum unknown = ApiEnum(value: '', label: '—');

  factory ApiEnum.fromJson(Object? json) {
    if (json == null) return unknown;
    if (json is String) {
      // A bare string means the payload changed shape; show it rather than
      // crashing, but do not invent a label of our own.
      return ApiEnum(value: json, label: json);
    }
    final map = json as Map<String, dynamic>;
    return ApiEnum(
      value: (map['value'] ?? '').toString(),
      label: (map['label'] ?? map['value'] ?? '—').toString(),
      tone: map['tone'] as String?,
    );
  }

  bool get isEmpty => value.isEmpty;

  @override
  String toString() => label;
}
