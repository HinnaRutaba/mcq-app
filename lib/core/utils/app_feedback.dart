import 'package:flutter/material.dart';

import '../../config/routes/app_router.dart';
import '../../config/theme/app_colors.dart';
import '../../widgets/dialogs/app_message_dialog.dart';
import '../../widgets/text/app_text.dart';

/// The app's one route for showing a message that did not come from a
/// screen's own build method — a 403 caught by the interceptor, a write
/// queued because the signal died, a 409 raised from a controller.
///
/// Kept here rather than in a controller because it is cross-cutting: the
/// Dio interceptor has no `BuildContext`, and a refusal must be shown
/// wherever the officer happens to be.
class AppFeedback {
  AppFeedback._();

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static BuildContext? get _context => rootNavigatorKey.currentContext;

  /// A short, non-blocking message. Used for a 403 — the refusal of one
  /// action — and for confirmations. Never for a 409.
  static void toast(String message, {bool isError = false}) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: AppText.body(message, color: Colors.white),
        backgroundColor: isError ? AppColors.error : AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// A sentence the officer has to read and act on. Shown verbatim, in a
  /// dialog they have to dismiss.
  static Future<bool> serverRefusal(
    String message, {
    String? title,
    String? secondaryLabel,
  }) async {
    final context = _context;
    if (context == null) {
      toast(message, isError: true);
      return false;
    }
    return AppMessageDialog.show(
      context,
      message: message,
      title: title,
      secondaryLabel: secondaryLabel,
    );
  }
}
