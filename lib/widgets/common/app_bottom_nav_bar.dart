import 'package:flutter/material.dart';

import '../motion/app_pressable.dart';

/// One destination in the bottom navigation bar.
class AppBottomNavEntry {
  const AppBottomNavEntry({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
  });

  final IconData icon;

  /// The filled twin of [icon]. The *shape* changes on selection, not only
  /// the colour — this has to read in greyscale and in sunlight.
  final IconData activeIcon;

  final String label;

  /// What has not reached the server yet is never hidden from the officer.
  final int badgeCount;
}

/// The app's bottom navigation.
///
/// A real Material 3 [NavigationBar]: it brings the selection indicator
/// that slides between destinations, the correct 48dp targets, the
/// semantics a screen reader needs ("tab 2 of 5, selected"), and the
/// platform's own handling of the system gesture inset — none of which a
/// hand-rolled `Row` of `InkWell`s had.
///
/// **Never icon-only.** Every entry carries an icon *and* a word, and the
/// theme pins `labelBehavior` to `alwaysShow` so no future edit can quietly
/// switch to labels-on-selection-only. This officer may not be a daily
/// smartphone user, and an unlabelled glyph is a guess he has to make while
/// somebody argues at his elbow.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.entries,
    required this.currentIndex,
    required this.onTap,
  });

  final List<AppBottomNavEntry> entries;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex.clamp(0, entries.length - 1),
        onDestinationSelected: (index) {
          // The bar answers the thumb even when the branch it opens takes a
          // moment to paint.
          AppHaptics.select();
          onTap(index);
        },
        destinations: [
          for (final entry in entries)
            NavigationDestination(
              icon: _WithBadge(
                count: entry.badgeCount,
                child: Icon(entry.icon),
              ),
              selectedIcon: _WithBadge(
                count: entry.badgeCount,
                child: Icon(entry.activeIcon),
              ),
              label: entry.label,
              tooltip: entry.label,
            ),
        ],
      ),
    );
  }
}

/// The unsynced count, on the destination it belongs to.
///
/// Material's own [Badge], so it inherits the theme's badge colours and
/// announces itself to a screen reader instead of being a decorative dot.
class _WithBadge extends StatelessWidget {
  const _WithBadge({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    return Badge(
      // Past ninety-nine the exact figure stops being information and
      // starts being a wide badge over the icon.
      label: Text(count > 99 ? '99+' : '$count'),
      child: child,
    );
  }
}
