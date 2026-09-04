import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../config/theme/app_brand.dart';
import '../text/app_text.dart';
import 'app_hero_ornament.dart';
import '../../config/theme/app_radius.dart';

class AppSliverHeroHeader extends StatelessWidget {
  const AppSliverHeroHeader({
    super.key,
    required this.title,
    required this.expandedHeight,
    this.subtitle,
    this.leading,
    this.trailing,
    this.bottom,
    this.bottomSpacing,
    this.compactTitle = false,
  });

  /// The one thing that survives the collapse.
  final String title;

  final double expandedHeight;
  final String? subtitle;
  final Widget? leading;

  final Widget? trailing;

  final Widget? bottom;

  /// The gap between the title and [bottom], which then rides under the title
  /// rather than sitting on the header's bottom edge.
  ///
  /// Null keeps [bottom] pinned to that edge, where the gap is whatever
  /// [expandedHeight] leaves over and has to be tuned through it.
  final double? bottomSpacing;

  final bool compactTitle;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _HeroHeaderDelegate(
        title: title,
        subtitle: subtitle,
        leading: leading,
        trailing: trailing,
        bottom: bottom,
        bottomSpacing: bottomSpacing,
        compactTitle: compactTitle,
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
    required this.leading,
    required this.trailing,
    required this.bottom,
    required this.bottomSpacing,
    required this.compactTitle,
    required this.expandedHeight,
    required this.topPadding,
    required this.brand,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? bottom;
  final double? bottomSpacing;
  final bool compactTitle;
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

    // Faded out it is still there, and `Opacity` does not stop a tap: without
    // this, a press on the collapsed toolbar lands on an invisible search box
    // and raises the keyboard.
    final Widget? faded = bottom == null
        ? null
        : IgnorePointer(
            ignoring: fade == 0,
            child: Opacity(opacity: fade, child: bottom!),
          );

    // Whether [bottom] rides under the title instead of on the bottom edge.
    final bool stacked = faded != null && bottomSpacing != null;

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
                left: leading == null ? 20 : 58,
                right: 76,
                top: topPadding + 16,
                child: Opacity(
                  opacity: fade,
                  child: AppText.body(
                    subtitle!,
                    color: Colors.white.withValues(alpha: 0.75),
                    maxLines: 1,
                  ),
                ),
              ),
            if (bottom != null && !stacked)
              Positioned(left: 20, right: 20, bottom: 20, child: faded!),
            // Unless [compactTitle] says otherwise this is headline-sized,
            // because expanded it is the hero's subject — who the handset is
            // acting as — not an app-bar label. It travels from under the
            // subtitle onto the toolbar line, shrinking to a title on the way
            // rather than cutting between two sizes.
            Positioned(
              left: 20,
              // Stacked, the block runs the full width and the title keeps the
              // trailing button's corner clear on its own.
              right: stacked ? 20 : 76,
              top: lerpDouble(
                topPadding + (subtitle == null ? 16 : 36),
                topPadding + (compactTitle ? 16 : 17),
                t,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(right: stacked ? 56 : 0),
                    child: Row(
                      children: <Widget>[
                        if (leading != null) ...<Widget>[
                          leading!,
                          const SizedBox(width: 6),
                        ],
                        Expanded(child: _title(t)),
                      ],
                    ),
                  ),
                  if (stacked) ...<Widget>[
                    SizedBox(height: bottomSpacing),
                    faded,
                  ],
                ],
              ),
            ),
            if (trailing != null)
              Positioned(right: 20, top: topPadding + 7, child: trailing!),
          ],
        ),
      ),
    );
  }

  /// A compact title is already the size it collapses to, so it neither
  /// scales nor moves — the bar shrinks around it.
  Widget _title(double t) {
    if (compactTitle) {
      return AppText.titleLarge(title, color: Colors.white, maxLines: 1);
    }
    return Transform.scale(
      scale: lerpDouble(1, 0.8, t)!,
      alignment: Alignment.centerLeft,
      child: AppText.headlineLarge(title, color: Colors.white, maxLines: 1),
    );
  }

  @override
  bool shouldRebuild(_HeroHeaderDelegate old) =>
      title != old.title ||
      subtitle != old.subtitle ||
      leading != old.leading ||
      bottom != old.bottom ||
      bottomSpacing != old.bottomSpacing ||
      compactTitle != old.compactTitle ||
      trailing != old.trailing ||
      expandedHeight != old.expandedHeight ||
      topPadding != old.topPadding ||
      brand != old.brand;
}
