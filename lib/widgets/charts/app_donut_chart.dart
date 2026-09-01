import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_status_colors.dart';
import '../text/app_text.dart';
import 'app_chart_frame.dart';

/// One slice of [AppDonutChart].
class DonutSlice {
  const DonutSlice({
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final int value;
  final IconData? icon;
}

/// A donut of how a total divides — the share each kind of action took of
/// a month's work.
///
/// **A donut and not a pie**, for one reason: the hole is where the total
/// goes. A pie asks the officer to add the slices up in his head to learn
/// what he did in a month; a donut puts that figure in the middle, at
/// display size, and the ring answers the second question rather than the
/// first.
///
/// Slices are coloured from the **ordinal escalation ramp**, in the order
/// they are given — gentlest first — so the ring reads light-to-dark
/// around its circumference and the darkest wedge is the hardest action.
/// Every slice also appears in the legend with its glyph and its figure,
/// so nothing here is carried by colour alone, and the table view under the
/// frame gives the numbers outright.
///
/// It is deliberately capped: past six slices a donut is a colour-matching
/// puzzle, so the tail folds into one "Other" wedge rather than generating
/// a seventh hue.
class AppDonutChart extends StatelessWidget {
  const AppDonutChart({
    super.key,
    required this.slices,
    required this.centreValue,
    required this.centreLabel,
    this.title,
    this.subtitle,
    this.otherLabel = 'Other',
    this.maxSlices = 6,
    this.height = 200,
  });

  final List<DonutSlice> slices;

  /// The figure in the hole — already formatted, and usually a count.
  final String centreValue;
  final String centreLabel;

  final String? title;
  final String? subtitle;

  /// What the folded tail is called.
  final String otherLabel;

  final int maxSlices;
  final double height;

  @override
  Widget build(BuildContext context) {
    final status = context.status;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    final folded = _fold(slices, maxSlices, otherLabel);
    final total = folded.fold<int>(0, (sum, s) => sum + s.value);
    if (total == 0) return const SizedBox.shrink();

    final colours = [
      for (var i = 0; i < folded.length; i++)
        status.escalationStep(i, folded.length),
    ];

    return AppChartFrame(
      title: title,
      subtitle: subtitle,
      height: height,
      entries: [
        for (var i = 0; i < folded.length; i++)
          ChartLegendEntry(
            label: folded[i].label,
            colour: colours[i],
            value: '${folded[i].value}',
            icon: folded[i].icon,
            share: folded[i].value / total,
          ),
      ],
      chart: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              // The hole is 40% of the radius: wide enough for the total to
              // sit in it at display size, narrow enough that the ring is
              // still a ring.
              centerSpaceRadius: height * 0.21,
              // A 2px surface gap between wedges, so two adjacent steps of
              // one ramp are still two wedges.
              sectionsSpace: 2,
              startDegreeOffset: -90,
              sections: [
                for (var i = 0; i < folded.length; i++)
                  PieChartSectionData(
                    value: folded[i].value.toDouble(),
                    color: colours[i],
                    radius: height * 0.19,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          // The total, in the hole. Text wears text tokens, never a series
          // colour.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText.headlineMedium(centreValue, maxLines: 1),
              AppText.bodySmall(
                centreLabel,
                color: muted,
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Folds the smallest slices into one, **without reordering the rest**.
  ///
  /// The caller's order is the meaning here — it is the escalation, and the
  /// ramp is applied along it. Sorting by size before colouring would make
  /// the ramp track *rank* instead: the largest wedge would always be the
  /// lightest, whatever it was, and the ring would stop saying anything
  /// about how hard the month was. Colour follows the entity, never its
  /// rank.
  static List<DonutSlice> _fold(
    List<DonutSlice> slices,
    int max,
    String otherLabel,
  ) {
    final present = slices.where((s) => s.value > 0).toList();
    if (present.length <= max) return present;

    // Which ones go — the smallest — decided by size; where the survivors
    // sit — decided by the caller's order, untouched.
    final bySize = [...present]..sort((a, b) => b.value.compareTo(a.value));
    final keep = bySize.take(max - 1).toSet();
    final folded = present.where(keep.contains).toList();
    final other = present
        .where((slice) => !keep.contains(slice))
        .fold<int>(0, (sum, slice) => sum + slice.value);

    return [
      ...folded,
      DonutSlice(
        label: otherLabel,
        value: other,
        icon: Icons.more_horiz_rounded,
      ),
    ];
  }
}
