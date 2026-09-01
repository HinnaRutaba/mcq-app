import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../controllers/api/offline_queue_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/widgets.dart';

/// The officer's app shell: the five things he does, in the order he does
/// them — see the beat, work the list, walk the round, find the unit in
/// front of him, and everything else.
///
/// **Never icon-only.** Every entry carries an icon *and* a word. This
/// officer may not be a daily smartphone user, and an unlabelled glyph is
/// a guess he has to make while somebody argues at his elbow.
class OfficerShell extends StatelessWidget {
  const OfficerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final queue = Get.find<OfflineQueueController>();

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Obx(
        () => AppBottomNavBar(
          currentIndex: navigationShell.currentIndex,
          onTap: _goBranch,
          entries: [
            AppBottomNavEntry(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: t('nav.home'),
            ),
            AppBottomNavEntry(
              icon: Icons.storefront_outlined,
              activeIcon: Icons.storefront_rounded,
              label: t('nav.defaulters'),
            ),
            AppBottomNavEntry(
              icon: Icons.directions_walk_outlined,
              activeIcon: Icons.directions_walk_rounded,
              label: t('nav.round'),
            ),
            AppBottomNavEntry(
              icon: Icons.search_outlined,
              activeIcon: Icons.search_rounded,
              label: t('nav.find'),
            ),
            AppBottomNavEntry(
              icon: Icons.more_horiz_outlined,
              activeIcon: Icons.more_horiz_rounded,
              label: t('nav.more'),
              // What has not synced is never hidden from the officer.
              badgeCount: queue.badgeCount,
            ),
          ],
        ),
      ),
    );
  }
}
