import 'package:flutter/material.dart';

import '../../config/theme/app_radius.dart';
import '../text/app_text.dart';

class AppFormSection extends StatelessWidget {
  const AppFormSection({
    super.key,
    required this.step,
    required this.title,
    required this.child,
    this.note,
  });

  /// The step's number, as it is printed — '1', '2'.
  final String step;

  final String title;

  /// One line under the title, where the section needs saying.
  final String? note;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color? muted = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.6,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              height: 24,
              width: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: AppText.caption(
                step,
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: AppText.titleLarge(title)),
          ],
        ),
        if (note != null) ...<Widget>[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 34),
            child: AppText.body(note!, color: muted),
          ),
        ],
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
