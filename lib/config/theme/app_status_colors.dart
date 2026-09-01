import 'package:flutter/material.dart';

/// The semantic colours Material's [ColorScheme] has no slot for, carried
/// on the theme as a first-class [ThemeExtension] rather than as global
/// constants a widget reaches around the theme to read.
///
/// Why an extension and not a `static const`:
///
/// * It **lerps**. Switching light to dark animates through
///   [AppStatusColors.lerp] like every other themed colour, so a status
///   pill does not snap while the card behind it fades.
/// * It is **overridable**. A test, a preview or a future high-contrast
///   mode can wrap a subtree in a `Theme` with a different set and every
///   pill, rail, banner and chart in that subtree follows.
/// * It keeps one source of truth. `AppTone.on(context)` resolves through
///   here, so the red on a defaulter card, the red on the seal banner and
///   the red on a chart bar are the same red by construction.
///
/// ### The colours were validated, not chosen by eye
///
/// The status four are checked for perceptual separation under normal
/// vision and under protanopia/deuteranopia/tritanopia, and for contrast
/// against the surface they sit on. The previous amber (`#B54708`) failed
/// badly: it sat ΔE 7.7 from the danger red under normal vision and ΔE 1.5
/// under protanopia — a magistrate with the commonest form of colour
/// blindness could not tell an overdue card from a promise card, which is
/// the single distinction this app exists to draw. The amber here is a
/// true gold-brown at ΔE 17.9 / 8.3, and it differs in **lightness** as
/// well as hue so the pair survives greyscale and direct sunlight.
///
/// Colour is still never the only signal — every pill carries an icon and
/// a word — but the colour now does its share of the work.
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.danger,
    required this.onDanger,
    required this.dangerContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.accent,
    required this.onAccent,
    required this.accentContainer,
    required this.brand,
    required this.neutral,
    required this.escalation,
    required this.chartGrid,
    required this.chartLabel,
  });

  /// Money overdue, a broken promise, a shop sealed.
  final Color danger;
  final Color onDanger;

  /// The tinted plate a danger pill or rail sits on. Opaque, so it can be
  /// layered without compounding alpha.
  final Color dangerContainer;

  /// A standing commitment, a warning served, something due today.
  final Color warning;
  final Color onWarning;
  final Color warningContainer;

  /// Paid, settled, released, cleared. Cooler and brighter than the brand
  /// green on purpose — a settled pill must not read as a primary button.
  final Color success;
  final Color onSuccess;
  final Color successContainer;

  /// A fact, a count that is not money, a vacant unit.
  final Color info;
  final Color onInfo;
  final Color infoContainer;

  /// Warm gold. **Chrome, never a status and never a data mark** — it is
  /// the corporation's accent, and it always carries dark text.
  final Color accent;
  final Color onAccent;
  final Color accentContainer;

  /// The brand green used as a *tone* — a neutral-positive emphasis that
  /// is not a status claim.
  final Color brand;

  /// The unemphatic tone: a fact with no colour opinion attached.
  final Color neutral;

  /// A six-step single-hue ramp, light to dark, for **ordinal** data.
  ///
  /// Enforcement actions are not categories, they are an escalation — a
  /// visit, a verbal warning, a final warning, a notice, a seal. Colouring
  /// them with a categorical palette would say they are merely different;
  /// a ramp says the darker one is the harder step, which is the truth and
  /// is readable at a glance. It also keeps the chart out of the status
  /// hues, so nothing in a breakdown can be misread as "this is overdue".
  final List<Color> escalation;

  /// Recessive gridlines and axis rules.
  final Color chartGrid;

  /// Axis and legend ink. Text wears text tokens, never a series colour.
  final Color chartLabel;

  /// The step of [escalation] for position [index] of [total] ordered
  /// items, spread across the whole ramp so two items do not land on
  /// neighbouring steps that read as the same colour.
  Color escalationStep(int index, int total) {
    if (escalation.isEmpty) return neutral;
    if (total <= 1) return escalation[escalation.length ~/ 2];
    final span = (escalation.length - 1) / (total - 1);
    final at = (index * span).round().clamp(0, escalation.length - 1);
    return escalation[at];
  }

  // -------------------------------------------------------------------
  // Light — validated against the card surface #FFFFFF
  //
  //   danger  #D92D20   warning #BC8A00   success #0BA678   info #1273A8
  //   worst adjacent ΔE: 17.9 normal, 8.3 deutan · all ≥ 3:1 on surface
  // -------------------------------------------------------------------
  static const AppStatusColors light = AppStatusColors(
    danger: Color(0xFFD92D20),
    onDanger: Color(0xFFFFFFFF),
    dangerContainer: Color(0xFFFDECEA),
    warning: Color(0xFFBC8A00),
    onWarning: Color(0xFF2E2205),
    warningContainer: Color(0xFFFBF3DE),
    success: Color(0xFF0BA678),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFE3F7F0),
    info: Color(0xFF1273A8),
    onInfo: Color(0xFFFFFFFF),
    infoContainer: Color(0xFFE5F1F8),
    accent: Color(0xFFD9A520),
    onAccent: Color(0xFF2E2205),
    accentContainer: Color(0xFFFBF1D8),
    brand: Color(0xFF0F4C35),
    neutral: Color(0xFF505A4F),
    // Validated ordinal ramp: monotone lightness, one hue (spread 2°),
    // light end 2.36:1 against white.
    escalation: [
      Color(0xFF6FB795),
      Color(0xFF4FA47D),
      Color(0xFF2E8B63),
      Color(0xFF15734E),
      Color(0xFF0E5B3D),
      Color(0xFF093F2A),
    ],
    chartGrid: Color(0xFFE6ECE6),
    chartLabel: Color(0xFF505A4F),
  );

  // -------------------------------------------------------------------
  // Dark — validated against the card surface #101812
  //
  //   danger  #ED5548   warning #D3A62E   success #1DBE8B   info #3AA6DB
  //   worst adjacent ΔE: 15.6 normal, 9.6 deutan · all ≥ 3:1 on surface
  //
  // These are re-stepped for the dark surface, not the light values with
  // opacity thrown at them. A status palette also *varies* lightness on
  // purpose — that is what keeps the four apart in greyscale — so it does
  // not sit inside the single narrow band a categorical palette wants.
  // -------------------------------------------------------------------
  static const AppStatusColors dark = AppStatusColors(
    danger: Color(0xFFED5548),
    onDanger: Color(0xFF080D0A),
    dangerContainer: Color(0xFF2A1614),
    warning: Color(0xFFD3A62E),
    onWarning: Color(0xFF221904),
    warningContainer: Color(0xFF26200F),
    success: Color(0xFF1DBE8B),
    onSuccess: Color(0xFF080D0A),
    successContainer: Color(0xFF10261F),
    info: Color(0xFF3AA6DB),
    onInfo: Color(0xFF080D0A),
    infoContainer: Color(0xFF122129),
    accent: Color(0xFFE8BC4A),
    onAccent: Color(0xFF2E2205),
    accentContainer: Color(0xFF2A2312),
    brand: Color(0xFF56B98C),
    neutral: Color(0xFFAEBBAC),
    escalation: [
      Color(0xFFCBEBDB),
      Color(0xFFA8D5BF),
      Color(0xFF7CBF9F),
      Color(0xFF4FA57F),
      Color(0xFF2A8862),
      Color(0xFF176B4A),
    ],
    chartGrid: Color(0xFF1E2C23),
    chartLabel: Color(0xFFAEBBAC),
  );

  @override
  AppStatusColors copyWith({
    Color? danger,
    Color? onDanger,
    Color? dangerContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? accent,
    Color? onAccent,
    Color? accentContainer,
    Color? brand,
    Color? neutral,
    List<Color>? escalation,
    Color? chartGrid,
    Color? chartLabel,
  }) {
    return AppStatusColors(
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentContainer: accentContainer ?? this.accentContainer,
      brand: brand ?? this.brand,
      neutral: neutral ?? this.neutral,
      escalation: escalation ?? this.escalation,
      chartGrid: chartGrid ?? this.chartGrid,
      chartLabel: chartLabel ?? this.chartLabel,
    );
  }

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) {
    if (other is! AppStatusColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppStatusColors(
      danger: mix(danger, other.danger),
      onDanger: mix(onDanger, other.onDanger),
      dangerContainer: mix(dangerContainer, other.dangerContainer),
      warning: mix(warning, other.warning),
      onWarning: mix(onWarning, other.onWarning),
      warningContainer: mix(warningContainer, other.warningContainer),
      success: mix(success, other.success),
      onSuccess: mix(onSuccess, other.onSuccess),
      successContainer: mix(successContainer, other.successContainer),
      info: mix(info, other.info),
      onInfo: mix(onInfo, other.onInfo),
      infoContainer: mix(infoContainer, other.infoContainer),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      accentContainer: mix(accentContainer, other.accentContainer),
      brand: mix(brand, other.brand),
      neutral: mix(neutral, other.neutral),
      escalation: [
        for (var i = 0; i < escalation.length; i++)
          mix(
            escalation[i],
            i < other.escalation.length ? other.escalation[i] : escalation[i],
          ),
      ],
      chartGrid: mix(chartGrid, other.chartGrid),
      chartLabel: mix(chartLabel, other.chartLabel),
    );
  }
}

/// `context.status.danger` — the short way to the extension.
///
/// Falls back to the light set rather than throwing: a widget rendered
/// outside an app theme (a golden test, a `Navigator` overlay built from a
/// bare `Theme`) should draw in the right colours, not crash.
extension AppStatusColorsContext on BuildContext {
  AppStatusColors get status =>
      Theme.of(this).extension<AppStatusColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppStatusColors.dark
          : AppStatusColors.light);
}
