import 'package:flutter/material.dart';

import '../text/app_text.dart';

/// Visual styles [AppButton] supports.
enum AppButtonVariant { primary, secondary, outline, ghost, danger }

/// The single button widget every screen should use.
///
/// Handles loading / disabled state, an optional leading icon, and full
/// width layout, all driven by [variant] so buttons look consistent
/// everywhere.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;
  final double height;

  bool get _disabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Color background;
    final Color foreground;
    final BorderSide border;

    switch (variant) {
      case AppButtonVariant.primary:
        background = scheme.primary;
        foreground = scheme.onPrimary;
        border = BorderSide.none;
        break;
      case AppButtonVariant.secondary:
        // The accent is gold: dark ink on it, always (white fails contrast).
        background = scheme.secondary;
        foreground = scheme.onSecondary;
        border = BorderSide.none;
        break;
      case AppButtonVariant.outline:
        background = Colors.transparent;
        foreground = scheme.primary;
        border = BorderSide(color: scheme.primary, width: 1.5);
        break;
      case AppButtonVariant.ghost:
        background = Colors.transparent;
        foreground = scheme.primary;
        border = BorderSide.none;
        break;
      case AppButtonVariant.danger:
        background = scheme.error;
        foreground = scheme.onError;
        border = BorderSide.none;
        break;
    }

    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: foreground),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 8),
              ],
              AppText(
                label,
                variant: AppTextVariant.labelLarge,
                color: foreground,
              ),
            ],
          );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: _disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          disabledBackgroundColor: background.withValues(alpha: 0.5),
          foregroundColor: foreground,
          elevation: 0,
          shadowColor: Colors.transparent,
          side: border,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: child,
      ),
    );
  }
}
