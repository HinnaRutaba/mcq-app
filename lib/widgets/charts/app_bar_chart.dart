import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_status_colors.dart';
import '../../config/theme/app_text_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/common/money.dart';
import '../text/app_text.dart';
import 'app_chart_frame.dart';

/// One period's figures for [AppPaidDueChart] — a month, a week.
class ChartPoint {
  const ChartPoint({
    required this.label,
    required this.paid,
    required this.due,
    this.paidAmount,
    this.dueAmount,
  });

  final String label;

  /// Plotted heights only. **Never rendered as money** — the amounts the
  /// officer reads come from [paidAmount] and [dueAmount], which are the
  /// server's own strings. A bar can be a rounded double; a figure quoted
  /// to a shopkeeper cannot.
  final double paid;
  final double due;

  final Money? paidAmount;
  final Money? dueAmount;
}

/// "Paid against due", by period.
///
/// Two **states**, not two categories, so this uses the reserved status
/// colours rather than a categorical palette — settled emerald against
/// information blue — and each ships with an icon and a word in the legend.
class AppPaidDueChart extends StatelessWidget {
  const AppPaidDueChart({
    super.key,
    required this.data,
    this.title,
    this.subtitle,
    this.height = 190,
  });

  final List<ChartPoint> data;
  final String? title;
  final String? subtitle;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final status = context.status;
    final paidColour = status.success;
    final dueColour = status.info;

    final maxValue = data.fold<double>(
      0,
      (m, d) => math.max(m, math.max(d.paid, d.due)),
    );
    // Scale to the data, with a tenth of headroom so the tallest bar is not
    // welded to the top of the frame.
    final top = maxValue <= 0 ? 1.0 : maxValue * 1.12;

    return AppChartFrame(
      title: title,
      subtitle: subtitle,
      height: height,
      entries: [
        ChartLegendEntry(
          label: t('chart.paid'),
          colour: paidColour,
          icon: Icons.check_circle_rounded,
          value: _total(data.map((d) => d.paidAmount)),
        ),
        ChartLegendEntry(
          label: t('chart.due'),
          colour: dueColour,
          icon: Icons.schedule_rounded,
          value: _total(data.map((d) => d.dueAmount)),
        ),
      ],
      chart: BarChart(
        BarChartData(
          maxY: top,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          barGroups: [
            for (var i = 0; i < data.length; i++)
              BarChartGroupData(
                x: i,
                // A 2px surface gap between adjacent bars, so the pair
                // reads as two marks rather than as one two-tone mark.
                barsSpace: 2,
                barRods: [
                  _rod(data[i].paid, paidColour),
                  _rod(data[i].due, dueColour),
                ],
              ),
          ],
          // Recessive gridlines: horizontal only, and no frame.
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: top / 3,
            getDrawingHorizontalLine: (_) => FlLine(
              color: status.chartGrid,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: AppText.caption(
                      data[index].label,
                      color: status.chartLabel,
                      maxLines: 1,
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => theme.colorScheme.inverseSurface,
              tooltipBorderRadius: BorderRadius.circular(10),
              tooltipPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final point = data[groupIndex];
                final paid = rodIndex == 0;
                final amount = paid ? point.paidAmount : point.dueAmount;
                return BarTooltipItem(
                  '${point.label}\n'
                  '${paid ? t('chart.paid') : t('chart.due')}: '
                  '${amount?.withSymbol() ?? (paid ? point.paid : point.due).round().toString()}',
                  (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
                    color: theme.colorScheme.onInverseSurface,
                    fontFeatures: kTabularFigures,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static BarChartRodData _rod(double value, Color colour) => BarChartRodData(
        toY: value,
        color: colour,
        // Thin marks, and a 4px rounded top anchored to the baseline: the
        // bar's *end* is rounded, its foot is square, so nothing floats.
        width: 13,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      );

  /// The legend figure. Sums are the server's job; where the caller has not
  /// supplied one, the legend simply names the series.
  static String _total(Iterable<Money?> amounts) {
    final present = amounts.whereType<Money>().toList();
    if (present.length == 1) return present.first.withSymbol();
    return '';
  }
}

/// A horizontal bar chart of one ordered series — "my work, by action".
///
/// Horizontal because the categories are words, not dates: "Reminder to
/// revisit" rotated forty-five degrees under a vertical bar is a label
/// nobody reads. Bars run from a shared baseline on the leading edge and
/// carry their figure at the end, so no value has to be estimated against
/// a gridline.
///
/// The colour is an **ordinal ramp**, not a categorical palette. Enforcement
/// actions are an escalation — a visit, a verbal warning, a final warning, a
/// notice, a seal — so the darker step *means* the harder action. A
/// categorical palette would say only that they are different, and it would
/// put hues on screen that mean "overdue" and "settled" everywhere else in
/// the app.
class AppOrdinalBarChart extends StatelessWidget {
  const AppOrdinalBarChart({
    super.key,
    required this.entries,
    this.title,
    this.subtitle,
    this.animate = true,
  });

  /// Ordered hardest-last: the ramp is applied in this order.
  final List<ChartBarEntry> entries;

  final String? title;
  final String? subtitle;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final status = context.status;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final busiest =
        entries.fold<int>(0, (m, e) => e.value > m ? e.value : m);
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);

    return AppChartFrame(
      title: title,
      subtitle: subtitle,
      // The plot sizes itself to the number of rows rather than being
      // squeezed into a fixed frame.
      height: entries.length * 44,
      showLegend: false,
      entries: [
        for (var i = 0; i < entries.length; i++)
          ChartLegendEntry(
            label: entries[i].label,
            colour: status.escalationStep(i, entries.length),
            value: '${entries[i].value}',
            icon: entries[i].icon,
            share: total == 0 ? null : entries[i].value / total,
          ),
      ],
      chart: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < entries.length; i++)
            Expanded(
              child: _Bar(
                entry: entries[i],
                colour: status.escalationStep(i, entries.length),
                fraction: busiest == 0 ? 0 : entries[i].value / busiest,
                track: status.chartGrid,
                muted: muted,
                animate: animate,
                delay: Duration(milliseconds: 60 * i),
              ),
            ),
        ],
      ),
    );
  }
}

/// One labelled row of [AppOrdinalBarChart].
class ChartBarEntry {
  const ChartBarEntry({
    required this.label,
    required this.value,
    this.icon,
    this.onTap,
  });

  final String label;
  final int value;
  final IconData? icon;
  final VoidCallback? onTap;
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.entry,
    required this.colour,
    required this.fraction,
    required this.track,
    required this.muted,
    required this.animate,
    required this.delay,
  });

  final ChartBarEntry entry;
  final Color colour;
  final double fraction;
  final Color track;
  final Color muted;
  final bool animate;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final row = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            if (entry.icon != null) ...[
              Icon(entry.icon, size: 16, color: muted),
              const SizedBox(width: 7),
            ],
            Expanded(
              child: AppText.bodySmall(entry.label, maxLines: 1),
            ),
            const SizedBox(width: 10),
            // The figure, direct-labelled. Never estimated off a gridline.
            Directionality(
              textDirection: TextDirection.ltr,
              child: AppText.titleSmall('${entry.value}'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: animate ? 0 : fraction, end: fraction),
            duration: animate
                ? const Duration(milliseconds: 700)
                : Duration.zero,
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Stack(
              children: [
                Container(height: 9, color: track),
                FractionallySizedBox(
                  widthFactor: value.clamp(0.0, 1.0),
                  child: Container(height: 9, color: colour),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (entry.onTap == null) return row;
    return InkWell(
      onTap: entry.onTap,
      borderRadius: BorderRadius.circular(8),
      child: row,
    );
  }
}
