import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes/app_routes.dart';
import '../../controllers/seal_controller.dart';
import '../../widgets/widgets.dart';

/// Magistrate app shell: Home / Collections / Sealed / Profile, with the
/// one thing a magistrate does most — raise a chalaan — on an extended
/// floating action button rather than buried a screen deep.
///
/// The FAB is **extended and labelled**, not a bare `+`. A plus sign asks
/// the officer to guess what it adds; "New chalaan" tells him. It docks to
/// the end rather than notching the centre of the bar, because a notch
/// steals the middle destination's label and this bar never goes
/// icon-only.
class MagistrateShell extends StatelessWidget {
  const MagistrateShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sealController = Get.find<SealController>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          AppHaptics.select();
          context.push(AppRoutes.createChalaan);
        },
        // Gold carries dark text, always.
        backgroundColor: scheme.secondary,
        foregroundColor: scheme.onSecondary,
        icon: const Icon(Icons.receipt_long_rounded),
        label: const Text('New chalaan'),
      ),
      bottomNavigationBar: Obx(
        () => AppBottomNavBar(
          currentIndex: navigationShell.currentIndex,
          onTap: _goBranch,
          entries: [
            const AppBottomNavEntry(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Home',
            ),
            const AppBottomNavEntry(
              icon: Icons.location_on_outlined,
              activeIcon: Icons.location_on_rounded,
              label: 'Collect',
            ),
            AppBottomNavEntry(
              icon: Icons.lock_outline_rounded,
              activeIcon: Icons.lock_rounded,
              label: 'Sealed',
              badgeCount: sealController.readyToUnsealCount,
            ),
            const AppBottomNavEntry(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
