import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import 'package:mcq_app/config/routes/app_routes.dart';
import 'package:mcq_app/controllers/round_controller.dart';
import 'package:mcq_app/core/network/api_exception.dart';
import 'package:mcq_app/data/repositories/defaulters_repository.dart';
import 'package:mcq_app/data/repositories/enforcement_case_repository.dart';
import 'package:mcq_app/data/repositories/reporting_repository.dart';
import 'package:mcq_app/models/defaulter_card.dart';
import 'package:mcq_app/models/round_group.dart';
import 'package:mcq_app/views/magistrate/property/property_profile_screen.dart';
import 'package:mcq_app/views/magistrate/round/round_screen.dart';
import 'package:mcq_app/views/magistrate/round/widgets/round_sticky_head.dart';
import 'package:mcq_app/views/magistrate/shared/widgets/defaulter_tile.dart';
import 'package:mcq_app/widgets/widgets.dart';

import 'support/dashboard_fixtures.dart';
import 'support/property_profile_fixtures.dart';

/// Today's round, end to end from the payload: the controller fetches
/// `enforcement/field/round`, and the screen draws each bazaar's head followed
/// by the stops that bazaar sent — in the server's order, never re-sorted.
void main() {
  late FakeDefaultersRepository defaulters;

  const ApiException offline = ApiException(
    message: 'No connection. Check your signal and try again.',
    failure: ApiFailure.network,
  );

  /// Settles the frame *and* the entrance animations, which `flutter_animate`
  /// schedules on a plain `Timer` that `pumpAndSettle` does not advance.
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  Future<RoundController> pumpRound(
    WidgetTester tester, {
    double height = 3000,
    double width = 420,
  }) async {
    // A phone's width, but tall enough that every row is laid out — a sliver
    // list does not build what is below the fold.
    tester.view
      ..physicalSize = Size(width, height)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final RoundController controller = Get.put<RoundController>(
      RoundController(defaultersRepository: defaulters),
    );
    await tester.pumpWidget(const MaterialApp(home: RoundScreen()));
    await settle(tester);
    return controller;
  }

  /// The markets on screen, top to bottom.
  List<String> marketsOnScreen(WidgetTester tester) => tester
      .widgetList<RoundBazaarHead>(find.byType(RoundBazaarHead))
      .map((RoundBazaarHead head) => head.group.marketName ?? '?')
      .toList();

  /// The stops on screen, top to bottom — across every market.
  List<String> stopsOnScreen(WidgetTester tester) => tester
      .widgetList<DefaulterTile>(find.byType(DefaulterTile))
      .map((DefaulterTile tile) => tile.card.shopNo ?? '?')
      .toList();

  /// Types into the search box in the header. No debounce: the round arrives
  /// in one payload and the box narrows what is in hand.
  Future<void> searchFor(WidgetTester tester, String term) async {
    await tester.enterText(find.byType(EditableText), term);
    await settle(tester);
  }

  setUp(() {
    Get.reset();
    defaulters = FakeDefaultersRepository();
  });

  tearDown(Get.reset);

  group('the walking order', () {
    testWidgets('is the one the server sent', (WidgetTester tester) async {
      await pumpRound(tester);

      expect(defaulters.roundCalls, 1);
      expect(marketsOnScreen(tester), <String>[
        'Liaquat Bazaar',
        'Prince Road Market',
        'Kandahari Bazaar',
      ]);
    });

    testWidgets('puts each bazaar’s stops under its own head', (
      WidgetTester tester,
    ) async {
      await pumpRound(tester);

      // Grouped, not a flat ranking: F-11 owes less than S-4 and still comes
      // first, because it is in the bazaar the server listed second.
      expect(stopsOnScreen(tester), <String>[
        'S-22',
        'S-4',
        'F-3',
        'F-11',
        'K-7',
        'K-19',
      ]);
    });

    testWidgets('says what the bazaar owes before the officer walks in', (
      WidgetTester tester,
    ) async {
      await pumpRound(tester);

      // Printed from the string the server sent, never totalled in Dart.
      expect(find.text('Rs 887,458'), findsOneWidget);
      // 25 behind and 2 stops are different figures; side by side they read
      // as a contradiction unless the shortlist says it is one.
      // Two markets share Jinnah Road and both carry two stops, so the line
      // is the same on each of their heads — what tells them apart is on the
      // chips.
      expect(find.text('Jinnah Road · worst 2 to call at'), findsNWidgets(2));

      // The four figures the round sends per market, zeroes included: a chip
      // that appeared only when non-zero would leave an officer wondering
      // whether it had been checked.
      expect(find.text('Shops behind · 25'), findsOneWidget);
      expect(find.text('Broken promises · 0'), findsOneWidget);
      expect(find.text('Never paid · 14'), findsOneWidget);

      // And Prince Road Market's own, which differ on every one of them.
      expect(find.text('Shops behind · 21'), findsOneWidget);
      expect(find.text('Broken promises · 2'), findsOneWidget);
      expect(find.text('Never paid · 9'), findsOneWidget);
      expect(find.text('Sealed · 1'), findsOneWidget);

      // Nothing sealed in either Jinnah Road market, and both say so.
      expect(find.text('Sealed · 0'), findsNWidgets(2));
    });

    testWidgets('the stops are the same cards the defaulter list draws', (
      WidgetTester tester,
    ) async {
      await pumpRound(tester);

      expect(find.text('Muhammad Iqbal'), findsOneWidget);
      expect(find.text('S-22 · Liaquat Bazaar'), findsOneWidget);
      expect(find.text('Rs 187,450'), findsOneWidget);
      expect(find.text('14 months behind'), findsOneWidget);
      expect(find.text('Promised · 5 Sep 2026'), findsOneWidget);
      expect(find.text('Sealed · SL-2026-0037'), findsOneWidget);
      // A unit nobody holds is still a stop.
      expect(find.text('No holder on record'), findsOneWidget);
    });

    testWidgets('the header counts the walking, not the arrears', (
      WidgetTester tester,
    ) async {
      await pumpRound(tester);

      expect(find.text('3 bazaars · 6 stops'), findsOneWidget);
    });
  });

  group('the bazaar chips', () {
    testWidgets('are read off the round itself', (WidgetTester tester) async {
      // Wider than a handset: the chip row scrolls on a real one, and a chip
      // off screen is not built to assert on.
      await pumpRound(tester, width: 900);

      // Two bazaars over three markets, and the count is markets — which is
      // what the chip narrows the screen to. The round names its own areas on
      // every entry, so this costs no second call.
      expect(find.text('All bazaars · 3'), findsOneWidget);
      expect(find.text('Jinnah Road · 2'), findsOneWidget);
      expect(find.text('Prince Road · 1'), findsOneWidget);
    });

    testWidgets('narrow what is in hand, without a call', (
      WidgetTester tester,
    ) async {
      await pumpRound(tester, width: 900);
      final int beforePick = defaulters.roundCalls;

      await tester.tap(find.text('Prince Road · 1'));
      await settle(tester);

      expect(marketsOnScreen(tester), <String>['Prince Road Market']);
      expect(stopsOnScreen(tester), <String>['F-3', 'F-11']);
      expect(find.text('1 bazaar · 2 stops'), findsOneWidget);
      expect(
        defaulters.roundCalls,
        beforePick,
        reason: 'every market arrived in one payload; a bazaar is not a call',
      );
    });

    testWidgets('one bazaar on the beat is a label, not a choice', (
      WidgetTester tester,
    ) async {
      defaulters = FakeDefaultersRepository(
        roundGroups: roundFixture
            .where((RoundGroup group) => group.areaId == 2)
            .toList(),
      );
      await pumpRound(tester, width: 900);

      expect(find.byType(AppChipTabs<int>), findsNothing);
      expect(marketsOnScreen(tester), <String>['Prince Road Market']);
    });

    testWidgets('a bazaar that leaves the round does not empty the screen', (
      WidgetTester tester,
    ) async {
      final RoundController controller = await pumpRound(tester);
      controller.showArea(2);
      await settle(tester);
      expect(marketsOnScreen(tester), <String>['Prince Road Market']);

      // Prince Road pays up overnight, so the next refresh carries no chip
      // for it — and the officer would be left staring at an empty round.
      final List<RoundGroup> withoutPrinceRoad = roundFixture
          .where((RoundGroup group) => group.areaId != 2)
          .toList();
      Get.delete<RoundController>(force: true);
      final RoundController next = Get.put<RoundController>(
        RoundController(
          defaultersRepository: FakeDefaultersRepository(
            roundGroups: withoutPrinceRoad,
          ),
        ),
      );
      next.showArea(2);
      await next.load();

      expect(next.areaId.value, RoundController.allAreas);
      expect(next.visible.length, 2);
    });
  });

  group('searching', () {
    testWidgets('a bazaar name keeps that market whole', (
      WidgetTester tester,
    ) async {
      await pumpRound(tester);
      final int beforeTyping = defaulters.roundCalls;

      await searchFor(tester, 'kandahari');

      // The officer asked for the market, not for a shop in it, so both of
      // its stops stay.
      expect(marketsOnScreen(tester), <String>['Kandahari Bazaar']);
      expect(stopsOnScreen(tester), <String>['K-7', 'K-19']);
      expect(
        defaulters.roundCalls,
        beforeTyping,
        reason: 'the round takes no search term; the whole beat is in hand',
      );
    });

    testWidgets('a bazaar’s own area name finds every market in it', (
      WidgetTester tester,
    ) async {
      await pumpRound(tester);

      await searchFor(tester, 'jinnah');

      expect(marketsOnScreen(tester), <String>[
        'Liaquat Bazaar',
        'Kandahari Bazaar',
      ]);
    });

    testWidgets('a person keeps only the stops that match', (
      WidgetTester tester,
    ) async {
      await pumpRound(tester);

      await searchFor(tester, 'zubaida');

      // The market stays so the stop has a head over it, and says what the
      // whole market owes — but only the one shop is a stop now.
      expect(marketsOnScreen(tester), <String>['Liaquat Bazaar']);
      expect(stopsOnScreen(tester), <String>['S-4']);
      expect(find.text('Rs 887,458'), findsOneWidget);
      // The head still counts the market, not the search.
      expect(find.text('Jinnah Road · worst 2 to call at'), findsOneWidget);
      expect(find.text('1 bazaar · 1 stop'), findsOneWidget);
    });

    testWidgets('a shop number, a code and a CNIC all find the stop', (
      WidgetTester tester,
    ) async {
      await pumpRound(tester);

      for (final String term in <String>[
        'F-11',
        'PR-PM-145',
        '5440012345673',
        'ALT-2018-063',
      ]) {
        await searchFor(tester, term);
        expect(
          stopsOnScreen(tester),
          <String>['F-11'],
          reason: 'searching "$term" should reach Noor Ahmed’s shop',
        );
      }
    });

    testWidgets('every bazaar keeps its chip while typing', (
      WidgetTester tester,
    ) async {
      await pumpRound(tester, width: 900);

      await searchFor(tester, 'jinnah');

      // The chips come off the whole round, not off what is left, so the
      // bazaar an officer is reaching for cannot vanish from under their
      // thumb mid-word — it reads 0 instead.
      expect(find.text('Prince Road · 0'), findsOneWidget);

      await searchFor(tester, 'nothing answers to this');
      expect(find.text('Jinnah Road · 0'), findsOneWidget);
      expect(find.text('Prince Road · 0'), findsOneWidget);
    });

    testWidgets('nothing matching is a dead end with a way out', (
      WidgetTester tester,
    ) async {
      final RoundController controller = await pumpRound(tester);

      await searchFor(tester, 'nobody by that name');

      expect(find.byType(RoundBazaarHead), findsNothing);
      expect(find.text('Nothing matches'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await settle(tester);

      expect(find.byType(RoundBazaarHead), findsNWidgets(3));
      // The box itself is cleared, not just the rows put back.
      expect(controller.searchController.text, isEmpty);
      expect(controller.query.value, isEmpty);
    });
  });

  group('an empty round', () {
    testWidgets('nobody behind anywhere is said as the good outcome', (
      WidgetTester tester,
    ) async {
      defaulters = FakeDefaultersRepository(roundGroups: const <RoundGroup>[]);
      await pumpRound(tester);

      expect(find.text('Nothing to walk today'), findsOneWidget);
      expect(find.byType(RoundBazaarHead), findsNothing);
    });

    testWidgets('a chip that emptied it offers the way back out', (
      WidgetTester tester,
    ) async {
      defaulters = FakeDefaultersRepository(
        roundGroups: roundFixture
            .where((RoundGroup group) => group.areaId == 1)
            .toList(),
      );
      final RoundController controller = await pumpRound(tester);

      // A bazaar with no market on the round — reachable while a refresh is
      // in flight, and a dead end either way.
      controller.showArea(2);
      await settle(tester);

      expect(find.text('Nothing matches'), findsOneWidget);
      await tester.tap(find.text('Clear filters'));
      await settle(tester);

      expect(find.byType(RoundBazaarHead), findsNWidgets(2));
    });
  });

  group('when the bazaar has no signal', () {
    testWidgets('the failure is on screen with a way to retry', (
      WidgetTester tester,
    ) async {
      defaulters = FakeDefaultersRepository(failure: offline);
      await pumpRound(tester);

      expect(find.text('Could not load the round'), findsOneWidget);
      expect(find.text(offline.message), findsOneWidget);

      // Signal back, and the same button loads the round it failed on.
      defaulters.failure = null;
      await tester.tap(find.text('Try again'));
      await settle(tester);

      expect(find.byType(RoundBazaarHead), findsNWidgets(3));
      expect(find.text('Could not load the round'), findsNothing);
    });

    testWidgets('a later failure is a note over the round already up', (
      WidgetTester tester,
    ) async {
      final RoundController controller = await pumpRound(tester);
      expect(find.byType(RoundBazaarHead), findsNWidgets(3));

      defaulters.failure = offline;
      await controller.load();
      await settle(tester);

      // The last good round stays: an officer mid-walk is not shown a wall
      // because one call missed.
      expect(find.byType(AppAlert), findsOneWidget);
      expect(find.byType(RoundBazaarHead), findsNWidgets(3));
    });
  });

  group('after a write somewhere else', () {
    test('a round nobody has opened is not re-read', () async {
      Get.put<DefaultersRepository>(defaulters, permanent: true);
      Get.lazyPut<RoundController>(RoundController.new, fenix: true);

      await RoundController.reloadIfOpened();

      // `isRegistered` alone answers true for a factory that has never been
      // built; finding it would build it and fetch twice.
      expect(defaulters.roundCalls, 0);
    });

    test('an open round is re-read', () async {
      Get.put<DefaultersRepository>(defaulters, permanent: true);
      Get.lazyPut<RoundController>(RoundController.new, fenix: true);
      Get.find<RoundController>();
      await Future<void>.delayed(Duration.zero);
      expect(defaulters.roundCalls, 1);

      await RoundController.reloadIfOpened();

      expect(defaulters.roundCalls, 2);
    });
  });

  group('the bazaar head', () {
    testWidgets('stays on screen while its own stops scroll under it', (
      WidgetTester tester,
    ) async {
      // A real handset's worth of screen, so there is something to scroll.
      await pumpRound(tester, height: 820);

      Finder headFor(String market) => find.ancestor(
        of: find.text(market),
        matching: find.byType(RoundBazaarHead),
      );

      final double before = tester.getTopLeft(headFor('Liaquat Bazaar')).dy;
      expect(find.text('Muhammad Iqbal'), findsOneWidget);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -220));
      await settle(tester);

      // Pinned: the head is still up, and no lower than it was — the stops
      // have gone under it rather than taken it with them.
      expect(headFor('Liaquat Bazaar'), findsOneWidget);
      expect(
        tester.getTopLeft(headFor('Liaquat Bazaar')).dy,
        lessThanOrEqualTo(before),
      );
    });

    testWidgets('collapses to the name and the money, and the briefing goes', (
      WidgetTester tester,
    ) async {
      await pumpRound(tester, height: 820);

      double headHeight() => tester
          .getSize(
            find
                .ancestor(
                  of: find.text('Liaquat Bazaar'),
                  matching: find.byType(RoundBazaarHead),
                )
                .first,
          )
          .height;

      final double expanded = headHeight();
      expect(find.text('Jinnah Road · worst 2 to call at'), findsOneWidget);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await settle(tester);

      // The block is laid out at full height and clipped, so what shrinks is
      // the strip the sliver declares, not the widget's own box.
      expect(headHeight(), expanded);
      final RenderSliver head = tester.renderObject<RenderSliver>(
        find
            .ancestor(
              of: find.text('Liaquat Bazaar'),
              matching: find.byType(SliverPersistentHeader),
            )
            .first,
      );
      expect(head.geometry!.paintExtent, lessThan(expanded));

      // Faded out, so the last of the scroll is a clean name line.
      final Opacity briefing = tester.widget<Opacity>(
        find
            .descendant(
              of: find
                  .ancestor(
                    of: find.text('Liaquat Bazaar'),
                    matching: find.byType(RoundBazaarHead),
                  )
                  .first,
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(briefing.opacity, 0);
      expect(find.text('Liaquat Bazaar'), findsOneWidget);
      expect(find.text('Rs 887,458'), findsOneWidget);
    });
  });

  group('folding a market away', () {
    testWidgets('the head keeps the market, the stops go', (
      WidgetTester tester,
    ) async {
      final RoundController controller = await pumpRound(tester);
      expect(stopsOnScreen(tester).length, 6);

      await tester.tap(find.text('Liaquat Bazaar'));
      await settle(tester);

      // Walked and put away, not hidden: the head is still there and still
      // says what the bazaar owes.
      expect(marketsOnScreen(tester).length, 3);
      expect(find.text('Rs 887,458'), findsOneWidget);
      expect(stopsOnScreen(tester), <String>['F-3', 'F-11', 'K-7', 'K-19']);
      expect(controller.isCollapsed(controller.groups.first), isTrue);

      await tester.tap(find.text('Liaquat Bazaar'));
      await settle(tester);

      expect(stopsOnScreen(tester).length, 6);
    });

    testWidgets('a folded market stays folded across a refresh', (
      WidgetTester tester,
    ) async {
      final RoundController controller = await pumpRound(tester);

      await tester.tap(find.text('Kandahari Bazaar'));
      await settle(tester);
      expect(stopsOnScreen(tester), <String>['S-22', 'S-4', 'F-3', 'F-11']);

      // An officer who has walked a bazaar has finished with it; a pull to
      // refresh is not them asking for it back.
      await controller.load();
      await settle(tester);

      expect(stopsOnScreen(tester), <String>['S-22', 'S-4', 'F-3', 'F-11']);
    });

    testWidgets('folding one market leaves the others alone', (
      WidgetTester tester,
    ) async {
      await pumpRound(tester);

      await tester.tap(find.text('Prince Road Market'));
      await settle(tester);

      // Two markets share Jinnah Road, so a key that was the bazaar alone
      // would fold both of them.
      expect(stopsOnScreen(tester), <String>['S-22', 'S-4', 'K-7', 'K-19']);
    });
  });

  group('the payload off the wire', () {
    test('reads through the model, nulls and string money included', () {
      final List<RoundGroup> groups = roundOffTheWire;
      expect(groups.length, 3);

      final RoundGroup first = groups.first;
      expect(first.marketName, 'Kandahari Jamia Cabins');
      expect(first.areaId, 1);
      expect(first.shops, 58);
      expect(first.neverPaid, 39);
      expect(first.brokenPromises, 0);
      // Kept as the server's text, never parsed into a double.
      expect(first.outstanding, '8043306.00');
      expect(first.stops.length, 2);

      final DefaulterCard stop = first.stops.first;
      expect(stop.allotmentNo, 'MCQ-AL-00302');
      expect(stop.propertyId, 302);
      expect(stop.shopNo, '67');
      expect(stop.allotteeName, 'Abdul Zahir');
      expect(stop.outstanding, '410200.00');
      // A shop that has paid recently: 0 behind and no overdue day count at
      // all, which is what the tile's "N months behind" line has to survive.
      expect(stop.monthsBehind, 0);
      expect(stop.daysOverdue, isNull);
      expect(stop.neverPaid, isFalse);
      expect(stop.lastPaymentDate, DateTime(2026, 9, 14));
      // The round has never yet carried a non-null commitment.
      expect(stop.hasCommitment, isFalse);
      // Coordinates arrive as strings, and are only parsed for a map pin.
      expect(stop.map?.hasFix, isTrue);
      expect(stop.map?.latitudeValue, closeTo(30.194934, 1e-6));
      expect(stop.map?.longitudeValue, closeTo(67.016106, 1e-6));

      final DefaulterCard sealed = groups[1].stops.single;
      expect(sealed.isSealed, isTrue);
      expect(sealed.sealNo, 'MCQ-SL-2627-00001');
      expect(groups[1].sealed, 1);

      // A market the server sent with no stops at all.
      expect(groups[2].stops, isEmpty);
      expect(groups[2].areaId, 2);
    });

    testWidgets('draws as a market with a head and no stops under it', (
      WidgetTester tester,
    ) async {
      defaulters = FakeDefaultersRepository(roundGroups: roundOffTheWire);
      await pumpRound(tester);

      expect(marketsOnScreen(tester), <String>[
        'Kandahari Jamia Cabins',
        'Baldia Plaza',
        'Prince Road Shops',
      ]);
      expect(stopsOnScreen(tester), <String>['67', '30', '29']);
      // 7 behind and nothing picked out: the head says so rather than
      // standing over a gap.
      expect(
        find.text('Prince Road · none picked out yet'),
        findsOneWidget,
      );
      expect(find.text('Shops behind · 7'), findsOneWidget);
      expect(find.text('Rs 8,043,306'), findsOneWidget);
      // No overdue reading on the wire, so the tile shows none.
      expect(find.textContaining('days overdue'), findsNothing);
    });
  });

  group('opening a shop', () {
    testWidgets('a stop takes the officer to that shop’s profile', (
      WidgetTester tester,
    ) async {
      tester.view
        ..physicalSize = const Size(420, 6000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      Get.put<RoundController>(
        RoundController(defaultersRepository: defaulters),
      );
      Get.put<ReportingRepository>(FakeReportingRepository(), permanent: true);
      Get.put<EnforcementCaseRepository>(
        FakeEnforcementCaseRepository(),
        permanent: true,
      );

      // The two real routes, so the tap is answered by the app's own path and
      // its `extra` rather than by a stand-in.
      final GoRouter router = GoRouter(
        initialLocation: AppRoutes.magistrateRound,
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.magistrateRound,
            builder: (BuildContext context, GoRouterState state) =>
                const RoundScreen(),
          ),
          GoRoute(
            path: AppRoutes.propertyProfile,
            builder: (BuildContext context, GoRouterState state) =>
                PropertyProfileScreen(
                  propertyId: int.parse(state.pathParameters['id']!),
                  card: state.extra is DefaulterCard
                      ? state.extra! as DefaulterCard
                      : null,
                ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await settle(tester);

      await tester.tap(find.text('Muhammad Iqbal'));
      await settle(tester);

      expect(find.text('S-22 · Liaquat Bazaar'), findsOneWidget);
      expect(find.text('Register 949 · 949/JR/0118'), findsOneWidget);
    });
  });
}
