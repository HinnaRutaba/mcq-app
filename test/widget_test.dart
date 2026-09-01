import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:mcq_app/app/app.dart';
import 'package:mcq_app/app/dependency_injection.dart';
import 'package:mcq_app/views/magistrate/collections_screen.dart';
import 'package:mcq_app/views/magistrate/sealed_screen.dart';

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

  // The screens below are placeholders until they are wired to the MCQ
  // Magistrate API. These tests hold the shape that survives that wiring —
  // each screen builds, and names itself — so a screen cannot quietly go
  // blank on the way to being connected. Home has been wired and left this
  // list; it is covered by `dashboard_screen_test.dart`.
  testWidgets('Collections screen builds while it awaits the defaulters list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CollectionsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Collections'), findsOneWidget);
    expect(find.text('Not wired up yet'), findsOneWidget);
  });

  testWidgets('Sealed screen builds while it awaits the seal list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SealedScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Sealed Shops'), findsOneWidget);
    expect(find.text('Not wired up yet'), findsOneWidget);
  });
}
