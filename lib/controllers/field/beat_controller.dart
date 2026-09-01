import 'package:get/get.dart';

import '../../data/api/repositories/field_repository.dart';
import '../../models/field/beat.dart';
import '../../models/field/field_activity.dart';
import '../../models/field/round.dart';
import '../api/async_state.dart';

/// The home screen.
///
/// `GET /enforcement/field/beat` answers the whole thing in one request.
/// The round and the month's activity are two smaller reads that follow it
/// and are allowed to fail on their own: a bazaar signal that could not
/// fetch the activity summary must not take the six queues down with it.
class BeatController extends GetxController with AsyncState {
  BeatController({required FieldRepository field}) : _field = field;

  factory BeatController.resolve() => BeatController(field: Get.find());

  final FieldRepository _field;

  final Rx<FieldBeat?> beat = Rx<FieldBeat?>(null);
  final RxList<RoundMarket> round = <RoundMarket>[].obs;
  final Rx<FieldActivity?> activity = Rx<FieldActivity?>(null);

  /// False after the first successful load, so a refresh does not replay
  /// the count-up and the card stagger over figures the officer is already
  /// reading.
  final RxBool isFirstLoad = true.obs;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload({bool refreshing = false}) async {
    await load(
      () async {
        final fetched = await _field.beat();
        beat.value = fetched.value;
        markFetched(fetched.fetchedAt, fromCache: fetched.fromCache);
      },
      refreshing: refreshing,
    );
    // Deliberately after, and deliberately not awaited into the same
    // failure: the beat is the screen, these two are furniture on it.
    unawaited(_loadRound());
    unawaited(_loadActivity());
    if (beat.value != null) isFirstLoad.value = false;
  }

  Future<void> _loadRound() async {
    try {
      final fetched = await _field.round();
      round.assignAll(fetched.value);
    } catch (_) {
      // Leave whatever is already there. A round that failed to refresh is
      // still the round the officer planned his morning around.
    }
  }

  Future<void> _loadActivity() async {
    try {
      final fetched = await _field.activity();
      activity.value = fetched.value;
    } catch (_) {
      // Same: the summary card simply does not appear.
    }
  }

  BeatScope get scope => beat.value?.scope ?? BeatScope.unknown;

  BeatOfficer get officer => beat.value?.officer ?? BeatOfficer.unknown;

  List<BeatQueue> get queues => beat.value?.queues ?? const [];

  /// An officer with no posting sees an explanation, not six zeroes.
  bool get hasNoPosting => beat.value != null && !scope.hasPosting;

  /// The first market of the round — the card the home screen previews.
  RoundMarket? get nextMarket => round.isEmpty ? null : round.first;
}

/// `unawaited`, without pulling in `dart:async` at every call site.
void unawaited(Future<void> future) {
  future.catchError((Object _) {});
}
