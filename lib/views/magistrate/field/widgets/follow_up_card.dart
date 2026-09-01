import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/field/follow_up.dart';
import '../../../../widgets/widgets.dart';

/// One row of the chase queue.
///
/// Three states, three treatments, because they call for three different
/// things. Overdue is red and offers escalation on the spot — he said he
/// would pay and did not. Due today is amber and offers a call first.
/// Upcoming is a note.
///
/// **Both amounts are shown**, and that is the useful part: a balance that
/// has come down means the promise was partly kept, which is a completely
/// different conversation from one that has not moved at all.
class FollowUpCard extends StatelessWidget {
  const FollowUpCard({
    super.key,
    required this.followUp,
    this.onTap,
    this.onCall,
    this.onEscalate,
  });

  final FollowUp followUp;
  final VoidCallback? onTap;
  final VoidCallback? onCall;

  /// Offered on an overdue promise only. Fine, seal, open a case — the
  /// steps a broken promise justifies.
  final VoidCallback? onEscalate;

  AppTone get _tone {
    switch (followUp.state) {
      case FollowUpState.overdue:
        return AppTone.danger;
      case FollowUpState.dueToday:
        return AppTone.warning;
      case FollowUpState.upcoming:
        return AppTone.neutral;
    }
  }

  String get _headline {
    switch (followUp.state) {
      case FollowUpState.overdue:
        return followUp.isPromise
            ? t('followUps.brokenDaysAgo',
                args: {'days': '${followUp.daysOverdue}'})
            : t('followUps.visitOverdue',
                args: {'days': '${followUp.daysOverdue}'});
      case FollowUpState.dueToday:
        return followUp.isPromise
            ? t('followUps.promisedToday')
            : t('followUps.visitToday');
      case FollowUpState.upcoming:
        return followUp.isPromise
            ? t('followUps.dueInDays',
                args: {'days': '${followUp.daysRemaining}'})
            : t('followUps.visitInDays',
                args: {'days': '${followUp.daysRemaining}'});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final colour = _tone.on(context);

    return AppCard(
      onTap: onTap,
      tone: _tone == AppTone.neutral ? null : _tone,
      rail: _tone != AppTone.neutral,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                followUp.isPromise
                    ? Icons.handshake_rounded
                    : Icons.event_repeat_rounded,
                size: 18,
                color: colour,
              ),
              const SizedBox(width: 8),
              Expanded(child: AppText.titleMedium(_headline, color: colour)),
            ],
          ),
          const SizedBox(height: 12),
          UserText.headline(followUp.allotteeName, maxLines: 2),
          const SizedBox(height: 3),
          AppText.bodySmall(followUp.unitLabel, color: muted, maxLines: 1),
          UserText.caption(followUp.areaName, color: muted),
          if ((followUp.remarks ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(11),
              ),
              // The shopkeeper's own words, kept verbatim: "Said he would
              // pay after Eid" is the most useful sentence on this card.
              child: UserText.body('“${followUp.remarks!}”', maxLines: 3),
            ),
          ],
          const SizedBox(height: 14),
          _Balances(followUp: followUp),
          const SizedBox(height: 14),
          Row(
            children: [
              if (onCall != null)
                Expanded(
                  child: AppButton(
                    label: t('common.call'),
                    icon: Icons.phone_rounded,
                    variant: followUp.state == FollowUpState.dueToday
                        // Due today: the call is the whole job.
                        ? AppButtonVariant.primary
                        : AppButtonVariant.outline,
                    height: 46,
                    onPressed: onCall,
                  ),
                ),
              if (onCall != null && onEscalate != null)
                const SizedBox(width: 10),
              if (onEscalate != null)
                Expanded(
                  child: AppButton(
                    label: t('followUps.escalate'),
                    icon: Icons.gavel_rounded,
                    variant: AppButtonVariant.danger,
                    height: 46,
                    onPressed: onEscalate,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The balance when the promise was taken, and the balance now.
///
/// The brief asks for "Paid ₨3,000 since promising" and that sentence
/// quotes a figure at a counter — a figure this app is not allowed to
/// compute, because subtracting two server amounts in Dart is the same
/// error as adding them. So both figures are shown as the server sent them
/// and the movement is stated in words. A `paid_since_promise` field on the
/// payload would let the exact sentence be drawn; it is filed in
/// QUESTIONS.md.
class _Balances extends StatelessWidget {
  const _Balances({required this.followUp});

  final FollowUp followUp;

  @override
  Widget build(BuildContext context) {
    final then = followUp.outstandingAtPromise;
    final now = followUp.outstandingNow;
    if (then == null || now == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final moved = followUp.hasPaidSomething;

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(13, 11, 13, 11),
      decoration: BoxDecoration(
        color: (moved ? AppTone.success : AppTone.neutral).surface(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.bodySmall(t('followUps.atPromise'), color: muted),
                    MoneyText(
                      then,
                      variant: AppTextVariant.titleSmall,
                      color: muted,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, size: 16, color: muted),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppText.bodySmall(t('followUps.now'), color: muted),
                  MoneyText(
                    now,
                    variant: AppTextVariant.titleMedium,
                    color: moved
                        ? AppTone.success.on(context)
                        : AppTone.danger.on(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                moved ? Icons.trending_down_rounded : Icons.horizontal_rule_rounded,
                size: 15,
                color: moved
                    ? AppTone.success.on(context)
                    : AppTone.danger.on(context),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: AppText.bodySmall(
                  moved
                      ? t('followUps.hasComeDown')
                      : followUp.hasNotMoved
                          ? t('followUps.hasNotMoved')
                          : t('followUps.hasGoneUp'),
                  color: moved
                      ? AppTone.success.on(context)
                      : AppTone.danger.on(context),
                ),
              ),
              if (followUp.dueOn != null)
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: AppText.bodySmall(
                    Formatters.date(followUp.dueOn!),
                    color: muted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
