import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';

/// The deep-green band a screen opens with, as a **collapsing
/// [SliverAppBar]**.
///
/// It is a sliver rather than the first item of a `ListView` for a reason
/// that matters on a 5-inch handset: as the officer scrolls into the work,
/// the greeting collapses into a compact bar that keeps his name and his
/// actions pinned, instead of scrolling a fifth of the screen away and
/// leaving him with no title at all. That is one gesture's worth of screen
/// recovered on every list in the app.
///
/// The gradient carries a slow ambient glow — two soft lights drifting
/// behind the content, painted rather than animated with widgets so it
/// costs one repaint of a single layer. It is slow enough to be felt rather
/// than watched, and it sits behind everything, so it never competes with a
/// figure the officer is reading.
class AppGradientSliverHeader extends StatefulWidget {
  const AppGradientSliverHeader({
    super.key,
    required this.expanded,
    required this.collapsedTitle,
    this.actions = const [],
    this.leading,
    this.expandedHeight = 210,
    this.bottom,
  });

  /// The full-height content — a greeting, a name, a row of chips.
  final Widget expanded;

  /// What is left once it has collapsed: the officer's name, typically.
  final Widget collapsedTitle;

  final List<Widget> actions;
  final Widget? leading;
  final double expandedHeight;

  /// A pinned strip below the bar — a search field, a tab bar.
  final PreferredSizeWidget? bottom;

  @override
  State<AppGradientSliverHeader> createState() =>
      _AppGradientSliverHeaderState();
}

class _AppGradientSliverHeaderState extends State<AppGradientSliverHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    const onBand = Colors.white;

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: widget.expandedHeight,
      collapsedHeight: 64,
      backgroundColor:
          dark ? const Color(0xFF11301F) : AppColors.primaryDark,
      surfaceTintColor: Colors.transparent,
      foregroundColor: onBand,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: widget.leading,
      automaticallyImplyLeading: widget.leading != null,
      actions: widget.actions,
      iconTheme: const IconThemeData(color: onBand),
      actionsIconTheme: const IconThemeData(color: onBand),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      bottom: widget.bottom,
      flexibleSpace: FlexibleSpaceBar(
        // Material fades the title in as the bar collapses and out as it
        // expands, so the officer's name is never drawn twice at once.
        titlePadding: const EdgeInsetsDirectional.fromSTEB(56, 0, 56, 16),
        title: DefaultTextStyle.merge(
          style: const TextStyle(color: onBand),
          child: widget.collapsedTitle,
        ),
        centerTitle: false,
        collapseMode: CollapseMode.parallax,
        background: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: dark
                  ? const [Color(0xFF16402A), Color(0xFF0A1A11)]
                  : const [AppColors.primaryLight, AppColors.primaryDark],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _drift,
                    builder: (context, _) => CustomPaint(
                      painter: AppAmbientGlowPainter(
                        phase: _drift.value,
                        accent: AppColors.accent,
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 22),
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(color: onBand),
                    child: widget.expanded,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The same band, not collapsing — for a screen that is not a scroll view.
class AppGradientBand extends StatelessWidget {
  const AppGradientBand({
    super.key,
    required this.child,
    this.padding = const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 24),
    this.radius = 28,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: dark
                ? const [Color(0xFF16402A), Color(0xFF0A1A11)]
                : const [AppColors.primaryLight, AppColors.primaryDark],
          ),
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              top: MediaQuery.paddingOf(context).top,
            ).add(padding),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Two soft lights drifting behind a gradient band, one gold and one a
/// lighter green.
///
/// Painted rather than built out of widgets so the whole effect costs one
/// repaint of a single layer, inside a `RepaintBoundary`, and never
/// invalidates the officer's name or his figures above it.
class AppAmbientGlowPainter extends CustomPainter {
  AppAmbientGlowPainter({required this.phase, required this.accent});

  final double phase;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final angle = phase * math.pi * 2;

    void glow(Offset centre, double radius, Color colour) {
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [colour, colour.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: centre, radius: radius)),
      );
    }

    glow(
      Offset(
        size.width * (0.78 + 0.08 * math.cos(angle)),
        size.height * (0.20 + 0.12 * math.sin(angle)),
      ),
      size.width * 0.42,
      accent.withValues(alpha: 0.16),
    );
    glow(
      Offset(
        size.width * (0.14 + 0.10 * math.sin(angle * 0.7)),
        size.height * (0.86 + 0.08 * math.cos(angle * 0.7)),
      ),
      size.width * 0.36,
      const Color(0xFF56B98C).withValues(alpha: 0.18),
    );
  }

  @override
  bool shouldRepaint(covariant AppAmbientGlowPainter old) =>
      old.phase != phase || old.accent != accent;
}
