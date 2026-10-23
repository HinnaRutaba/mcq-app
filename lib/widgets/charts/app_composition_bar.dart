import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
/// Each segment springs out in turn when the screen arrives, instead of the
/// bar appearing finished. A stacked bar rather than a ring: at a glance forty per cent and forty-five look alike on
/// a pie, and along a bar they do not.
///
/// Use it only where the parts genuinely belong to the whole. Counts that can
/// overlap — a visit that both served a notice and imposed a fine — are not a
/// composition, and stacking them would invent a total nobody can defend.
class AppCompositionBar extends StatelessWidget {
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

  static const double _height = 22;

  /// The surface showing between segments. Two pixels, so adjacent fills read
  /// as separate without a border drawing more attention than the data.
  static const double _gapPixels = 2;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty || total <= 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final still = MediaQuery.disableAnimationsOf(context);

    final accounted = slices.fold<double>(
      0,
      (double sum, CompositionSlice s) => sum + s.value,
    );
    final remainder = (total - accounted).clamp(0.0, total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _height,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // The gap is sized from the real width so it lands as two
              // pixels rather than as some fraction that changes with the
              // screen.
              final width = constraints.maxWidth;
              final gap = width <= 0 ? 0.0 : total * (_gapPixels / width);
              final segments = _segments(theme, remainder, gap);

              return ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xs),
                child: Stack(
                  children: <Widget>[
                    for (int i = 0; i < segments.length; i++)
                      Positioned(
                        left: segments[i].from / total * width,
                        width:
                            (segments[i].to - segments[i].from) / total * width,
                        top: 0,
                        bottom: 0,
                        child: _spring(
                          ColoredBox(color: segments[i].color),
                          i,
                          still,
                        ),
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
        for (int i = 0; i < slices.length; i++) ...[
          if (i > 0) const SizedBox(height: 9),
          _LegendRow(
            color: slices[i].color,
            label: slices[i].label,
            value: slices[i].valueLabel,
            share: _share(slices[i].value),
          ),
        ],
        if (remainder > 0) ...[
          const SizedBox(height: 9),
          _LegendRow(
            color: theme.colorScheme.surfaceContainerHighest,
            label: remainderLabel,
            value: '',
            share: _share(remainder),
            muted: muted,
          ),
        ],
      ],
    );
  }

  /// One segment springing out from its own left edge, a beat after the one
  /// before it. Its overshoot runs into the next segment's room before that
  /// one arrives. The wait is on the effect, not on `animate`, which uses a
  /// `Timer` a test's settle never runs out.
  static Widget _spring(Widget segment, int index, bool still) {
    if (still) return segment;
    return segment.animate().scaleX(
      delay: 250.ms + 140.ms * index,
      begin: 0,
      end: 1,
      alignment: Alignment.centerLeft,
      duration: 900.ms,
      curve: const ElasticOutCurve(0.55),
    );
  }

  /// Segments end to end along the bar, with the gaps between them left
  /// empty so the card shows through.
  List<({double from, double to, Color color})> _segments(
    ThemeData theme,
    double remainder,
    double gap,
  ) {
    final parts = <(double, Color)>[
      for (final CompositionSlice slice in slices)
        if (slice.value > 0) (slice.value, slice.color),
      if (remainder > 0) (remainder, theme.colorScheme.surfaceContainerHighest),
    ];
    if (parts.isEmpty) return const <({double from, double to, Color color})>[];

    // The separators come out of the bar's length rather than being added to
    // it: laid end to end past the total, the last segment starts beyond the
    // bar's end. Gaps that would not fit are dropped instead.
    final gaps = gap * (parts.length - 1);
    final spaced = gaps > 0 && gaps < total;
    final scale = spaced ? (total - gaps) / total : 1.0;

    final items = <({double from, double to, Color color})>[];
    var at = 0.0;
    for (final (double value, Color color) in parts) {
      if (spaced && items.isNotEmpty) at = math.min(at + gap, total);
      // Parts adding up past the server's total are cut off at it — the bar
      // never draws beyond its own end.
      final end = math.min(at + value * scale, total);
      items.add((from: at, to: end, color: color));
      at = end;
    }
    return items;
  }

  String _share(double value) {
    final percent = (value / total) * 100;
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
