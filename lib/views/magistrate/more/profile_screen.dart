import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../controllers/auth_controller.dart';
import '../../../widgets/widgets.dart';
import 'widgets/appearance_settings.dart';
import 'widgets/officer_card.dart';

/// The officer's own page: who is signed in, how the app should look, and the
/// way out.
///
/// The identity card lives here rather than on the dashboard. Home is for the
/// work waiting; an officer does not need to be told their own name every time
/// they open the app, but they do need somewhere to check which account this
/// handset is signed in as before they seal a shop under it.
class MagistrateProfileScreen extends StatelessWidget {
  const MagistrateProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Scaffold(
      body: Column(
        children: [
          const AppHeroHeader(title: 'Profile'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                Obx(() {
                  final officer = auth.officer.value;
                  if (officer == null) {
                    return const AppCard(child: AppText.body('Not signed in.'));
                  }
                  return OfficerCard(officer: officer);
                }),
                const SizedBox(height: 28),
                const AppText.titleLarge('Appearance'),
                const SizedBox(height: 4),
                AppText.body(
                  'Pick the colours you find easiest to look at. This only '
                  'affects your own screen.',
                  color: muted,
                ),
                const SizedBox(height: 18),
                const AppearanceSettings(),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Log out',
                  icon: Icons.logout_rounded,
                  variant: AppButtonVariant.outline,
                  onPressed: () => _signOut(context, auth),
                ),
                const SizedBox(height: 10),
                AppText.caption(
                  'Signing out revokes this handset’s access. Other '
                  'devices you are signed in on are not affected.',
                  color: muted,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Confirmed, because it is not a small thing in the middle of a round: the
  /// officer has to sign in again before they can record anything else.
  Future<void> _signOut(BuildContext context, AuthController auth) async {
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
    await auth.signOut();
    if (context.mounted) context.go(AppRoutes.login);
  }
}
