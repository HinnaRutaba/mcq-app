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
    this.gradient,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  /// A tinted plate to draw the card on instead of the surface — pass
  /// `tone.container(context)` for a status wash. Opaque, so a pill or a
  /// filled chip inside the card stays readable.
  final Color? color;

  /// A gradient plate instead of [color] — pass `context.brand.filledPlate`
  /// for a solid brand tile.
  final Gradient? gradient;

  /// Defaults to the scheme's outline — a component's edge, which is a firmer
  /// line than the divider this used to draw and the one `cardTheme.shape`
  /// already names. Pass a tone-tinted border to go with [color].
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.md);

    final Widget content = InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: borderColor ?? theme.colorScheme.outline),
        ),
        child: child,
      ),
    );

    return Material(
      color: gradient != null
          ? Colors.transparent
          : color ?? theme.cardTheme.color ?? theme.colorScheme.surface,
      borderRadius: radius,
      // [Ink] rather than a plain container: the gradient is painted onto the
      // Material, so a tap ripple still shows above it.
      child: gradient == null
          ? content
          : Ink(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: radius,
              ),
              child: content,
            ),
    );
  }
}
