import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/enforcement_case.dart';
import '../../../../widgets/widgets.dart';

/// One enforcement case as a card: where the file stands, what it is worth
/// now against when it opened, and what the officer may do with it.
///
/// Read in three places — a shop's own profile, the seal form's case picker,
/// and the [CasesScreen] list — which is why it lives here rather than beside
/// any one of them.
class CaseCard extends StatelessWidget {
  const CaseCard({
    super.key,
    required this.file,
    this.selected = false,
    this.showSubject = false,
    this.hint,
    this.onTap,
  });

  final EnforcementCase file;

  /// Whether this card is the one its screen is acting on — the case whose
  /// timeline is open, or the one a seal is being hung on.
  final bool selected;

  /// Whether to name the shop and holder the case is about. Off where the
  /// reader already knows — a shop's own profile, a picker of that shop's
  /// cases — and on for a list that spans the whole beat, where the case
  /// number alone says nothing about which shopfront to walk to.
  final bool showSubject;

  /// What tapping the card does, at the end of the count line. Null says
  /// nothing, for a card that does not respond to a tap.
  final String? hint;

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
              Expanded(child: AppText.titleMedium(_title, maxLines: 1)),
              if (file.status != null) ...<Widget>[
                const SizedBox(width: 12),
                AppStatusBadge(label: file.status!.label, tone: tone),
              ],
            ],
          ),
          if (_where != null) ...<Widget>[
            const SizedBox(height: 3),
            AppText.body(_where!, maxLines: 1),
          ],
          const SizedBox(height: 8),
          if (_opened != null)
            AppDetailRow(icon: Icons.folder_open_outlined, value: _opened!),
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
              ?hint,
            ].join(' · '),
            color: muted,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  /// The case number, unless the card is naming the shopfront — then the
  /// holder leads and the number moves down to the opened line, because a
  /// list of case numbers is not something an officer can read a beat off.
  String get _title => showSubject
      ? (_holder ?? _unit ?? _caseNo)
      : _caseNo;

  String get _caseNo => file.caseNo ?? 'Case #${file.id}';

  /// Whoever the case names. A conduct case can be about somebody who is not
  /// on the register at all, and then [EnforcementCase.offender] is the only
  /// name on the file.
  String? get _holder => file.allottee?.fullName ?? file.offender?.name;

  String? get _unit => file.property?.displayName ?? file.property?.propertyCode;

  /// The shop and its bazaar, dropped when the title above is already the
  /// shop. Only ever drawn under a card that is naming its subject.
  String? get _where {
    if (!showSubject) return null;
    final List<String> parts = <String>[
      if (_unit != null && _unit != _title) _unit!,
      ?file.area?.name,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// When the file was opened — carrying the case number where the title gave
  /// it up, so the number an officer reads down the phone is never missing.
  String? get _opened {
    final String? on = file.openedOn == null
        ? null
        : Formatters.date(file.openedOn!.toLocal());
    if (!showSubject) return on == null ? null : 'Opened $on';
    return on == null ? _caseNo : '$_caseNo · opened $on';
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
