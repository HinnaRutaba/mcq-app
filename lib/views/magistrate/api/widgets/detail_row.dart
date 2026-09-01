import 'package:flutter/material.dart';

import '../../../../widgets/widgets.dart';

/// A label and its value on one line, laid out with logical (start/end)
/// padding so it mirrors correctly in Urdu.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
    this.icon,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 6, 0, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
          ],
          Expanded(child: AppText.caption(label, maxLines: 2)),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: valueWidget ??
                  AppText.body(
                    value ?? '—',
                    fontWeight: FontWeight.w600,
                    textAlign: TextAlign.end,
                    maxLines: 3,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
