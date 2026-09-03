import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/enforcement_case.dart';
import '../../../../widgets/widgets.dart';


class CaseCard extends StatelessWidget {
  const CaseCard({
    super.key,
    required this.file,
    this.selected = false,
    this.onTap,
  });

  final EnforcementCase file;

  /// Whether the history tab is showing this case's timeline.
  final bool selected;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppTone tone = AppToneColors.fromApi(file.status?.tone);
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final String? now = Formatters.money(file.position.outstandingNow);
    final String? atOpen = Formatters.money(file.amounts.outstandingAtOpen);

    return AppCard(
      onTap: onTap,
      // The selected file is outlined in the brand colour rather than tinted:
      // the status pill already owns the colour on this card, and a second
      // wash behind it would argue with it.
      borderColor: selected ? primary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: AppText.titleMedium(
                  file.caseNo ?? 'Case #${file.id}',
                  maxLines: 1,
                ),
              ),
              if (file.status != null) ...<Widget>[
                const SizedBox(width: 12),
                AppStatusBadge(label: file.status!.label, tone: tone),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (file.openedOn != null)
            AppDetailRow(
              icon: Icons.folder_open_outlined,
              value: 'Opened ${Formatters.date(file.openedOn!.toLocal())}',
            ),
          if (now != null)
            AppDetailRow(
              icon: Icons.account_balance_wallet_outlined,
              value: atOpen == null
                  ? '$now owed'
                  : '$now owed · $atOpen when it opened',
            ),
          if (file.nextVisitDate != null)
            AppDetailRow(
              icon: Icons.event_outlined,
              value:
                  'Next visit ${Formatters.date(file.nextVisitDate!.toLocal())}',
            ),
          if (file.magistrate != null)
            AppDetailRow(
              icon: Icons.assignment_ind_outlined,
              value: 'With ${file.magistrate!.name}',
            ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: <Widget>[
              ?_movement(context, file.position.direction),
              if (file.visitOverdue)
                const AppStatusBadge(
                  label: 'Visit overdue',
                  tone: AppTone.danger,
                ),
              if (file.isSealed)
                const AppStatusBadge(label: 'Sealed', tone: AppTone.danger),
              if (file.unpaidMonths != null)
                AppStatusBadge(label: '${file.unpaidMonths} months unpaid'),
              if (file.priority != null)
                AppStatusBadge(
                  label: file.priority!.label,
                  tone: AppToneColors.fromApi(file.priority!.tone),
                ),
            ],
          ),
          const SizedBox(height: 8),
          AppText.caption(
            <String>[
              '${file.actionCount} ${file.actionCount == 1 ? 'entry' : 'entries'}',
              if (file.fineCount > 0)
                '${file.fineCount} ${file.fineCount == 1 ? 'fine' : 'fines'}',
              if (selected) 'history open' else 'tap to read its history',
            ].join(' · '),
            color: muted,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  /// Which way the debt has moved since the file opened — the server's own
  /// reading, never worked out here from two money strings.
  ///
  /// `level` is the only value the published spec captures; anything else is
  /// shown as sent rather than guessed at.
  static Widget? _movement(BuildContext context, String? direction) {
    if (direction == null) return null;
    return switch (direction) {
      'level' => const AppStatusBadge(label: 'Unchanged'),
      'up' || 'grown' || 'increased' => const AppStatusBadge(
        label: 'Debt grown',
        tone: AppTone.danger,
      ),
      'down' || 'reduced' || 'decreased' => const AppStatusBadge(
        label: 'Debt down',
        tone: AppTone.success,
      ),
      _ => AppStatusBadge(label: _humanise(direction)),
    };
  }

  static String _humanise(String value) {
    final String words = value.replaceAll('_', ' ').trim();
    if (words.isEmpty) return 'Unknown';
    return words[0].toUpperCase() + words.substring(1);
  }
}
