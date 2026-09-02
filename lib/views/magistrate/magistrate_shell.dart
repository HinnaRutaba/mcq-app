import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/widgets.dart';
import 'shared/widgets/back_to_home_button.dart';
import 'shared/widgets/create_fine_button.dart';

class MagistrateShell extends StatelessWidget {
  const MagistrateShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Even by necessity: the create button's gap splits the row in half.
  static const List<AppBottomNavEntry> entries = <AppBottomNavEntry>[
    AppBottomNavEntry(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    AppBottomNavEntry(
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront_rounded,
      label: 'Defaulters',
    ),
    AppBottomNavEntry(
      icon: Icons.directions_walk_outlined,
      activeIcon: Icons.directions_walk_rounded,
      label: 'Round',
    ),
    AppBottomNavEntry(
      icon: Icons.more_horiz_outlined,
      activeIcon: Icons.more_horiz_rounded,
      label: 'More',
    ),
  ];

  /// Tapping the tab you are already on returns that branch to its first
  /// screen — the way back out of a shop's profile without hunting for a
  /// back arrow.
  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final onHome = navigationShell.currentIndex == BackToHomeButton.homeBranch;

    return PopScope(
      canPop: onHome,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _goBranch(BackToHomeButton.homeBranch);
      },
      child: Scaffold(
        body: navigationShell,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: const CreateFineButton(),
        bottomNavigationBar: AppBottomNavBar(
          entries: entries,
          currentIndex: navigationShell.currentIndex,
          onTap: _goBranch,
          centerGap: CreateFineButton.notchGap,
          centerGapRadius: CreateFineButton.notchRadius,
        ),
      ),
    );
  }
}
