import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:mcq_app/app/dependency_injection.dart';
import 'package:mcq_app/config/routes/app_router.dart';
import 'package:mcq_app/config/routes/app_routes.dart';
import 'package:mcq_app/controllers/auth_controller.dart';
import 'package:mcq_app/controllers/unit_search_controller.dart';
import 'package:mcq_app/data/repositories/dashboard_repository.dart';
import 'package:mcq_app/data/repositories/defaulters_repository.dart';
import 'package:mcq_app/data/repositories/enforcement_case_repository.dart';
import 'package:mcq_app/data/repositories/reporting_repository.dart';
import 'package:mcq_app/data/repositories/units_repository.dart';
import 'package:mcq_app/views/magistrate/home/widgets/home_search_button.dart';
import 'package:mcq_app/views/magistrate/property/property_profile_screen.dart';
import 'package:mcq_app/views/magistrate/search/unit_search_screen.dart';
import 'package:mcq_app/views/magistrate/search/widgets/unit_tile.dart';

import 'support/api_stub.dart';
import 'support/dashboard_fixtures.dart';
import 'support/property_profile_fixtures.dart';
import 'support/units_fixtures.dart';

/// The search box on Home, and the page it opens.
///
/// The officer is standing in front of a shop: the question is "which unit is
/// this?", and it has to reach `enforcement/field/units` — the list that holds
/// every unit, including the ones that owe nothing and so never appear on the
/// defaulter list they would otherwise be looked for on.
void main() {
  late FakeUnitsRepository units;
  late FakeReportingRepository reporting;

  setUp(() {
    Get.reset();
    installInMemoryKeychain();
    setupDependencies();

    // Swap the repositories, not the controllers: `Get.put` is
    // put-*if-absent*, so putting a controller over the registration made by
    // `setupDependencies` is silently a no-op.
    Get.delete<DashboardRepository>(force: true);
    Get.put<DashboardRepository>(FakeDashboardRepository(), permanent: true);
    Get.delete<DefaultersRepository>(force: true);
    Get.put<DefaultersRepository>(FakeDefaultersRepository(), permanent: true);
    Get.delete<UnitsRepository>(force: true);
    units = FakeUnitsRepository();
    Get.put<UnitsRepository>(units, permanent: true);
    Get.delete<ReportingRepository>(force: true);
    reporting = FakeReportingRepository();
    Get.put<ReportingRepository>(reporting, permanent: true);
    Get.delete<EnforcementCaseRepository>(force: true);
    Get.put<EnforcementCaseRepository>(
      FakeEnforcementCaseRepository(),
      permanent: true,
    );

    Get.find<AuthController>().officer.value = officerFixture;
  });

  tearDown(Get.reset);

  /// Settles the frame and the entrance animations, which `flutter_animate`
  /// schedules on a plain `Timer` that `pumpAndSettle` does not advance.
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
  }

  /// Home, on the real router: what is under test is the whole trip a press
  /// makes, out of the circle on Home and into the page it grows into.
  Future<void> pumpHome(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(420, 2200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    appRouter.go(AppRoutes.magistrateHome);
    await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter));
    await settle(tester);
  }

  Future<void> openSearch(WidgetTester tester) async {
    await pumpHome(tester);
    expect(find.byType(HomeSearchButton), findsOneWidget);
    await tester.tap(find.byType(HomeSearchButton));
    await settle(tester);
  }

  testWidgets('the search action on Home opens the register, already read', (
    WidgetTester tester,
  ) async {
    await openSearch(tester);

    expect(find.byType(UnitSearchScreen), findsOneWidget);

    // Read the moment it opens, with no term: the officer is in front of a
    // shop, so their own bazaars are worth showing before a word is typed.
    expect(units.calls, 1);
    expect(units.lastSearch, isNull);
    expect(units.lastLimit, UnitSearchController.pageSize);
    expect(find.byType(UnitTile), findsWidgets);
  });

  testWidgets('typing asks the register once, not once a letter', (
    WidgetTester tester,
  ) async {
    await openSearch(tester);

    await tester.enterText(find.byType(TextFormField), 'Abdul');
    // Each keystroke restarts the wait; only the last one is asked.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextFormField), 'Abdul Z');
    await settle(tester);

    expect(units.lastSearch, 'Abdul Z');
    expect(units.calls, 2);

    // And the answer is what is on screen: one holder, not the whole beat.
    expect(find.byType(UnitTile), findsOneWidget);
    expect(find.text('Abdul Zahir'), findsOneWidget);
  });

  testWidgets('a paid-up shop is on the list the defaulters never show', (
    WidgetTester tester,
  ) async {
    await openSearch(tester);

    await tester.enterText(find.byType(TextFormField), 'MCQ-KJC-0268');
    await settle(tester);

    // The whole point of searching this list rather than the defaulter one.
    expect(find.text('Muhammad Iqbal'), findsOneWidget);
    expect(find.text('Paid up'), findsOneWidget);
  });

  testWidgets('a result opens that shop’s profile', (
    WidgetTester tester,
  ) async {
    await openSearch(tester);

    await tester.tap(find.byType(UnitTile).first);
    await settle(tester);

    expect(find.byType(PropertyProfileScreen), findsOneWidget);
    // The unit that was tapped, not the list's first defaulter.
    expect(reporting.lastPropertyId, unitsFixture.first.propertyId);
  });

  testWidgets('leaving the page drops the search behind it', (
    WidgetTester tester,
  ) async {
    await openSearch(tester);
    expect(Get.isRegistered<UnitSearchController>(), isTrue);

    appRouter.pop();
    await settle(tester);

    // A search is one question asked in front of one shop: coming back to
    // Home and pressing the box again is a new one.
    expect(find.byType(UnitSearchScreen), findsNothing);
    expect(Get.isRegistered<UnitSearchController>(), isFalse);
  });
}
