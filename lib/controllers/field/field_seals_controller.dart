import 'package:get/get.dart';

import '../../data/api/repositories/field_repository.dart';
import '../../models/field/field_seal.dart';
import '../api/async_state.dart';

/// Seals, and the unseal queue MCQ asked for.
///
/// One list, two readings. The whole list is fetched and split here rather
/// than fetched twice, so a seal cannot fall between "what I have sealed"
/// and "what now needs unsealing" — which is exactly what two endpoints
/// would eventually let it do.
class FieldSealsController extends GetxController with AsyncState {
  FieldSealsController({required FieldRepository field, bool readyFirst = false})
      : _field = field {
    onlyReady.value = readyFirst;
  }

  factory FieldSealsController.resolve({bool readyFirst = false}) =>
      FieldSealsController(field: Get.find(), readyFirst: readyFirst);

  final FieldRepository _field;

  final RxList<FieldSeal> rows = <FieldSeal>[].obs;

  /// The home screen's "Ready to unseal" tile opens this list already
  /// narrowed. It is a view of the same rows, not a second request.
  final RxBool onlyReady = false.obs;

  final RxBool isFirstLoad = true.obs;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload({bool refreshing = false}) => load(
        () async {
          final fetched = await _field.seals();
          rows.assignAll(fetched.value);
          markFetched(fetched.fetchedAt, fromCache: fetched.fromCache);
          isFirstLoad.value = false;
        },
        refreshing: refreshing,
      );

  void showOnlyReady(bool value) => onlyReady.value = value;

  List<FieldSeal> get ready =>
      rows.where((row) => row.readyToRelease).toList();

  List<FieldSeal> get stillSealed =>
      rows.where((row) => !row.readyToRelease).toList();

  /// Ready to release first, always. It is the only part of this screen
  /// that is a job waiting to be done.
  List<FieldSeal> get ordered =>
      onlyReady.value ? ready : [...ready, ...stillSealed];

  int get readyCount => ready.length;
}
