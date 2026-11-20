import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcq_app/widgets/widgets.dart';

Widget _host(String text) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 240, child: AppExpandableText(text))),
);

void main() {
  testWidgets('short text has no toggle', (WidgetTester tester) async {
    await tester.pumpWidget(_host('Confirm the deposit.'));
    expect(find.text('Show more'), findsNothing);
  });

  testWidgets('long text folds at two lines and opens on tap', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host('The arrears statement does not match. ' * 8),
    );
    final Text clamped = tester.widget<Text>(find.byType(Text).first);
    expect(clamped.maxLines, 2);

    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byType(Text).first).maxLines, isNull);
    expect(find.text('Show less'), findsOneWidget);

    await tester.tap(find.text('Show less'));
    await tester.pumpAndSettle();
    expect(find.text('Show more'), findsOneWidget);
  });
}
