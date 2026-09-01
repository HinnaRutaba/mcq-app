import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_status_colors.dart';
import 'app_text_theme.dart';

/// The shape language, in one place.
///
/// Three radii and nothing else. An interface with seven corner radii looks
/// assembled; one with three looks drawn.
class AppShape {
  AppShape._();

  /// Chips, pills, the call button — anything the eye reads as a token.
  static const double pill = 999;

  /// Buttons, inputs, small tiles.
  static const double control = 14;

  /// Cards and panels.
  static const double card = 18;

  /// Sheets and dialogs — the largest surfaces, and the only ones that get
  /// the generous Material 3 corner.
  static const double sheet = 28;

  static RoundedRectangleBorder get cardBorder =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(card));

  static RoundedRectangleBorder get controlBorder =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(control));
}

/// Light and dark [ThemeData] for the app.
///
/// **Everything in `lib/widgets` reads its look from here.** No screen
/// hardcodes a colour, a radius or an elevation; a change in this file
/// restyles the whole app, in both brightnesses, in both languages.
///
/// Three things this theme does that a default `ThemeData` does not:
///
/// * A **complete Material 3 [ColorScheme]**, generated from the brand seed
///   and then corrected on every role MCQ actually owns — primary,
///   secondary (the gold), tertiary, the four surface-container steps, the
///   outlines and the error family. Generating from a seed alone gives a
///   scheme that is harmonious and wrong; overriding every role by hand
///   gives one that is right and disharmonious in dark mode. Doing both is
///   the only way to get a scheme where `surfaceContainerHigh` is a real,
///   usable step *and* `primary` is exactly the corporation's green.
/// * The **semantic status colours** as a [ThemeExtension] — see
///   [AppStatusColors]. Material has no slot for "warning" or "paid", and
///   the app has more of those than it has primaries.
/// * A **styled component for every Material widget the app uses**, so a
///   screen can reach for a plain `FilledButton`, `FilterChip`,
///   `NavigationBar`, `TabBar`, `ListTile`, `AlertDialog` or `Badge` and
///   get the MCQ look without a wrapper. The wrappers in `lib/widgets`
///   exist to enforce *rules* (never white on gold, never a status without
///   a word), not to re-apply paint.
class AppTheme {
  AppTheme._();

  static ThemeData get light => build(Brightness.light);

  static ThemeData get dark => build(Brightness.dark);

  /// [textTheme] lets the app hand in the localised scale — Urdu's face and
  /// line height — so that component themes that embed a text style (the
  /// app bar title, a navigation label, a chip caption) are built from the
  /// *same* scale as the body copy rather than from the Latin fallback.
  static ThemeData build(Brightness brightness, {TextTheme? textTheme}) {
    final dark = brightness == Brightness.dark;
    final scheme = dark ? _darkScheme : _lightScheme;
    final status = dark ? AppStatusColors.dark : AppStatusColors.light;
    final text = textTheme ?? (dark ? AppTextTheme.dark : AppTextTheme.light);

    final background =
        dark ? AppColors.darkBackground : AppColors.lightBackground;
    final divider = dark ? AppColors.darkDivider : AppColors.lightDivider;
    final muted =
        dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final hint = dark ? AppColors.darkTextHint : AppColors.lightTextHint;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>[status],
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: text,
      // Named so a raw `Text` inherits the right face even where somebody
      // forgot [AppText].
      fontFamily: text.bodyMedium?.fontFamily,
      dividerColor: divider,
      splashFactory: InkSparkle.splashFactory,
      // The officer taps with a thumb, standing up. Nothing gets denser.
      visualDensity: VisualDensity.standard,

      // ---------------------------------------------------------------
      // Chrome
      // ---------------------------------------------------------------
      appBarTheme: AppBarThemeData(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: scheme.onSurface, size: 24),
        actionsIconTheme: IconThemeData(color: scheme.onSurface, size: 24),
      ),

      // Cards carry a real shadow in light mode, because the whole
      // complaint about the old build was that every row looked like the
      // row above it. In dark mode a shadow does nothing, so the surface
      // itself lifts a step instead.
      cardTheme: CardThemeData(
        color: dark ? AppColors.darkSurfaceContainer : AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: dark ? Colors.transparent : const Color(0x2914231A),
        elevation: dark ? 0 : 2,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShape.card),
          side: BorderSide(
            color: dark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),

      iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 24),

      // ---------------------------------------------------------------
      // Buttons — the real Material 3 set, styled once
      // ---------------------------------------------------------------
      //
      // Height 52: this is tapped by somebody standing on a footpath,
      // holding a phone in one hand, in the sun. Radius 14 rather than the
      // Material stadium, so a button reads as a control rather than as a
      // very large chip.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: AppShape.controlBorder,
          textStyle: text.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: AppShape.controlBorder,
          textStyle: text.labelLarge,
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: AppShape.controlBorder,
          textStyle: text.labelLarge,
          foregroundColor: scheme.primary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: AppShape.controlBorder,
          textStyle: text.labelLarge,
          backgroundColor: scheme.surfaceContainerLow,
          foregroundColor: scheme.onSurface,
          elevation: dark ? 0 : 1,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: scheme.onSurfaceVariant,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: dark ? 0 : 4,
        focusElevation: 4,
        hoverElevation: 4,
        highlightElevation: 2,
        extendedTextStyle: text.labelLarge?.copyWith(color: scheme.onPrimary),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShape.card),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          minimumSize: const Size(48, 46),
          textStyle: text.labelMedium,
          selectedBackgroundColor: scheme.primary,
          selectedForegroundColor: scheme.onPrimary,
          foregroundColor: scheme.onSurfaceVariant,
          side: BorderSide(color: scheme.outline),
        ),
      ),

      // ---------------------------------------------------------------
      // Chips — the filter row, and every pill on a card
      // ---------------------------------------------------------------
      chipTheme: ChipThemeData(
        backgroundColor: dark
            ? AppColors.darkSurfaceContainer
            : AppColors.lightSurfaceLow,
        selectedColor: scheme.primary,
        checkmarkColor: scheme.onPrimary,
        secondarySelectedColor: scheme.primary,
        disabledColor: scheme.surfaceContainerHighest,
        surfaceTintColor: Colors.transparent,
        labelStyle: text.labelMedium,
        secondaryLabelStyle: text.labelMedium?.copyWith(color: scheme.onPrimary),
        // 40 tall: a chip an officer can hit while walking.
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        labelPadding: const EdgeInsetsDirectional.symmetric(horizontal: 5),
        side: BorderSide(color: scheme.outline),
        shape: const StadiumBorder(),
        showCheckmark: false,
        elevation: 0,
        pressElevation: 0,
        iconTheme: IconThemeData(size: 18, color: scheme.onSurfaceVariant),
      ),

      badgeTheme: BadgeThemeData(
        backgroundColor: status.danger,
        textColor: status.onDanger,
        textStyle: text.labelSmall?.copyWith(
          fontSize: 11,
          color: status.onDanger,
          height: 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        smallSize: 8,
        largeSize: 18,
      ),

      // ---------------------------------------------------------------
      // Navigation
      // ---------------------------------------------------------------
      //
      // **Labels are always shown.** This officer may not be a daily
      // smartphone user, and an unlabelled glyph is a guess he has to make
      // while somebody argues at his elbow.
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        backgroundColor:
            dark ? AppColors.darkSurfaceLow : AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: dark
            ? AppColors.primaryOnDark.withValues(alpha: 0.20)
            : AppColors.primarySoft,
        indicatorShape: const StadiumBorder(),
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return text.labelSmall?.copyWith(
            color: selected ? scheme.primary : muted,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? scheme.primary : muted,
          );
        }),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: muted,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: divider,
        dividerHeight: 1,
        indicator: UnderlineTabIndicator(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          borderSide: BorderSide(color: scheme.primary, width: 3),
        ),
        overlayColor: WidgetStatePropertyAll(
          scheme.primary.withValues(alpha: 0.06),
        ),
      ),

      // ---------------------------------------------------------------
      // Surfaces that open over the screen
      // ---------------------------------------------------------------
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:
            dark ? AppColors.darkSurfaceContainer : AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor:
            dark ? AppColors.darkSurfaceContainer : AppColors.lightSurface,
        modalElevation: 0,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: scheme.outline,
        dragHandleSize: const Size(44, 4),
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppShape.sheet)),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor:
            dark ? AppColors.darkSurfaceHigh : AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: dark ? 0 : 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShape.sheet - 4),
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      ),

      // A refusal an officer has to read while a shopkeeper watches gets a
      // floating card, not a bar welded to the bottom edge.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        elevation: 6,
        insetPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShape.control),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: text.bodySmall?.copyWith(color: scheme.onInverseSurface),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: dark ? AppColors.darkSurfaceHigh : AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: dark ? 0 : 6,
        textStyle: text.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShape.control),
        ),
      ),

      // ---------------------------------------------------------------
      // Rows and disclosure
      // ---------------------------------------------------------------
      listTileTheme: ListTileThemeData(
        contentPadding:
            const EdgeInsetsDirectional.symmetric(horizontal: 18, vertical: 6),
        minVerticalPadding: 12,
        horizontalTitleGap: 14,
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodySmall?.copyWith(color: muted),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShape.control),
        ),
      ),

      expansionTileTheme: ExpansionTileThemeData(
        iconColor: scheme.primary,
        collapsedIconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        collapsedTextColor: scheme.onSurface,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        tilePadding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
        shape: const Border(),
        collapsedShape: const Border(),
      ),

      // ---------------------------------------------------------------
      // Inputs
      // ---------------------------------------------------------------
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor:
            dark ? AppColors.darkSurfaceContainer : AppColors.lightSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        hintStyle: text.bodyMedium?.copyWith(color: hint),
        labelStyle: text.bodyMedium?.copyWith(color: muted),
        floatingLabelStyle: text.labelMedium?.copyWith(color: scheme.primary),
        errorStyle: text.bodySmall?.copyWith(color: scheme.error),
        prefixIconColor: muted,
        suffixIconColor: muted,
        border: _inputBorder(scheme.outline),
        enabledBorder: _inputBorder(scheme.outline),
        focusedBorder: _inputBorder(scheme.primary, width: 2),
        errorBorder: _inputBorder(scheme.error),
        focusedErrorBorder: _inputBorder(scheme.error, width: 2),
        disabledBorder: _inputBorder(scheme.outlineVariant),
      ),

      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(
          dark ? AppColors.darkSurfaceContainer : AppColors.lightSurface,
        ),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        constraints: const BoxConstraints(minHeight: 54),
        padding: const WidgetStatePropertyAll(
          EdgeInsetsDirectional.symmetric(horizontal: 16),
        ),
        hintStyle: WidgetStatePropertyAll(
          text.bodyMedium?.copyWith(color: hint),
        ),
        textStyle: WidgetStatePropertyAll(text.bodyMedium),
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppShape.control),
          ),
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
        side: BorderSide(color: scheme.outline, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.outline,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: WidgetStatePropertyAll(scheme.outline),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: text.bodyMedium,
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            dark ? AppColors.darkSurfaceHigh : AppColors.lightSurface,
          ),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppShape.control),
            ),
          ),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
        linearMinHeight: 8,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color colour, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppShape.control),
        borderSide: BorderSide(color: colour, width: width),
      );

  // -------------------------------------------------------------------
  // The schemes
  // -------------------------------------------------------------------
  //
  // Seeded from the corporation's green so every role Material generates
  // and the app never names — `surfaceTint`, the `*Fixed` family, the
  // inverse roles — is harmonious rather than arbitrary; then corrected on
  // every role the app *does* own, so nothing MCQ can point at on the web
  // application comes out approximated.

  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primarySoft,
    onPrimaryContainer: AppColors.primaryDark,
    // The gold. It carries dark text, always — white on gold fails
    // contrast at the sizes this app uses, outdoors.
    secondary: AppColors.accent,
    onSecondary: AppColors.onAccent,
    secondaryContainer: const Color(0xFFFBF1D8),
    onSecondaryContainer: AppColors.onAccent,
    tertiary: AppColors.tertiary,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.tertiarySoft,
    onTertiaryContainer: const Color(0xFF0A2E2C),
    error: AppColors.danger,
    onError: Colors.white,
    errorContainer: const Color(0xFFFDECEA),
    onErrorContainer: const Color(0xFF5F1512),
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightTextPrimary,
    onSurfaceVariant: AppColors.lightTextSecondary,
    surfaceContainerLowest: AppColors.lightSurfaceLowest,
    surfaceContainerLow: AppColors.lightSurfaceLow,
    surfaceContainer: AppColors.lightSurfaceContainer,
    surfaceContainerHigh: AppColors.lightSurfaceHigh,
    surfaceContainerHighest: AppColors.lightSurfaceVariant,
    surfaceDim: const Color(0xFFDCE4DC),
    surfaceBright: AppColors.lightSurface,
    outline: AppColors.lightBorder,
    outlineVariant: AppColors.lightDivider,
    inverseSurface: const Color(0xFF1B241C),
    onInverseSurface: const Color(0xFFF0F4F0),
    inversePrimary: AppColors.primaryOnDark,
    shadow: const Color(0xFF14231A),
    scrim: const Color(0xFF000000),
  );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
    primary: AppColors.primaryOnDark,
    onPrimary: const Color(0xFF04140C),
    primaryContainer: AppColors.primarySoftDark,
    onPrimaryContainer: const Color(0xFFB7E5CE),
    secondary: AppColors.accentOnDark,
    onSecondary: AppColors.onAccent,
    secondaryContainer: const Color(0xFF2A2312),
    onSecondaryContainer: const Color(0xFFF2DCA4),
    tertiary: AppColors.tertiaryOnDark,
    onTertiary: const Color(0xFF04211F),
    tertiaryContainer: AppColors.tertiarySoftDark,
    onTertiaryContainer: const Color(0xFFB4E7E3),
    error: AppColors.dangerOnDark,
    onError: AppColors.darkBackground,
    errorContainer: const Color(0xFF2A1614),
    onErrorContainer: const Color(0xFFFFD6D1),
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkTextPrimary,
    onSurfaceVariant: AppColors.darkTextSecondary,
    surfaceContainerLowest: AppColors.darkSurfaceLowest,
    surfaceContainerLow: AppColors.darkSurfaceLow,
    surfaceContainer: AppColors.darkSurfaceContainer,
    surfaceContainerHigh: AppColors.darkSurfaceHigh,
    surfaceContainerHighest: const Color(0xFF202E24),
    surfaceDim: AppColors.darkBackground,
    surfaceBright: const Color(0xFF243027),
    outline: AppColors.darkBorder,
    outlineVariant: AppColors.darkDivider,
    inverseSurface: AppColors.darkTextPrimary,
    onInverseSurface: AppColors.darkSurface,
    inversePrimary: AppColors.primary,
    shadow: const Color(0xFF000000),
    scrim: const Color(0xFF000000),
  );
}
