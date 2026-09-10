import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:mcq_app/app/dependency_injection.dart';
import 'package:mcq_app/config/routes/app_router.dart';
import 'package:mcq_app/config/routes/app_routes.dart';
import 'package:mcq_app/controllers/auth_controller.dart';
import 'package:mcq_app/controllers/cases_controller.dart';
import 'package:mcq_app/controllers/defaulters_controller.dart';
import 'package:mcq_app/controllers/follow_ups_controller.dart';
import 'package:mcq_app/controllers/seals_controller.dart';
import 'package:mcq_app/data/repositories/dashboard_repository.dart';
import 'package:mcq_app/data/repositories/defaulters_repository.dart';
import 'package:mcq_app/data/repositories/enforcement_case_repository.dart';
import 'package:mcq_app/data/repositories/field_seal_repository.dart';
import 'package:mcq_app/views/magistrate/cases/cases_screen.dart';
import 'package:mcq_app/views/magistrate/home/queue_destination.dart';
import 'package:mcq_app/views/magistrate/defaulters/defaulters_screen.dart';
import 'package:mcq_app/views/magistrate/followups/follow_ups_screen.dart';
import 'package:mcq_app/views/magistrate/home/widgets/beat_queue_tile.dart';
import 'package:mcq_app/views/magistrate/more/sealed_screen.dart';
import 'package:mcq_app/views/magistrate/shared/widgets/defaulter_tile.dart';

import 'support/api_stub.dart';
import 'support/dashboard_fixtures.dart';
import 'support/property_profile_fixtures.dart';
import 'support/seal_fixtures.dart';

/// Where the queue tiles on Home go.
///
/// The figures are the point of that grid, and a figure an officer cannot
/// press is half a screen: tapping "55 defaulters" has to land on those 55,
/// on the reading the tile named — not on the list's last filter, and not on
/// an approximate list somewhere else.
void main() {
  late FakeEnforcementCaseRepository cases;
  late FakeDefaultersRepository defaulters;

  setUp(() {
    Get.reset();
    installInMemoryKeychain();
    setupDependencies();

    // Swap the repositories, not the controllers: `Get.put` is
    // put-*if-absent*, so putting a controller over the `lazyPut` made by
    // `setupDependencies` is silently a no-op. The controllers are `fenix`,
    // so each screen's `Get.find` builds a fresh one over the fakes below.
    Get.delete<DashboardRepository>(force: true);
    Get.put<DashboardRepository>(FakeDashboardRepository(), permanent: true);
    Get.delete<DefaultersRepository>(force: true);
    defaulters = FakeDefaultersRepository();
    Get.put<DefaultersRepository>(defaulters, permanent: true);
    Get.delete<FieldSealRepository>(force: true);
    Get.put<FieldSealRepository>(FakeFieldSealRepository(), permanent: true);
    Get.delete<EnforcementCaseRepository>(force: true);
    cases = FakeEnforcementCaseRepository();
    Get.put<EnforcementCaseRepository>(cases, permanent: true);

    Get.find<AuthController>().officer.value = officerFixture;
  });

  tearDown(Get.reset);

  /// Settles the frame *and* the entrance animations, which `flutter_animate`
  /// schedules on a plain `Timer` that `pumpAndSettle` does not advance.
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  /// Home, on the real router: what is under test is the whole trip a tap
  /// makes, through the shell's branches and into the screen at the end.
  Future<void> pumpHome(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(420, 2200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    appRouter.go(AppRoutes.magistrateHome);
    await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter));
    await settle(tester);
  }

  /// Presses the tile labelled [label] — by its tile, not its text: the
  /// bottom bar carries some of the same words.
  Future<void> tapQueue(WidgetTester tester, String label) async {
    final Finder tile = find.widgetWithText(BeatQueueTile, label);
    expect(tile, findsOneWidget, reason: 'no queue tile reads "$label"');
    await tester.tap(tile);
    await settle(tester);
  }

  testWidgets('the defaulters queue opens the defaulter list', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);
    await tapQueue(tester, 'Defaulters');

    expect(find.byType(DefaultersScreen), findsOneWidget);
    expect(
      Get.find<DefaultersController>().stateFilter.value,
      DefaulterState.everyone,
    );
  });

  testWidgets('the follow-ups queue opens the promises that have come due', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);
    await tapQueue(tester, 'Follow-ups due');

    // The follow-ups endpoint's own list, not the defaulter list narrowed by
    // the `commitment` on its rows: those are two different questions, and a
    // tile reading 1 over a list showing none is what that cost.
    expect(find.byType(FollowUpsScreen), findsOneWidget);
    expect(Get.find<FollowUpsController>().state.value, FollowUpState.due);
    expect(defaulters.lastFollowUpState, FollowUpState.due);

    // Asked for once, on the reading the tile named — not the default list
    // followed by this one.
    expect(defaulters.followUpCalls, 1);

    // And the rows are up: the count on the tile and the length of this list
    // are the same fact.
    expect(find.byType(DefaulterTile), findsOneWidget);
  });

  testWidgets('the unseal queue opens the seals cleared to come off', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);
    await tapQueue(tester, 'Awaiting unseal');

    expect(find.byType(SealedScreen), findsOneWidget);
    expect(Get.find<SealsController>().queue.value, SealQueue.ready);
  });

  testWidgets('the sealed queue opens the whole register', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);
    await tapQueue(tester, 'Sealed shops');

    expect(find.byType(SealedScreen), findsOneWidget);
    expect(Get.find<SealsController>().queue.value, SealQueue.all);
  });

  testWidgets('the open cases queue opens the case register', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);
    await tapQueue(tester, 'Open cases');

    expect(find.byType(CasesScreen), findsOneWidget);
    expect(Get.find<CasesController>().filter.value, CaseFilter.all);
  });

  testWidgets('the assigned queue opens the register on this officer’s own', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);
    await tapQueue(tester, 'Assigned to me');

    expect(find.byType(CasesScreen), findsOneWidget);
    expect(Get.find<CasesController>().filter.value, CaseFilter.mine);

    // And the first page was asked for once, not once per filter: the tile
    // seeds the filter before the controller's first fetch rather than
    // fetching the whole register and then this slice of it. A bazaar's
    // uplink is what pays for a wasted page.
    expect(
      cases.pagesRequested.where((int page) => page == 1),
      hasLength(1),
      reason: 'page one went out twice: ${cases.pagesRequested}',
    );
  });

  testWidgets('a queue the app has no screen for is not pressable', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);

    final BeatQueueTile answered = tester.widget<BeatQueueTile>(
      find.widgetWithText(BeatQueueTile, 'Open cases'),
    );
    expect(answered.onTap, isNotNull);

    // Every queue the enforcement beat sends is answered; this is the guard
    // for one the server adds after this build ships, which has to draw as a
    // figure rather than as a button that goes nowhere.

    expect(QueueDestination.exists('something_new'), isFalse);
  });
}
