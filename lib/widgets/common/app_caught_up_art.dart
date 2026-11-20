import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme/app_brand.dart';
import '../../config/theme/app_status_colors.dart';

/// "All caught up": an empty tray with a tick, drawn rather than shipped as
/// an asset so it follows the officer's scheme and dark mode.
class AppCaughtUpArt extends StatelessWidget {
  const AppCaughtUpArt({super.key, this.size = 76});

  final double size;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget art = CustomPaint(
      size: Size.square(size),
      painter: _CaughtUpPainter(
        brand: context.brand.primary,
        accent: context.brand.accent,
        tick: context.status.success,
        onTick: context.status.onSuccess,
        surface: theme.colorScheme.surface,
        dark: theme.brightness == Brightness.dark,
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return art;
    return art
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(
          begin: const Offset(0.7, 0.7),
          duration: 750.ms,
          curve: Curves.elasticOut,
        );
  }
}

class _CaughtUpPainter extends CustomPainter {
  _CaughtUpPainter({
    required this.brand,
    required this.accent,
    required this.tick,
    required this.onTick,
    required this.surface,
    required this.dark,
  });

  final Color brand;
  final Color accent;
  final Color tick;
  final Color onTick;
  final Color surface;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on a 100-unit grid.
    canvas.scale(size.width / 100, size.height / 100);

    final Paint line = Paint()
      ..color = brand
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(
      const Offset(50, 54),
      44,
      Paint()..color = brand.withValues(alpha: dark ? 0.16 : 0.09),
    );

    // The tray's back wall, slanting out to its rim.
    final Path back = Path()
      ..moveTo(31, 38)
      ..lineTo(69, 38)
      ..lineTo(78, 60)
      ..lineTo(22, 60)
      ..close();
    canvas.drawPath(back, Paint()..color = surface);
    canvas.drawPath(back, Paint()..color = brand.withValues(alpha: 0.10));
    canvas.drawPath(back, line);

    // The front, with the notch every inbox has.
    final Path front = Path()
      ..moveTo(22, 60)
      ..lineTo(38, 60)
      ..lineTo(42, 67)
      ..lineTo(58, 67)
      ..lineTo(62, 60)
      ..lineTo(78, 60)
      ..lineTo(78, 74)
      ..quadraticBezierTo(78, 80, 72, 80)
      ..lineTo(28, 80)
      ..quadraticBezierTo(22, 80, 22, 74)
      ..close();
    canvas.drawPath(front, Paint()..color = surface);
    canvas.drawPath(
      front,
      Paint()..color = brand.withValues(alpha: dark ? 0.30 : 0.22),
    );
    canvas.drawPath(front, line);

    // The tick, ringed in the surface so it sits on the tray, not in it.
    const Offset badge = Offset(72, 34);
    canvas.drawCircle(badge, 13.5, Paint()..color = surface);
    canvas.drawCircle(badge, 11, Paint()..color = tick);
    canvas.drawPath(
      Path()
        ..moveTo(66.8, 34.2)
        ..lineTo(70.4, 37.8)
        ..lineTo(77.2, 30.6),
      Paint()
        ..color = onTick
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    _sparkle(canvas, const Offset(25, 27), 6, accent);
    _sparkle(canvas, const Offset(41, 19), 3.5, brand.withValues(alpha: 0.55));
    canvas.drawCircle(const Offset(86, 56), 2.2, Paint()..color = accent);
  }

  /// A four-pointed star.
  void _sparkle(Canvas canvas, Offset c, double r, Color color) {
    final double w = r * 0.28;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx + w, c.dy - w, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx + w, c.dy + w, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx - w, c.dy + w, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx - w, c.dy - w, c.dx, c.dy - r)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _CaughtUpPainter old) =>
      old.brand != brand ||
      old.accent != accent ||
      old.tick != tick ||
      old.surface != surface ||
      old.dark != dark;
}
