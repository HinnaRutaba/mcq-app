import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../config/theme/app_brand.dart';
import '../text/app_text.dart';
import 'app_hero_ornament.dart';
import '../../config/theme/app_radius.dart';

/// The collapsing counterpart to [AppHeroHeader], for a screen built out of
/// slivers.
///
/// Expanded it is the full block — who is signed in, and whatever [bottom]
/// carries. Scrolled, everything but [title] fades out and the bar shrinks to
/// a pinned toolbar with the name on it, so the officer always knows which
/// account the handset is acting under without giving up a fifth of the screen
/// to say so.
///
/// [expandedHeight] is the caller's to give, because only the caller knows how
/// tall [bottom] is: a persistent header has to state its extents up front and
/// cannot measure a child to find out.
class AppSliverHeroHeader extends StatelessWidget {
  const AppSliverHeroHeader({
    super.key,
    required this.title,
    required this.expandedHeight,
    this.subtitle,
    this.trailing,
    this.bottom,
  });

  /// The one thing that survives the collapse.
  final String title;

  final double expandedHeight;
  final String? subtitle;
  final Widget? trailing;

  /// The block under the title — a scope strip, a headline figure. Gone once
  /// the bar is collapsed.
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _HeroHeaderDelegate(
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        bottom: bottom,
        expandedHeight: expandedHeight,
        topPadding: MediaQuery.paddingOf(context).top,
        brand: context.brand,
      ),
    );
  }
}

/// The corner the bar keeps in both states.
const double _lipRadius = AppRadius.xl;

class _HeroHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _HeroHeaderDelegate({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.bottom,
    required this.expandedHeight,
    required this.topPadding,
    required this.brand,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? bottom;
  final double expandedHeight;
  final double topPadding;
  final AppBrandColors brand;

  @override
  double get minExtent => topPadding + kToolbarHeight;

  @override
  double get maxExtent => topPadding + expandedHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final range = maxExtent - minExtent;
    final t = range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);

    // The extras go before the bar finishes collapsing, so the last stretch of
    // the scroll is a clean toolbar rather than ghost text over it.
    final fade = (1 - t * 1.8).clamp(0.0, 1.0);

    // The lip is clipped, not just painted: the ornament sits past the
    // bottom-right corner and has to be cut by the same curve.
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(_lipRadius),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[brand.headerFrom, brand.headerTo],
          ),
        ),
        child: Stack(
          children: <Widget>[
            // Pinned to the bottom edge, so it rides up with the bar as the
            // officer scrolls — and goes with the rest of the expanded block,
            // slower than the text does. Held on, it would end up drawing
            // rings around the notification button on the collapsed toolbar.
            Positioned(
              right: -26,
              bottom: -44,
              child: Opacity(opacity: 1 - t, child: const AppHeroOrnament()),
            ),
            if (subtitle != null)
              Positioned(
                left: 20,
                right: 76,
                top: topPadding + 18,
                child: Opacity(
                  opacity: fade,
                  child: AppText.body(
                    subtitle!,
                    color: Colors.white.withValues(alpha: 0.75),
                    maxLines: 1,
                  ),
                ),
              ),
            if (bottom != null)
              Positioned(
                left: 20,
                right: 20,
                bottom: 22,
                child: Opacity(opacity: fade, child: bottom!),
              ),
            // The name travels from under the subtitle up onto the toolbar
            // line, and shrinks on the way rather than cutting between two
            // sizes.
            Positioned(
              left: 20,
              right: 76,
              top: lerpDouble(
                topPadding + (subtitle == null ? 18 : 41),
                topPadding + 15,
                t,
              ),
              child: Transform.scale(
                scale: lerpDouble(1, 0.92, t)!,
                alignment: Alignment.centerLeft,
                child: AppText.titleLarge(
                  title,
                  color: Colors.white,
                  maxLines: 1,
                ),
              ),
            ),
            if (trailing != null)
              Positioned(right: 20, top: topPadding + 7, child: trailing!),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_HeroHeaderDelegate old) =>
      title != old.title ||
      subtitle != old.subtitle ||
      bottom != old.bottom ||
      trailing != old.trailing ||
      expandedHeight != old.expandedHeight ||
      topPadding != old.topPadding ||
      brand != old.brand;
}
