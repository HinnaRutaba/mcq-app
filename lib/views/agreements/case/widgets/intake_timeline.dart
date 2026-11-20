import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/agreement_case.dart';
import '../../../../widgets/widgets.dart';
import '../../shared/intake_labels.dart';

/// The case's workflow, newest step first: who acted, at which branch, what
/// they wrote and what they attached. Nothing here is cut short.
class IntakeTimeline extends StatelessWidget {
  const IntakeTimeline({
    super.key,
    required this.actions,
    required this.onOpen,
    this.openingUrl,
  });

  final List<IntakeAction> actions;
  final ValueChanged<IntakeDocument> onOpen;
  final String? openingUrl;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const AppEmptyState(
        icon: Icons.timeline_rounded,
        title: 'No steps yet',
        message: 'Each act on the case is recorded here.',
      );
    }
    // The server sends them oldest first.
    final List<IntakeAction> steps = actions.reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < steps.length; i++)
          AppEntrance(
            index: i,
            child: _Step(
              action: steps[i],
              last: i == steps.length - 1,
              onOpen: onOpen,
              openingUrl: openingUrl,
            ),
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.action,
    required this.last,
    required this.onOpen,
    this.openingUrl,
  });

  final IntakeAction action;

  /// The bottom step, the oldest: the rail stops at its node.
  final bool last;
  final ValueChanged<IntakeDocument> onOpen;
  final String? openingUrl;

  @override
  Widget build(BuildContext context) {
    final AppTone tone = _tone(action.action?.value);
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final String? label = action.action?.label;
    final String who = <String>[
      ?action.actor,
      if (action.actorRole != null) IntakeLabels.humanise(action.actorRole!),
      if (action.branch != null) IntakeLabels.branch(action.branch!),
    ].join(' · ');
    final String? move = action.fromStatus == null || action.toStatus == null
        ? null
        : '${IntakeLabels.status(action.fromStatus!)} → '
              '${IntakeLabels.status(action.toStatus!)}';

    final Color rail = Theme.of(context).dividerColor;
    final Widget node = Container(
      height: _node,
      width: _node,
      decoration: BoxDecoration(
        color: tone.container(context),
        shape: BoxShape.circle,
        border: Border.all(
          color: tone.on(context).withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Icon(
        _glyph(action.action?.value),
        size: 16,
        color: tone.on(context),
      ),
    );

    // The rail runs the step's full height, so it meets the next node.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: _node,
            child: Column(
              children: <Widget>[
                node,
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: rail,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 14),
              child: _card(context, label, who, move, muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context,
    String? label,
    String who,
    String? move,
    Color? muted,
  ) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppText.body(
            label == null || label == action.action?.value
                ? IntakeLabels.humanise(action.action?.value ?? 'Step')
                : label,
            fontWeight: FontWeight.w700,
          ),
          if (action.at != null)
            AppText.caption(
              Formatters.dateTime(action.at!.toLocal()),
              color: muted,
            ),
          const SizedBox(height: 8),
          if (who.isNotEmpty)
            AppDetailRow(
              icon: Icons.person_outline_rounded,
              value: who,
              maxLines: null,
            ),
          if (move != null)
            AppDetailRow(
              icon: Icons.swap_horiz_rounded,
              value: move,
              maxLines: null,
            ),
          if (action.destination != null)
            AppDetailRow(
              icon: Icons.call_split_rounded,
              value: 'Sent to ${IntakeLabels.branch(action.destination!)}',
              maxLines: null,
            ),
          if (action.changeCount > 0)
            AppDetailRow(
              icon: Icons.edit_note_rounded,
              value:
                  'Resubmitted with ${action.changeCount} '
                  '${action.changeCount == 1 ? 'change' : 'changes'}',
              maxLines: null,
            ),
          if (action.remarks != null) ...<Widget>[
            const SizedBox(height: 2),
            AppText.body('“${action.remarks}”'),
          ],
          for (final IntakeDocument file in action.attachments)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: AppDetailRow(
                icon: file.isPdf
                    ? Icons.picture_as_pdf_outlined
                    : Icons.attach_file_rounded,
                value: file.name,
                maxLines: null,
                trailing: file.url == null
                    ? null
                    : openingUrl == file.url
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : AppCircleIconButton(
                        icon: Icons.open_in_new_rounded,
                        size: 30,
                        // On a card, not a header: the white default vanishes.
                        background: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        iconColor: Theme.of(context).colorScheme.primary,
                        onTap: () => onOpen(file),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  static const double _node = 34;

  static AppTone _tone(String? action) => switch (action) {
    'endorsed' || 'approved' || 'dispatched' => AppTone.success,
    'rejected' => AppTone.danger,
    'returned' || 'queried' => AppTone.warning,
    'responded' => AppTone.info,
    final String a when a.contains('forward') => AppTone.success,
    _ => AppTone.neutral,
  };

  static IconData _glyph(String? action) => switch (action) {
    'submitted' || 'resubmitted' => Icons.upload_file_outlined,
    'endorsed' => Icons.thumb_up_alt_outlined,
    'approved' => Icons.verified_outlined,
    'rejected' => Icons.block_rounded,
    'returned' || 'queried' => Icons.undo_rounded,
    'responded' => Icons.question_answer_outlined,
    'dispatched' => Icons.send_outlined,
    final String a when a.contains('forward') => Icons.forward_outlined,
    _ => Icons.circle_outlined,
  };
}
