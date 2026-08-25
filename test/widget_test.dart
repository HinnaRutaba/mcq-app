import 'package:flutter_test/flutter_test.dart';

import 'package:mcq_app/app/app.dart';

void main() {
  testWidgets('Splash screen shows the app name', (WidgetTester tester) async {
    await tester.pumpWidget(const McqApp());
    await tester.pump();

    expect(find.text('MCQ'), findsOneWidget);

    // Let the splash screen's navigation timer finish so it doesn't leak
    // into the next test.
    await tester.pumpAndSettle(const Duration(milliseconds: 1800));
  });
}
