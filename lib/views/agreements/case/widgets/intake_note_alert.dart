import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/agreement_case.dart';
import '../../../../widgets/widgets.dart';
import '../../shared/intake_labels.dart';

/// A return or an open query: who sent it and from where in bold, then their
/// words set off in a highlighted block that folds past two lines.
class IntakeNoteAlert extends StatelessWidget {
  const IntakeNoteAlert({
    super.key,
    required this.lead,
    required this.note,
    required this.tone,
    required this.icon,
  });

  /// "Returned", "Query".
  final String lead;
  final IntakeNote note;
  final AppTone tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final Color ink = tone.on(context);
    final TextStyle base = Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(color: ink);
    final TextStyle bold = base.copyWith(fontWeight: FontWeight.w800);
    final String? by = note.by;
    // "by Administrator, from the Administrator" says one thing twice.
    final String? from =
        note.fromStage == null ||
            (by ?? '').toLowerCase().contains(note.fromStage!.toLowerCase())
        ? null
        : IntakeLabels.branch(note.fromStage!);
    final String? remarks = note.remarks;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: tone.container(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: ink),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text.rich(
                  TextSpan(
                    style: base,
                    children: <InlineSpan>[
                      TextSpan(text: lead, style: bold),
                      if (by != null) ...<InlineSpan>[
                        const TextSpan(text: ' by '),
                        TextSpan(text: by, style: bold),
                      ],
                      if (from != null) ...<InlineSpan>[
                        const TextSpan(text: ' from '),
                        TextSpan(text: from, style: bold),
                      ],
                    ],
                  ),
                ),
                if (note.at != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: AppText.caption(
                      Formatters.date(note.at!.toLocal()),
                      color: ink.withValues(alpha: 0.75),
                    ),
                  ),
                if (remarks != null) ...<Widget>[
                  const SizedBox(height: 8),
                  _Quote(ink: ink, text: remarks),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The note's words on a stronger wash with a bar down the side.
class _Quote extends StatelessWidget {
  const _Quote({required this.ink, required this.text});

  final Color ink;
  final String text;

  @override
  Widget build(BuildContext context) {
    final Color words = Theme.of(context).colorScheme.onSurface;
    // Clipped rather than given a radius: a one-sided border can't take one.
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        decoration: BoxDecoration(
          color: ink.withValues(alpha: 0.12),
          border: Border(left: BorderSide(color: ink, width: 3)),
        ),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: AppExpandableText(
          '“$text”',
          color: words,
          fontWeight: FontWeight.w600,
          linkColor: ink,
        ),
      ),
    );
  }
}
