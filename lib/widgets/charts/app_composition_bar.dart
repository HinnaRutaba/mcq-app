import 'package:flutter/material.dart';

import '../text/app_text.dart';

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
  static const double _gap = 2;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty || total <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    final accounted = slices.fold<double>(
      0,
      (double sum, CompositionSlice s) => sum + s.value,
    );
    final remainder = (total - accounted).clamp(0.0, total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: _height,
            child: Row(
              // Stretch, or a childless fill has no height to take and the
              // whole bar draws as nothing.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < slices.length; i++) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  Expanded(
                    flex: _flex(slices[i].value),
                    child: ColoredBox(color: slices[i].color),
                  ),
                ],
                if (remainder > 0) ...[
                  const SizedBox(width: _gap),
                  Expanded(
                    flex: _flex(remainder),
                    child: ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ],
            ),
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

  /// Integer flex in tenths of a percent — fine enough that a small share is
  /// still proportional, coarse enough to stay whole numbers.
  int _flex(double value) => ((value / total) * 1000).round().clamp(1, 1000);

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
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: AppText.body(label, color: muted, maxLines: 1)),
        const SizedBox(width: 10),
        if (value.isNotEmpty) ...[
          AppText.caption(value, color: muted),
          const SizedBox(width: 10),
        ],
        SizedBox(width: 42, child: AppText.label(share, textAlign: TextAlign.end)),
      ],
    );
  }
}
