import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../controllers/auth_controller.dart';
import '../../../widgets/widgets.dart';
import '../agreements_shell.dart';

/// The reviewers' hub: profile, switching workspace, and signing out.
class AgreementsMoreScreen extends StatelessWidget {
  const AgreementsMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController auth = Get.find<AuthController>();

    return Scaffold(
      body: Column(
        children: <Widget>[
          AppHeroHeader(
            title: 'More',
            leading: AppHeaderBackButton(
              onTap: () => AgreementsShell.goHome(context),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: <Widget>[
                MoreMenuTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Profile and appearance',
                  subtitle: 'The account this handset uses, and how it looks.',
                  onTap: () => context.push(AppRoutes.agreementsProfile),
                ),
                Obx(() {
                  if (!(auth.access.value?.hasMany ?? false)) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: MoreMenuTile(
                      icon: Icons.swap_horiz_rounded,
                      title: 'Switch workspace',
                      subtitle: 'Your account also works in the field.',
                      onTap: () => context.go(AppRoutes.workspaces),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                MoreMenuTile(
                  icon: Icons.logout_rounded,
                  title: 'Log out',
                  subtitle:
                      'Revokes this handset’s access. Other devices '
                      'stay signed in.',
                  tint: Theme.of(context).colorScheme.error,
                  onTap: () => AppSignOutDialog.confirmAndSignOut(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
