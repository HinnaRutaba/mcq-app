import 'package:flutter/material.dart';
import '../../config/theme/app_radius.dart';
import '../../config/theme/app_shadows.dart';

/// How far a card stands off the page.
enum AppLift {
  /// Flat on the page, held by its border alone. The app's default.
  none,

  /// Lifted just enough that the page reads as a surface under it.
  soft,

  /// The one block on a screen that should read as raised.
  high,
}

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
    this.lift = AppLift.none,
    this.radius = AppRadius.md,
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
  ///
  /// [Colors.transparent] drops the edge, for a card that is already held by
  /// its own plate and its shadow.
  final Color? borderColor;

  /// The shadow under the card. Off by default: a page where everything is
  /// lifted has no depth, only haze.
  final AppLift lift;

  /// The corner. [AppRadius.md] unless the card is big enough to want more.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final corner = BorderRadius.circular(radius);

    final Widget content = InkWell(
      borderRadius: corner,
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: corner,
          border: Border.all(color: borderColor ?? theme.colorScheme.outline),
        ),
        child: child,
      ),
    );

    final Widget card = Material(
      color: gradient != null
          ? Colors.transparent
          : color ?? theme.cardTheme.color ?? theme.colorScheme.surface,
      borderRadius: corner,
      // [Ink] rather than a plain container: the gradient is painted onto the
      // Material, so a tap ripple still shows above it.
      child: gradient == null
          ? content
          : Ink(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: corner,
              ),
              child: content,
            ),
    );

    if (lift == AppLift.none) return card;

    // The shadow is cast by a box behind the card rather than by the Material,
    // so a gradient plate keeps its own colour instead of being tinted by an
    // elevation overlay.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: corner,
        boxShadow: lift == AppLift.high
            ? AppShadows.lifted(context)
            : AppShadows.soft(context),
      ),
      child: card,
    );
  }
}
