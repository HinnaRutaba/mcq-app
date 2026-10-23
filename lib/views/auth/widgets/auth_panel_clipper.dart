import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A rounded panel with a step cut out of its top-left and bottom-right
/// corners, every turn filleted — the brand panel on the wide sign-in screen.
///
/// The steps are fractions of the box, floored so the fillets always fit.
class AuthPanelClipper extends CustomClipper<Path> {
  const AuthPanelClipper({
    this.radius = 32,
    this.notchWidth = 0.2,
    this.notchHeight = 0.12,
  });

  final double radius;

  /// How far the steps reach in, as fractions of the box.
  final double notchWidth;
  final double notchHeight;

  @override
  Path getClip(Size size) {
    final double w = size.width;
    final double h = size.height;
    final double r = radius;
    final double nx = math.max(w * notchWidth, r * 2);
    final double ny = math.max(h * notchHeight, r * 2);
    final Radius round = Radius.circular(r);

    return Path()
      ..moveTo(nx + r, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: round)
      ..lineTo(w, h - ny - r)
      ..arcToPoint(Offset(w - r, h - ny), radius: round)
      ..lineTo(w - nx + r, h - ny)
      ..arcToPoint(Offset(w - nx, h - ny + r), radius: round, clockwise: false)
      ..lineTo(w - nx, h - r)
      ..arcToPoint(Offset(w - nx - r, h), radius: round)
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: round)
      ..lineTo(0, ny + r)
      ..arcToPoint(Offset(r, ny), radius: round)
      ..lineTo(nx - r, ny)
      ..arcToPoint(Offset(nx, ny - r), radius: round, clockwise: false)
      ..lineTo(nx, r)
      ..arcToPoint(Offset(nx + r, 0), radius: round)
      ..close();
  }

  @override
  bool shouldReclip(AuthPanelClipper old) =>
      radius != old.radius ||
      notchWidth != old.notchWidth ||
      notchHeight != old.notchHeight;
}
