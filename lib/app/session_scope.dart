import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/cases_controller.dart';
import '../controllers/challans_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/defaulters_controller.dart';
import '../controllers/seals_controller.dart';
import '../controllers/trade_licences_controller.dart';
import '../models/auth_user.dart';

/// Ties the tab controllers to the officer who is signed in.
///
/// Each of them fetches once in `onInit` and then holds what it fetched, so
/// without this the next officer on the handset opens Home to the last one's
/// beat — and their filters, cursors and search box — until a pull to refresh.
/// The seal register is the same: it is the officer's own seals, not the
/// bazaar's.
/// They are registered `fenix`, so dropping them here is enough: the next
/// sign-in rebuilds each from scratch when its tab is first opened.
///
/// [DefinitionsController] and [TradeBeatController] are not dropped: they are
/// permanent, and already watch the session to clear their own rows.
void watchSessionScope() {
  final AuthController auth = Get.find<AuthController>();

  String? signedInAs = auth.officer.value?.username;

  ever<AuthUser?>(auth.officer, (AuthUser? officer) {
    // A sign-out, or a different officer on the same handset. The forced
    // password change re-signs the same officer in, which is not a change of
    // whose data is on screen.
    if (officer?.username == signedInAs) return;
    signedInAs = officer?.username;
    _dropSessionControllers();
  });
}

void _dropSessionControllers() {
  Get.delete<DashboardController>();
  Get.delete<DefaultersController>();
  Get.delete<TradeLicencesController>();
  Get.delete<ChallansController>();
  Get.delete<SealsController>();
  Get.delete<CasesController>();
}
