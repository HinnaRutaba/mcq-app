import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:mcq_app/app/app.dart';
import 'package:mcq_app/app/dependency_injection.dart';
import 'package:mcq_app/views/magistrate/magistrate_home_screen.dart';
import 'package:mcq_app/views/tenant/tenant_home_screen.dart';

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

  testWidgets('Tenant Home screen loads with seeded chalaans', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TenantHomeScreen()));
    await tester.pumpAndSettle();

    // Seed data has exactly two outstanding chalaans for the demo tenant
    // (CHL-101 upcoming, CHL-102 overdue).
    expect(find.text('Upcoming Payments (2)'), findsOneWidget);
    expect(find.text('Past Payments'), findsOneWidget);
  });

  testWidgets('Magistrate Home screen loads with seeded collections', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MagistrateHomeScreen()));
    await tester.pumpAndSettle();

    // Seed data has exactly one unpaid fine (FIN-201).
    expect(find.text('Unpaid Fines (1)'), findsOneWidget);
    expect(find.text('Pending Collections'), findsOneWidget);
    // "Ready to Unseal" appears twice: the section header and the seal's
    // own status badge (SealStatus.readyToUnseal.label).
    expect(find.text('Ready to Unseal'), findsNWidgets(2));
  });
}
