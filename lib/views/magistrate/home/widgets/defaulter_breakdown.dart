import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_series_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/round_group.dart';
import '../../../../widgets/widgets.dart';

class DefaulterBreakdown extends StatelessWidget {
  const DefaulterBreakdown({
    super.key,
    required this.groups,
    required this.brokenPromises,
    required this.neverPaid,
    required this.sealed,
    this.totalOutstanding,
  });

  /// Worst first — the controller has already ordered them.
  final List<RoundGroup> groups;

  final int brokenPromises;
  final int neverPaid;
  final int sealed;

  /// The arrears across the whole beat, as the server totalled it — the
  /// `defaulters` queue's own amount. The share chart needs a denominator and
  /// this app does not add money together in Dart, so without it that chart
  /// simply does not draw.
  final String? totalOutstanding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          lift: AppLift.soft,
          radius: AppRadius.lg,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Stat(
                value: brokenPromises,
                label: 'Missed payment',
                icon: Icons.event_busy_outlined,
                tone: AppTone.danger,
              ),
              const _Divider(),
              _Stat(
                value: neverPaid,
                label: 'Never paid',
                icon: Icons.money_off_csred_outlined,
                tone: AppTone.warning,
              ),
              const _Divider(),
              // No tone: a seal count is a fact, not a severity, and a third
              // status colour in the row would make it read as one.
              _Stat(
                value: sealed,
                label: 'Sealed',
                icon: Icons.lock_outline_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Builder(
          builder: (BuildContext context) {
            // Colour is assigned here, once, from each bazaar's place in the
            // list the controller ordered — so the share bar and the ranked
            // list below it agree, and a bazaar is one colour on both.
            final colours = <String, Color>{
              for (int i = 0; i < groups.length; i++)
                _name(groups[i]): AppSeriesColors.at(context, i),
            };
            final total = double.tryParse(totalOutstanding?.trim() ?? '');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (total != null && total > 0) ...[
                  AppCard(
                    lift: AppLift.soft,
                    radius: AppRadius.lg,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppText.titleMedium('Share of the arrears'),
                        const SizedBox(height: 4),
                        AppText.caption(
                          'Of ${Formatters.money(totalOutstanding)} owed '
                          'across your beat.',
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 11),
                        AppCompositionBar(
                          total: total,
                          slices: <CompositionSlice>[
                            for (final RoundGroup group in groups)
                              CompositionSlice(
                                label: _name(group),
                                value: _amount(group),
                                valueLabel:
                                    Formatters.money(group.outstanding) ?? '',
                                color: colours[_name(group)]!,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                AppCard(
                  lift: AppLift.soft,
                  radius: AppRadius.lg,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText.titleMedium('Outstanding by bazaar'),
                      const SizedBox(height: 11),
                      AppBarList(
                        // Already sorted; keeping the caller's order means the
                        // bars and the share bar above stay in step.
                        sorted: false,
                        data: <BarDatum>[
                          for (final RoundGroup group in groups)
                            BarDatum(
                              label: _name(group),
                              value: _amount(group),
                              valueLabel:
                                  Formatters.money(group.outstanding) ??
                                  group.outstanding,
                              caption: _caption(group),
                              color: colours[_name(group)],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Parsed for bar geometry only — never printed, never added to another.
  static double _amount(RoundGroup group) =>
      double.tryParse(group.outstanding.trim()) ?? 0;

  static String _name(RoundGroup group) =>
      group.marketName ?? group.areaName ?? 'Unnamed bazaar';

  /// The area only when it adds something the market name has not already
  /// said — "Prince Road Market, Prince Road" is noise.
  static String _caption(RoundGroup group) {
    final shops =
        '${group.shops} ${group.shops == 1 ? 'shop' : 'shops'} behind';
    final area = group.areaName;
    if (area == null || group.marketName == null || group.marketName == area) {
      return shops;
    }
    return '$shops · $area';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.icon,
    this.tone,
  });

  final int value;
  final String label;
  final IconData icon;

  /// Null for a figure that carries no severity — it wears the ordinary ink.
  final AppTone? tone;

  @override
  Widget build(BuildContext context) {
    // Nothing to be alarmed by at zero: no missed payments is the good
    // outcome, and a red 0 reads as one more thing to chase.
    final bool live = value > 0 && tone != null;
    final Color colour = live
        ? tone!.on(context)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Expanded(
      child: Column(
        children: [
          Container(
            height: 26,
            width: 26,
            decoration: BoxDecoration(
              color: colour.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 14, color: colour),
          ),
          const SizedBox(height: 6),
          AppCountUp.count(value, color: live ? colour : null),
          const SizedBox(height: 3),
          AppText.caption(
            label,
            maxLines: 1,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 44,
    margin: const EdgeInsets.only(top: 4),
    color: Theme.of(context).dividerColor,
  );
}
