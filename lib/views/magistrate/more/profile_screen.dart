import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
                  onPressed: () => AppSignOutDialog.confirmAndSignOut(context),
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
}
