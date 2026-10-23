import 'package:flutter/material.dart';

import '../../../../config/theme/app_brand.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_shadows.dart';
import '../../../../widgets/widgets.dart';

/// The home page's dark blocks: the brand gradient, a curved wash clipped
/// across it and a warm glow out of the corner.
///
/// Dark mode does not use the header gradient — it is near-black, and a
/// near-black card on a near-black page is not a card. There the plate is the
/// raised surface with the brand mixed into it.
class BrandPlate extends StatelessWidget {
  const BrandPlate({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 13, 16, 14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// The ink to draw on the plate.
  static Color inkOf(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    final dark = theme.brightness == Brightness.dark;
    final corner = BorderRadius.circular(AppRadius.lg);
    final ink = inkOf(context);

    final List<Color> plate = dark
        ? <Color>[
            Color.lerp(
              theme.colorScheme.surfaceContainerHigh,
              brand.primary,
              0.14,
            )!,
            theme.colorScheme.surfaceContainerLow,
          ]
        : <Color>[brand.headerFrom, brand.headerTo];

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: corner,
        boxShadow: AppShadows.lifted(context),
      ),
      child: ClipRRect(
        borderRadius: corner,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: plate,
            ),
            border: Border.all(color: ink.withValues(alpha: 0.12)),
            borderRadius: corner,
          ),
          child: Stack(
            children: <Widget>[
              // The accent's glow, low and out of the right-hand corner — the
              // warm note the scheme already carries, not a second brand.
              Positioned(
                right: -50,
                bottom: -66,
                child: _Glow(color: brand.accent, size: 190),
              ),
              Positioned.fill(
                child: ClipPath(
                  clipper: const AppSweepClipper(
                    begin: 0.86,
                    end: 0.40,
                    bow: 0.16,
                  ),
                  child: ColoredBox(color: ink.withValues(alpha: 0.055)),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// A soft disc of colour, for the corner of a plate.
class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color.withValues(alpha: 0.30),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
