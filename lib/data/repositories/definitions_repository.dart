import '../../core/network/api_config.dart';
import '../../core/network/api_service.dart';
import '../../models/enforcement_definitions.dart';

/// The enforcement module's master data: the fine types, the action types and
/// the four status vocabularies.
///
/// Fetch it once at sign-in and cache it. It is not a per-screen call: it is
/// the list every drop-down in the module is drawn from, and it changes when
/// MCQ edits a row, not when an officer opens a form.
///
/// The point of going to the server for it at all is that hardcoding the
/// offences and the actions produces a picker that silently stops matching the
/// register — a fine written under a code MCQ retired is a fine nobody can
/// report on.
abstract class DefinitionsRepository {
  /// The cached definitions, fetching them the first time.
  ///
  /// Concurrent callers share one call, so a home screen and a fine form
  /// asking at the same moment do not both go to the wire.
  Future<EnforcementDefinitions> definitions({bool refresh});

  /// What is already in hand, without a call. Null before the first fetch —
  /// so a form that must not be drawn from a stale picker can tell the
  /// difference between "empty" and "not asked yet".
  EnforcementDefinitions? get cached;

  /// Throws the cache away, for a sign-out: the next officer on this handset
  /// may be posted somewhere with a different set of rows.
  void forget();
}

class ApiDefinitionsRepository implements DefinitionsRepository {
  ApiDefinitionsRepository({required this._api});

  final ApiService _api;

  EnforcementDefinitions? _cached;

  /// The call in flight, so the second caller waits on the first rather than
  /// starting a second one.
  Future<EnforcementDefinitions>? _inFlight;

  @override
  EnforcementDefinitions? get cached => _cached;

  @override
  Future<EnforcementDefinitions> definitions({bool refresh = false}) {
    final held = _cached;
    if (held != null && !refresh) {
      return Future<EnforcementDefinitions>.value(held);
    }
    return _inFlight ??= _fetch();
  }

  Future<EnforcementDefinitions> _fetch() async {
    try {
      final response = await _api.get(ApiPaths.definitions);
      final definitions = EnforcementDefinitions.fromJson(response.dataMap);
      _cached = definitions;
      return definitions;
    } finally {
      // Cleared whether or not it worked: a failed fetch must not leave a
      // rejected future behind for every later caller to trip over.
      _inFlight = null;
    }
  }

  @override
  void forget() {
    _cached = null;
    _inFlight = null;
  }
}
