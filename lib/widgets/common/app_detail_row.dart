import 'package:flutter/material.dart';

import '../text/app_text.dart';

/// One fact about a record: a glyph, and the fact itself.
///
/// The label is left out on purpose — "Last signed in 2 Sep 2026" and a phone
/// number beside a handset icon read without one, and a column of "Mobile:"
/// prefixes costs a third of a narrow screen's width to say what the icon
/// already said. Rows are only drawn for fields the server actually sent: one
/// reading "—" is noise.
class AppDetailRow extends StatelessWidget {
  const AppDetailRow({
    super.key,
    required this.icon,
    required this.value,
    this.maxLines = 1,
    this.trailing,
  });

  final IconData icon;
  final String value;
  final int maxLines;

  /// An action the fact carries — a call button beside a number.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: muted),
          const SizedBox(width: 10),
          Expanded(child: AppText.body(value, maxLines: maxLines)),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );
  }
}
