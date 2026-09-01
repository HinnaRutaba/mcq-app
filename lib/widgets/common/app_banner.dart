import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../text/app_text.dart';
import 'app_status_badge.dart';

/// An inline message block: the area-scope line at the top of a screen, a
/// stale-cache warning, a stay-order warning, a 409 the officer has to act
/// on.
///
/// Not a toast. Anything the officer has to read while standing in front of
/// a shopkeeper needs a container that does not fade after three seconds.
class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.tone = AppStatusTone.info,
    this.action,
    this.onDismiss,
  });

  final String message;
  final String? title;
  final IconData? icon;
  final AppStatusTone tone;
  final Widget? action;
  final VoidCallback? onDismiss;

  // One place decides what each tone looks like, in both themes — see
  // [AppTone]. A banner's amber and a pill's amber are the same amber.
  Color _color(BuildContext context) => tone.tone.on(context);

  @override
  Widget build(BuildContext context) {
    final color = _color(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  AppText.titleMedium(title!, color: color),
                  const SizedBox(height: 2),
                ],
                AppText.body(message),
                if (action != null) ...[
                  const SizedBox(height: 10),
                  action!,
                ],
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: onDismiss,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
