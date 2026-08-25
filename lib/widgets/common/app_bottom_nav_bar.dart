import 'package:flutter/material.dart';

import '../text/app_text.dart';

/// One destination in a bottom nav bar.
class AppBottomNavEntry {
  const AppBottomNavEntry({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;
}

/// A single nav destination's icon/label — the piece shared by the plain
/// [AppBottomNavBar] (Tenant, no FAB) and a role shell's custom notched
/// `BottomAppBar` layout (Magistrate, center FAB), so both roles' bottom
/// nav look identical even though their container layouts differ.
class AppBottomNavItem extends StatelessWidget {
  const AppBottomNavItem({
    super.key,
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final AppBottomNavEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : Theme.of(context).textTheme.bodySmall?.color;

    return InkWell(
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(selected ? entry.activeIcon : entry.icon, color: color, size: 24),
                if (entry.badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      child: Text(
                        '${entry.badgeCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            AppText.caption(
              entry.label,
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ],
        ),
      ),
    );
  }
}

/// The plain (no-FAB) bottom nav bar — used by the Tenant shell.
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < entries.length; i++)
                Expanded(
                  child: AppBottomNavItem(
                    entry: entries[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
