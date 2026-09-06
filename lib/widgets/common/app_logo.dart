import 'package:flutter/material.dart';

import '../../config/theme/app_radius.dart';
import '../text/app_text.dart';

/// The corporation's crest, on the white plate the launcher icon uses.
///
/// The artwork is dark green ink on transparency, so it needs a light ground
/// of its own — dropped straight onto the brand gradient it would all but
/// disappear.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 108, this.radius});

  static const String asset = 'assets/mcq-logo.png';

  final double size;

  /// The plate's corner. Defaults to the step that suits the size: [AppRadius]
  /// picks by how big the thing being rounded is.
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      padding: EdgeInsets.all(size * 0.13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          radius ?? (size >= 88 ? AppRadius.xl : AppRadius.lg),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        semanticLabel: 'Metropolitan Corporation Quetta',
      ),
    );
  }
}

/// Whose app this is, said quietly at the foot of a screen.
///
/// [onDark] tints the crest white for the brand gradient — it is a
/// single-colour mark on transparency, so the cutouts stay cutouts and the
/// tint costs nothing but the ink.
class AppGovernmentMark extends StatelessWidget {
  const AppGovernmentMark({super.key, this.onDark = false, this.height = 34});

  static const String asset = 'assets/gob-logo.png';

  final bool onDark;
  final double height;

  @override
  Widget build(BuildContext context) {
    final Color ink = onDark
        ? Colors.white.withValues(alpha: 0.85)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);

    Widget crest = Image.asset(
      asset,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'Government of Balochistan',
    );
    // The artwork's own dark green disappears on anything but a light ground,
    // so on the gradient — and on the dark scheme's surface — it is tinted.
    if (onDark || Theme.of(context).brightness == Brightness.dark) {
      crest = ColorFiltered(
        colorFilter: ColorFilter.mode(ink, BlendMode.srcIn),
        child: crest,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        crest,
        const SizedBox(height: 8),
        AppText.caption('Government of Balochistan', color: ink),
      ],
    );
  }
}
