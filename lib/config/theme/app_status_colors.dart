import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The status palette, carried on [ThemeData.extensions] so every widget
/// that shows a state reads the *same* red, amber, emerald and sky — and
/// gets the dark-mode step of each for free when the officer switches
/// themes.
///
/// Three colours per status, and each one has a job:
///
/// * the tone itself — text, an icon, a 1px rule;
/// * `on…` — the ink to put on top of the tone when it is drawn **filled**,
///   chosen for contrast (dark ink on amber and emerald, white on red and
///   sky) rather than for looks;
/// * `…Container` — the opaque tinted plate the tone sits on. Opaque, not
///   translucent, so a pill inside a tinted card does not compound into mud.
///
/// Read it with `context.status`, or through [AppTone] which is the API
/// widgets should prefer.
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
    required this.brand,
    required this.neutral,
  });

  /// Money overdue, a broken promise, sealing a shop.
  final Color danger;
  final Color onDanger;
  final Color dangerContainer;

  /// A standing commitment, a warning given, something due today.
  final Color warning;
  final Color onWarning;
  final Color warningContainer;

  /// Paid, settled, released — cooler and brighter than the brand green so
  /// a settled pill cannot be read as a primary button.
  final Color success;
  final Color onSuccess;
  final Color successContainer;

  /// Information — a note, a count that is not money.
  final Color info;
  final Color onInfo;
  final Color infoContainer;

  /// The brand green at the step that is legible on this brightness. Not a
  /// status: it is the tone for "ours / primary emphasis".
  final Color brand;

  /// Secondary ink — the "no particular state" tone.
  final Color neutral;

  /// The palette with the brand tone taken from the officer's chosen scheme.
  /// Only [brand] moves — a scheme changes the app's own colour, never what
  /// red means.
  static AppStatusColors lightFor(Color brand) => light.copyWith(brand: brand);

  static AppStatusColors darkFor(Color brand) => dark.copyWith(brand: brand);

  static const AppStatusColors light = AppStatusColors(
    danger: AppColors.danger,
    onDanger: Colors.white,
    dangerContainer: Color(0xFFFBE7E5),
    warning: AppColors.warning,
    onWarning: AppColors.onAccent,
    warningContainer: Color(0xFFF8EFD3),
    success: AppColors.paid,
    onSuccess: Color(0xFF04231A),
    successContainer: Color(0xFFDDF3EB),
    info: AppColors.info,
    onInfo: Colors.white,
    infoContainer: Color(0xFFE1EEF7),
    brand: AppColors.primary,
    neutral: AppColors.lightTextSecondary,
  );

  static const AppStatusColors dark = AppStatusColors(
    danger: AppColors.dangerOnDark,
    onDanger: AppColors.darkBackground,
    dangerContainer: Color(0xFF2A1512),
    warning: AppColors.warningOnDark,
    onWarning: AppColors.onAccent,
    warningContainer: Color(0xFF26200D),
    success: AppColors.paidOnDark,
    onSuccess: AppColors.darkBackground,
    successContainer: Color(0xFF0C2A21),
    info: AppColors.infoOnDark,
    onInfo: AppColors.darkBackground,
    infoContainer: Color(0xFF0F2431),
    brand: AppColors.primaryOnDark,
    neutral: AppColors.darkTextSecondary,
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
    Color? brand,
    Color? neutral,
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
      brand: brand ?? this.brand,
      neutral: neutral ?? this.neutral,
    );
  }

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) {
    if (other is! AppStatusColors) return this;
    return AppStatusColors(
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
    );
  }
}

/// `context.status` — the status palette for the current theme, with a
/// brightness-matched fallback so a widget pumped without the extension
/// (a test, a bare `MaterialApp`) still gets sane colours.
extension AppStatusColorsContext on BuildContext {
  AppStatusColors get status {
    final theme = Theme.of(this);
    return theme.extension<AppStatusColors>() ??
        (theme.brightness == Brightness.dark
            ? AppStatusColors.dark
            : AppStatusColors.light);
  }
}
