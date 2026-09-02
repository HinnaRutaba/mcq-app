import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../widgets/widgets.dart';
import '../shared/widgets/back_to_home_button.dart';
import 'widgets/more_menu_tile.dart';

/// The fifth tab: everything that is not a list of shops to walk to.
///
/// Home, Defaulters, Round and Find are the four things an officer does on a
/// beat, and they earn a permanent place on the bar. Imposing a fine, the seal
/// register and the officer's own account are all real work but none of them
/// is a destination somebody taps twenty times a day, so they live one tap
/// deeper rather than crowding the bar.
///
/// Imposing a fine sits at the top because it used to be the centre button.
/// It is also reached from a unit's profile, which is where it is normally
/// started — this is the entry for the case where the officer has the shop in
/// front of them and not on the screen.
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
                  icon: Icons.person_outline_rounded,
                  title: 'Profile and appearance',
                  subtitle: 'The account this handset uses, and how it looks.',
                  onTap: () => context.push(AppRoutes.magistrateProfile),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
