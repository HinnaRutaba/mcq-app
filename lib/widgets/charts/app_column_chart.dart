import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_radius.dart';
import '../../config/theme/app_status_colors.dart';
import '../text/app_text.dart';

/// One column of an [AppColumnChart].
class ColumnDatum {
  const ColumnDatum({
    required this.label,
    required this.value,
    this.caption,
    this.color,
    this.onTap,
  });

  final String label;
  final int value;

  /// A second, smaller line over the figure, e.g. "14 acts".
  final String? caption;

  /// This column's fill; the brand when null. Give it per category, not by rank.
  final Color? color;

  /// Opens what this column counted. The whole column height is the target.
  final VoidCallback? onTap;
}

/// One measure across a handful of named categories, as columns that grow in
/// when they arrive. Every column prints its figure over itself.
class AppColumnChart extends StatelessWidget {
  const AppColumnChart({super.key, required this.data, this.height = 190});

  final List<ColumnDatum> data;
  final double height;

  static const double _labelHeight = 34;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final ThemeData theme = Theme.of(context);
    final Color fill = context.status.brand;
    final Color ink = theme.colorScheme.onSurface;
    final Color muted = theme.colorScheme.onSurfaceVariant;
    final bool still = MediaQuery.disableAnimationsOf(context);

    final int largest = data.fold<int>(
      0,
      (int m, ColumnDatum d) => math.max(m, d.value),
    );
    // Headroom for the figure printed over the tallest column.
    final double maxY = math.max(1, largest) * 1.32;

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) {
          final double slot = box.maxWidth / data.length;
          final double barWidth = (slot * 0.46).clamp(14.0, 40.0);

          return TweenAnimationBuilder<double>(
            key: ValueKey<String>(
              data.map((ColumnDatum d) => d.value).join(','),
            ),
            tween: Tween<double>(begin: still ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double t, Widget? _) => BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(
                  show: true,
                  border: Border(bottom: BorderSide(color: theme.dividerColor)),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: _labelHeight,
                      getTitlesWidget: (double x, TitleMeta meta) =>
                          SideTitleWidget(
                            meta: meta,
                            space: 6,
                            child: SizedBox(
                              width: slot - 4,
                              child: AppText.caption(
                                data[x.toInt()].label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                color: muted,
                              ),
                            ),
                          ),
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  handleBuiltInTouches: false,
                  // The invisible full-height rod below makes the column the target.
                  allowTouchBarBackDraw: true,
                  touchExtraThreshold: EdgeInsets.symmetric(
                    horizontal: math.max(4, (slot - barWidth) / 2 - 2),
                  ),
                  touchCallback: (FlTouchEvent event, BarTouchResponse? r) {
                    if (event is! FlTapUpEvent) return;
                    final int? i = r?.spot?.touchedBarGroupIndex;
                    if (i != null) data[i].onTap?.call();
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.transparent,
                    tooltipPadding: EdgeInsets.zero,
                    tooltipMargin: 6,
                    fitInsideVertically: true,
                    getTooltipItem: (_, int i, _, _) => BarTooltipItem(
                      '${data[i].value}',
                      theme.textTheme.titleSmall!.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w700,
                      ),
                      children: <TextSpan>[
                        if (data[i].caption != null)
                          TextSpan(
                            text: '\n${data[i].caption}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                barGroups: <BarChartGroupData>[
                  for (int i = 0; i < data.length; i++)
                    BarChartGroupData(
                      x: i,
                      // Figures land once the columns have grown.
                      showingTooltipIndicators: t > 0.85
                          ? const <int>[0]
                          : const <int>[],
                      barRods: <BarChartRodData>[
                        BarChartRodData(
                          toY: data[i].value * t,
                          width: barWidth,
                          color: data[i].color ?? fill,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppRadius.xs),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              duration: Duration.zero,
            ),
          );
        },
      ),
    );
  }
}
