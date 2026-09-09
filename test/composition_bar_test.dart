import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mcq_app/widgets/charts/app_composition_bar.dart';

/// The share bar's segment maths. The slivers between segments have to be
/// taken out of the bar's length: added on top, they walk the last segment off
/// the end of the axis, and a bar whose parts already reach the total has
/// nowhere left to put one.
void main() {
  Widget wrap(AppCompositionBar bar) => MaterialApp(
    home: Scaffold(body: Center(child: SizedBox(width: 320, child: bar))),
  );

  List<CompositionSlice> slices(List<double> values) => <CompositionSlice>[
    for (int i = 0; i < values.length; i++)
      CompositionSlice(
        label: 'Bazaar $i',
        value: values[i],
        valueLabel: '${values[i]}',
        color: Colors.primaries[i].shade400,
      ),
  ];

  testWidgets('draws a market too small to sit beside the slivers', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        AppCompositionBar(
          total: 29736402.24,
          slices: slices(<double>[
            9736402.24,
            8000000,
            6000000,
            5999900,
            100,
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('draws a remainder smaller than the slivers', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        AppCompositionBar(
          total: 1000,
          slices: slices(<double>[400, 300, 299.5]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('draws slices that overrun the server total', (
    WidgetTester tester,
  ) async {
    // Parts summing past the whole is the server disagreeing with itself; the
    // bar cuts them off at its end rather than throwing.
    await tester.pumpWidget(
      wrap(
        AppCompositionBar(total: 1000, slices: slices(<double>[800, 700, 600])),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
