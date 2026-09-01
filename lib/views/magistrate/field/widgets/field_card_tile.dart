import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/dialer.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/field/field_card.dart';
import '../../../../widgets/widgets.dart';

/// **One card widget, for every list in the app.**
///
/// `field/defaulters`, `field/units` and the round's `stops` all return the
/// same object, so this draws all three. Two widgets that started the same
/// and drifted apart is exactly the failure the server's shared shape was
/// designed to prevent, and the app should not reintroduce it.
///
/// The card carries everything needed to decide **without opening
/// anything** — an officer with five minutes and one hand free cannot be
/// tapping into a detail screen per shop.
///
/// ### The layout, and why it changed
///
/// The previous card put everything at one weight and the list read as a
/// wall: eight pills, a name, an address, an agreement number and a
/// full-width button per row, so no two rows looked different from four
/// feet away. This one is built in three bands separated by real space:
///
/// 1. **Who and where** — the name at title weight, the unit and market
///    beneath it in muted body, and the call button *here*, beside the
///    name, rather than costing a whole row at the bottom.
/// 2. **What is owed** — right-aligned, at display size, in the danger
///    tone, under a small caption saying what the figure is. It is the
///    largest thing on the card because it is the thing the officer is
///    looking for.
/// 3. **The triage signals** — pills, below a hairline, and **capped at
///    three** with a "+N" overflow. A signal an officer has to hunt for is
///    a signal he does not see; nine of them is nine he does not see. The
///    rest are on the profile, one tap away.
///
/// The pills are ordered by what an officer triages on, so the four that
/// survive the cap are the four that matter: the commitment first, then
/// never-paid, then how far past due, then the seal.
class FieldCardTile extends StatelessWidget {
  const FieldCardTile({
    super.key,
    required this.card,
    this.onTap,
    this.onCall,
    this.trailing,
    this.dimmed = false,
    this.heroPrefix = 'card',
    this.maxPills = 3,
  });

  final FieldCard card;
  final VoidCallback? onTap;

  /// Null hides the call button. A card with no mobile number on it is not
  /// a card with a dead button on it.
  final VoidCallback? onCall;

  /// A tick, a chevron, a "walked" marker — whatever the list needs.
  final Widget? trailing;

  /// Drawn back, for a stop the officer has already called on.
  final bool dimmed;

  /// Namespaces the [Hero] tags so the same shop appearing in two lists on
  /// one screen does not collide.
  final String heroPrefix;

  /// How many pills survive before the rest fold into a "+N". Three is
  /// what fits on two rows at the sizes this app uses, and it is also
  /// about as many signals as anybody triages on at a glance.
  final int maxPills;

  AppTone get _tone {
    if (card.isSealed) return AppTone.danger;
    if (card.promiseBroken) return AppTone.danger;
    if (card.isVacant) return AppTone.info;
    if (card.promiseStanding) return AppTone.warning;
    if (card.neverPaid) return AppTone.danger;
    return AppTone.neutral;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = _pills(context);
    final pills = all.take(maxPills).toList();
    // The ones that did not fit are counted into the action row rather
    // than costing a whole third row of their own to say "+2".
    final hidden = all.length - pills.length;

    final body = AppCard(
      onTap: onTap,
      tone: _tone == AppTone.neutral ? null : _tone,
      rail: _tone != AppTone.neutral,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 15, 14, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The amount sits beside the **name only**. Beside the whole
          // identity block it stole a third of the width and truncated the
          // property code, the market and the agreement number — three of
          // the four things an officer reads out loud to a shopkeeper.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Hero(
                  // The name continues into the profile page rather than
                  // cutting to it. Wrapped in a transparent Material so
                  // the text keeps its style mid-flight.
                  tag: '$heroPrefix-name-${card.propertyId}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: UserText.name(
                      card.allotteeName ?? t('card.noTenant'),
                      maxLines: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _Amount(card: card, heroPrefix: heroPrefix),
            ],
          ),
          const SizedBox(height: 8),
          // The facts, each on the card's full width.
          _Meta(icon: Icons.storefront_outlined, label: card.unitLabel),
          _Meta(icon: Icons.place_outlined, label: card.placeLabel, user: true),
          if ((card.allotmentNo ?? '').isNotEmpty)
            _Meta(
              icon: Icons.description_outlined,
              label: t('card.agreement', args: {'no': card.allotmentNo!}),
            ),
          if (pills.isNotEmpty) ...[
            const SizedBox(height: 13),
            Divider(color: theme.dividerColor, height: 1),
            const SizedBox(height: 12),
            AppPillStrip(pills: pills),
          ],
          if (onCall != null || trailing != null || hidden > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (hidden > 0)
                  AppPill(
                    icon: Icons.more_horiz_rounded,
                    tone: AppTone.neutral,
                    label: t('card.moreSignals', args: {'n': '$hidden'}),
                  ),
                const Spacer(),
                if (trailing != null) ...[
                  trailing!,
                  const SizedBox(width: 10),
                ],
                // One tap to dial. On a list of a hundred rows this alone
                // saves an officer an hour a day — and as an icon button
                // it costs a corner rather than a whole row.
                if (onCall != null)
                  AppIconAction(
                    icon: Icons.phone_rounded,
                    label: t('common.call'),
                    tone: AppTone.success,
                    onPressed: onCall,
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    final shown = dimmed ? Opacity(opacity: 0.55, child: body) : body;

    // A commitment that lapses today gets a slow pulse. It is the one card
    // on the list where waiting another day changes what the officer is
    // entitled to do — and it is the only repeating animation in the app,
    // so it cannot be lost among others.
    return AppAttentionPulse(
      enabled: card.commitment?.lapsesToday == true,
      colour: AppTone.warning.on(context),
      radius: AppCard.radius,
      child: shown,
    );
  }

  /// Every signal this card could show, **in the order an officer triages
  /// by**, so that trimming to [maxPills] keeps the ones that matter: the
  /// commitment first, then never-paid, then how far past due.
  List<Widget> _pills(BuildContext context) {
    final pills = <Widget>[];

    // The commitment first: it is the whole reason this list was worth
    // rebuilding. Without it an officer re-walking a bazaar cannot tell a
    // shopkeeper he spoke to last week from one nobody has ever visited.
    final commitment = card.commitment;
    if (commitment != null) {
      if (commitment.broken) {
        pills.add(
          AppPill(
            icon: Icons.warning_amber_rounded,
            tone: AppTone.danger,
            emphasis: true,
            label: commitment.daysSinceBroken == 0
                ? t('card.promiseBrokenToday')
                : t('card.promiseBroken',
                    args: {'days': '${commitment.daysSinceBroken}'}),
          ),
        );
      } else {
        final date = commitment.promisedPaymentDate;
        pills.add(
          AppPill(
            icon: Icons.handshake_rounded,
            tone: AppTone.warning,
            emphasis: true,
            label: commitment.daysRemaining == 0
                ? t('card.promisedToday')
                : t('card.promised', args: {
                    'date': date == null ? '' : Formatters.date(date),
                    'days': '${commitment.daysRemaining}',
                  }),
          ),
        );
      }
    }

    // Never paid is its own problem. Somebody who pays late needs a phone
    // call; somebody who has never paid at all needs a visit.
    if (card.neverPaid && !card.isVacant) {
      pills.add(
        AppPill(
          icon: Icons.block_rounded,
          tone: AppTone.danger,
          emphasis: true,
          label: t('card.neverPaid'),
        ),
      );
    }

    if (card.isSealed) {
      pills.add(
        AppPill(
          icon: Icons.lock_rounded,
          tone: AppTone.danger,
          label: (card.sealNo ?? '').isEmpty
              ? t('card.sealedPlain')
              : t('card.sealed', args: {'seal': card.sealNo!}),
        ),
      );
    }

    // Null days_overdue is not zero days overdue. Nothing is drawn where
    // nothing is past due — a "0 days overdue" pill invents a fact.
    if (card.daysOverdue != null && card.daysOverdue! > 0) {
      pills.add(
        AppPill(
          icon: Icons.schedule_rounded,
          tone: AppTone.danger,
          label: t('card.daysOverdue', args: {'days': '${card.daysOverdue}'}),
        ),
      );
    }

    if (card.monthsBehind > 0) {
      pills.add(
        AppPill(
          icon: Icons.event_busy_rounded,
          tone: AppTone.warning,
          label:
              t('card.monthsBehind', args: {'months': '${card.monthsBehind}'}),
        ),
      );
    }

    if (card.hasOpenCase) {
      pills.add(
        AppPill(
          icon: Icons.folder_open_rounded,
          tone: AppTone.info,
          label: t('card.caseOpen', args: {'id': '${card.openCaseId}'}),
        ),
      );
    }

    if (card.nextVisitDate != null) {
      pills.add(
        AppPill(
          icon: Icons.event_repeat_rounded,
          tone: AppTone.neutral,
          label: t('card.revisit',
              args: {'date': Formatters.date(card.nextVisitDate!)}),
        ),
      );
    }

    return pills;
  }
}

/// One fact under the name: a glyph, then the words, on the card's full
/// width. The glyph is what makes the three lines scannable — an officer
/// looking for the shop number does not read the market first.
class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label, this.user = false});

  final IconData icon;
  final String label;

  /// True where the text came from a person and may be Urdu, Latin or
  /// mixed — a market name, an address.
  final bool user;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 15, color: muted),
          const SizedBox(width: 6),
          Expanded(
            child: user
                ? UserText.caption(label, color: muted)
                : AppText.bodySmall(label, color: muted, maxLines: 1),
          ),
        ],
      ),
    );
  }
}

/// The amount, dominant on the trailing edge, under a caption saying what
/// it is.
///
/// A **null** amount is a vacant unit and is drawn as the word "Vacant".
/// Nobody owes anything because nobody holds it — a different statement
/// from a tenant who is up to date, and only one of them is good news.
class _Amount extends StatelessWidget {
  const _Amount({required this.card, required this.heroPrefix});

  final FieldCard card;
  final String heroPrefix;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final owed = card.outstanding;

    if (owed == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 18,
            color: AppTone.info.on(context),
          ),
          const SizedBox(height: 2),
          AppText.titleMedium(
            t('card.vacant'),
            color: AppTone.info.on(context),
            textAlign: TextAlign.end,
          ),
        ],
      );
    }

    final settled = owed.isZero;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AppText.caption(
          settled ? t('card.settled') : t('card.owes'),
          color: muted,
          maxLines: 1,
        ),
        const SizedBox(height: 1),
        Hero(
          tag: '$heroPrefix-amount-${card.propertyId}',
          child: Material(
            type: MaterialType.transparency,
            child: MoneyText(
              owed,
              variant: AppTextVariant.headlineSmall,
              color: settled
                  ? AppTone.success.on(context)
                  : AppTone.danger.on(context),
              textAlign: TextAlign.end,
            ),
          ),
        ),
      ],
    );
  }
}

/// The call button as a bare circle, for rows too tight for a full button.
class FieldCallButton extends StatelessWidget {
  const FieldCallButton({super.key, required this.mobileNo});

  final String? mobileNo;

  @override
  Widget build(BuildContext context) {
    return AppIconAction(
      icon: Icons.phone_rounded,
      label: t('common.call'),
      tone: AppTone.success,
      onPressed: () => Dialer.call(mobileNo),
    );
  }
}
