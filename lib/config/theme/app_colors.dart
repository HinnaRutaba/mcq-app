import 'package:flutter/material.dart';

import 'app_status_colors.dart';

/// The colour system, matched to the MCQ web application's "Balochistan
/// Green" palette so the handset and the desk feel like one system.
///
/// Four rules hold this file together, and every one of them is a decision
/// somebody will otherwise undo by accident:
///
/// 1. **Deep forest green is the corporation, warm gold is the accent, and
///    gold always carries dark text.** White on gold fails contrast at the
///    sizes this app uses, in a bazaar, in sunlight.
/// 2. **Body text is near-black ink, never brand-tinted.** Coloured body
///    text costs readability and the colour never means anything.
/// 3. **Status colour means only status.** Red is money overdue and danger,
///    amber is a warning and a standing commitment, emerald is paid and
///    settled, sky is information. Because green is also the brand, "paid"
///    is a brighter, cooler emerald so a settled pill cannot be mistaken
///    for a primary button. Gold is *chrome* and never a status.
/// 4. **Colour is never the only carrier of meaning.** Every status here is
///    paired with an icon and a word at the widget level — see
///    [AppStatusBadge] and [AppPill].
///
/// The status values themselves now live in [AppStatusColors], carried on
/// the theme as a `ThemeExtension`, and they were **validated** rather than
/// picked: separation under normal vision and under the three common forms
/// of colour blindness, and contrast against the surface each sits on. The
/// constants below mirror that set so context-free code (a painter, a
/// `const` default) has somewhere to read them from.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------
  // Brand — deep forest green
  // ---------------------------------------------------------------------
  static const Color primary = Color(0xFF0F4C35);
  static const Color primaryLight = Color(0xFF1B6B4A);
  static const Color primaryDark = Color(0xFF07301F);

  /// The lightest brand wash — a tinted card behind primary content.
  static const Color primarySoft = Color(0xFFE6F0EA);
  static const Color primarySoftDark = Color(0xFF11291F);

  /// A third brand hue for the Material 3 `tertiary` role: a muted teal
  /// that sits between the forest green and the information blue. It
  /// carries *neutral emphasis* — a selected chip, a chart's secondary
  /// series — and never a status claim.
  static const Color tertiary = Color(0xFF1F6F6B);
  static const Color tertiarySoft = Color(0xFFE3F0EF);
  static const Color tertiaryOnDark = Color(0xFF5BC0BA);
  static const Color tertiarySoftDark = Color(0xFF10251F);

  // ---------------------------------------------------------------------
  // Accent — warm gold. Dark text on it, always.
  // ---------------------------------------------------------------------
  static const Color accent = Color(0xFFD9A520);
  static const Color accentDark = Color(0xFFB2831A);

  /// The only foreground gold is ever paired with.
  static const Color onAccent = Color(0xFF2E2205);

  /// Kept for the widgets that still ask for a "secondary" — it is the
  /// accent, not a second brand colour.
  static const Color secondary = accent;
  static const Color secondaryDark = accentDark;

  // ---------------------------------------------------------------------
  // Status — and nothing else ever uses these
  // ---------------------------------------------------------------------

  /// Money overdue, a broken promise, sealing a shop.
  static const Color danger = Color(0xFFD92D20);

  /// A standing commitment, a warning given, something due today.
  ///
  /// A true gold-brown, **not** the burnt orange this used to be. The old
  /// `#B54708` sat ΔE 7.7 from the danger red under normal vision and ΔE
  /// 1.5 under protanopia — the two were the same colour to a large
  /// minority of readers, and they are the app's single most important
  /// distinction. See [AppStatusColors].
  static const Color warning = Color(0xFFBC8A00);

  /// Paid, settled, released. Cooler and brighter than the brand green on
  /// purpose.
  static const Color paid = Color(0xFF0BA678);

  /// Information — a note, a count that is not money.
  static const Color info = Color(0xFF1273A8);

  // Aliases the rest of the app already speaks.
  static const Color error = danger;
  static const Color success = paid;

  // ---------------------------------------------------------------------
  // Light theme — a warm off-white with the faintest green in it
  // ---------------------------------------------------------------------
  static const Color lightBackground = Color(0xFFF4F7F4);
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// The Material 3 `surfaceContainer` family: four steps between the page
  /// and a raised card, so a sheet, a search bar, a chip and a card are
  /// separated by *surface* rather than all being white with a border.
  static const Color lightSurfaceLowest = Color(0xFFFFFFFF);
  static const Color lightSurfaceLow = Color(0xFFFAFCFA);
  static const Color lightSurfaceContainer = Color(0xFFF0F4F0);
  static const Color lightSurfaceHigh = Color(0xFFE9EFE9);
  static const Color lightSurfaceVariant = Color(0xFFEDF2ED);
  static const Color lightBorder = Color(0xFFDDE5DD);
  static const Color lightDivider = Color(0xFFE6ECE6);

  /// Near-black ink. Not green, not grey-blue — ink.
  static const Color lightTextPrimary = Color(0xFF11170F);
  static const Color lightTextSecondary = Color(0xFF505A4F);
  static const Color lightTextHint = Color(0xFF83907F);

  // ---------------------------------------------------------------------
  // Dark theme — field officers use this at night
  // ---------------------------------------------------------------------
  static const Color darkBackground = Color(0xFF080D0A);
  static const Color darkSurface = Color(0xFF101812);
  static const Color darkSurfaceLowest = Color(0xFF060A07);
  static const Color darkSurfaceLow = Color(0xFF0D140F);
  static const Color darkSurfaceContainer = Color(0xFF141E17);
  static const Color darkSurfaceHigh = Color(0xFF1A261D);
  static const Color darkSurfaceVariant = Color(0xFF17231B);
  static const Color darkBorder = Color(0xFF26362C);
  static const Color darkDivider = Color(0xFF1E2C23);
  static const Color darkTextPrimary = Color(0xFFE9EFE8);
  static const Color darkTextSecondary = Color(0xFFAEBBAC);
  static const Color darkTextHint = Color(0xFF7C8B7B);

  /// Status colours re-stepped for a dark surface — the light-theme values
  /// are too dense to read against near-black. Re-stepped and re-validated
  /// as a set, not the light values with opacity thrown at them.
  static const Color dangerOnDark = Color(0xFFED5548);
  static const Color warningOnDark = Color(0xFFD3A62E);
  static const Color paidOnDark = Color(0xFF1DBE8B);
  static const Color infoOnDark = Color(0xFF3AA6DB);
  static const Color accentOnDark = Color(0xFFE8BC4A);
  static const Color primaryOnDark = Color(0xFF56B98C);
}

/// What a colour is *saying* — assigned from state, never from taste, and
/// never the only signal. Every widget that takes a tone also takes an icon
/// and a label.
enum AppTone { neutral, primary, info, success, warning, danger }

/// Resolves an [AppTone] against the theme.
///
/// [on] is the one to use: it reads [AppStatusColors] off the theme, so a
/// red pill on the defaulters list and a red banner on the follow-ups queue
/// are the same red, and both animate together when the officer switches
/// to dark mode. [resolve] is the context-free fallback for a `CustomPainter`
/// or a `const` default.
extension AppToneColors on AppTone {
  Color on(BuildContext context) {
    final status = context.status;
    switch (this) {
      case AppTone.danger:
        return status.danger;
      case AppTone.warning:
        return status.warning;
      case AppTone.success:
        return status.success;
      case AppTone.info:
        return status.info;
      case AppTone.primary:
        return status.brand;
      case AppTone.neutral:
        return status.neutral;
    }
  }

  /// The ink to put *on top of* this tone when it is drawn filled.
  Color onFilled(BuildContext context) {
    final status = context.status;
    switch (this) {
      case AppTone.danger:
        return status.onDanger;
      case AppTone.warning:
        return status.onWarning;
      case AppTone.success:
        return status.onSuccess;
      case AppTone.info:
        return status.onInfo;
      case AppTone.primary:
        return Theme.of(context).colorScheme.onPrimary;
      case AppTone.neutral:
        return Theme.of(context).colorScheme.surface;
    }
  }

  /// The opaque tinted plate this tone sits on — a filled chip, a soft
  /// stat tile, the wash behind an icon. Opaque rather than translucent so
  /// stacking two of them does not compound into mud.
  Color container(BuildContext context) {
    final status = context.status;
    switch (this) {
      case AppTone.danger:
        return status.dangerContainer;
      case AppTone.warning:
        return status.warningContainer;
      case AppTone.success:
        return status.successContainer;
      case AppTone.info:
        return status.infoContainer;
      case AppTone.primary:
        return Theme.of(context).colorScheme.primaryContainer;
      case AppTone.neutral:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
  }

  Color resolve(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (this) {
      case AppTone.danger:
        return dark ? AppColors.dangerOnDark : AppColors.danger;
      case AppTone.warning:
        return dark ? AppColors.warningOnDark : AppColors.warning;
      case AppTone.success:
        return dark ? AppColors.paidOnDark : AppColors.paid;
      case AppTone.info:
        return dark ? AppColors.infoOnDark : AppColors.info;
      case AppTone.primary:
        return dark ? AppColors.primaryOnDark : AppColors.primary;
      case AppTone.neutral:
        return dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    }
  }

  /// The soft tinted background behind a toned card or pill, as a
  /// translucent wash. Prefer [container] where the result is layered.
  Color surface(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return on(context).withValues(alpha: dark ? 0.16 : 0.09);
  }

  /// The `tone` the API sends beside an enum value or a beat queue:
  /// `neutral | info | success | warning | danger | primary`. Mapped
  /// straight through — the server decides what a state means, not the app.
  static AppTone fromApi(String? tone) {
    switch (tone) {
      case 'success':
        return AppTone.success;
      case 'warning':
        return AppTone.warning;
      case 'danger':
        return AppTone.danger;
      case 'info':
        return AppTone.info;
      case 'primary':
        return AppTone.primary;
      default:
        return AppTone.neutral;
    }
  }
}
