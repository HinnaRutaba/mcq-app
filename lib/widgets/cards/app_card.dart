import 'package:flutter/material.dart';
import '../../config/theme/app_radius.dart';

/// The single card container every list item / grouped-content block
/// should use, instead of a raw [Container]/[Card].
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  /// A tinted plate to draw the card on instead of the surface — pass
  /// `tone.container(context)` for a status wash. Opaque, so a pill or a
  /// filled chip inside the card stays readable.
  final Color? color;

  /// Defaults to the theme divider. Pass a tone-tinted border to go with
  /// [color].
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.md);

    return Material(
      color: color ?? theme.cardTheme.color ?? theme.colorScheme.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: borderColor ?? theme.dividerColor),
          ),
          child: child,
        ),
      ),
    );
  }
}
