import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:mcq_app/app/app.dart';
import 'package:mcq_app/app/dependency_injection.dart';
import 'package:mcq_app/views/magistrate/collections_screen.dart';
import 'package:mcq_app/views/magistrate/magistrate_home_screen.dart';
import 'package:mcq_app/views/magistrate/sealed_screen.dart';

void main() {
  setUp(() {
    Get.reset();
    setupDependencies();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('Splash screen shows the app name', (WidgetTester tester) async {
    await tester.pumpWidget(const McqApp());
    await tester.pump();

    expect(find.text('MCQ'), findsOneWidget);

    // Let the splash screen's navigation timer finish so it doesn't leak
    // into the next test.
    await tester.pumpAndSettle(const Duration(milliseconds: 1800));
  });

  // The screens below are placeholders until they are wired to the MCQ
  // Magistrate API. These tests hold the shape that survives that wiring —
  // each screen builds, and names itself — so a screen cannot quietly go
  // blank on the way to being connected.
  testWidgets('Home screen builds while it awaits the field beat', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MagistrateHomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Not wired up yet'), findsOneWidget);
  });

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
