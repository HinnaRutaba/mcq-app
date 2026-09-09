import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:mcq_app/app/app.dart';
import 'package:mcq_app/app/dependency_injection.dart';
import 'package:mcq_app/views/magistrate/round/round_screen.dart';

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

  // The screen below is a placeholder until it is wired to the MCQ Magistrate
  // API. This test holds the shape that survives that wiring — the screen
  // builds, and names itself — so it cannot quietly go blank on the way to
  // being connected. Home, Defaulters and the seal register have been wired
  // and left this list; they are covered by `dashboard_screen_test.dart`,
  // `defaulters_screen_test.dart` and `seals_screen_test.dart`.
  testWidgets('Round screen builds while it awaits the walking order', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RoundScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Today\u2019s Round'), findsOneWidget);
    expect(find.text('Not wired up yet'), findsOneWidget);
  });
}
