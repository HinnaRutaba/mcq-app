import 'package:get/get.dart';

import '../core/network/api_exception.dart';
import '../data/repositories/defaulters_repository.dart';
import '../models/defaulter_card.dart';

/// The promises an officer has taken, and where each one stands.
///
/// Its own list, not a filter over the defaulter one: the count on Home comes
/// from `enforcement/field/follow-ups`, and narrowing the defaulters list by
/// the `commitment` on its rows answers a different question — which is how a
/// queue reading 1 used to open a list showing none.
class FollowUpsController extends GetxController {
  FollowUpsController({DefaultersRepository? defaultersRepository})
    : _defaulters = defaultersRepository ?? Get.find<DefaultersRepository>();

  final DefaultersRepository _defaulters;

  /// The reading [open] asked for before this controller existed, read once by
  /// [onInit]. Without it a tile wanting the due promises would fetch the
  /// upcoming ones first and the due ones second.
  static FollowUpState? _wanted;

  /// As the server ordered them. Never re-sorted here.
  final RxList<DefaulterCard> followUps = RxList<DefaulterCard>();

  /// Which promises are on screen. Both readings are a question for the
  /// server — `state=due` or `state=upcoming` — so switching costs a call and
  /// the chips carry no counts: the rows for the one an officer is not
  /// looking at are not in hand.
  final Rx<FollowUpState> state = Rx<FollowUpState>(FollowUpState.due);

  final RxBool isLoading = RxBool(false);

  final RxnString errorMessage = RxnString();

  /// Bumped per fetch, so a slow answer to an old question cannot land on top
  /// of a newer one.
  int _sequence = 0;

  @override
  void onInit() {
    super.onInit();
    if (_wanted != null) {
      state.value = _wanted!;
      _wanted = null;
    }
    load();
  }

  bool get hasData => followUps.isNotEmpty;

  /// Opens the list on [which] — called from the follow-ups tile on Home,
  /// which may be the first thing to ask for this controller at all.
  ///
  /// The reading is seeded before the find rather than set after it, so the
  /// arrival is one call. A controller that was already up never runs
  /// [onInit] again, and is left holding [_wanted] — which is how this knows
  /// to switch it by hand.
  static Future<void> open(FollowUpState which) async {
    _wanted = which;
    final FollowUpsController controller = Get.find<FollowUpsController>();
    if (_wanted == null) return;
    _wanted = null;
    await controller.showState(which);
  }

  /// Safe to call again — this is the pull-to-refresh.
  Future<void> load() => _fetch();

  /// Shows [which]. A different request, so it fetches.
  Future<void> showState(FollowUpState which) async {
    if (which == state.value) return;
    state.value = which;
    await _fetch();
  }

  Future<void> _fetch() async {
    final int ticket = ++_sequence;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final List<DefaulterCard> rows = await _defaulters.followUps(
        state: state.value,
      );
      if (ticket != _sequence) return;
      followUps.value = rows;
    } on ApiException catch (error) {
      if (ticket != _sequence) return;
      errorMessage.value = error.message;
    } finally {
      if (ticket == _sequence) isLoading.value = false;
    }
  }
}
