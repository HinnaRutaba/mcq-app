import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../config/theme/app_theme.dart';

/// Skeleton loaders, never spinners, on every list and dashboard.
///
/// The shape of the content appears immediately and a highlight sweeps
/// across it, so the officer knows *what* is coming and roughly how much of
/// it. A spinner on a bazaar connection tells him only that the app is not
/// broken yet.
///
/// The sweep is one [Shimmer] wrapped around the whole placeholder rather
/// than one per bar — a single shader pass for a screenful of shapes, and,
/// more importantly, one wave crossing the screen instead of nine bars
/// pulsing out of step, which reads as broken rather than as loading.
class AppShimmer extends StatelessWidget {
  const AppShimmer({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      // Dark needs more separation than light: at 5% white on a near-black
      // card the placeholder shapes are invisible at rest, so the skeleton
      // stops describing the shape of what is coming and becomes a blank
      // rectangle — which is the thing it exists to avoid.
      baseColor: dark
          ? Colors.white.withValues(alpha: 0.09)
          : Colors.black.withValues(alpha: 0.055),
      highlightColor: dark
          ? Colors.white.withValues(alpha: 0.20)
          : Colors.black.withValues(alpha: 0.028),
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

/// One shape in a placeholder. Always drawn inside an [AppShimmer].
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  /// A line of text.
  const AppSkeleton.line({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.radius = 7,
  });

  const AppSkeleton.block({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = 14,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        // Shimmer paints its gradient over whatever is opaque underneath,
        // so the fill only has to exist — its colour comes from the sweep.
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// An outlined box with nothing opaque in it but the placeholder shapes.
///
/// [Shimmer] paints its gradient over **everything opaque underneath it**,
/// so a placeholder built inside a filled card comes out as one solid
/// rectangle: the card's own surface swallows the shapes, and the skeleton
/// stops describing the content it is standing in for. The frame is drawn
/// as a border only, and the shapes are the sole fill.
class _SkeletonFrame extends StatelessWidget {
  const _SkeletonFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppShape.card),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: child,
    );
  }
}

/// The shape of a field card while it loads — a name, a place, an amount
/// and a strip of pills.
class AppSkeletonCard extends StatelessWidget {
  const AppSkeletonCard({super.key, this.shimmer = true});

  /// False when the caller already wraps a whole list in one [AppShimmer].
  final bool shimmer;

  @override
  Widget build(BuildContext context) {
    final body = _SkeletonFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton.line(width: 150, height: 18),
                    SizedBox(height: 10),
                    AppSkeleton.line(width: 190),
                    SizedBox(height: 8),
                    AppSkeleton.line(width: 120),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppSkeleton.line(width: 110, height: 22),
                  SizedBox(height: 8),
                  AppSkeleton.line(width: 70),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              AppSkeleton(width: 92, height: 28, radius: AppShape.pill),
              SizedBox(width: 8),
              AppSkeleton(width: 108, height: 28, radius: AppShape.pill),
            ],
          ),
        ],
      ),
    );
    return shimmer ? AppShimmer(child: body) : body;
  }
}

/// A column of skeleton cards, for a list that has not answered yet.
class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            // Each one a little fainter, so the list reads as continuing
            // below the fold rather than ending.
            Opacity(
              opacity: 1 - (i * 0.16).clamp(0.0, 0.6),
              child: const AppSkeletonCard(shimmer: false),
            ),
          ],
        ],
      ),
    );
  }
}

/// The shape of a two-column dashboard while it loads: six stat tiles.
class AppSkeletonGrid extends StatelessWidget {
  const AppSkeletonGrid({
    super.key,
    this.count = 6,
    this.columns = 2,
    this.gap = 12,
    // The same extent the real grid uses. A skeleton whose tiles are a
    // different height from the tiles that replace them makes the whole
    // page jump when the data lands — which is worse than a spinner.
    this.tileHeight = 246,
  });

  final int count;
  final int columns;
  final double gap;
  final double tileHeight;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width =
              (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < count; i++)
                SizedBox(
                  width: width,
                  height: tileHeight,
                  child: _SkeletonFrame(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppSkeleton(width: 40, height: 40, radius: 12),
                        const Spacer(),
                        const AppSkeleton.line(width: 74, height: 28),
                        const SizedBox(height: 10),
                        const AppSkeleton.line(width: 110),
                        const SizedBox(height: 6),
                        const AppSkeleton.line(width: 84),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// The shape of a chart while its figures load.
class AppSkeletonChart extends StatelessWidget {
  const AppSkeletonChart({super.key, this.height = 180});

  final double height;

  @override
  Widget build(BuildContext context) {
    // Bars of uneven height, because a row of identical bars reads as a
    // rendered chart with bad data rather than as a placeholder.
    const heights = [0.45, 0.8, 0.6, 1.0, 0.35, 0.7, 0.5];
    return AppShimmer(
      child: _SkeletonFrame(
        child: SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < heights.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: AppSkeleton(
                    width: double.infinity,
                    height: height * heights[i],
                    radius: 6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
