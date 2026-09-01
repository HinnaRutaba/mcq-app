import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes/app_routes.dart';
import '../../controllers/seal_controller.dart';
import '../../widgets/widgets.dart';

/// Magistrate app shell: Home / Collections / Sealed / Profile on a neutral
/// bar, notched around a center FAB (opens "Create Chalaan/Fine").
class MagistrateShell extends StatelessWidget {
  const MagistrateShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final sealController = Get.find<SealController>();

    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.createChalaan),
        tooltip: 'Create Chalaan/Fine',
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        child: const Icon(Icons.add_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).colorScheme.surface,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            Expanded(
              child: AppBottomNavItem(
                entry: const AppBottomNavEntry(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                ),
                selected: navigationShell.currentIndex == 0,
                onTap: () => _goBranch(0),
              ),
            ),
            Expanded(
              child: AppBottomNavItem(
                entry: const AppBottomNavEntry(
                  icon: Icons.location_on_outlined,
                  activeIcon: Icons.location_on_rounded,
                  label: 'Collect',
                ),
                selected: navigationShell.currentIndex == 1,
                onTap: () => _goBranch(1),
              ),
            ),
            const SizedBox(width: 48),
            Expanded(
              child: Obx(
                () => AppBottomNavItem(
                  entry: AppBottomNavEntry(
                    icon: Icons.lock_outline_rounded,
                    activeIcon: Icons.lock_rounded,
                    label: 'Sealed',
                    badgeCount: sealController.readyToUnsealCount,
                  ),
                  selected: navigationShell.currentIndex == 2,
                  onTap: () => _goBranch(2),
                ),
              ),
            ),
            Expanded(
              child: AppBottomNavItem(
                entry: const AppBottomNavEntry(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                ),
                selected: navigationShell.currentIndex == 3,
                onTap: () => _goBranch(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
