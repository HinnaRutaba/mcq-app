import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcq_app/widgets/widgets.dart';

/// A tab chosen elsewhere (a dashboard tile) must come into view on the bar.
void main() {
  final List<String> items = <String>[
    for (int i = 0; i < 12; i++) 'Filter number $i',
  ];

  Future<void> pump(WidgetTester tester, String selected) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListView(
          children: <Widget>[
            const SizedBox(height: 500),
            AppChipTabs<String>(
              items: items,
              itemLabel: (String s) => s,
              selected: selected,
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    ),
  );

  bool onScreen(WidgetTester tester, String label) {
    final Rect chip = tester.getRect(find.text(label));
    return chip.left >= 0 && chip.right <= 800;
  }

  testWidgets('opens scrolled to a far selected chip', (tester) async {
    await pump(tester, items.last);
    await tester.pumpAndSettle();
    expect(onScreen(tester, items.last), isTrue);
  });

  testWidgets('scrolls to a newly selected chip, not the page', (tester) async {
    await pump(tester, items.first);
    await tester.pumpAndSettle();
    expect(onScreen(tester, items[9]), isFalse);

    await pump(tester, items[9]);
    await tester.pumpAndSettle();
    expect(onScreen(tester, items[9]), isTrue);
    // The bar sits low on the page; revealing a chip must not drag it up.
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels,
      0,
    );
  });
}
