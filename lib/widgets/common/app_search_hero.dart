import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../config/theme/app_radius.dart';
import 'app_circle_icon_button.dart';

/// The flight between a header's search action and the search box on the page
/// it opens: the circle stretches into the box, and folds back into it on the
/// way out.
///
/// One tag, because exactly two of these are ever on screen at once — the
/// action, and the box it opened. What flies is a shape of its own rather than
/// either end's widget: a text field laid out at 42pt is an overflow, not a
/// transition.
class AppSearchHero extends StatelessWidget {
  const AppSearchHero({super.key, required this.child});

  static const String tag = 'app.search-box';

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Hero(tag: tag, flightShuttleBuilder: _shuttle, child: child);
}

Widget _shuttle(
  BuildContext flight,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHero,
  BuildContext toHero,
) {
  // Drawn off the field theme, so what lands is the box the page actually has.
  final ThemeData theme = Theme.of(flight);
  final InputDecorationThemeData input = theme.inputDecorationTheme;
  final InputBorder? edge = input.enabledBorder ?? input.border;
  final double boxCorner = edge is OutlineInputBorder
      ? edge.borderRadius.topLeft.x
      : AppRadius.md;
  final Color boxFill = input.fillColor ?? theme.colorScheme.surface;
  final Color boxLine = edge?.borderSide.color ?? theme.dividerColor;
  final Color boxIcon =
      input.hintStyle?.color ??
      theme.textTheme.bodyMedium?.color ??
      theme.colorScheme.onSurface;

  return AnimatedBuilder(
    animation: animation,
    builder: (BuildContext context, Widget? child) {
      // 0 is the circle on the header, 1 the box on the page. A pop runs the
      // same animation backwards, so the shape folds up the way it opened.
      final double t = Curves.easeInOut.transform(animation.value);

      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // The flight is laid out at the rectangle of the moment, so the
          // corner is read off it: a stadium while it is round, the field's
          // own corner by the time it is a box.
          final double corner = lerpDouble(
            constraints.maxHeight / 2,
            boxCorner,
            t,
          )!;

          return DecoratedBox(
            decoration: BoxDecoration(
              color: Color.lerp(AppCircleIconButton.headerFill, boxFill, t),
              borderRadius: BorderRadius.circular(corner),
              border: Border.all(
                color: boxLine.withValues(alpha: boxLine.a * t),
              ),
            ),
            child: Align(
              // Centred in the circle, and where a field's prefix sits by the
              // time it is one.
              alignment: Alignment.lerp(
                Alignment.center,
                Alignment.centerLeft,
                t,
              )!,
              child: Padding(
                padding: EdgeInsets.only(left: lerpDouble(0, 14, t)!),
                child: Icon(
                  Icons.search_rounded,
                  size: lerpDouble(21, 20, t),
                  color: Color.lerp(Colors.white, boxIcon, t),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
