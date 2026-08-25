import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/widgets.dart';

/// Tenant app shell: persistent bottom nav (Home, Payments, Profile) around
/// the [navigationShell]'s three branches.
class TenantShell extends StatelessWidget {
  const TenantShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _entries = [
    AppBottomNavEntry(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    AppBottomNavEntry(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Payments',
    ),
    AppBottomNavEntry(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        entries: _entries,
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
