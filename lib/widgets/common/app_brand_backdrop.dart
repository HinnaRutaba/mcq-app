import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme/app_brand.dart';

/// The full-bleed brand ground the splash and the auth screens stand on: the
/// header gradient, with soft waves and spheres drifting over it.
///
/// Painted from `context.brand` rather than from fixed colours, so it follows
/// the scheme the officer picked and goes dark with the rest of the app.
/// Everything is placed in fractions of the surface, so the same composition
/// holds on a small handset and on a tablet.
class AppBrandBackdrop extends StatelessWidget {
  const AppBrandBackdrop({super.key, this.child, this.drift = false});

  final Widget? child;

  /// Lets the waves and spheres drift on a slow loop. Off by default; the
  /// loop never settles, so it is for a ground that stays on screen.
  final bool drift;

  /// One full drift. Slow enough to read as ambient, not as a loader.
  static const Duration _cycle = Duration(seconds: 14);

  @override
  Widget build(BuildContext context) {
    final AppBrandColors brand = context.brand;
    final Brightness brightness = Theme.of(context).brightness;

    CustomPaint ground(double phase, Widget? content) => CustomPaint(
      painter: _BackdropPainter(
        brand: brand,
        brightness: brightness,
        phase: phase,
      ),
      isComplex: true,
      willChange: drift,
      child: content,
    );

    // Expanded rather than sized by the child: a `Column` is only as wide as
    // its widest line, and the ground has to reach the edges. Its own
    // boundary, so the drift repaints the ground and not what sits on it.
    final Widget content = SizedBox.expand(
      child: child == null ? null : RepaintBoundary(child: child),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[brand.headerFrom, brand.headerTo],
        ),
      ),
      child: RepaintBoundary(
        child: drift && !MediaQuery.disableAnimationsOf(context)
            ? content
                  .animate(onPlay: (AnimationController loop) => loop.repeat())
                  .custom(
                    duration: _cycle,
                    curve: Curves.linear,
                    builder: (_, double phase, Widget child) =>
                        ground(phase, child),
                  )
            : ground(0, content),
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter({
    required this.brand,
    required this.brightness,
    this.phase = 0,
  });

  final AppBrandColors brand;

  /// Where in the drift loop this frame is, 0 to 1. At 0 every shape is
  /// exactly where the still composition puts it.
  final double phase;

  /// A loop that is 0 at phase 0 and back to 0 at phase 1. [seed] sets
  /// where each shape is in its swing, so no two move in step.
  double _sway(double seed) =>
      math.sin(phase * 2 * math.pi + seed) - math.sin(seed);

  /// The dark scheme's ground is near-black, and white spheres on it glare.
  /// Everything pale is dimmed against it rather than redrawn.
  final Brightness brightness;

  double get _pale => brightness == Brightness.dark ? 0.45 : 1.0;

  /// How present the spheres are over the gradient — every sphere's alpha is
  /// scaled by this. The whole dial for how much they show.
  static const double _presence = 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    canvas.clipRect(Offset.zero & size);

    // Two sweeps out of the top-right, the paler one behind: a single band
    // reads as a fold in the gradient, a pair reads as water.
    _fill(canvas, Colors.white.withValues(alpha: 0.05), (Path p) {
      p
        ..moveTo(w * 0.58, 0)
        ..cubicTo(
          w * 0.74,
          h * (0.09 + 0.025 * _sway(0.4)),
          w * 0.84,
          h * 0.14,
          w,
          h * (0.31 + 0.02 * _sway(1.3)),
        )
        ..lineTo(w, 0)
        ..close();
    });
    _fill(canvas, Colors.white.withValues(alpha: 0.09), (Path p) {
      p
        ..moveTo(w * 0.36, 0)
        ..cubicTo(
          w * 0.57,
          h * 0.05,
          w * 0.63,
          h * (0.12 + 0.025 * _sway(2.1)),
          w,
          h * (0.18 + 0.015 * _sway(2.9)),
        )
        ..lineTo(w, 0)
        ..close();
    });

    // The long S down the left, and the shadow it lands in. Both are wide and
    // faint — this is ground for a crest to sit on, not a pattern.
    _fill(canvas, Colors.white.withValues(alpha: 0.045), (Path p) {
      p
        ..moveTo(0, h * 0.34)
        ..cubicTo(
          w * (0.34 + 0.04 * _sway(0.9)),
          h * 0.44,
          w * (0.04 + 0.04 * _sway(3.6)),
          h * 0.63,
          w * 0.44,
          h * 0.82,
        )
        ..cubicTo(w * 0.60, h * 0.90, w * 0.50, h * 0.96, w * 0.56, h)
        ..lineTo(0, h)
        ..close();
    });
    _fill(canvas, Colors.black.withValues(alpha: 0.12), (Path p) {
      p
        ..moveTo(0, h * 0.78)
        ..cubicTo(
          w * 0.28,
          h * (0.86 + 0.015 * _sway(4.4)),
          w * 0.52,
          h * (0.90 - 0.015 * _sway(5.1)),
          w,
          h * 0.83,
        )
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
    });

    // The spheres, lit from the top-left like the gradient behind them. They
    // keep to the edges: the middle of the screen belongs to the crest.
    _sphere(
      canvas,
      Offset(w * (0.14 + 0.03 * _sway(0.2)), h * (0.08 + 0.02 * _sway(1.8))),
      w * 0.21 * (1 + 0.03 * _sway(3.0)),
      Color.lerp(
        brand.headerTo,
        Colors.black,
        0.30,
      )!.withValues(alpha: 0.85 * _presence),
      Color.lerp(
        brand.headerTo,
        Colors.black,
        0.55,
      )!.withValues(alpha: 0.55 * _presence),
    );
    _sphere(
      canvas,
      Offset(w * (0.88 - 0.03 * _sway(2.4)), h * (0.12 + 0.025 * _sway(4.0))),
      w * 0.115 * (1 + 0.04 * _sway(0.7)),
      Colors.white.withValues(alpha: 0.80 * _pale * _presence),
      Colors.white.withValues(alpha: 0.28 * _pale * _presence),
    );
    _sphere(
      canvas,
      Offset(w * (0.11 + 0.035 * _sway(5.2)), h * (0.63 - 0.025 * _sway(0.5))),
      w * 0.075 * (1 + 0.05 * _sway(2.2)),
      Colors.white.withValues(alpha: 0.85 * _pale * _presence),
      Colors.white.withValues(alpha: 0.40 * _pale * _presence),
    );
    _sphere(
      canvas,
      Offset(w * (0.84 - 0.025 * _sway(3.3)), h * (0.92 - 0.02 * _sway(1.1))),
      w * 0.24 * (1 + 0.03 * _sway(4.7)),
      // The dark scheme's brand is a bright mint, so this one is dimmed with
      // the pale shapes rather than left to glow in the corner.
      brand.primary.withValues(alpha: 0.42 * _pale * _presence),
      Color.lerp(
        brand.primary,
        Colors.black,
        0.45,
      )!.withValues(alpha: 0.30 * _pale * _presence),
    );
  }

  void _fill(Canvas canvas, Color color, void Function(Path path) shape) {
    final Path path = Path();
    shape(path);
    canvas.drawPath(path, Paint()..color = color);
  }

  void _sphere(
    Canvas canvas,
    Offset center,
    double radius,
    Color light,
    Color dark,
  ) {
    // The cast shadow first, so the sphere sits on the ground rather than on
    // top of it.
    canvas.drawCircle(
      center.translate(radius * 0.10, radius * 0.14),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.10 * _presence)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.35),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.45),
          radius: 0.95,
          colors: <Color>[light, dark],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) =>
      oldDelegate.brand != brand ||
      oldDelegate.brightness != brightness ||
      oldDelegate.phase != phase;
}
