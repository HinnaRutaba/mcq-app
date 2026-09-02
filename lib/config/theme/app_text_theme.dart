import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Builds the Material [TextTheme] used across the app.
///
/// [AppText] (see `lib/widgets/text/app_text.dart`) reads its styles from
/// `Theme.of(context).textTheme`, so any change made here is reflected
/// everywhere in the app automatically.
class AppTextTheme {
  AppTextTheme._();

  static TextTheme light = _build(AppColors.lightTextPrimary);
  static TextTheme dark = _build(AppColors.darkTextPrimary);

  static TextTheme _build(Color baseColor) {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.2,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 29,
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.2,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.25,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.25,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.3,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.3,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.3,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.35,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.35,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.5,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.4,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.3,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: baseColor,
        height: 1.3,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 9.5,
        fontWeight: FontWeight.w500,
        color: baseColor,
        height: 1.3,
      ),
    );
  }
}
