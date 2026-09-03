import 'package:flutter/material.dart';

import '../text/app_text.dart';
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

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.pill);

    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: compact ? 30 : 36,
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: compact ? 14 : 16, color: Colors.white),
              SizedBox(width: compact ? 6 : 8),
              if (compact)
                AppText.caption(
                  label,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                )
              else
                AppText.label(
                  label,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
