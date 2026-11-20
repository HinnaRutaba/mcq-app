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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
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
            // Shrunk to the slot rather than wrapped: a bar this full gives a
            // long label less width than it wants, and a second line pushes
            // the whole bar taller. Never scaled up — a short label stays put.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: AppText.caption(
                entry.label,
                maxLines: 1,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : mutedColor,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
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
    final ThemeData theme = Theme.of(context);
    final double? gap = centerGap;
    final bool dark = theme.brightness == Brightness.dark;

    final Widget row = SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
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
      ),
    );

    return CustomPaint(
      painter: _BarPainter(
        notchWidth: gap,
        notchRadius: centerGapRadius,
        color: theme.colorScheme.surface,
        borderColor: theme.dividerColor,
        shadowColor: Colors.black.withValues(alpha: dark ? 0.45 : 0.08),
      ),
      // Transparent Material so the item ripples draw above the painted fill.
      child: Material(type: MaterialType.transparency, child: row),
    );
  }
}

/// Fills the bar, lifts it with a soft shadow and traces its edge — rounded
/// top corners, plus the notch when there is a center gap.
class _BarPainter extends CustomPainter {
  const _BarPainter({
    required this.notchWidth,
    required this.notchRadius,
    required this.color,
    required this.borderColor,
    required this.shadowColor,
  });

  final double? notchWidth;
  final double? notchRadius;
  final Color color;
  final Color borderColor;
  final Color shadowColor;

  static const ShapeBorder _host = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
  );

  Path _outline(Size size) {
    // Pushed just past the sides and bottom so the stroke only shows on top.
    final Rect host = Rect.fromLTRB(-1, 0, size.width + 1, size.height + 1);
    final double? width = notchWidth;
    if (width == null) return _host.getOuterPath(host);
    return AutomaticNotchedShape(
      _host,
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(notchRadius ?? width / 2),
      ),
    ).getOuterPath(
      host,
      Rect.fromCenter(
        center: Offset(size.width / 2, 0),
        width: width,
        height: width,
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = _outline(size);
    canvas
      ..drawPath(
        path.shift(const Offset(0, -2)),
        Paint()
          ..color = shadowColor
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      )
      ..drawPath(path, Paint()..color = color)
      ..drawPath(
        path,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.notchWidth != notchWidth ||
      old.notchRadius != notchRadius ||
      old.color != color ||
      old.borderColor != borderColor ||
      old.shadowColor != shadowColor;
}
