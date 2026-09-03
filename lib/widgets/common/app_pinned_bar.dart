import 'package:flutter/material.dart';

class AppPinnedBar extends StatelessWidget {
  const AppPinnedBar({super.key, required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SliverPersistentHeader(
      pinned: true,
      delegate: _PinnedBarDelegate(
        height: height,
        background: theme.scaffoldBackgroundColor,
        divider: theme.dividerColor,
        child: child,
      ),
    );
  }
}

class _PinnedBarDelegate extends SliverPersistentHeaderDelegate {
  const _PinnedBarDelegate({
    required this.height,
    required this.background,
    required this.divider,
    required this.child,
  });

  final double height;
  final Color background;
  final Color divider;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    // Opaque, or the rows would read straight through the bar they pass under.
    // `DecoratedBox` rather than `Container`: a container insets its child by
    // the border, so the hairline arriving would shift the bar by a pixel.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        // Only once there are rows behind it — over the page's own background
        // it would be a line drawn under nothing.
        border: overlaps ? Border(bottom: BorderSide(color: divider)) : null,
      ),
      // Clipped, so a bar that comes out taller than [height] — a big text
      // scale on the picker — is cut rather than painted over the rows.
      child: ClipRect(
        child: SizedBox(height: height, child: child),
      ),
    );
  }

  @override
  bool shouldRebuild(_PinnedBarDelegate old) =>
      height != old.height ||
      background != old.background ||
      divider != old.divider ||
      child != old.child;
}
