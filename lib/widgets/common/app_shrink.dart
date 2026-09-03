import 'package:flutter/widgets.dart';

/// Draws [child] at [scale] and takes only the room that leaves, so a column
/// of these has a height that follows the scale.
///
/// A collapsing header shrinks its parts with this instead of cross-fading a
/// big copy into a small one: a transform rasterises text at the size it is
/// drawn, so every point of the collapse is a legible header rather than two
/// headers over each other.
class AppShrink extends StatelessWidget {
  const AppShrink({super.key, required this.scale, required this.child});

  /// 1 draws the child untouched; 0 leaves nothing of it.
  final double scale;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double s = scale.clamp(0.0, 1.0);
    if (s == 1) return child;
    // A zero scale is a degenerate transform, and there is nothing to draw.
    if (s == 0) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.topLeft,
      heightFactor: s,
      child: Transform.scale(
        scale: s,
        alignment: Alignment.topLeft,
        child: child,
      ),
    );
  }
}
