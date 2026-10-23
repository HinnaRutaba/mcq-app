import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth_controller.dart';
import '../../../widgets/widgets.dart';
import 'widgets/appearance_settings.dart';
import 'widgets/officer_card.dart';

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
