import 'key_value_store.dart';

/// The last successful read of a list or dashboard, with the time it was
/// fetched.
///
/// A magistrate seeing this morning's defaulter list in a basement is
/// useful; a spinner is not. But a cached figure must never look live —
/// every screen that shows one also shows the stamp, which is why
/// [CachedRead.fetchedAt] is not optional.
class ReadCache {
  ReadCache(this._store);

  final KeyValueStore _store;

  Future<void> write(String name, Object json, {DateTime? at}) async {
    await _store.setJson(KeyValueStore.cacheKey(name), json);
    await _store.setString(
      KeyValueStore.cacheStampKey(name),
      (at ?? DateTime.now()).toIso8601String(),
    );
  }

  CachedRead<Map<String, dynamic>>? readMap(String name) {
    final json = _store.getJson(KeyValueStore.cacheKey(name));
    if (json == null) return null;
    return CachedRead(json, _stamp(name));
  }

  CachedRead<List<dynamic>>? readList(String name) {
    final json = _store.getJsonList(KeyValueStore.cacheKey(name));
    if (json == null) return null;
    return CachedRead(json, _stamp(name));
  }

  Future<void> clear(String name) async {
    await _store.remove(KeyValueStore.cacheKey(name));
    await _store.remove(KeyValueStore.cacheStampKey(name));
  }

  DateTime _stamp(String name) {
    final raw = _store.getString(KeyValueStore.cacheStampKey(name));
    return DateTime.tryParse(raw ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Cache names, one per read the app is willing to show stale.
  static const String dashboard = 'dashboard';

  /// The field module. The beat and the round are the two an officer opens
  /// first thing in a bazaar with no signal, so both are worth holding.
  static const String beat = 'field_beat';
  static const String round = 'field_round';
  static const String fieldDefaulters = 'field_defaulters';
  static const String followUps = 'field_follow_ups';
  static const String fieldSeals = 'field_seals';
  static const String activity = 'field_activity';
  static const String defaulters = 'defaulters';
  static const String cases = 'cases';
  static const String seals = 'seals';
  static const String fines = 'fines';
  static const String session = 'session_user';
}

/// A value read from the cache, inseparable from when it was fetched.
class CachedRead<T> {
  const CachedRead(this.value, this.fetchedAt);

  final T value;
  final DateTime fetchedAt;
}
