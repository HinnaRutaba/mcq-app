import 'package:flutter/widgets.dart';

/// Cuts a box along one curve, keeping the part on one side of it.
///
/// This is the app's only decorative clip. A card that wants depth stacks a
/// faint wash behind its content and clips it with this, so the light falls
/// across the card on a curve instead of in a straight band — a straight band
/// reads as a second panel, a curve reads as a surface.
///
/// Everything is a fraction of the box, so one sweep looks the same on a
/// 113pt tile and on a full-width card.
class AppSweepClipper extends CustomClipper<Path> {
  const AppSweepClipper({
    this.begin = 0.62,
    this.end = 0.26,
    this.bow = 0.18,
    this.above = false,
  });

  /// Where the curve meets the left edge, down the box.
  final double begin;

  /// Where it meets the right edge.
  final double end;

  /// How far the curve bellies past the straight line between the two.
  /// Positive sags, negative arches.
  final double bow;

  /// Keep what is over the curve rather than under it.
  final bool above;

  @override
  Path getClip(Size size) {
    final double w = size.width;
    final double h = size.height;
    final double control = h * ((begin + end) / 2 + bow);

    final Path path = Path()
      ..moveTo(0, h * begin)
      ..quadraticBezierTo(w / 2, control, w, h * end);

    if (above) {
      path
        ..lineTo(w, 0)
        ..lineTo(0, 0);
    } else {
      path
        ..lineTo(w, h)
        ..lineTo(0, h);
    }

    return path..close();
  }

  @override
  bool shouldReclip(AppSweepClipper old) =>
      begin != old.begin ||
      end != old.end ||
      bow != old.bow ||
      above != old.above;
}
