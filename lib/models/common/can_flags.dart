/// The server-computed `can_*` / `is_*` flags that arrive on cases, seals,
/// fines and properties.
///
/// **Enable buttons from these flags, never from `status`.** The server
/// accounts for state the app cannot see: a court stay order suspending
/// enforcement, an instalment plan pausing recovery, dues cleared at a
/// counter this morning, another officer having already acted. A state
/// machine written on the client will be wrong within a month, and it will
/// be wrong in the direction of offering an action that gets refused — in
/// front of a shopkeeper.
///
/// Flags are kept as a map rather than a fixed set of fields on purpose:
/// the documents disagree on some names (`can_unseal` vs
/// `can_release`), and an unknown flag must default to *not permitted*
/// rather than break parsing.
class CanFlags {
  const CanFlags(this._flags);

  final Map<String, bool> _flags;

  static const CanFlags none = CanFlags({});

  /// Picks up every boolean whose key starts with `can_`, `is_`, `has_`,
  /// `requires_`, `awaiting_` or ends in `_overdue`.
  factory CanFlags.fromJson(Map<String, dynamic>? json) {
    if (json == null) return none;
    final flags = <String, bool>{};
    json.forEach((key, value) {
      if (value is! bool) return;
      final interesting = key.startsWith('can_') ||
          key.startsWith('is_') ||
          key.startsWith('has_') ||
          key.startsWith('requires_') ||
          key.startsWith('awaiting_') ||
          key.endsWith('_overdue');
      if (interesting) flags[key] = value;
    });
    return CanFlags(flags);
  }

  /// False unless the server said true. Absent means not permitted.
  bool operator [](String flag) => _flags[flag] ?? false;

  /// True when the server sent this flag at all — lets a screen tell
  /// "refused" apart from "this payload does not carry the flag".
  bool knows(String flag) => _flags.containsKey(flag);

  bool anyOf(List<String> flags) => flags.any((flag) => this[flag]);

  Map<String, bool> get all => Map.unmodifiable(_flags);

  // --- The flags the screens actually ask about -------------------------
  bool get canSeal => this['can_seal'];
  bool get canRelease => anyOf(['can_release', 'can_unseal']);
  bool get canClose => this['can_close'];
  bool get canFine => this['can_fine'];
  bool get canRecordAction => this['can_record_action'];
  bool get canApprove => this['can_approve'];
  bool get isLive => this['is_live'];
  bool get isSealed => this['is_sealed'];
  bool get visitOverdue => this['visit_overdue'];
  bool get requiresApproval => this['requires_approval'];
  bool get awaitingApproval => this['awaiting_approval'];
  bool get hasLiveStay => anyOf(['has_live_stay', 'has_stay_order', 'is_stayed']);
}
