import 'package:flutter/material.dart';

import '../text/app_text.dart';

/// A circular icon + label action, laid out in a row under a header (Pay
/// Now / Payments / Profile, etc.) — the quick-access row pattern.
class AppQuickAction extends StatelessWidget {
  const AppQuickAction({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(color: tint.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: tint),
            ),
            const SizedBox(height: 8),
            AppText.caption(label),
          ],
        ),
      ),
    );
  }
}
