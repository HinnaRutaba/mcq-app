
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// One step of the type scale.
///
/// The scale is written down as data rather than as fifteen `copyWith`
/// calls so the language-neutral theme ([AppTextTheme]) and the localised
/// one ([LocalisedTextTheme]) cannot drift apart — which is exactly what
/// happened before, and it is how a screen ends up with two sizes of
/// "title".
@immutable
class AppTypeStep {
  const AppTypeStep({
    required this.size,
    required this.weight,
    required this.tracking,
    this.heading = false,
    this.tabular = false,
  });

  final double size;
  final FontWeight weight;

  /// Letter-spacing, in logical pixels at [size]. Large type needs to be
  /// pulled in and small type opened up; leaving both at zero is most of
  /// what makes an interface look untouched.
  final double tracking;

  /// Headings take the tighter heading line-height; body takes the
  /// language's own reading height (1.5 Latin, 1.85 Urdu).
  final bool heading;

  /// Figures line up in a column. On by default for every step big enough
  /// to carry a count or an amount.
  final bool tabular;
}

/// **The scale starts at 15, not 12.** This is read at arm's length, in
/// sunlight, by an officer who may be over fifty and is standing on a
/// footpath with somebody arguing at him. The one exception is
/// `labelSmall` at 14, which is a bold pill caption and never a sentence.
///
/// Weights carry the hierarchy as hard as sizes do: 800 on display, 700 on
/// headline, 600 on title. Plus Jakarta Sans has the range for it, which is
/// most of why it is here.
const Map<String, AppTypeStep> kAppTypeScale = {
  'displayLarge': AppTypeStep(
      size: 44,
      weight: FontWeight.w800,
      tracking: -1.1,
      heading: true,
      tabular: true),
  'displayMedium': AppTypeStep(
      size: 36,
      weight: FontWeight.w800,
      tracking: -0.9,
      heading: true,
      tabular: true),
  'displaySmall': AppTypeStep(
      size: 31,
      weight: FontWeight.w800,
      tracking: -0.7,
      heading: true,
      tabular: true),
  'headlineLarge': AppTypeStep(
      size: 27,
      weight: FontWeight.w700,
      tracking: -0.5,
      heading: true,
      tabular: true),
  'headlineMedium': AppTypeStep(
      size: 23,
      weight: FontWeight.w700,
      tracking: -0.4,
      heading: true,
      tabular: true),
  'headlineSmall': AppTypeStep(
      size: 21,
      weight: FontWeight.w700,
      tracking: -0.3,
      heading: true,
      tabular: true),
  'titleLarge': AppTypeStep(
      size: 19,
      weight: FontWeight.w700,
      tracking: -0.2,
      heading: true,
      tabular: true),
  'titleMedium':
      AppTypeStep(size: 17, weight: FontWeight.w600, tracking: -0.1, tabular: true),
  'titleSmall':
      AppTypeStep(size: 16, weight: FontWeight.w600, tracking: 0, tabular: true),
  'bodyLarge': AppTypeStep(size: 17, weight: FontWeight.w400, tracking: 0),
  'bodyMedium': AppTypeStep(size: 16, weight: FontWeight.w400, tracking: 0),
  'bodySmall': AppTypeStep(size: 15, weight: FontWeight.w400, tracking: 0.05),
  'labelLarge': AppTypeStep(size: 16, weight: FontWeight.w600, tracking: 0.1),
  'labelMedium': AppTypeStep(size: 15, weight: FontWeight.w600, tracking: 0.15),
  // The floor, and only for a bold pill caption — never a sentence.
  'labelSmall': AppTypeStep(size: 14, weight: FontWeight.w700, tracking: 0.25),
};

/// Figures that line up in a column, wherever they are drawn.
///
/// A proportional face with tabular figures on, **not** a monospace face:
/// the web application made that mistake and every rent figure rendered in
/// Consolas, which reads as source code rather than as money.
const List<FontFeature> kTabularFigures = [
  FontFeature.tabularFigures(),
  FontFeature.slashedZero(),
];

/// Builds the Material [TextTheme] used across the app.
///
/// This is the language-neutral fallback. The app itself renders through
/// [LocalisedTextTheme], which carries the same scale plus Urdu's line
/// height and the officer's large-text setting. Both read [kAppTypeScale].
class AppTextTheme {
  AppTextTheme._();

  /// The base the scale is applied to. Material's own 2021 typography,
  /// re-based onto a bundled family.
  static final TextTheme _base = Typography.material2021().black;

  /// Plus Jakarta Sans. Chosen over Inter for one reason that matters at
  /// arm's length in sunlight: its heavy weights are genuinely heavy and
  /// its letterforms stay open at 15px, so the hierarchy survives on a
  /// cheap screen behind a smeared protector. Its figures are also close to
  /// even-width before tabular kicks in, which keeps a column of rupees
  /// steady while it animates.
  ///
  /// **Bundled, not fetched.** `google_fonts` downloads on first use and
  /// renders the platform default until it arrives; the first time these
  /// handsets are switched on is in a bazaar, and a government revenue
  /// application must not open in whatever face Android happened to have.
  static TextTheme latin() => _base.apply(fontFamily: 'PlusJakartaSans');

  /// Nastaliq actually draws the script. Nothing else in the Google set
  /// does it properly at this size. One variable file — hierarchy in Urdu
  /// is carried by size, not by weight.
  static TextTheme nastaliq() => _base.apply(fontFamily: 'NotoNastaliqUrdu');

  static TextTheme light = build(latin(), AppColors.lightTextPrimary);
  static TextTheme dark = build(latin(), AppColors.darkTextPrimary);

  /// Applies [kAppTypeScale] to [base].
  ///
  /// [bodyHeight] is the language's reading line-height — Urdu needs ~1.85
  /// against Latin's ~1.5, because Nastaliq ascenders and descenders
  /// collide otherwise. [factor] is the officer's own large-text setting,
  /// applied on top of whatever the operating system already does; some
  /// officers are older than the accessibility settings nobody has shown
  /// them.
  static TextTheme build(
    TextTheme base,
    Color colour, {
    double bodyHeight = 1.5,
    double headingHeight = 1.22,
    double factor = 1.0,
    double sizeScale = 1.0,
    double trackingScale = 1.0,
  }) {
    TextStyle? step(TextStyle? style, String name) {
      final spec = kAppTypeScale[name]!;
      final size = spec.size * sizeScale * factor;
      return style?.copyWith(
        fontSize: size,
        fontWeight: spec.weight,
        color: colour,
        height: spec.heading ? headingHeight : bodyHeight,
        // Tracking is specified at the design size, so it scales with it.
        // [trackingScale] is 0 for Nastaliq: letter-spacing a connected
        // script pulls the joins apart and makes it unreadable.
        letterSpacing: spec.tracking * sizeScale * factor * trackingScale,
        fontFeatures: spec.tabular ? kTabularFigures : null,
      );
    }

    return base.copyWith(
      displayLarge: step(base.displayLarge, 'displayLarge'),
      displayMedium: step(base.displayMedium, 'displayMedium'),
      displaySmall: step(base.displaySmall, 'displaySmall'),
      headlineLarge: step(base.headlineLarge, 'headlineLarge'),
      headlineMedium: step(base.headlineMedium, 'headlineMedium'),
      headlineSmall: step(base.headlineSmall, 'headlineSmall'),
      titleLarge: step(base.titleLarge, 'titleLarge'),
      titleMedium: step(base.titleMedium, 'titleMedium'),
      titleSmall: step(base.titleSmall, 'titleSmall'),
      bodyLarge: step(base.bodyLarge, 'bodyLarge'),
      bodyMedium: step(base.bodyMedium, 'bodyMedium'),
      bodySmall: step(base.bodySmall, 'bodySmall'),
      labelLarge: step(base.labelLarge, 'labelLarge'),
      labelMedium: step(base.labelMedium, 'labelMedium'),
      labelSmall: step(base.labelSmall, 'labelSmall'),
    );
  }
}
