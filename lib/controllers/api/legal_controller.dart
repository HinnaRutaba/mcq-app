import 'package:get/get.dart';

import '../../data/api/repositories/legal_repository.dart';
import '../../models/legal/legal_case.dart';
import 'async_state.dart';

/// Court cases and the hearing diary. Read-only: the Legal branch maintains
/// these records, and a magistrate holds only the view permissions.
class LegalController extends GetxController with AsyncState {
  LegalController({required LegalRepository legal}) : _legal = legal;

  factory LegalController.resolve() => LegalController(legal: Get.find());

  final LegalRepository _legal;

  final RxList<LegalCase> cases = <LegalCase>[].obs;
  final RxList<Hearing> diary = <Hearing>[].obs;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload({bool refreshing = false}) => load(
        () async {
          final page = await _legal.cases();
          cases.assignAll(page.items);
          diary.assignAll(await _legal.diary());
          markFetched(DateTime.now(), fromCache: false);
        },
        refreshing: refreshing,
      );

  /// The cases that stop enforcement. Shown first, because an officer
  /// planning a round needs to know which shutters not to walk to.
  List<LegalCase> get stayed =>
      cases.where((legalCase) => legalCase.hasLiveStay).toList();
}
