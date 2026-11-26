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
    // Newest first by time; undated steps go last.
    final List<IntakeAction> steps = actions.reversed.toList()
      ..sort((IntakeAction a, IntakeAction b) {
        if (a.at == null || b.at == null) {
          return (a.at == null ? 1 : 0) - (b.at == null ? 1 : 0);
        }
        return b.at!.compareTo(a.at!);
      });
    final DateTime now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < steps.length; i++)
          AppEntrance(
            index: i,
            child: _Step(
              action: steps[i],
              last: i == steps.length - 1,
              // How long the case sat after this step: until the next, or now.
              held: steps[i].at == null
                  ? null
                  : (i == 0 ? now : steps[i - 1].at ?? now).difference(
                      steps[i].at!,
                    ),
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
    this.held,
    this.openingUrl,
  });

  final IntakeAction action;
  final Duration? held;

  /// The bottom step, the oldest: the rail stops at its node.
  final bool last;
  final ValueChanged<IntakeDocument> onOpen;
  final String? openingUrl;

  @override
  Widget build(BuildContext context) {
    final AppTone tone = _tone(action.action?.value);
    final String? label = action.action?.label;
    final Color rail = Theme.of(context).dividerColor;

    // The rail runs the step's full height, so it meets the next node.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: _node,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 16),
                Container(
                  height: _node,
                  width: _node,
                  decoration: BoxDecoration(
                    color: tone.container(context),
                    shape: BoxShape.circle,
                    border: Border.all(color: tone.on(context), width: 2),
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: rail,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 12),
              child: _card(context, tone, label),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, AppTone tone, String? label) {
    final String? role = action.actorRole == null
        ? null
        : IntakeLabels.humanise(action.actorRole!);
    final String? branch = action.branch == null
        ? null
        : IntakeLabels.branch(action.branch!);
    final String? to = action.destination != null
        ? IntakeLabels.branch(action.destination!)
        : action.toStatus == null
        ? null
        : IntakeLabels.status(action.toStatus!);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppStatusBadge(
            label: label == null || label == action.action?.value
                ? IntakeLabels.humanise(action.action?.value ?? 'Step')
                : label,
            tone: tone,
            icon: _glyph(action.action?.value),
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _Party(
                    tag: 'FROM',
                    name: action.actor ?? branch ?? '—',
                    detail: <String>{
                      ?role,
                      ?branch,
                    }.where((String d) => d != action.actor).join(' · '),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: tone.on(context),
                  ),
                ),
                Expanded(
                  child: _Party(tag: 'TO', name: to ?? '—'),
                ),
              ],
            ),
          ),
          if (action.changeCount > 0) ...<Widget>[
            const SizedBox(height: 8),
            AppDetailRow(
              icon: Icons.edit_note_rounded,
              value:
                  'Resubmitted with ${action.changeCount} '
                  '${action.changeCount == 1 ? 'change' : 'changes'}',
              maxLines: null,
            ),
          ],
          if (action.remarks != null) ...<Widget>[
            const SizedBox(height: 8),
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
          if (action.at != null || held != null) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                if (action.at != null)
                  AppStatusBadge(
                    label: Formatters.dateTime(action.at!.toLocal()),
                    icon: Icons.schedule_rounded,
                  ),
                if (held != null)
                  AppStatusBadge(
                    label: Formatters.span(held!),
                    icon: Icons.hourglass_empty_rounded,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static const double _node = 14;

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

/// One side of a step: who sent it, or where it went.
class _Party extends StatelessWidget {
  const _Party({required this.tag, required this.name, this.detail = ''});

  final String tag;
  final String name;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppText.caption(tag, color: muted, fontWeight: FontWeight.w700),
          const SizedBox(height: 2),
          AppText.body(name, fontWeight: FontWeight.w700, maxLines: 2),
          if (detail.isNotEmpty)
            AppText.caption(detail, color: muted, maxLines: 2),
        ],
      ),
    );
  }
}
