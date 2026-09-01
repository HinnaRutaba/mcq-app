import 'package:flutter/material.dart';

import '../../config/theme/app_status_colors.dart';
import '../text/app_text.dart';

/// One row of an [AppBarList].
class BarDatum {
  const BarDatum({
    required this.label,
    required this.value,
    required this.valueLabel,
    this.caption,
    this.color,
  });

  /// The category this bar names, e.g. a bazaar or an action type.
  final String label;

  /// The magnitude the bar length encodes. Only ever compared against the
  /// other bars in the same list.
  final double value;

  /// The figure as it should be printed — formatted money, or a count. Kept
  /// separate from [value] so money can be shown exactly as the server sent
  /// it while the bar is drawn from a number.
  final String valueLabel;

  /// An optional second line, e.g. "25 shops behind".
  final String? caption;

  /// This entity's own colour. Null leaves the list in one hue.
  ///
  /// Assign it from what the row *is*, never from where it sorts — the point
  /// of colouring a ranked list at all is that the same entity is the same
  /// colour in the chart beside it, and that breaks the moment a bar takes its
  /// colour from its position.
  final Color? color;
}

/// A ranked horizontal bar list: one measure across a handful of named
/// categories, longest first.
///
/// Horizontal because the categories are names — "Liaquat Bazaar", "Notices
/// served" — and names read along a row rather than rotated under a column.
///
/// One colour by default: the bars carry length, not identity, and giving each
/// category its own hue would imply a distinction that is not in the data. The
/// default hue is the theme's brand step, chosen per brightness rather than
/// flipped, so dark mode is its own colour and not an inversion.
///
/// A caller that is already showing these same entities in another chart can
/// pass [BarDatum.color] per row, so one bazaar is one colour on both.
///
/// Every row prints its own figure. There are few enough rows that a number on
/// each is readable, and it means the length is a second reading of the value
/// and never the only one — nothing here is encoded in colour alone.
class AppBarList extends StatelessWidget {
  const AppBarList({super.key, required this.data, this.sorted = true});

  final List<BarDatum> data;

  /// Longest first. Off when the caller's own order carries meaning.
  final bool sorted;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final rows = sorted
        ? (List<BarDatum>.of(data)..sort((a, b) => b.value.compareTo(a.value)))
        : data;

    // Bars are read against each other, not against an absolute scale, so the
    // longest sets the width. A list where every value is zero draws no fill
    // rather than dividing by nothing.
    final largest = rows.fold<double>(0, (m, d) => d.value > m ? d.value : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _Bar(datum: rows[i], largest: largest),
        ],
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.datum, required this.largest});

  final BarDatum datum;
  final double largest;

  /// Thin: the bar is a comparison, not a block of colour.
  static const double _height = 8;

  @override
  Widget build(BuildContext context) {
    final fill = datum.color ?? context.status.brand;
    final track = Theme.of(context).colorScheme.surfaceContainerHighest;
    final muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    final fraction = largest <= 0 ? 0.0 : (datum.value / largest).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: AppText.body(datum.label, maxLines: 1)),
            const SizedBox(width: 12),
            // The figure wears a text token, never the bar's colour — the mark
            // beside it is what carries identity.
            AppText.label(datum.valueLabel),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final width = fraction == 0
                ? 0.0
                // A real but tiny value still gets something to see.
                : (constraints.maxWidth * fraction).clamp(3.0, constraints.maxWidth);

            return Stack(
              children: [
                Container(
                  height: _height,
                  decoration: BoxDecoration(
                    color: track,
                    borderRadius: const BorderRadiusDirectional.horizontal(
                      end: Radius.circular(4),
                    ),
                  ),
                ),
                // Square at the baseline, rounded at the data end, so the bar
                // reads as growing from an axis rather than floating — and it
                // does grow: from nothing to its figure when the list arrives.
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: width),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (BuildContext context, double grown, Widget? _) =>
                      Container(
                        height: _height,
                        width: grown,
                        decoration: BoxDecoration(
                          color: fill,
                          borderRadius:
                              const BorderRadiusDirectional.horizontal(
                                end: Radius.circular(4),
                              ),
                        ),
                      ),
                ),
              ],
            );
          },
        ),
        if (datum.caption != null) ...[
          const SizedBox(height: 5),
          AppText.caption(datum.caption!, color: muted, maxLines: 1),
        ],
      ],
    );
  }
}
