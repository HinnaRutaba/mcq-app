import 'package:flutter/material.dart';

/// The colours that change when the officer picks a different scheme.
///
/// Everything else in the theme — surfaces, text, the status palette — is
/// deliberately *not* here. A scheme changes the app's own colour; it must
/// never restate what red means.
///
/// Carried on the theme as an extension so a widget that needs the brand
/// beyond the [ColorScheme] roles — the hero header's gradient, mostly — reads
/// it from `context.brand` rather than reaching for a static constant, which
/// is what made the app single-scheme in the first place.
@immutable
class AppBrandColors extends ThemeExtension<AppBrandColors> {
  const AppBrandColors({
    required this.primary,
    required this.accent,
    required this.headerFrom,
    required this.headerTo,
  });

  /// The brand at the step that is legible on this brightness. Not a flip of
  /// the other brightness — its own value.
  final Color primary;

  /// The warm counterweight: the FAB, a highlight pill. Never a status.
  final Color accent;

  /// The hero header runs [headerFrom] to [headerTo], top-left to
  /// bottom-right. Authored rather than derived, because a gradient that ends
  /// too light stops carrying white text.
  final Color headerFrom;
  final Color headerTo;

  /// The ink to put on [primary] when it is drawn filled.
  Color get onPrimary => inkOn(primary);

  /// The ink to put on [accent]. Gold and sand need dark ink; coral does not.
  Color get onAccent => inkOn(accent);

  /// The plate a filled tile is drawn on — the brand muted and lifted to a
  /// tint, lit from the top-left, so a row of them breaks up a page of pale
  /// cards without shouting over it.
  Gradient get filledPlate {
    final Color top = Color.lerp(_muted(primary), Colors.white, 0.6)!;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[top, Color.lerp(top, Colors.black, 0.12)!],
    );
  }

  /// The ink on [filledPlate]: the app's near-black, since the plate is a
  /// light tint in both themes. Around 6:1 — legible in bright sun.
  Color get onFilledPlate => const Color(0xFF11170F);

  /// The brand at 60% saturation, lifted to luminance 0.28. Measured rather
  /// than a fixed lightness step: HSL lightness is not perceptual, and one
  /// step lands the green scheme twice as bright as the indigo one.
  static Color _muted(Color fill) {
    var hsl = HSLColor.fromColor(fill);
    hsl = hsl.withSaturation(hsl.saturation * 0.6);
    var lifted = hsl.toColor();
    while (hsl.lightness < 1 && lifted.computeLuminance() < 0.28) {
      hsl = hsl.withLightness((hsl.lightness + 0.005).clamp(0.0, 1.0));
      lifted = hsl.toColor();
    }
    return lifted;
  }

  /// White or near-black, whichever the fill can actually carry.
  ///
  /// A rule rather than a hand-picked value per scheme: ten hand-picked inks
  /// is ten chances to ship an unreadable button, and luminance answers it
  /// correctly every time.
  static Color inkOn(Color fill) =>
      fill.computeLuminance() > 0.45 ? const Color(0xFF17130A) : Colors.white;

  /// The soft tinted plate this brand sits on — a container role, mixed
  /// toward the surface it will be drawn against.
  Color containerOn(Color surface) => Color.lerp(primary, surface, 0.87)!;

  Color accentContainerOn(Color surface) => Color.lerp(accent, surface, 0.85)!;

  @override
  AppBrandColors copyWith({
    Color? primary,
    Color? accent,
    Color? headerFrom,
    Color? headerTo,
  }) => AppBrandColors(
    primary: primary ?? this.primary,
    accent: accent ?? this.accent,
    headerFrom: headerFrom ?? this.headerFrom,
    headerTo: headerTo ?? this.headerTo,
  );

  @override
  AppBrandColors lerp(ThemeExtension<AppBrandColors>? other, double t) {
    if (other is! AppBrandColors) return this;
    return AppBrandColors(
      primary: Color.lerp(primary, other.primary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      headerFrom: Color.lerp(headerFrom, other.headerFrom, t)!,
      headerTo: Color.lerp(headerTo, other.headerTo, t)!,
    );
  }
}

/// The schemes an officer can choose between.
///
/// Five, not a colour wheel: each one is a decision someone can defend, and a
/// free colour picker would let an officer build an interface where the brand
/// is the same red as an overdue account.
enum AppColorScheme {
  balochistanGreen(
    label: 'Balochistan Green',
    description: "The corporation's own colour. The default.",
    light: AppBrandColors(
      primary: Color(0xFF0F4C35),
      accent: Color(0xFFD9A520),
      headerFrom: Color(0xFF0F4C35),
      headerTo: Color(0xFF07301F),
    ),
    dark: AppBrandColors(
      primary: Color(0xFF56B98C),
      accent: Color(0xFFE8BC4A),
      headerFrom: Color(0xFF17231B),
      headerTo: Color(0xFF080D0A),
    ),
  ),

  governmentBlue(
    label: 'Government Blue',
    description: 'The familiar administrative blue.',
    light: AppBrandColors(
      primary: Color(0xFF1D4E9B),
      accent: Color(0xFFD9A520),
      headerFrom: Color(0xFF1D4E9B),
      headerTo: Color(0xFF10305F),
    ),
    dark: AppBrandColors(
      primary: Color(0xFF6BA6E8),
      accent: Color(0xFFE8BC4A),
      headerFrom: Color(0xFF16202E),
      headerTo: Color(0xFF070B10),
    ),
  ),

  graphite(
    label: 'Graphite',
    description: 'Grey and quiet, so colour only ever means status.',
    light: AppBrandColors(
      primary: Color(0xFF454C49),
      accent: Color(0xFFC4712C),
      headerFrom: Color(0xFF454C49),
      headerTo: Color(0xFF232726),
    ),
    dark: AppBrandColors(
      primary: Color(0xFFA8B3AE),
      accent: Color(0xFFE09A55),
      headerFrom: Color(0xFF1B1E1D),
      headerTo: Color(0xFF0A0B0B),
    ),
  ),

  indigo(
    label: 'Indigo',
    description: 'Deep violet with a warm coral accent. The most colourful.',
    light: AppBrandColors(
      primary: Color(0xFF4A3AA8),
      accent: Color(0xFFE8663D),
      headerFrom: Color(0xFF4A3AA8),
      headerTo: Color(0xFF2C2168),
    ),
    dark: AppBrandColors(
      primary: Color(0xFF9B8AF0),
      accent: Color(0xFFF58A64),
      headerFrom: Color(0xFF201A38),
      headerTo: Color(0xFF0C0A16),
    ),
  ),

  teal(
    label: 'Teal',
    description: 'Cool teal with warm sand. Calm, and still in colour.',
    light: AppBrandColors(
      primary: Color(0xFF14706E),
      accent: Color(0xFFD09A3C),
      headerFrom: Color(0xFF14706E),
      headerTo: Color(0xFF0A4746),
    ),
    dark: AppBrandColors(
      primary: Color(0xFF4EC5C0),
      accent: Color(0xFFE8C87A),
      headerFrom: Color(0xFF142524),
      headerTo: Color(0xFF06100F),
    ),
  );

  const AppColorScheme({
    required this.label,
    required this.description,
    required this.light,
    required this.dark,
  });

  /// What the officer sees in the picker.
  final String label;

  /// One line on what choosing it means. Not marketing — the Graphite line
  /// tells them something true about how the app will read.
  final String description;

  final AppBrandColors light;
  final AppBrandColors dark;

  AppBrandColors of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// What a stored preference resolves to, and what an unrecognised one falls
  /// back to — a scheme dropped in a later build must not strand anybody.
  static AppColorScheme fromName(String? name) => values.firstWhere(
    (AppColorScheme scheme) => scheme.name == name,
    orElse: () => balochistanGreen,
  );
}

/// `context.brand` — the brand colours for the current theme, with the
/// default scheme as a fallback so a widget pumped without the extension
/// still draws.
extension AppBrandContext on BuildContext {
  AppBrandColors get brand {
    final theme = Theme.of(this);
    return theme.extension<AppBrandColors>() ??
        AppColorScheme.balochistanGreen.of(theme.brightness);
  }
}
