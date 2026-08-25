import 'package:flutter/material.dart';

/// Central color palette for the app — Tailwind "sky" blue (primary /
/// primaryLight / primaryDark / dark-mode surfaces / light background),
/// paired with a teal accent.
///
/// Keep every raw color value here — screens and widgets should never
/// hardcode a `Color(0x...)`, they should reference `AppColors` (directly
/// or through `Theme.of(context)`) instead.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------
  // Brand
  // ---------------------------------------------------------------------
  static const Color primary = Color(0xFF0D5375);
  static const Color primaryLight = Color(0xFF0C496B);
  static const Color primaryDark = Color(0xFF072842);

  static const Color secondary = Color(0xFF0891B2);
  static const Color secondaryDark = Color(0xFF0E7490);

  // ---------------------------------------------------------------------
  // Semantic
  // ---------------------------------------------------------------------
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  // ---------------------------------------------------------------------
  // Light theme neutrals
  // ---------------------------------------------------------------------
  static const Color lightBackground = Color(0xFFF0F9FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEEF2F7);
  static const Color lightBorder = Color(0xFFDCE3EC);
  static const Color lightDivider = Color(0xFFE3E8EF);
  static const Color lightTextPrimary = Color(0xFF0B1F33);
  static const Color lightTextSecondary = Color(0xFF4B5D75);
  static const Color lightTextHint = Color(0xFF8B9AB0);

  // ---------------------------------------------------------------------
  // Dark theme neutrals
  // ---------------------------------------------------------------------
  static const Color darkBackground = Color(0xFF030D1B);
  static const Color darkSurface = Color(0xFF04192E);
  static const Color darkSurfaceVariant = Color(0xFF082E47);
  static const Color darkBorder = Color(0xFF1F3A5F);
  static const Color darkDivider = Color(0xFF1B3252);
  static const Color darkTextPrimary = Color(0xFFE7EEF7);
  static const Color darkTextSecondary = Color(0xFFA9BBD1);
  static const Color darkTextHint = Color(0xFF7690AD);
}
