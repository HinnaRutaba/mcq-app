import 'package:flutter/material.dart';

import '../../models/common/money.dart';
import 'app_text.dart';

/// The single widget for rendering an amount.
///
/// Two rules it exists to enforce:
///
/// * The value is a [Money] — a string the server sent — so no `double`
///   ever comes near an amount. There is nothing here that could parse one.
/// * Figures are **tabular**, so columns of amounts line up. Note that this
///   is a proportional font with tabular figures enabled, not a monospace
///   font: the web application made that mistake and every rent figure
///   rendered in Consolas, which reads as source code.
///
/// Digits stay Western (0–9) in Urdu as well as English — the Pakistani
/// software norm, and it keeps a column readable.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    super.key,
    this.variant = AppTextVariant.titleMedium,
    this.color,
    this.withSymbol = true,
    this.textAlign,
    this.maxLines = 1,
  });

  /// A big headline figure — the one number on a dashboard tile.
  const MoneyText.headline(
    this.amount, {
    super.key,
    this.color,
    this.withSymbol = true,
    this.textAlign,
    this.maxLines = 1,
  }) : variant = AppTextVariant.displaySmall;

  /// A figure inside a row of a list.
  const MoneyText.row(
    this.amount, {
    super.key,
    this.color,
    this.withSymbol = true,
    this.textAlign,
    this.maxLines = 1,
  }) : variant = AppTextVariant.titleMedium;

  /// A small figure — a decomposition line, a caption.
  const MoneyText.small(
    this.amount, {
    super.key,
    this.color,
    this.withSymbol = false,
    this.textAlign,
    this.maxLines = 1,
  }) : variant = AppTextVariant.bodySmall;

  final Money amount;
  final AppTextVariant variant;
  final Color? color;
  final bool withSymbol;
  final TextAlign? textAlign;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    // An amount is a run of Latin digits and separators. Force LTR around
    // it so it reads correctly inside an Urdu, right-to-left line.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: AppText(
        withSymbol ? amount.withSymbol() : amount.format(),
        variant: variant,
        color: color,
        textAlign: textAlign,
        maxLines: maxLines,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
