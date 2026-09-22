import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:mcq_app/app/app.dart';
import 'package:mcq_app/app/dependency_injection.dart';

import 'support/api_stub.dart';

void main() {
  setUp(() {
    Get.reset();
    // The splash screen asks the keychain whether anybody is signed in before
    // it routes, so a test has to answer.
    installInMemoryKeychain();
    setupDependencies();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('Splash screen shows the app name, then routes to sign-in', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const McqApp());
    await tester.pump();

    expect(find.text('MCQ'), findsOneWidget);

    // No stored token, so the splash sends them to sign in rather than to a
    // dashboard they are not entitled to. Settling also drains the splash's
    // timer so it cannot leak into the next test.
    await tester.pumpAndSettle(const Duration(milliseconds: 1800));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('MCQ'), findsNothing);
  });
}
