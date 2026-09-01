import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../models/common/money.dart';
import '../cards/app_card.dart';
import '../motion/app_count_up.dart';
import '../text/app_text.dart';
import '../text/money_text.dart';

/// One tile of a dashboard grid.
///
/// The anatomy, top to bottom, and each part is load-bearing:
///
/// * an **accent rail** down the leading edge and a **soft tinted plate**,
///   so the tile's state is legible before a word is read;
/// * an **icon in its own tinted square** — the shape changes with the
///   state, not only the colour, so it survives greyscale and sunlight;
/// * the **count**, the largest thing on the tile, counting up on first
///   load;
/// * the **amount underneath**, and *only where there is one*;
/// * a **title and a sub-label** in plain language.
///
/// Two rules it holds:
///
/// **Nothing on a dashboard is a dead end.** [onTap] is required: every
/// tile opens the list behind it. A figure an officer cannot act on is a
/// figure he stops reading.
///
/// **A null amount is not zero.** `amount: null` means this queue is not
/// measured in money, and nothing is drawn — rendering `0.00` there says
/// "nothing is at stake" where the truth is "rupees are not the unit".
///
/// It expects a **bounded height** — a grid cell with a `mainAxisExtent`.
/// The figure sits under the icon and the labels are pushed to the foot of
/// the tile, so titles line up across a row however short one queue's
/// count happens to be; ragged baselines are most of what makes a grid look
/// assembled rather than laid out.
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.icon,
    required this.count,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.amount,
    this.tone = AppTone.neutral,
    this.animate = true,
    this.clearIcon = Icons.check_rounded,
    this.clearLabel,
  });

  final IconData icon;
  final int count;
  final String title;
  final String? subtitle;

  /// Null where the queue is not measured in money.
  final Money? amount;

  final AppTone tone;
  final VoidCallback onTap;

  /// False on a refresh, so a figure the officer already read does not
  /// count itself up again.
  final bool animate;

  /// The shape a cleared tile shows instead of its own icon.
  final IconData clearIcon;

  /// What the tile says at zero. **A zero queue is good news and has to
  /// look like it** — a tile that stays red at zero teaches the officer
  /// that the colours mean nothing, and once he has learnt that, the red
  /// one that matters is just another red tile.
  final String? clearLabel;

  bool get _clear => count == 0 && clearLabel != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colour = tone.on(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return AppCard(
      onTap: onTap,
      tone: tone == AppTone.neutral ? null : tone,
      rail: tone != AppTone.neutral,
      padding: const EdgeInsetsDirectional.fromSTEB(15, 15, 13, 15),
      // The tile is designed for a grid cell, but it must not *assert* on
      // one: it is also rendered in a widget test, and one day in a
      // scrolling column somebody adds. Where the height is bounded the
      // labels are pushed to the foot so they line up across a row; where
      // it is not, the column simply shrink-wraps.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bounded = constraints.maxHeight.isFinite;

          final label = AppText.bodySmall(
            subtitle ?? '',
            color: muted,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tone.container(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _clear ? clearIcon : icon,
                      size: 21,
                      color: colour,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: colour.withValues(alpha: 0.55),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_clear)
                AppText.titleMedium(clearLabel!, color: colour, maxLines: 2)
              else ...[
                AppCountUp(
                  count,
                  variant: AppTextVariant.displaySmall,
                  color: colour,
                  enabled: animate,
                ),
                if (amount != null) ...[
                  const SizedBox(height: 2),
                  MoneyText(
                    amount!,
                    variant: AppTextVariant.titleSmall,
                    color: colour.withValues(alpha: 0.92),
                  ),
                ],
              ],
              if (bounded) const Spacer(),
              const SizedBox(height: 8),
              // The title is rigid: it is what the tile *is*, and a queue
              // whose name is cut in half is a queue the officer has to
              // guess at.
              AppText.titleSmall(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null)
                // The sub-label is the one that gives, if anything has to —
                // it qualifies the title rather than naming the queue.
                // Flexible only where there is a bound for it to flex
                // against; a flex child in an unbounded column asserts.
                bounded ? Flexible(child: label) : label,
            ],
          );
        },
      ),
    );
  }
}

/// A small "label + big value" block, for a row of three or four figures
/// inside a card rather than a grid of tiles.
class AppStatTile extends StatelessWidget {
  const AppStatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
          ],
          AppText.headlineSmall(value, color: valueColor, maxLines: 1),
          const SizedBox(height: 4),
          AppText.caption(
            label,
            maxLines: 1,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

/// One counted figure in a row inside a card — "34 visits · 4 fines · 2
/// sealed". Counts up, and stays legible when the label wraps.
class AppFigure extends StatelessWidget {
  const AppFigure({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.tone,
    this.animate = true,
    this.onTap,
  });

  final int value;
  final String label;
  final IconData? icon;
  final AppTone? tone;
  final bool animate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colour = tone?.on(context);
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: colour ?? Theme.of(context).colorScheme.primary),
          const SizedBox(height: 6),
        ],
        AppCountUp(
          value,
          variant: AppTextVariant.headlineSmall,
          color: colour,
          enabled: animate,
        ),
        const SizedBox(height: 2),
        AppText.bodySmall(
          label,
          maxLines: 2,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    );

    if (onTap == null) return body;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: body,
    );
  }
}
