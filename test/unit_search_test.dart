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
import 'package:mcq_app/views/magistrate/search/widgets/pin_card.dart';
import 'package:mcq_app/views/magistrate/search/widgets/unit_map.dart';
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
    // The map is a platform view: without an answer on its channel, drawing
    // one throws out of an async gap and fails whatever was on screen.
    installPlatformViewStub();
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
    reporting = FakeReportingRepository(pins: mapPinsFixture);
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

  /// Reads the same shops as a map. The icon is the one on the header, which
  /// is the only map glyph on the page.
  Future<void> openMap(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.map_outlined));
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

  testWidgets('the map icon places the shops the register could place', (
    WidgetTester tester,
  ) async {
    await openSearch(tester);
    await openMap(tester);

    expect(find.byType(UnitMap), findsOneWidget);
    expect(find.byType(UnitTile), findsNothing);

    // The map is its own endpoint — the whole beat, not the search's 50.
    expect(reporting.mapCalls, 1);
    expect(reporting.lastMapLimit, UnitSearchController.pinPageSize);

    // And what it could not place is said out loud rather than left to imply
    // the bazaar is six shops big.
    expect(find.text('6 shops placed · 5 without a fix'), findsOneWidget);
  });

  testWidgets('searching on the map opens the shop it found', (
    WidgetTester tester,
  ) async {
    await openSearch(tester);
    await openMap(tester);

    await tester.enterText(find.byType(TextFormField), 'Abdul Zahir');
    await settle(tester);

    // The camera goes to the pin — see `UnitMap` — and the card names it.
    final UnitSearchController controller = Get.find<UnitSearchController>();
    expect(controller.selectedPin.value?.propertyId, 302);
    // The holder comes off the search row: a pin names nobody. Scoped to the
    // card, because the same words are sitting in the search box.
    expect(find.widgetWithText(PinCard, 'Abdul Zahir'), findsOneWidget);
    expect(
      find.widgetWithText(PinCard, '67 · Kandahari Jamia Cabins'),
      findsOneWidget,
    );
  });

  testWidgets('a shop the map never placed is placed from its own fix', (
    WidgetTester tester,
  ) async {
    await openSearch(tester);
    await openMap(tester);

    // On the register and in the search, but not among the six pins.
    await tester.enterText(find.byType(TextFormField), 'Muhammad Iqbal');
    await settle(tester);

    final UnitSearchController controller = Get.find<UnitSearchController>();
    expect(controller.selectedPin.value?.propertyId, 268);
    expect(find.byType(PinCard), findsOneWidget);
  });

  testWidgets('the icon goes back to the list, and the pins are kept', (
    WidgetTester tester,
  ) async {
    await openSearch(tester);
    await openMap(tester);

    await tester.tap(find.byIcon(Icons.format_list_bulleted_rounded));
    await settle(tester);
    expect(find.byType(UnitTile), findsWidgets);
    expect(find.byType(UnitMap), findsNothing);

    await openMap(tester);
    expect(find.byType(UnitMap), findsOneWidget);
    // A whole beat read twice for two presses of the same icon.
    expect(reporting.mapCalls, 1);
  });
}
