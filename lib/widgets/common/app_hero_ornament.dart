import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../config/theme/app_brand.dart';

/// The soft geometry scattered across a hero header.
///
/// Outlines only — rings and tilted squares drawn as thin strokes, never
/// filled. A filled shape on a gradient reads as a panel someone forgot to put
/// content in; a stroke reads as ornament, which is all this is.
///
/// The arcs sweep out of the bottom-right corner and the shapes scatter away
/// from them. Size and alpha are deliberately *not* tied to how far out a
/// shape sits — the biggest is mid-field, the smallest is up among the arcs —
/// because a group that shrinks and fades in step reads as one line of shapes
/// rather than a scatter. Blur still grows with distance: that is the depth
/// cue. It all keeps right and low, because the title sits top-left and
/// outlines drifting under it read as dirt on the screen.
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

  /// The corner the arcs ripple out from. Still one shared centre — concentric
  /// circles never cross, so the strokes cannot collide — but the radii below
  /// are spaced unevenly, because three even gaps read as ruled lines.
  static const double _originRight = 30;
  static const double _originBottom = 18;

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
            // Gaps of 44 then 90, not 43 then 50: uneven enough that they
            // stop reading as a ripple. The outermost is faint enough to be a
            // suggestion rather than a third band.
            _arc(radius: 52, stroke: 1.2, blur: 2, color: white, alpha: 0.30),
            _arc(radius: 96, stroke: 1.1, blur: 3, color: white, alpha: 0.20),
            _arc(radius: 186, stroke: 1, blur: 5, color: white, alpha: 0.10),

            // The scatter, and the placement is checked rather than eyed:
            // uneven gaps both ways, no shape sharing a height with a
            // neighbour, and no three within 22pt of a straight line. Any one
            // of those regularities on its own reads as a row.

            // Small, and nearest the corner — the near shapes are not the
            // big ones.
            _Outline(
              right: 92,
              bottom: 115,
              side: 14,
              radius: 7,
              stroke: 0.9,
              blur: 2,
              color: white.withValues(alpha: 0.14),
            ),
            _Outline(
              right: 118,
              bottom: 71,
              side: 30,
              radius: 9,
              stroke: 1,
              blur: 2,
              angle: 0.25,
              color: white.withValues(alpha: 0.16),
            ),
            _Outline(
              right: 168,
              bottom: 170,
              side: 18,
              radius: 5,
              stroke: 0.9,
              blur: 1.8,
              angle: 0.6,
              color: white.withValues(alpha: 0.20),
            ),
            // The warm note, and the largest of them — out in the field rather
            // than in the corner, so the scheme's accent tints the header
            // instead of announcing itself on it.
            _Outline(
              right: 199,
              bottom: 48,
              side: 46,
              radius: 23,
              stroke: 1,
              blur: 2.2,
              color: context.brand.accent.withValues(alpha: 0.30),
            ),
            // Tilted the other way, so no two squares are parallel.
            _Outline(
              right: 238,
              bottom: 145,
              side: 38,
              radius: 11,
              stroke: 1,
              blur: 2.6,
              angle: -0.4,
              color: white.withValues(alpha: 0.13),
            ),
            _Outline(
              right: 276,
              bottom: 88,
              side: 24,
              radius: 12,
              stroke: 0.9,
              blur: 3,
              color: white.withValues(alpha: 0.11),
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
