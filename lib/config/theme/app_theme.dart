import 'package:flutter/material.dart';

import 'app_brand.dart';
import 'app_colors.dart';
import 'app_status_colors.dart';
import 'app_text_theme.dart';
import 'app_radius.dart';

/// Light and dark [ThemeData] for the app, for a chosen [AppColorScheme].
///
/// All generic widgets in `lib/widgets` pull their look (colors, shapes,
/// input decoration, etc.) from this theme instead of hardcoding values,
/// so switching light/dark mode restyles the whole app consistently.
///
/// Two things travel on the theme beyond the usual [ColorScheme]:
/// the `surfaceContainer` family (so a sheet, a card and a chip are
/// separated by *surface* rather than all being white with a border), and
/// [AppStatusColors] as a `ThemeExtension` — the status palette every
/// badge, pill and banner reads through `context.status` / [AppTone].
///
/// The brand colours travel too, as [AppBrandColors], so the one thing a
/// scheme changes is in one place. Surfaces, text and the status palette are
/// shared by every scheme: what the officer picks is the app's own colour, not
/// a new meaning for red.
class AppTheme {
  AppTheme._();

  static const double _radius = AppRadius.md;

  static ThemeData light([
    AppColorScheme scheme = AppColorScheme.balochistanGreen,
  ]) {
    final brand = scheme.light;
    final colorScheme = ColorScheme.light(
      primary: brand.primary,
      onPrimary: brand.onPrimary,
      primaryContainer: brand.containerOn(AppColors.lightSurface),
      onPrimaryContainer: brand.primary,
      // "Secondary" is the warm accent — the ink on it follows its luminance.
      secondary: brand.accent,
      onSecondary: brand.onAccent,
      secondaryContainer: brand.accentContainerOn(AppColors.lightSurface),
      onSecondaryContainer: brand.onAccent,
      tertiary: AppColors.tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.tertiarySoft,
      onTertiaryContainer: const Color(0xFF0B2E2C),
      error: AppColors.danger,
      onError: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      onSurfaceVariant: AppColors.lightTextSecondary,
      surfaceContainerLowest: AppColors.lightSurfaceLowest,
      surfaceContainerLow: AppColors.lightSurfaceLow,
      surfaceContainer: AppColors.lightSurfaceContainer,
      surfaceContainerHigh: AppColors.lightSurfaceHigh,
      surfaceContainerHighest: AppColors.lightSurfaceVariant,
      outline: AppColors.lightBorder,
      outlineVariant: AppColors.lightDivider,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      extensions: <ThemeExtension<dynamic>>[
        AppStatusColors.lightFor(brand.primary),
        brand,
      ],
      scaffoldBackgroundColor: AppColors.lightBackground,
      textTheme: AppTextTheme.light,
      fontFamily: AppTextTheme.light.bodyMedium?.fontFamily,
      dividerColor: AppColors.lightDivider,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextTheme.light.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        hintStyle: AppTextTheme.light.bodyMedium?.copyWith(
          color: AppColors.lightTextHint,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: brand.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? brand.primary
              : Colors.transparent,
        ),
        side: const BorderSide(color: AppColors.lightBorder, width: 1.5),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: AppTextTheme.light.bodyMedium,
      ),
      splashFactory: InkRipple.splashFactory,
      colorSchemeSeed: null,
    );
  }

  static ThemeData dark([
    AppColorScheme scheme = AppColorScheme.balochistanGreen,
  ]) {
    final brand = scheme.dark;
    final colorScheme = ColorScheme.dark(
      // A deep brand colour is unreadable on near-black, so dark mode runs on
      // the scheme's own lighter step with dark ink on top of it.
      primary: brand.primary,
      onPrimary: brand.onPrimary,
      primaryContainer: brand.containerOn(AppColors.darkSurface),
      onPrimaryContainer: brand.primary,
      secondary: brand.accent,
      onSecondary: brand.onAccent,
      secondaryContainer: brand.accentContainerOn(AppColors.darkSurface),
      onSecondaryContainer: brand.accent,
      tertiary: AppColors.tertiaryOnDark,
      onTertiary: AppColors.darkBackground,
      tertiaryContainer: AppColors.tertiarySoftDark,
      onTertiaryContainer: AppColors.tertiaryOnDark,
      error: AppColors.dangerOnDark,
      onError: AppColors.darkBackground,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      onSurfaceVariant: AppColors.darkTextSecondary,
      surfaceContainerLowest: AppColors.darkSurfaceLowest,
      surfaceContainerLow: AppColors.darkSurfaceLow,
      surfaceContainer: AppColors.darkSurfaceContainer,
      surfaceContainerHigh: AppColors.darkSurfaceHigh,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkDivider,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      extensions: <ThemeExtension<dynamic>>[
        AppStatusColors.darkFor(brand.primary),
        brand,
      ],
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: AppTextTheme.dark,
      fontFamily: AppTextTheme.dark.bodyMedium?.fontFamily,
      dividerColor: AppColors.darkDivider,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextTheme.dark.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        hintStyle: AppTextTheme.dark.bodyMedium?.copyWith(
          color: AppColors.darkTextHint,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: brand.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.dangerOnDark),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(
            color: AppColors.dangerOnDark,
            width: 1.5,
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? brand.primary
              : Colors.transparent,
        ),
        side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: AppTextTheme.dark.bodyMedium,
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
