import 'package:get/get.dart';

import '../../data/api/repositories/field_repository.dart';
import '../../models/field/field_card.dart';
import '../../models/field/round.dart';
import '../api/async_state.dart';

/// Today's round — the screen that saves him an hour.
///
/// The server has already ordered the markets by broken promises first,
/// then by count, and capped each at five stops. **None of that is redone
/// here.** A lapsed commitment beats a larger balance nobody has spoken to
/// yet, and a round nobody can finish is a list nobody reads.
class RoundController extends GetxController with AsyncState {
  RoundController({required FieldRepository field}) : _field = field;

  factory RoundController.resolve() => RoundController(field: Get.find());

  final FieldRepository _field;

  final RxList<RoundMarket> markets = <RoundMarket>[].obs;
  final RxBool isFirstLoad = true.obs;

  /// Which market is expanded. Only one at a time — this is read while
  /// walking, not while sitting down with it.
  final RxInt expanded = 0.obs;

  /// The stops the officer has ticked off this session, by property id.
  ///
  /// Deliberately **not** sent to the server and deliberately not
  /// persisted: "I have walked past this one" is not an enforcement action,
  /// and recording it as one would put a visit in the register that never
  /// happened. It survives as long as the screen does, which is as long as
  /// the round does.
  final RxSet<int> walked = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload({bool refreshing = false}) => load(
        () async {
          final fetched = await _field.round();
          markets.assignAll(fetched.value);
          markFetched(fetched.fetchedAt, fromCache: fetched.fromCache);
          isFirstLoad.value = false;
        },
        refreshing: refreshing,
      );

  void toggleExpanded(int index) =>
      expanded.value = expanded.value == index ? -1 : index;

  void markWalked(FieldCard stop) {
    if (walked.contains(stop.propertyId)) {
      walked.remove(stop.propertyId);
    } else {
      walked.add(stop.propertyId);
    }
  }

  bool hasWalked(FieldCard stop) => walked.contains(stop.propertyId);

  /// Every stop across every market, in the order the officer would walk
  /// them — what "Start round" steps through.
  List<FieldCard> get allStops =>
      [for (final market in markets) ...market.stops];

  int get totalStops => allStops.length;

  int get walkedCount =>
      allStops.where((stop) => walked.contains(stop.propertyId)).length;

  bool get isComplete => totalStops > 0 && walkedCount == totalStops;

  /// The next stop that has not been ticked off.
  FieldCard? get nextStop {
    for (final stop in allStops) {
      if (!walked.contains(stop.propertyId)) return stop;
    }
    return null;
  }
}
