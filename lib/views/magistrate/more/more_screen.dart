import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../widgets/widgets.dart';
import '../shared/widgets/back_to_home_button.dart';
import 'widgets/more_menu_tile.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          const AppHeroHeader(title: 'More', leading: BackToHomeButton()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: <Widget>[
                MoreMenuTile(
                  icon: Icons.gavel_rounded,
                  title: 'Impose a fine',
                  subtitle: 'Raise a challan, with a photograph and a seal.',
                  onTap: () => context.push(AppRoutes.createFine),
                ),
                const SizedBox(height: 12),
                MoreMenuTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Sealed shops',
                  subtitle: 'Everything sealed, and what can be released.',
                  onTap: () => context.push(AppRoutes.magistrateSealed),
                ),
                const SizedBox(height: 12),
                MoreMenuTile(
                  icon: Icons.event_repeat_outlined,
                  title: 'Follow-ups',
                  subtitle: 'Promises due or broken, and the ones ahead.',
                  onTap: () => context.push(AppRoutes.magistrateFollowUps),
                ),
                const SizedBox(height: 12),
                MoreMenuTile(
                  icon: Icons.folder_open_outlined,
                  title: 'Cases',
                  subtitle: 'Every file open on the beat, and yours in it.',
                  onTap: () => context.push(AppRoutes.magistrateCases),
                ),
                const SizedBox(height: 12),
                MoreMenuTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Profile and appearance',
                  subtitle: 'The account this handset uses, and how it looks.',
                  onTap: () => context.push(AppRoutes.magistrateProfile),
                ),
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
