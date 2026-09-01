import 'package:get/get.dart';

import '../../data/api/repositories/field_repository.dart';
import '../../models/field/follow_up.dart';
import '../api/async_state.dart';

/// The chase queue.
///
/// Grouped by state with the overdue first, because the three states call
/// for three different things: an officer who said he would pay and did not
/// needs escalation offered on the spot, one who promised today needs a
/// phone call, and one due in a week needs nothing at all.
class FollowUpsController extends GetxController with AsyncState {
  FollowUpsController({required FieldRepository field, String? initialState})
      : _field = field {
    if (initialState != null) state.value = initialState;
  }

  factory FollowUpsController.resolve({String? initialState}) =>
      FollowUpsController(field: Get.find(), initialState: initialState);

  final FieldRepository _field;

  /// `due` — overdue and today, the tile the home screen links to — or
  /// `upcoming`, or null for everything.
  final RxString state = ''.obs;

  final RxList<FollowUp> rows = <FollowUp>[].obs;
  final RxBool isFirstLoad = true.obs;

  static const String stateDue = 'due';
  static const String stateUpcoming = 'upcoming';

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  void stateChanged(String value) {
    if (state.value == value) return;
    state.value = value;
    reload();
  }

  Future<void> reload({bool refreshing = false}) => load(
        () async {
          final fetched = await _field.followUps(
            state: state.value.isEmpty ? null : state.value,
          );
          rows.assignAll(fetched.value);
          markFetched(fetched.fetchedAt, fromCache: fetched.fromCache);
          isFirstLoad.value = false;
        },
        refreshing: refreshing,
      );

  List<FollowUp> _of(FollowUpState which) =>
      rows.where((row) => row.state == which).toList();

  List<FollowUp> get overdue => _of(FollowUpState.overdue);
  List<FollowUp> get dueToday => _of(FollowUpState.dueToday);
  List<FollowUp> get upcoming => _of(FollowUpState.upcoming);

  /// The sections, in the order they matter, with the empty ones dropped.
  List<MapEntry<FollowUpState, List<FollowUp>>> get sections {
    final all = [
      MapEntry(FollowUpState.overdue, overdue),
      MapEntry(FollowUpState.dueToday, dueToday),
      MapEntry(FollowUpState.upcoming, upcoming),
    ];
    return all.where((entry) => entry.value.isNotEmpty).toList();
  }
}
