import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../controllers/cases_controller.dart';
import '../../../controllers/defaulters_controller.dart';
import '../../../controllers/seals_controller.dart';
import '../../../models/field_beat.dart';

/// Which screen a queue tile on Home opens, and on which reading of it.
///
/// The server sends each queue an `endpoint` — the list the tile counts — but
/// the app has screens, not endpoints: two queues can be two chips on one
/// list, and one screen can answer a queue the payload words differently. So
/// the [FieldQueue.key] is matched here, in one place, and both the tile's tap
/// and whether it is tappable at all are read off the same switch.
///
/// A key with no screen behind it — a queue the server adds after this build
/// ships — is left untappable rather than sent somewhere approximate: a figure
/// is honest, a tile that opens the wrong list is not.
class QueueDestination {
  QueueDestination._();

  /// Whether a screen answers [key].
  static bool exists(String key) => _screenFor(key) != null;

  /// Opens the list [queue] counts, on the reading its tile named.
  static void open(BuildContext context, FieldQueue queue) =>
      _screenFor(queue.key)?.call(context);

  /// The one mapping. Known keys are the enforcement beat's own — see
  /// [FieldQueue.key].
  static void Function(BuildContext context)? _screenFor(String key) =>
      switch (key) {
        'defaulters' => (BuildContext context) =>
          _defaulters(context, DefaulterState.everyone),

        // The nearest list the app has: a follow-up that is due is a promise
        // to pay whose date has come, and "Promised" is the chip that holds
        // them. There is no follow-ups screen of its own yet.
        'follow_ups_due' => (BuildContext context) =>
          _defaulters(context, DefaulterState.promised),

        'awaiting_unseal' => (BuildContext context) =>
          _seals(context, SealQueue.ready),
        'sealed_shops' => (BuildContext context) =>
          _seals(context, SealQueue.all),

        'open_cases' => (BuildContext context) =>
          _cases(context, CaseFilter.all),
        'assigned_to_me' => (BuildContext context) =>
          _cases(context, CaseFilter.mine),

        _ => null,
      };

  /// The defaulter list, on one of its state chips.
  ///
  /// The bazaar picker is left where the officer set it: it is a standing
  /// choice of theirs, and it is on screen and labelled where they land.
  static void _defaulters(BuildContext context, DefaulterState state) {
    Get.find<DefaultersController>().showState(state);
    _go(context, AppRoutes.magistrateDefaulters);
  }

  static void _seals(BuildContext context, SealQueue queue) {
    Get.find<SealsController>().showQueue(queue);
    _go(context, AppRoutes.magistrateSealed);
  }

  static void _cases(BuildContext context, CaseFilter filter) {
    // Not `Get.find` first: this may be the tap that builds the controller,
    // and seeding the filter through here keeps the arrival to one call
    // rather than the whole register followed by the officer's own slice.
    CasesController.open(filter);
    _go(context, AppRoutes.magistrateCases);
  }

  /// `go`, not `goBranch`: a branch the officer left standing on a shop's
  /// profile would otherwise come back to that profile, and a tile counting
  /// 55 defaulters has to land on the 55.
  static void _go(BuildContext context, String location) =>
      context.go(location);
}
