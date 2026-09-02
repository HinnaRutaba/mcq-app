import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../text/app_text.dart';
import '../../config/theme/app_radius.dart';

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
    final mutedColor = Theme.of(context).textTheme.bodySmall?.color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: selected ? 14 : 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? scheme.primary.withValues(alpha: 0.3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Icon(
                    selected ? entry.activeIcon : entry.icon,
                    color: selected ? scheme.primary : mutedColor,
                    size: 21,
                  ),
                ),
                if (entry.badgeCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: scheme.surface, width: 1.5),
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      child: Text(
                        '${entry.badgeCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            AppText.caption(
              entry.label,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : mutedColor,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ],
        ),
      ),
    );
  }
}

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.entries,
    required this.currentIndex,
    required this.onTap,
    this.centerGap,
    this.centerGapRadius,
  });

  final List<AppBottomNavEntry> entries;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Room left mid-row for a center-docked FAB. The notch is cut from the
  /// FAB's real geometry, so the scaffold also needs
  /// [FloatingActionButtonLocation.centerDocked] for the curve to appear.
  /// An even number of entries keeps the two sides the same width.
  final double? centerGap;

  /// Corner radius of the cut. Half of [centerGap] — the default — rounds it
  /// all the way into a semicircle; a smaller value squares it off to match a
  /// rounded-square button.
  final double? centerGapRadius;

  /// The gap a button of [size] needs — the notch comes out this wide, and
  /// sizing to the button alone lets the cut bite into the entries beside it.
  static double notchGapFor(double size) => size + _notchMargin * 2;

  /// The cut's corner radius for a button cornered at [buttonRadius]. Grown
  /// by the same margin as the gap, so the clearance stays even the whole way
  /// round the button instead of pinching at the corners.
  static double notchRadiusFor(double buttonRadius) =>
      buttonRadius + _notchMargin;

  static const double _notchMargin = 8;

  @override
  Widget build(BuildContext context) {
    final double? gap = centerGap;
    final Color surface = Theme.of(context).colorScheme.surface;

    final Widget row = SafeArea(
      top: false,
      child: Row(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (gap != null && i == entries.length ~/ 2) SizedBox(width: gap),
            Expanded(
              child: AppBottomNavItem(
                entry: entries[i],
                selected: i == currentIndex,
                onTap: () => onTap(i),
              ),
            ),
          ],
        ],
      ),
    );

    if (gap == null) {
      return Container(
        decoration: BoxDecoration(
          color: surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: row,
      );
    }

    return PhysicalShape(
      clipper: _NotchClipper(width: gap, radius: centerGapRadius),
      color: surface,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      child: row,
    );
  }
}

class _NotchClipper extends CustomClipper<Path> {
  const _NotchClipper({required this.width, this.radius});

  final double width;
  final double? radius;

  @override
  Path getClip(Size size) =>
      AutomaticNotchedShape(
        const RoundedRectangleBorder(),
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius ?? width / 2),
        ),
      ).getOuterPath(
        Offset.zero & size,
        Rect.fromCenter(
          center: Offset(size.width / 2, 0),
          width: width,
          height: width,
        ),
      );

  @override
  bool shouldReclip(_NotchClipper oldClipper) =>
      oldClipper.width != width || oldClipper.radius != radius;
}
