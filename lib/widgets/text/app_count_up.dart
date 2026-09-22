import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import 'app_text.dart';

/// A figure that runs up to its value when the screen arrives.
///
/// The run is decoration; the number is not. Whatever the tween is passing
/// through, the frame it lands on prints [text] — the caller's own string —
/// so a money figure ends as the server sent it rather than as something this
/// widget re-derived on the way past.
///
/// A value it cannot count to (an unparseable amount, a zero) is printed
/// straight: an animation from nothing to nothing is a flicker, not an
/// entrance.
class AppCountUp extends StatelessWidget {
  /// A plain count — queue sizes, visits, shops.
  AppCountUp.count(
    int value, {
    super.key,
    this.variant = AppTextVariant.headlineMedium,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.duration = _duration,
  }) : value = value.toDouble(),
       text = '$value',
       _money = false;

  /// Money, from the server's own decimal string.
  AppCountUp.money(
    String amount, {
    super.key,
    this.variant = AppTextVariant.headlineMedium,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.duration = _duration,
  }) : value = double.tryParse(amount.trim()) ?? 0,
       text = Formatters.money(amount) ?? amount,
       _money = true;

  static const Duration _duration = Duration(milliseconds: 950);

  /// What the number counts to.
  final double value;

  /// What it reads at rest, and the only string the officer is left with.
  final String text;

  final bool _money;

  final AppTextVariant variant;
  final Color? color;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (value <= 0 || MediaQuery.disableAnimationsOf(context)) return _at(text);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double shown, Widget? _) =>
          _at(shown >= value ? text : _passing(shown)),
    );
  }

  /// Every frame before the last. Formatted the same way as [text] so the
  /// number does not change shape as it lands.
  String _passing(double shown) =>
      _money ? Formatters.currency(shown) : '${shown.round()}';

  Widget _at(String shown) => AppText(
    shown,
    variant: variant,
    color: color,
    fontWeight: fontWeight,
    textAlign: textAlign,
    maxLines: 1,
  );
}
