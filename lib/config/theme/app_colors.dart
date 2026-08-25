import 'package:flutter/material.dart';

/// Central color palette for the app.
///
/// Keep every raw color value here — screens and widgets should never
/// hardcode a `Color(0x...)`, they should reference `AppColors` (directly
/// or through `Theme.of(context)`) instead.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------
  // Brand
  // ---------------------------------------------------------------------
  static const Color primary = Color(0xFF2A5CFF);
  static const Color primaryLight = Color(0xFF6C8CFF);
  static const Color primaryDark = Color(0xFF1A3FCC);

  static const Color secondary = Color(0xFF00C897);
  static const Color secondaryDark = Color(0xFF00A87C);

  // ---------------------------------------------------------------------
  // Semantic
  // ---------------------------------------------------------------------
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF2E90FA);

  // ---------------------------------------------------------------------
  // Light theme neutrals
  // ---------------------------------------------------------------------
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEEF1F6);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightDivider = Color(0xFFE8EBF0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextHint = Color(0xFF94A3B8);

  // ---------------------------------------------------------------------
  // Dark theme neutrals
  // ---------------------------------------------------------------------
  static const Color darkBackground = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF131B2E);
  static const Color darkSurfaceVariant = Color(0xFF1B2436);
  static const Color darkBorder = Color(0xFF283248);
  static const Color darkDivider = Color(0xFF232D40);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF9AA7BD);
  static const Color darkTextHint = Color(0xFF6B7794);
}
