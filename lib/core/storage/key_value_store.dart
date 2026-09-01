import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Non-secret local state: the chosen language, the device name the officer
/// typed, cached reads, and the offline write queue.
///
/// The token is deliberately not here — it lives in the keychain, see
/// [SecureTokenStore]. Neither is the permission list: permissions are rows
/// resolved per request, and a transferred officer's authority changes
/// without them signing in again, so they are never cached past a session.
class KeyValueStore {
  KeyValueStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<KeyValueStore> open() async =>
      KeyValueStore(await SharedPreferences.getInstance());

  static const String localeKey = 'mcq.locale';
  static const String deviceNameKey = 'mcq.device_name';
  static const String queueKey = 'mcq.offline_queue';
  static String cacheKey(String name) => 'mcq.cache.$name';
  static String cacheStampKey(String name) => 'mcq.cache.$name.at';

  String? getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  Future<void> remove(String key) => _prefs.remove(key);

  Map<String, dynamic>? getJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  List<dynamic>? getJsonList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> setJson(String key, Object value) =>
      _prefs.setString(key, jsonEncode(value));
}
