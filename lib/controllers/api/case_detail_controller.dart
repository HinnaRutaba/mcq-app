import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/app_feedback.dart';
import '../../data/api/repositories/enforcement_repository.dart';
import '../../data/api/repositories/legal_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/auth/permissions.dart';
import '../../models/enforcement/enforcement_case.dart';
import 'async_state.dart';
import 'offline_queue_controller.dart';
import 'session_controller.dart';

/// One enforcement case: its header, its timeline, and the actions the
/// server says are possible on it right now.
///
/// Every button on this screen is gated twice — on the officer's permission
/// (so the app never offers what they cannot do) and on the case's own
/// `can_*` flag (so it never offers what the *state of the world* refuses).
class CaseDetailController extends GetxController with AsyncState {
  CaseDetailController({
    required this.caseId,
    required EnforcementRepository enforcement,
    required LegalRepository legal,
    required SessionController session,
    required OfflineQueueController queue,
  })  : _enforcement = enforcement,
        _legal = legal,
        _session = session,
        _queue = queue;

  factory CaseDetailController.resolve(int caseId) => CaseDetailController(
        caseId: caseId,
        enforcement: Get.find(),
        legal: Get.find(),
        session: Get.find(),
        queue: Get.find(),
      );

  final int caseId;
  final EnforcementRepository _enforcement;
  final LegalRepository _legal;
  final SessionController _session;
  final OfflineQueueController _queue;

  final Rx<EnforcementCase?> enforcementCase = Rx<EnforcementCase?>(null);
  final RxList<CaseAction> timeline = <CaseAction>[].obs;
  final RxBool hasLiveStay = false.obs;
  final RxBool isClosing = false.obs;

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
          final loaded = await _enforcement.caseById(caseId);
          enforcementCase.value = loaded;
          markFetched(DateTime.now(), fromCache: false);
          if (_session.can(Permissions.actionView)) {
            final actions = await _enforcement.caseActions(caseId);
            timeline.assignAll(actions.items);
          }
          _checkStayOrder(loaded);
        },
        refreshing: refreshing,
      );

  /// A stay order stops enforcement. The server will refuse a seal on a
  /// stayed property, but the officer should not be walking to the shop in
  /// the first place — so this is checked and shown, not discovered.
  Future<void> _checkStayOrder(EnforcementCase loaded) async {
    if (!_session.can(Permissions.legalCaseView)) return;
    try {
      hasLiveStay.value = await _legal.hasLiveStay(loaded.property.id);
    } on ApiException {
      // Not knowing is not the same as knowing there is no stay. The
      // seal button stays available and the server remains the authority.
      hasLiveStay.value = false;
    }
  }

  // --- Gating -----------------------------------------------------------

  bool get canRecordAction =>
      _session.can(Permissions.actionRecord) &&
      (enforcementCase.value?.isLive ?? false);

  /// `can_seal` and the permission, and never a state machine of our own.
  /// A known live stay hides it too.
  bool get canSeal =>
      _session.can(Permissions.sealApply) &&
      (enforcementCase.value?.flags.canSeal ?? false) &&
      !hasLiveStay.value;

  bool get canRelease =>
      _session.can(Permissions.sealRelease) &&
      (enforcementCase.value?.flags.canRelease ?? false) &&
      enforcementCase.value?.sealId != null;

  bool get canFine => _session.can(Permissions.fineImpose);

  bool get canClose =>
      _session.can(Permissions.caseManage) &&
      (enforcementCase.value?.flags.canClose ?? false);

  Future<bool> closeCase(String closingRemarks) async {
    isClosing.value = true;
    try {
      final outcome = await _enforcement.closeCase(
        caseId: caseId,
        closingRemarks: closingRemarks,
      );
      AppFeedback.toast(outcome.message ?? t('common.save'));
      await reload(refreshing: true);
      return true;
    } on ApiException catch (error) {
      if (error.isConflict) {
        await AppFeedback.serverRefusal(error.message);
      } else if (!error.isForbidden) {
        AppFeedback.toast(error.message, isError: true);
      }
      return false;
    } finally {
      isClosing.value = false;
    }
  }
}
