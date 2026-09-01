import 'package:get/get.dart';

import '../../data/api/repositories/field_repository.dart';
import '../../models/field/field_activity.dart';
import '../api/async_state.dart';

/// "My work" — the report that makes an officer trust the app.
///
/// Recovery is slow, unglamorous and mostly invisible. An officer who
/// cannot see that thirty visits sat behind four hundred thousand rupees
/// has no reason to believe the visits matter.
class ActivityController extends GetxController with AsyncState {
  ActivityController({required FieldRepository field}) : _field = field;

  factory ActivityController.resolve() => ActivityController(field: Get.find());

  final FieldRepository _field;

  final Rx<FieldActivity?> activity = Rx<FieldActivity?>(null);
  final RxInt days = 30.obs;
  final RxBool isFirstLoad = true.obs;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  void periodChanged(int value) {
    if (days.value == value) return;
    days.value = value;
    reload();
  }

  Future<void> reload({bool refreshing = false}) => load(
        () async {
          final fetched = await _field.activity(days: days.value);
          activity.value = fetched.value;
          markFetched(fetched.fetchedAt, fromCache: fetched.fromCache);
          isFirstLoad.value = false;
        },
        refreshing: refreshing,
      );
}
