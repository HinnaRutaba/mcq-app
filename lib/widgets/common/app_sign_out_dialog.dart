import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes/app_routes.dart';
import '../../controllers/auth_controller.dart';
import '../text/app_text.dart';

/// The one way out, shared by Home, the More hub and the profile page.
class AppSignOutDialog {
  AppSignOutDialog._();

  /// Confirmed, because it is not a small thing in the middle of a round: the
  /// officer has to sign in again before they can record anything else.
  static Future<void> confirmAndSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const AppText.titleMedium('Log out?'),
        content: const AppText.body(
          'You will need to sign in again before you can record a visit, a '
          'fine or a seal.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const AppText.label('Stay signed in'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: AppText.label(
              'Log out',
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Revokes this device's token server-side. The keychain is cleared even if
    // that call fails, so this never leaves a live token behind.
    await Get.find<AuthController>().signOut();
    if (context.mounted) context.go(AppRoutes.login);
  }
}
