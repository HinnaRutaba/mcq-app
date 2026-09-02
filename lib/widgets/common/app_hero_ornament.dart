import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../config/theme/app_brand.dart';

/// The soft geometry scattered across a hero header.
///
/// Outlines only — rings and tilted squares drawn as thin strokes, never
/// filled. A filled shape on a gradient reads as a panel someone forgot to put
/// content in; a stroke reads as ornament, which is all this is.
///
/// The group starts in the bottom-right corner, where the shapes are biggest,
/// sharpest and closest together, and breaks apart as it travels left: each one
/// further out is smaller, fainter and blurred harder, until the last is barely
/// there. It keeps to the lower band of the header on the way, because the
/// title sits top-left and outlines drifting up under it read as dirt on the
/// screen rather than as ornament.
///
/// Nothing here carries meaning — it exists so the header has something to
/// look at — which is why it is always the *first* child of the header's
/// stack, behind the title and whatever else the header carries.
class AppHeroOrnament extends StatelessWidget {
  const AppHeroOrnament({super.key});

  /// The cluster's footprint, measured from the corner it is pinned to. Wide
  /// and shallow: the drift needs the width to break up over, and everything
  /// above this band belongs to the title.
  static const Size size = Size(300, 190);

  /// The corner the arcs ripple out from, in cluster coordinates. Sharing one
  /// centre is what keeps them from crossing: concentric circles never do, so
  /// three of them stack up in the corner without a single stroke collision.
  static const double _originRight = 35;
  static const double _originBottom = 25;

  @override
  Widget build(BuildContext context) {
    final white = Colors.white;

    return RepaintBoundary(
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            // Three arcs off the same centre, just past the corner. Most of
            // each one is outside the header, so what shows is a sweep running
            // out of the corner rather than circles sitting in it.
            _arc(radius: 62, stroke: 1.2, blur: 2, color: white, alpha: 0.28),
            _arc(radius: 105, stroke: 1.2, blur: 3, color: white, alpha: 0.34),
            _arc(radius: 155, stroke: 1, blur: 4.5, color: white, alpha: 0.18),

            // Past the last arc the group breaks up, staying low as it
            // travels left so it never climbs into the title.

            // The warm note — dim, and out in the drift rather than in the
            // corner, so the scheme's accent tints the header instead of
            // announcing itself on it.
            _Outline(
              right: 193,
              bottom: 83,
              side: 44,
              radius: 22,
              stroke: 1,
              blur: 2,
              color: context.brand.accent.withValues(alpha: 0.32),
            ),
            // The one shape with corners, tilted so it is parallel to nothing
            // else on the screen.
            _Outline(
              right: 160,
              bottom: 145,
              side: 34,
              radius: 10,
              stroke: 1,
              blur: 2.5,
              angle: 0.5,
              color: white.withValues(alpha: 0.15),
            ),
            _Outline(
              right: 262,
              bottom: 58,
              side: 26,
              radius: 13,
              stroke: 0.9,
              blur: 2.5,
              color: white.withValues(alpha: 0.13),
            ),
            // The last of it, more suggestion than shape.
            _Outline(
              right: 250,
              bottom: 140,
              side: 16,
              radius: 5,
              stroke: 0.9,
              blur: 3,
              angle: 0.4,
              color: white.withValues(alpha: 0.09),
            ),
          ],
        ),
      ),
    );
  }

  Widget _arc({
    required double radius,
    required double stroke,
    required double blur,
    required Color color,
    required double alpha,
  }) => _Outline(
    right: _originRight - radius,
    bottom: _originBottom - radius,
    side: radius * 2,
    radius: radius,
    stroke: stroke,
    blur: blur,
    color: color.withValues(alpha: alpha),
  );
}

/// One stroked square-or-circle, placed from the cluster's bottom-right
/// corner and blurred on its own — the far shapes are blurred hardest, which
/// is what gives the drift its depth. One filter over the whole group would
/// only give it haze.
class _Outline extends StatelessWidget {
  const _Outline({
    required this.right,
    required this.bottom,
    required this.side,
    required this.radius,
    required this.stroke,
    required this.blur,
    required this.color,
    this.angle = 0,
  });

  final double right;
  final double bottom;
  final double side;

  /// Half of [side] gives a circle; anything less, a rounded square.
  final double radius;

  final double stroke;
  final double blur;
  final Color color;
  final double angle;

  @override
  Widget build(BuildContext context) {
    Widget shape = Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: color, width: stroke),
      ),
    );

    if (angle != 0) {
      shape = Transform.rotate(angle: angle, child: shape);
    }

    return Positioned(
      right: right,
      bottom: bottom,
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: shape,
      ),
    );
  }
}
