import 'package:flutter/material.dart';

import '../../config/theme/app_text_theme.dart';
import '../text/app_text.dart';

/// A count that counts up when it appears.
///
/// Only for **counts** — a number of shops, visits, cases. Never for money:
/// an amount is a string the server sent and is never turned into a number
/// on this handset, so there is nothing here that could animate one. A
/// money figure arrives whole, through [MoneyText].
///
/// Built on [TweenAnimationBuilder], which means the *widget tree* holds
/// the animation rather than a hand-managed controller: rebuild it with a
/// new value and it tweens from wherever it currently is to the new figure,
/// with no `didUpdateWidget` bookkeeping to get wrong. A refreshed figure
/// therefore counts from the old value to the new one, so a number that
/// moved is visibly a number that moved.
///
/// 620ms with a decelerating curve — long enough to read as deliberate,
/// short enough that the officer never waits for it.
class AppCountUp extends StatelessWidget {
  const AppCountUp(
    this.value, {
    super.key,
    this.variant = AppTextVariant.displaySmall,
    this.color,
    this.enabled = true,
    this.suffix,
  });

  final int value;
  final AppTextVariant variant;
  final Color? color;

  /// False shows the number immediately — used on a refresh, where
  /// re-animating a figure the officer already read is noise.
  final bool enabled;

  /// A unit drawn after the figure at the same size, e.g. a per-cent sign.
  final String? suffix;

  static const Duration duration = Duration(milliseconds: 620);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      // A count is a run of Latin digits; force LTR so it reads correctly
      // inside an Urdu line.
      textDirection: TextDirection.ltr,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: enabled ? 0 : value.toDouble(), end: value.toDouble()),
        duration: enabled ? duration : Duration.zero,
        curve: Curves.easeOutExpo,
        builder: (context, animated, _) => AppText(
          '${animated.round()}${suffix ?? ''}',
          variant: variant,
          color: color,
          maxLines: 1,
          // Tabular, so a figure counting up does not shuffle the label
          // beside it left and right on every frame.
          fontFeatures: kTabularFigures,
        ),
      ),
    );
  }
}
