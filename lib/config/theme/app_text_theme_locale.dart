import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'app_colors.dart';
import 'app_text_theme.dart';

/// Typography per language.
///
/// The scale itself lives in [kAppTypeScale] and is shared with
/// [AppTextTheme]; this file only decides the three things that genuinely
/// differ by language:
///
/// * **the face** — Plus Jakarta Sans for Latin, Noto Nastaliq Urdu for
///   Urdu, because nothing else in the Google set draws the script
///   properly at this size;
/// * **the reading height** — Urdu needs ~1.85 against Latin's ~1.5. The
///   web application uses those figures, and Nastaliq ascenders and
///   descenders collide below them;
/// * **the optical size** — Nastaliq sits taller in its box, so it is set
///   a little smaller and given more room, rather than being allowed to
///   push every card two lines longer than its English twin.
///
/// Digits stay Western (0–9) in both: that is the Pakistani software norm
/// and it keeps figures aligned in a column. See [MoneyText], which renders
/// them with tabular figures — as does every step of the scale from
/// `titleSmall` up.
class LocalisedTextTheme {
  LocalisedTextTheme._();

  static TextTheme of(
    AppLocale locale,
    Brightness brightness, {
    double factor = 1.0,
  }) {
    final colour = brightness == Brightness.dark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return AppTextTheme.build(
      locale.isRtl ? AppTextTheme.nastaliq() : AppTextTheme.latin(),
      colour,
      bodyHeight: locale.lineHeight,
      // Headings get more room in Nastaliq for the same reason body text
      // does — the script simply occupies more vertical space.
      headingHeight: locale.isRtl ? 1.6 : 1.22,
      factor: factor,
      sizeScale: locale.isRtl ? 0.94 : 1.0,
      // Nastaliq is a connected script: letter-spacing it pulls the joins
      // apart and the word stops being a word.
      trackingScale: locale.isRtl ? 0 : 1,
    );
  }
}
