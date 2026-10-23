import 'package:flutter/material.dart';

import '../../core/utils/screen_type.dart';

/// A list screen's cards: one per row on a phone, two per row wider than one.
///
/// [lead] rows (an alert over the list) always span the full width. Paired
/// cards are stretched to the taller of the two, so a row reads as one band.
class AppSliverTiles extends StatelessWidget {
  const AppSliverTiles({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.lead = const <Widget>[],
    this.spacing = 12,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final List<Widget> lead;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final int columns = context.isMobile ? 1 : 2;
    final int rows = (itemCount + columns - 1) ~/ columns;

    return SliverList.builder(
      itemCount: lead.length + rows,
      itemBuilder: (BuildContext context, int index) {
        final Widget row;
        if (index < lead.length) {
          row = lead[index];
        } else if (columns == 1) {
          row = itemBuilder(context, index - lead.length);
        } else {
          final int first = (index - lead.length) * columns;
          row = IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int c = 0; c < columns; c++) ...<Widget>[
                  if (c > 0) SizedBox(width: spacing),
                  // An odd last card keeps its half, not the whole row.
                  Expanded(
                    child: first + c < itemCount
                        ? itemBuilder(context, first + c)
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          );
        }
        return Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: row,
        );
      },
    );
  }
}
