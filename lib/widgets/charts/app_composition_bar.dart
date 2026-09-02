import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../text/app_text.dart';
import '../../config/theme/app_radius.dart';

/// One slice of an [AppCompositionBar].
class CompositionSlice {
  const CompositionSlice({
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.color,
  });

  final String label;

  /// The part. Compared only against the bar's total.
  final double value;

  /// The part as it should be printed.
  final String valueLabel;

  /// The entity's own colour — assigned from what it is, not from where it
  /// sorts, so it matches this entity everywhere else on the screen.
  final Color color;
}

/// One bar cut into shares of a whole: which parts a known total is made of.
///
/// The total is passed in rather than added up here, and that is the point.
/// The app never sums money in Dart — the server's own figure is the
/// denominator, so what the bar shows is the server's arithmetic, not the
/// handset's. If the parts do not cover the total, the remainder is drawn as a
/// gap rather than quietly scaled away; a bar that always fills would be
/// hiding the one thing worth noticing.
///
/// Drawn by `fl_chart` as a single rod turned on its side, so it grows into
/// place when the screen arrives instead of appearing finished. A stacked bar
/// rather than a ring: at a glance forty per cent and forty-five look alike on
/// a pie, and along a bar they do not.
///
/// Use it only where the parts genuinely belong to the whole. Counts that can
/// overlap — a visit that both served a notice and imposed a fine — are not a
/// composition, and stacking them would invent a total nobody can defend.
class AppCompositionBar extends StatefulWidget {
  const AppCompositionBar({
    super.key,
    required this.slices,
    required this.total,
    this.remainderLabel = 'Elsewhere',
  });

  final List<CompositionSlice> slices;

  /// The whole, from whoever computed it.
  final double total;

  /// What to call the part the slices do not account for.
  final String remainderLabel;

  @override
  State<AppCompositionBar> createState() => _AppCompositionBarState();
}

class _AppCompositionBarState extends State<AppCompositionBar> {
  /// fl_chart animates *between* states, so a bar built once at its final
  /// values never moves. Starting empty and swapping on the first frame is
  /// what makes it grow. A post-frame callback rather than a timer, so a
  /// widget test settles without one left pending.
  bool _grown = false;

  static const double _height = 22;

  /// The surface showing between segments. Two pixels, so adjacent fills read
  /// as separate without a border drawing more attention than the data.
  static const double _gapPixels = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _grown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slices.isEmpty || widget.total <= 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final still = MediaQuery.disableAnimationsOf(context);
    final grown = _grown || still;

    final accounted = widget.slices.fold<double>(
      0,
      (double sum, CompositionSlice s) => sum + s.value,
    );
    final remainder = (widget.total - accounted).clamp(0.0, widget.total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _height,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // The gap is a spacer segment in the data, sized from the real
              // width so it lands as two pixels rather than as some fraction
              // that changes with the screen.
              final gap = constraints.maxWidth <= 0
                  ? 0.0
                  : widget.total * (_gapPixels / constraints.maxWidth);

              return BarChart(
                duration: still
                    ? Duration.zero
                    : const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                BarChartData(
                  // Turned on its side: one rod, running left to right.
                  rotationQuarterTurns: 1,
                  alignment: BarChartAlignment.center,
                  maxY: widget.total,
                  minY: 0,
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(enabled: false),
                  barGroups: <BarChartGroupData>[
                    BarChartGroupData(
                      x: 0,
                      barRods: <BarChartRodData>[
                        BarChartRodData(
                          toY: grown ? widget.total : 0,
                          width: _height,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                          color: Colors.transparent,
                          rodStackItems: grown
                              ? _stack(theme, remainder, gap)
                              : const <BarChartRodStackItem>[],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        // The legend carries the figure and the share, so the segments are
        // never the only way to read the chart — and a reader who cannot tell
        // two of the colours apart loses nothing.
        for (int i = 0; i < widget.slices.length; i++) ...[
          if (i > 0) const SizedBox(height: 9),
          _LegendRow(
            color: widget.slices[i].color,
            label: widget.slices[i].label,
            value: widget.slices[i].valueLabel,
            share: _share(widget.slices[i].value),
          ),
        ],
        if (remainder > 0) ...[
          const SizedBox(height: 9),
          _LegendRow(
            color: theme.colorScheme.surfaceContainerHighest,
            label: widget.remainderLabel,
            value: '',
            share: _share(remainder),
            muted: muted,
          ),
        ],
      ],
    );
  }

  /// Segments end to end along the rod, each one separated from the next by a
  /// sliver of the card's own colour.
  List<BarChartRodStackItem> _stack(
    ThemeData theme,
    double remainder,
    double gap,
  ) {
    final items = <BarChartRodStackItem>[];
    final surface = theme.cardTheme.color ?? theme.colorScheme.surface;
    var at = 0.0;

    void add(double value, Color color) {
      if (value <= 0) return;
      if (items.isNotEmpty) {
        items.add(BarChartRodStackItem(at, at + gap, surface));
        at += gap;
      }
      final end = (at + value - (items.isEmpty ? 0 : 0)).clamp(
        at,
        widget.total,
      );
      items.add(BarChartRodStackItem(at, end, color));
      at = end;
    }

    for (final CompositionSlice slice in widget.slices) {
      add(slice.value, slice.color);
    }
    add(remainder, theme.colorScheme.surfaceContainerHighest);
    return items;
  }

  String _share(double value) {
    final percent = (value / widget.total) * 100;
    return percent >= 10 || percent == 0
        ? '${percent.round()}%'
        : '${percent.toStringAsFixed(1)}%';
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
    required this.share,
    this.muted,
  });

  final Color color;
  final String label;
  final String value;
  final String share;
  final Color? muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: AppText.body(label, color: muted, maxLines: 1)),
        const SizedBox(width: 10),
        if (value.isNotEmpty) ...[
          AppText.caption(value, color: muted),
          const SizedBox(width: 10),
        ],
        SizedBox(
          width: 42,
          child: AppText.label(share, textAlign: TextAlign.end),
        ),
      ],
    );
  }
}
