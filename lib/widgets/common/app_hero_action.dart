import 'package:flutter/material.dart';

import '../text/app_text.dart';
import '../../config/theme/app_brand.dart';
import '../../config/theme/app_radius.dart';

/// An action that belongs to whoever the hero header names — call the holder,
/// message them, open where their shop stands on a map.
///
/// A translucent white pill rather than an [AppButton]: the header is a brand
/// gradient, and a filled brand button on it is invisible. White ink and a
/// white wash, because the gradient is authored dark enough to carry white
/// text — the same reason the title on it is white.
class AppHeroAction extends StatelessWidget {
  const AppHeroAction({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.compact = false,
    this.solid = false,
  });

  final IconData icon;

  /// Always shown. The glyph is a second reading of the action, never the only
  /// one — "Call" and "Message" are one handset apart otherwise.
  final String label;

  final VoidCallback? onTap;

  /// A smaller pill, for a collapsed app bar where the action rides under the
  /// title rather than under a whole hero block. The label stays — see
  /// [label]; only the pill around it shrinks.
  final bool compact;

  /// Solid white with brand ink, for the one action a screen is really for.
  /// The wash above reads as a chip beside two others; filled, it reads as the
  /// button it is. Wins over [compact] — a page's main action is full size.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.pill);

    // The gradient's own dark end, so the ink stays the brand's and is still
    // guaranteed legible on white — that end is authored to carry white text.
    final Color ink = solid ? context.brand.headerFrom : Colors.white;
    final bool small = compact && !solid;

    return Material(
      color: solid ? Colors.white : Colors.white.withValues(alpha: 0.16),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: small ? 30 : (solid ? 40 : 36),
          padding: EdgeInsets.symmetric(
            horizontal: small ? 10 : (solid ? 18 : 14),
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: solid
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: small ? 14 : (solid ? 19 : 16), color: ink),
              SizedBox(width: small ? 6 : 8),
              if (small)
                AppText.caption(label, color: ink, fontWeight: FontWeight.w700)
              else
                AppText.label(label, color: ink, fontWeight: FontWeight.w700),
            ],
          ),
        ),
      ),
    );
  }
}
