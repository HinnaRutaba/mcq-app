import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../motion/app_pressable.dart';
import '../text/app_text.dart';

/// A circular icon + label action, laid out in a row under a section
/// heading — the quick-access row pattern.
///
/// The whole column is one tap target, not just the circle: a 52px disc is
/// a small thing to hit while walking, and the label under it is the part
/// the officer is actually aiming at.
class AppQuickAction extends StatelessWidget {
  const AppQuickAction({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
    this.tone,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// An explicit colour. Prefer [tone], which resolves through the theme.
  final Color? color;

  final AppTone? tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? tone?.on(context) ?? scheme.primary;
    final plate = tone?.container(context) ?? scheme.primaryContainer;

    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              AppHaptics.select();
              onTap!();
            },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(color: plate, shape: BoxShape.circle),
              child: Icon(icon, color: tint, size: 25),
            ),
            const SizedBox(height: 9),
            AppText.caption(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
