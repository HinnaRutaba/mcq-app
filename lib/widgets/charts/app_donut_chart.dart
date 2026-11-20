import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_radius.dart';
import '../common/app_press.dart';
import '../text/app_count_up.dart';
import '../text/app_text.dart';

/// One part of an [AppDonutChart].
class DonutSlice {
  const DonutSlice({
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  final String label;
  final int value;

  /// The entity's own colour, never its rank's.
  final Color color;

  /// Opens what this part counted; null leaves its legend row inert.
  final VoidCallback? onTap;
}

/// A ring cut into the parts of one whole, with the total in its middle and
/// a legend that prints every figure — the arcs are never the only reading.
///
/// Only for parts that cannot overlap. Adjacent slices sharing a colour draw
/// as one arc, so the neutral "and the rest" reads as a single remainder.
class AppDonutChart extends StatelessWidget {
  const AppDonutChart({
    super.key,
    required this.slices,
    required this.total,
    required this.totalLabel,
    this.size = 128,
  });

  final List<DonutSlice> slices;
  final int total;
  final String totalLabel;
  final double size;

  static const double _thickness = 16;

  @override
  Widget build(BuildContext context) {
    final List<DonutSlice> shown = slices
        .where((DonutSlice s) => s.value > 0)
        .toList();
    if (shown.isEmpty || total <= 0) return const SizedBox.shrink();

    final bool still = MediaQuery.disableAnimationsOf(context);

    final Widget ring = SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Keyed on the figures, so a new period sweeps in again.
          TweenAnimationBuilder<double>(
            key: ValueKey<String>(
              shown.map((DonutSlice s) => s.value).join(','),
            ),
            tween: Tween<double>(begin: still ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double t, Widget? _) => PieChart(
              PieChartData(
                sections: _sections(shown, t),
                centerSpaceRadius: size / 2 - _thickness,
                sectionsSpace: 2,
                startDegreeOffset: -90,
                pieTouchData: PieTouchData(enabled: false),
              ),
              duration: Duration.zero,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppCountUp.count(total, variant: AppTextVariant.headlineSmall),
              AppText.caption(totalLabel),
            ],
          ),
        ],
      ),
    );

    return Row(
      children: <Widget>[
        ring,
        const SizedBox(width: 18),
        Expanded(
          // Capped, so on a tablet the figure stays near its label.
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final DonutSlice slice in shown)
                    _LegendRow(slice: slice),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The parts swept out to [t] of the ring, the rest left transparent.
  List<PieChartSectionData> _sections(List<DonutSlice> shown, double t) {
    final List<(double, Color)> arcs = <(double, Color)>[];
    for (final DonutSlice s in shown) {
      if (arcs.isNotEmpty && arcs.last.$2 == s.color) {
        arcs.last = (arcs.last.$1 + s.value, s.color);
      } else {
        arcs.add((s.value.toDouble(), s.color));
      }
    }

    final double whole = math.max(
      total.toDouble(),
      arcs.fold<double>(0, (double sum, (double, Color) a) => sum + a.$1),
    );
    double left = whole * t;
    final List<PieChartSectionData> sections = <PieChartSectionData>[];
    for (final (double value, Color color) in arcs) {
      final double drawn = math.min(value, left);
      if (drawn <= 0) break;
      sections.add(_section(drawn, color));
      left -= drawn;
    }
    final double rest = whole - whole * t;
    if (rest > whole * 0.001) sections.add(_section(rest, Colors.transparent));
    return sections;
  }

  static PieChartSectionData _section(double value, Color color) =>
      PieChartSectionData(
        value: value,
        color: color,
        radius: _thickness,
        showTitle: false,
      );
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.slice});

  final DonutSlice slice;

  @override
  Widget build(BuildContext context) {
    final Color muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return AppPress(
      onTap: slice.onTap,
      scale: 0.96,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: <Widget>[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: slice.color,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: AppText.body(slice.label, maxLines: 2)),
            const SizedBox(width: 8),
            AppText.label('${slice.value}'),
            if (slice.onTap != null)
              Icon(Icons.chevron_right_rounded, size: 18, color: muted)
            else
              const SizedBox(width: 18),
          ],
        ),
      ),
    );
  }
}
