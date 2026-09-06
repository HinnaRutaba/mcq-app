import 'package:flutter/material.dart';

import '../../config/theme/app_brand.dart';

/// The full-bleed brand ground the splash and the auth screens stand on: the
/// header gradient, with soft waves and spheres drifting over it.
///
/// Painted from `context.brand` rather than from fixed colours, so it follows
/// the scheme the officer picked and goes dark with the rest of the app.
/// Everything is placed in fractions of the surface, so the same composition
/// holds on a small handset and on a tablet.
class AppBrandBackdrop extends StatelessWidget {
  const AppBrandBackdrop({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final AppBrandColors brand = context.brand;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[brand.headerFrom, brand.headerTo],
        ),
      ),
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _BackdropPainter(
            brand: brand,
            brightness: Theme.of(context).brightness,
          ),
          isComplex: true,
          willChange: false,
          // Expanded rather than sized by the child: a `Column` is only as
          // wide as its widest line, and the ground has to reach the edges.
          child: SizedBox.expand(child: child),
        ),
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter({required this.brand, required this.brightness});

  final AppBrandColors brand;

  /// The dark scheme's ground is near-black, and white spheres on it glare.
  /// Everything pale is dimmed against it rather than redrawn.
  final Brightness brightness;

  double get _pale => brightness == Brightness.dark ? 0.45 : 1.0;

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
        ..cubicTo(w * 0.74, h * 0.09, w * 0.84, h * 0.14, w, h * 0.31)
        ..lineTo(w, 0)
        ..close();
    });
    _fill(canvas, Colors.white.withValues(alpha: 0.09), (Path p) {
      p
        ..moveTo(w * 0.36, 0)
        ..cubicTo(w * 0.57, h * 0.05, w * 0.63, h * 0.12, w, h * 0.18)
        ..lineTo(w, 0)
        ..close();
    });

    // The long S down the left, and the shadow it lands in. Both are wide and
    // faint — this is ground for a crest to sit on, not a pattern.
    _fill(canvas, Colors.white.withValues(alpha: 0.045), (Path p) {
      p
        ..moveTo(0, h * 0.34)
        ..cubicTo(w * 0.34, h * 0.44, w * 0.04, h * 0.63, w * 0.44, h * 0.82)
        ..cubicTo(w * 0.60, h * 0.90, w * 0.50, h * 0.96, w * 0.56, h)
        ..lineTo(0, h)
        ..close();
    });
    _fill(canvas, Colors.black.withValues(alpha: 0.12), (Path p) {
      p
        ..moveTo(0, h * 0.78)
        ..cubicTo(w * 0.28, h * 0.86, w * 0.52, h * 0.90, w, h * 0.83)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
    });

    // The spheres, lit from the top-left like the gradient behind them. They
    // keep to the edges: the middle of the screen belongs to the crest.
    _sphere(
      canvas,
      Offset(w * 0.14, h * 0.08),
      w * 0.21,
      Color.lerp(brand.headerTo, Colors.black, 0.30)!.withValues(alpha: 0.85),
      Color.lerp(brand.headerTo, Colors.black, 0.55)!.withValues(alpha: 0.55),
    );
    _sphere(
      canvas,
      Offset(w * 0.88, h * 0.12),
      w * 0.115,
      Colors.white.withValues(alpha: 0.80 * _pale),
      Colors.white.withValues(alpha: 0.28 * _pale),
    );
    _sphere(
      canvas,
      Offset(w * 0.11, h * 0.63),
      w * 0.075,
      Colors.white.withValues(alpha: 0.85 * _pale),
      Colors.white.withValues(alpha: 0.40 * _pale),
    );
    _sphere(
      canvas,
      Offset(w * 0.84, h * 0.92),
      w * 0.24,
      // The dark scheme's brand is a bright mint, so this one is dimmed with
      // the pale shapes rather than left to glow in the corner.
      brand.primary.withValues(alpha: 0.42 * _pale),
      Color.lerp(
        brand.primary,
        Colors.black,
        0.45,
      )!.withValues(alpha: 0.30 * _pale),
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
        ..color = Colors.black.withValues(alpha: 0.10)
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
      oldDelegate.brand != brand || oldDelegate.brightness != brightness;
}
