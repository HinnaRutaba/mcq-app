import 'package:get/get.dart';

import '../core/network/api_exception.dart';
import '../data/repositories/trade_repository.dart';
import '../models/auth_user.dart';
import '../models/field_beat.dart';
import '../models/trade_beat.dart';
import 'auth_controller.dart';

/// Holds the officer's bazaars for the life of the session.
///
/// `trade/field/beat` is the only place the licensing module names them, and
/// two screens are drawn from it — the bazaar filter over the licence queues
/// and the picker on the capture form. Fetching it per screen means an officer
/// waits on a spinner for a list that has not changed since they signed in, so
/// it is fetched once here and kept.
///
/// **It follows the session rather than the app's start-up**, for the same
/// reason [DefinitionsController] does: a call before an officer is signed in
/// has no bearer token, and its 401 would clear the keychain out from under the
/// splash screen. The rows themselves live in the repository's cache, so a
/// controller rebuilt by `fenix` still finds them in hand.
class TradeBeatController extends GetxController {
  TradeBeatController({
    TradeRepository? tradeRepository,
    AuthController? authController,
  }) : _trade = tradeRepository ?? Get.find<TradeRepository>(),
       _auth = authController ?? Get.find<AuthController>();

  final TradeRepository _trade;
  final AuthController _auth;

  /// The beat, once an officer is signed in and the call has landed. Seeded
  /// from the repository's cache so a rebuild starts warm.
  late final Rxn<TradeBeat> beat = Rxn<TradeBeat>(_trade.cachedBeat);

  final RxBool isLoading = RxBool(false);

  /// Why the last attempt failed. A sign-in on a dead signal leaves the app
  /// usable and the picker empty rather than blocking either screen.
  final RxnString errorMessage = RxnString();

  bool get isReady => beat.value != null;

  List<FieldArea> get areas => beat.value?.scope.areas ?? const <FieldArea>[];

  /// The bazaars said out loud, e.g. "Jinnah Road and Prince Road".
  String? get scopeSentence {
    final FieldScope? scope = beat.value?.scope;
    if (scope == null || !scope.hasAreas) return null;
    return scope.areaSentence;
  }

  /// How many licences are live in those bazaars — the one figure the beat
  /// carries that no queue list repeats.
  int? get liveCount => beat.value?.queue('live')?.count;

  DateTime? get generatedAt => beat.value?.generatedAt;

  @override
  void onInit() {
    super.onInit();

    // The session is the trigger, not this controller's own construction.
    ever<AuthUser?>(_auth.officer, _onSessionChanged);

    // `ever` fires on change only. An officer already signed in by the time
    // this is built would otherwise wait for a sign-out and back in.
    _onSessionChanged(_auth.officer.value);
  }

  /// Fetches the beat if it is not in hand. Safe to call again — the
  /// repository caches, so this only reaches the wire once.
  Future<void> load({bool refresh = false}) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      beat.value = await _trade.beat(refresh: refresh);
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    } finally {
      isLoading.value = false;
    }
  }

  /// Goes back to the server for a fresh copy — the retry behind an error, and
  /// what a pull-to-refresh on either licensing screen calls.
  Future<void> reload() => load(refresh: true);

  void _onSessionChanged(AuthUser? officer) {
    // A session that cannot be used is not a session to fetch on: the server
    // refuses everything else while `must_change_password` stands.
    if (officer == null || officer.mustChangePassword) {
      if (isReady || errorMessage.value != null) clear();
      return;
    }
    load();
  }

  /// Throws the bazaars away. Called on sign-out: the next officer on this
  /// handset is posted to their own, not the last one's.
  void clear() {
    _trade.forgetBeat();
    beat.value = null;
    errorMessage.value = null;
    isLoading.value = false;
  }
}
