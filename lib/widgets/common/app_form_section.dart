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
    this.optional = false,
    this.required = false,
    this.trailing,
  });

  /// The step's number, as it is printed — '1', '2'.
  final String step;

  final String title;

  /// One line under the title, where the section needs saying.
  final String? note;

  /// Says "Optional" on the title's own row rather than as a note under it.
  final bool optional;

  /// A red star after the title.
  final bool required;

  /// At the far end of the title row — a count badge, say.
  final Widget? trailing;

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
            // The title gets the room; a trailing badge keeps its own size.
            Expanded(
              child: Row(
                children: <Widget>[
                  Flexible(child: AppText.titleLarge(title)),
                  if (required)
                    Semantics(
                      label: 'required',
                      child: AppText.titleLarge(
                        ' *',
                        color: theme.colorScheme.error,
                      ),
                    ),
                  if (optional) ...<Widget>[
                    const SizedBox(width: 8),
                    AppText.body('Optional', color: muted),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
        if (note != null) ...<Widget>[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 34),
            child: AppText.body(note!, color: muted),
          ),
        ],
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
