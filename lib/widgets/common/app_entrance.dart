import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppEntrance extends StatelessWidget {
  const AppEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
  });

  final Widget child;

  final int index;

  /// Held back this long before the stagger starts, invisible in the meantime.
  ///
  /// For a list that arrives behind something else — the rows inside a sheet
  /// that is still growing out of the button that opened it. The row is laid
  /// out from the first frame either way, so nothing moves when it appears.
  final Duration delay;

  static const Duration _duration = Duration(milliseconds: 420);
  static const Duration _step = Duration(milliseconds: 45);

  static const int _maxStagger = 11;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    return child
        .animate(delay: delay + _step * math.min(index, _maxStagger))
        .fadeIn(duration: _duration, curve: Curves.easeOutCubic)
        .slideY(
          begin: 0.14,
          end: 0,
          duration: _duration,
          curve: Curves.easeOutBack,
        )
        // A touch under, springing up to size. `easeOutBack` overshoots, which
        // is the whole point — a linear settle reads as a page loading, this
        // reads as a page arriving.
        .scaleXY(
          begin: 0.92,
          end: 1,
          duration: _duration,
          curve: Curves.easeOutBack,
        );
  }
}
