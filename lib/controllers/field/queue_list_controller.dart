import 'package:get/get.dart';

import '../../data/api/repositories/field_repository.dart';
import '../../models/field/field_card.dart';
import '../api/async_state.dart';

/// The fallback behind a beat tile the app has no designed screen for.
///
/// MCQ was explicit that **no number on the dashboard may be a dead end**,
/// and the server hands the route over in each queue's `endpoint` precisely
/// so the app does not hard-code paths. Tiles the app knows open their own
/// screen; a queue MCQ adds next month still opens — here, as a list of the
/// same cards — without waiting for a release.
class QueueListController extends GetxController with AsyncState {
  QueueListController({
    required FieldRepository field,
    required this.endpoint,
  }) : _field = field;

  factory QueueListController.resolve(String endpoint) =>
      QueueListController(field: Get.find(), endpoint: endpoint);

  final FieldRepository _field;

  /// Relative to `/api/v1`, exactly as the server sent it, query string
  /// and all.
  final String endpoint;

  final RxList<FieldCard> rows = <FieldCard>[].obs;
  final RxBool isFirstLoad = true.obs;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload({bool refreshing = false}) => load(
        () async {
          rows.assignAll(await _field.listAtEndpoint(endpoint));
          markFetched(DateTime.now(), fromCache: false);
          isFirstLoad.value = false;
        },
        refreshing: refreshing,
      );
}
