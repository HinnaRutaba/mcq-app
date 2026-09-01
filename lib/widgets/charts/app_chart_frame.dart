import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../cards/app_card.dart';
import '../text/app_text.dart';

/// One entry in a chart legend, and one row of its table view.
class ChartLegendEntry {
  const ChartLegendEntry({
    required this.label,
    required this.colour,
    required this.value,
    this.icon,
    this.share,
  });

  final String label;
  final Color colour;

  /// The figure, already formatted. A chart never formats money itself —
  /// it is handed the server's string.
  final String value;

  /// Paired with the colour so identity is never carried by colour alone.
  final IconData? icon;

  /// `0.0`–`1.0`, drawn as a per-cent beside the value where it helps.
  final double? share;
}

/// The frame every chart in the app is drawn in.
///
/// It exists to hold the three accessibility rules that are easy to skip
/// and impossible to retrofit:
///
/// 1. **A legend is always present for two or more series**, and each entry
///    carries a glyph as well as a swatch — colour is never the only
///    carrier of identity.
/// 2. **A table view always exists.** Some of these colours sit under the
///    3:1 contrast ratio against a white card at chart-mark sizes, and the
///    remedy for that is not a different colour — it is that the figures
///    are readable as text. Tapping "Figures" swaps the plot for the
///    numbers, which is also the answer for an officer who simply wants to
///    read the value rather than estimate it off a bar.
/// 3. **The plot is never the only place a number appears.** The legend
///    carries the value for every series.
class AppChartFrame extends StatefulWidget {
  const AppChartFrame({
    super.key,
    required this.chart,
    required this.entries,
    this.title,
    this.subtitle,
    this.height = 190,
    this.showLegend = true,
    this.trailing,
  });

  /// The plot itself.
  final Widget chart;

  /// The legend, and the table view's rows.
  final List<ChartLegendEntry> entries;

  final String? title;
  final String? subtitle;
  final double height;

  /// False for a single-series chart, where the title already names it and
  /// a one-row legend is noise.
  final bool showLegend;

  final Widget? trailing;

  @override
  State<AppChartFrame> createState() => _AppChartFrameState();
}

class _AppChartFrameState extends State<AppChartFrame> {
  bool _table = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null || widget.trailing != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.title != null)
                        AppText.titleMedium(widget.title!, maxLines: 2),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        AppText.bodySmall(widget.subtitle!, color: muted),
                      ],
                    ],
                  ),
                ),
                ?widget.trailing,
                // The table view, one tap away and never hidden in a menu.
                IconButton(
                  onPressed: () => setState(() => _table = !_table),
                  tooltip: _table ? t('chart.showChart') : t('chart.showTable'),
                  isSelected: _table,
                  icon: Icon(
                    _table ? Icons.bar_chart_rounded : Icons.table_rows_rounded,
                    size: 20,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _table
                  ? _Table(
                      key: const ValueKey('table'),
                      entries: widget.entries,
                    )
                  : SizedBox(
                      key: const ValueKey('chart'),
                      height: widget.height,
                      child: widget.chart,
                    ),
            ),
          ),
          if (widget.showLegend && widget.entries.length > 1 && !_table) ...[
            const SizedBox(height: 14),
            _Legend(entries: widget.entries),
          ],
        ],
      ),
    );
  }
}

/// Swatch, glyph, name, figure — on one line each, wrapping.
class _Legend extends StatelessWidget {
  const _Legend({required this.entries});

  final List<ChartLegendEntry> entries;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final entry in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The swatch is a rounded square, not a dot: at 10px a dot is
              // three pixels of colour and the hue is unreadable.
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: entry.colour,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              if (entry.icon != null) ...[
                const SizedBox(width: 5),
                Icon(entry.icon, size: 14, color: muted),
              ],
              const SizedBox(width: 6),
              // Text wears text tokens, never the series colour.
              AppText.bodySmall(entry.label, color: muted, maxLines: 1),
              const SizedBox(width: 6),
              AppText.labelMedium(entry.value, maxLines: 1),
            ],
          ),
      ],
    );
  }
}

/// The figures, as text. Always available, for the reader who cannot pick
/// two of these colours apart and for the one who just wants the number.
class _Table extends StatelessWidget {
  const _Table({super.key, required this.entries});

  final List<ChartLegendEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Column(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) Divider(color: theme.dividerColor, height: 17),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: entries[i].colour,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              if (entries[i].icon != null) ...[
                const SizedBox(width: 6),
                Icon(entries[i].icon, size: 15, color: muted),
              ],
              const SizedBox(width: 10),
              Expanded(child: AppText.body(entries[i].label, maxLines: 2)),
              const SizedBox(width: 10),
              if (entries[i].share != null) ...[
                AppText.bodySmall(
                  '${(entries[i].share! * 100).round()}%',
                  color: muted,
                ),
                const SizedBox(width: 10),
              ],
              AppText.titleSmall(entries[i].value),
            ],
          ),
        ],
      ],
    );
  }
}
