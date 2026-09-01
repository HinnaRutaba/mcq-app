import 'package:get/get.dart';

import '../../data/api/repositories/enforcement_repository.dart';
import '../../models/enforcement/fine.dart';
import 'async_state.dart';
import 'offline_queue_controller.dart';

/// Fines imposed in the officer's areas.
class FinesController extends GetxController with AsyncState {
  FinesController({
    required EnforcementRepository enforcement,
    required OfflineQueueController queue,
  })  : _enforcement = enforcement,
        _queue = queue;

  factory FinesController.resolve() => FinesController(
        enforcement: Get.find(),
        queue: Get.find(),
      );

  final EnforcementRepository _enforcement;
  final OfflineQueueController _queue;

  final RxList<Fine> fines = <Fine>[].obs;

  Worker? _landedWorker;

  @override
  void onInit() {
    super.onInit();
    reload();
    _landedWorker = ever<int>(_queue.landed, (_) => reload(refreshing: true));
  }

  @override
  void onClose() {
    _landedWorker?.dispose();
    super.onClose();
  }

  Future<void> reload({bool refreshing = false}) => load(
        () async {
          final fetched = await _enforcement.fines();
          fines.assignAll(fetched.value.items);
          markFetched(fetched.fetchedAt, fromCache: fetched.fromCache);
        },
        refreshing: refreshing,
      );

  /// Fines still waiting on somebody else's approval are not effective yet
  /// and are shown as such.
  List<Fine> get ordered {
    final list = fines.toList()
      ..sort((a, b) =>
          (b.imposedOn ?? DateTime(0)).compareTo(a.imposedOn ?? DateTime(0)));
    return list;
  }
}
