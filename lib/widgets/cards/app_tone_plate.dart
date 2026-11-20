import 'package:flutter/material.dart';

import '../../config/theme/app_brand.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';
import '../../config/theme/app_shadows.dart';
import '../common/app_sweep_clipper.dart';

/// A tile's surface in one status tone: a tinted gradient, a curved wash
/// clipped across its foot, and a soft shadow. Draw on it in `tone.on`.
class AppTonePlate extends StatelessWidget {
  const AppTonePlate({
    super.key,
    required this.tone,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(10, 9, 10, 9),
    this.fit = StackFit.expand,
  });

  final AppTone tone;
  final Widget child;
  final EdgeInsetsGeometry padding;

  /// [StackFit.expand] fills a fixed-size tile; [StackFit.loose] hugs the
  /// child, for a plate in a scrolling column.
  final StackFit fit;

  @override
  Widget build(BuildContext context) {
    final Color ink = tone.on(context);
    final bool toned = tone != AppTone.neutral;

    // Neutral sits on the card surface: the scheme's highest container is
    // the page's own colour, and a shadow alone cannot lift a tile off that.
    final Color plate = toned
        ? tone.container(context)
        : Theme.of(context).colorScheme.surface;
    // Neutral ink is a mid-grey, and a grey band reads as a smudge; the
    // brand reads as light falling on the tile.
    final Color wash = toned
        ? ink.withValues(alpha: 0.08)
        : context.brand.primary.withValues(alpha: 0.055);
    final BorderRadius corner = BorderRadius.circular(AppRadius.lg);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: corner,
        boxShadow: AppShadows.soft(context),
      ),
      child: ClipRRect(
        borderRadius: corner,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color.lerp(plate, Colors.white, 0.10)!,
                Color.lerp(plate, ink, 0.09)!,
              ],
            ),
            border: Border.all(color: ink.withValues(alpha: 0.16)),
            borderRadius: corner,
          ),
          child: Stack(
            fit: fit,
            children: <Widget>[
              Positioned.fill(
                child: ClipPath(
                  clipper: const AppSweepClipper(
                    begin: 0.74,
                    end: 0.40,
                    bow: 0.16,
                  ),
                  child: ColoredBox(color: wash),
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
