import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/field/field_card.dart';
import '../../../../models/field/round.dart';
import '../../../../widgets/widgets.dart';
import 'field_card_tile.dart';

/// One market on today's round, as a real [ExpansionTile] inside a card.
///
/// Collapsed it is the headline: how many shops, how many broken promises,
/// how much is outstanding. Expanded it is the five stops — **at most
/// five, on purpose.** A round nobody can finish is a list nobody reads.
///
/// It is Material's own expansion tile rather than a hand-rolled
/// `AnimatedCrossFade` because grouped data has semantics as well as a
/// shape: a screen reader has to say "expanded"/"collapsed", the whole
/// header has to be one focusable control, and the rotation of the chevron
/// has to agree with the state even when the parent changes it. The
/// [ExpansibleController] is what lets the parent stay the source of
/// truth for which market is open, which is how the round screen keeps only
/// one open at a time.
///
/// The order the markets arrive in is the server's and is not touched here.
/// Broken promises first, then count: a lapsed commitment beats a larger
/// balance nobody has spoken to yet, because somebody has already been
/// given a chance and has not taken it, and that is what justifies the next
/// step.
class RoundMarketCard extends StatefulWidget {
  const RoundMarketCard({
    super.key,
    required this.market,
    required this.expanded,
    required this.onToggle,
    required this.onOpenStop,
    required this.onCallStop,
    this.onStartRound,
    this.hasWalked,
    this.onWalked,
    this.heroPrefix = 'round',
  });

  final RoundMarket market;
  final bool expanded;
  final VoidCallback onToggle;
  final void Function(FieldCard stop) onOpenStop;
  final void Function(FieldCard stop) onCallStop;
  final VoidCallback? onStartRound;

  final bool Function(FieldCard stop)? hasWalked;
  final void Function(FieldCard stop)? onWalked;

  /// Namespaces the [Hero] tags on the stops inside.
  ///
  /// The shell keeps every branch alive at once, so the same market drawn
  /// on the home screen and on the round screen would otherwise put two
  /// heroes with the same tag in one subtree — which is a crash the moment
  /// any route transition starts, not a cosmetic problem.
  final String heroPrefix;

  @override
  State<RoundMarketCard> createState() => _RoundMarketCardState();
}

class _RoundMarketCardState extends State<RoundMarketCard> {
  final ExpansibleController _tile = ExpansibleController();

  @override
  void dispose() {
    _tile.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RoundMarketCard old) {
    super.didUpdateWidget(old);
    if (old.expanded == widget.expanded) return;
    // The parent decides which market is open. Drive the tile to match
    // rather than letting the two disagree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.expanded && !_tile.isExpanded) {
        _tile.expand();
      } else if (!widget.expanded && _tile.isExpanded) {
        _tile.collapse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final market = widget.market;
    final muted = theme.colorScheme.onSurfaceVariant;
    final tone = market.brokenPromises > 0 ? AppTone.danger : AppTone.primary;

    return AppCard(
      tone: tone,
      rail: true,
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        controller: _tile,
        initiallyExpanded: widget.expanded,
        onExpansionChanged: (_) {
          AppHaptics.select();
          widget.onToggle();
        },
        // The stops keep their scroll position and their "walked" ticks
        // while the tile is shut.
        maintainState: true,
        // The chart of pills is the subtitle, so the whole block is one
        // tap target and the chevron sits beside the money.
        tilePadding: const EdgeInsetsDirectional.fromSTEB(16, 6, 12, 6),
        childrenPadding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserText.headline(market.marketName, maxLines: 2),
                  const SizedBox(height: 2),
                  UserText.caption(market.areaName, color: muted),
                ],
              ),
            ),
            if (market.outstanding != null) ...[
              const SizedBox(width: 10),
              MoneyText(
                market.outstanding!,
                variant: AppTextVariant.titleMedium,
                color: AppTone.danger.on(context),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsetsDirectional.only(top: 10, bottom: 4),
          child: AppPillStrip(
            pills: [
              AppPill(
                icon: Icons.storefront_rounded,
                tone: AppTone.neutral,
                label: t('round.shops', args: {'n': '${market.shops}'}),
              ),
              if (market.brokenPromises > 0)
                AppPill(
                  icon: Icons.warning_amber_rounded,
                  tone: AppTone.danger,
                  emphasis: true,
                  label: t('round.brokenPromises',
                      args: {'n': '${market.brokenPromises}'}),
                ),
              if (market.neverPaid > 0)
                AppPill(
                  icon: Icons.block_rounded,
                  tone: AppTone.danger,
                  label:
                      t('round.neverPaid', args: {'n': '${market.neverPaid}'}),
                ),
              if (market.sealed > 0)
                AppPill(
                  icon: Icons.lock_rounded,
                  tone: AppTone.warning,
                  label: t('round.sealed', args: {'n': '${market.sealed}'}),
                ),
            ],
          ),
        ),
        children: [
          Divider(color: theme.dividerColor, height: 18),
          AppText.bodySmall(t('round.stopsNote'), color: muted),
          const SizedBox(height: 12),
          for (var i = 0; i < market.stops.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            FieldCardTile(
              card: market.stops[i],
              heroPrefix: '${widget.heroPrefix}-${market.marketName}',
              dimmed: widget.hasWalked?.call(market.stops[i]) ?? false,
              onTap: () => widget.onOpenStop(market.stops[i]),
              onCall: market.stops[i].isCallable
                  ? () => widget.onCallStop(market.stops[i])
                  : null,
              trailing: widget.onWalked == null
                  ? null
                  : _WalkedButton(
                      done: widget.hasWalked?.call(market.stops[i]) ?? false,
                      onTap: () => widget.onWalked!(market.stops[i]),
                    ),
            ),
          ],
          if (widget.onStartRound != null) ...[
            const SizedBox(height: 14),
            AppButton(
              label: t('round.start'),
              icon: Icons.directions_walk_rounded,
              onPressed: widget.onStartRound,
            ),
          ],
        ],
      ),
    );
  }
}

/// "I have called on this one."
///
/// Deliberately a local tick and **not** a write to the register. Walking
/// past a shop is not an enforcement action, and recording it as one would
/// put a visit in the file that never happened.
class _WalkedButton extends StatelessWidget {
  const _WalkedButton({required this.done, required this.onTap});

  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colour =
        done ? AppTone.success.on(context) : theme.colorScheme.onSurfaceVariant;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: () {
          AppHaptics.select();
          onTap();
        },
        icon: Icon(
          done ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
          size: 20,
          color: colour,
        ),
        // Labelled, not a bare tick: "walked" is a claim about what the
        // officer did, and it should say so in a word.
        label: AppText.label(
          done ? t('round.walked') : t('round.markWalked'),
          color: colour,
          maxLines: 1,
        ),
        style: TextButton.styleFrom(foregroundColor: colour),
      ),
    );
  }
}
