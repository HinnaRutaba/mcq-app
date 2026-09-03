import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/enforcement_action.dart';
import '../../../../widgets/widgets.dart';

/// A case's visit timeline: every warning given, notice served, promise made,
/// fine imposed and seal applied, in the order the server sent them.
///
/// This is the record a magistrate reads out if a seal is challenged, so it
/// shows what was recorded rather than a summary of it — the figure quoted on
/// the day, who quoted it, whether a photograph was taken, and whether the
/// entry was written in a bazaar with no signal and synced later.
class CaseTimeline extends StatelessWidget {
  const CaseTimeline({super.key, required this.actions});

  /// Oldest first, as the endpoint returns them. Never re-sorted here.
  final List<EnforcementAction> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < actions.length; i++)
          _Entry(
            action: actions[i],
            isFirst: i == 0,
            isLast: i == actions.length - 1,
          ),
      ],
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.action,
    required this.isFirst,
    required this.isLast,
  });

  final EnforcementAction action;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final AppTone tone = AppToneColors.fromApi(action.actionType?.tone);
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final String? owed = Formatters.money(action.amounts.outstandingAtAction);
    final String? fine = Formatters.money(action.amounts.fineAmount);

    // Intrinsic height so the rail runs the full height of the card beside
    // it: the line is what makes a column of cards read as one file.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Rail(
            icon: _glyph(action.actionType?.value),
            tone: tone,
            isFirst: isFirst,
            isLast: isLast,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: AppCard(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: AppText.body(
                            action.actionType?.label ?? 'Entry',
                            fontWeight: FontWeight.w700,
                            maxLines: 2,
                          ),
                        ),
                        if (action.actionDate != null) ...<Widget>[
                          const SizedBox(width: 12),
                          AppText.caption(
                            Formatters.date(action.actionDate!.toLocal()),
                            color: muted,
                            maxLines: 1,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    // The facts of the entry, each behind its own glyph, the
                    // way every other card in the app states one.
                    if (action.performedBy != null)
                      AppDetailRow(
                        icon: Icons.person_outline_rounded,
                        value: action.performedBy!.name,
                      ),
                    if (owed != null)
                      AppDetailRow(
                        icon: Icons.account_balance_wallet_outlined,
                        value: '$owed owed on the day',
                      ),
                    if (fine != null)
                      AppDetailRow(
                        icon: Icons.receipt_long_outlined,
                        value: '$fine fine',
                      ),
                    if (action.witnessName != null)
                      AppDetailRow(
                        icon: Icons.how_to_reg_outlined,
                        value: 'Witness ${action.witnessName}',
                      ),
                    if (action.remarks != null) _Remark(text: action.remarks!),
                    ..._marks(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The badges under an entry: what it committed the shopkeeper or the
  /// officer to, and how the record itself reached the server.
  List<Widget> _marks(BuildContext context) {
    final List<Widget> badges = <Widget>[
      if (action.promisedPaymentDate != null)
        AppStatusBadge(
          icon: Icons.handshake_outlined,
          label:
              'Promised ${Formatters.date(action.promisedPaymentDate!.toLocal())}',
          tone: AppTone.info,
        ),
      if (action.nextVisitDate != null)
        AppStatusBadge(
          icon: Icons.event_outlined,
          label:
              'Next visit ${Formatters.date(action.nextVisitDate!.toLocal())}',
        ),
      if (action.sealNo != null)
        AppStatusBadge(
          icon: Icons.lock_outline_rounded,
          label: 'Seal ${action.sealNo}',
          tone: AppTone.danger,
        ),
      if (action.hasPhoto)
        const AppStatusBadge(
          icon: Icons.photo_camera_outlined,
          label: 'Photograph',
          tone: AppTone.success,
        ),
      if (action.location.hasFix)
        const AppStatusBadge(
          icon: Icons.my_location_rounded,
          label: 'Located',
          tone: AppTone.success,
        ),
      if (action.sync.recordedOffline)
        AppStatusBadge(
          icon: Icons.cloud_off_rounded,
          label: _offline(action.sync),
        ),
    ];
    if (badges.isEmpty) return const <Widget>[];

    return <Widget>[
      const SizedBox(height: 2),
      Wrap(spacing: 12, runSpacing: 6, children: badges),
    ];
  }

  /// An entry written with no signal. The lag is the audit trail — the gap
  /// between the officer standing at the shop and the server hearing about it.
  static String _offline(ActionSync sync) {
    final int? lag = sync.lagMinutes;
    if (lag == null) return 'Recorded offline';
    if (lag < 60) return 'Offline · synced $lag min later';
    final int hours = lag ~/ 60;
    return 'Offline · synced ${hours}h later';
  }

  /// The glyph for a step of enforcement. Server-defined keys, mildest first;
  /// one it has not been told about still gets a mark on the rail.
  static IconData _glyph(String? actionType) => switch (actionType) {
    'site_visit' => Icons.storefront_outlined,
    'notice_served' => Icons.description_outlined,
    'verbal_warning' => Icons.campaign_outlined,
    'final_warning' => Icons.warning_amber_rounded,
    'payment_promised' => Icons.handshake_outlined,
    'reminder_visit_set' => Icons.event_outlined,
    'fine_imposed' => Icons.receipt_long_outlined,
    'shop_sealed' => Icons.lock_outline_rounded,
    'seal_released' => Icons.lock_open_outlined,
    _ => Icons.event_note_outlined,
  };
}

/// What the officer wrote at the shop, on a plate of its own so it does not
/// read as one more field: it is prose, and it is quoted as written.
class _Remark extends StatelessWidget {
  const _Remark({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color? muted = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.6,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.format_quote_rounded, size: 15, color: muted),
          const SizedBox(width: 8),
          // Verbatim: this is what the officer wrote at the shop.
          Expanded(child: AppText.body(text, maxLines: 4)),
        ],
      ),
    );
  }
}

/// The mark and the line down the side of an entry: which step of enforcement
/// this was, and that it belongs to the same file as the one above it.
class _Rail extends StatelessWidget {
  const _Rail({
    required this.icon,
    required this.tone,
    required this.isFirst,
    required this.isLast,
  });

  final IconData icon;
  final AppTone tone;
  final bool isFirst;
  final bool isLast;

  static const double _mark = 28;

  /// Where the mark sits, so it centres on the entry's first line of text
  /// rather than on the middle of the card.
  static const double _markTop = 9;

  @override
  Widget build(BuildContext context) {
    final Color line = Theme.of(context).dividerColor;

    return SizedBox(
      width: _mark,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: _markTop,
            child: isFirst ? null : _Line(color: line),
          ),
          Container(
            height: _mark,
            width: _mark,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tone.container(context),
              shape: BoxShape.circle,
              // A ring in the page's own colour, so the line running behind
              // the mark stops at it instead of touching the glyph.
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              ),
            ),
            child: Icon(icon, size: 15, color: tone.on(context)),
          ),
          Expanded(
            child: isLast ? const SizedBox.shrink() : _Line(color: line),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      Center(child: Container(width: 2, color: color));
}
