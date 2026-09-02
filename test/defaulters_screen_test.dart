import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:mcq_app/controllers/defaulters_controller.dart';
import 'package:mcq_app/core/network/api_exception.dart';
import 'package:mcq_app/core/utils/dialer.dart';
import 'package:mcq_app/views/magistrate/defaulters/defaulters_screen.dart';
import 'package:mcq_app/views/magistrate/defaulters/widgets/defaulter_tile.dart';
import 'package:mcq_app/widgets/widgets.dart';

import 'support/dashboard_fixtures.dart';

/// Defaulters, end to end from the payload: the controller fetches, the screen
/// lists what came back, and the two filters go where they belong — the bazaar
/// and the search term to the server, the state chips to the rows in hand.
void main() {
  late FakeDefaultersRepository defaulters;
  late FakeDashboardRepository dashboard;

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

  /// Builds the screen over the fakes, having registered the controller it
  /// resolves through GetX.
  Future<DefaultersController> pumpDefaulters(
    WidgetTester tester, {
    double height = 2400,
    double width = 400,
  }) async {
    // A phone's width, but tall enough that every row is laid out — a sliver
    // list does not build what is below the fold, and on the default surface
    // most of the list would not exist to assert on.
    tester.view
      ..physicalSize = Size(width, height)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final DefaultersController controller = Get.put<DefaultersController>(
      DefaultersController(
        defaultersRepository: defaulters,
        dashboardRepository: dashboard,
      ),
    );
    await tester.pumpWidget(const MaterialApp(home: DefaultersScreen()));
    await settle(tester);
    return controller;
  }

  /// Types into the search box and waits out the debounce.
  Future<void> searchFor(WidgetTester tester, String term) async {
    await tester.enterText(find.byType(EditableText), term);
    await tester.pump(DefaultersController.searchDebounce);
    await settle(tester);
  }

  List<String> shopsOnScreen(WidgetTester tester) => tester
      .widgetList<DefaulterTile>(find.byType(DefaulterTile))
      .map((DefaulterTile tile) => tile.card.shopNo ?? '?')
      .toList();

  setUp(() {
    Get.reset();
    defaulters = FakeDefaultersRepository();
    dashboard = FakeDashboardRepository();
  });

  tearDown(Get.reset);

  group('the list', () {
    testWidgets('arrives in the order the server ranked it', (
      WidgetTester tester,
    ) async {
      await pumpDefaulters(tester);

      // Worst first is the server's ranking. Re-sorting here would quietly
      // disagree with the figures on Home.
      expect(shopsOnScreen(tester), <String>[
        'S-22',
        'F-3',
        'F-11',
        'K-7',
        'S-4',
        'K-19',
      ]);
    });

    testWidgets('asks for the whole beat in one call', (
      WidgetTester tester,
    ) async {
      await pumpDefaulters(tester);

      // The state chips count what came back, so a truncated list would show
      // the officer a wrong figure rather than a short one.
      expect(defaulters.lastLimit, DefaultersController.pageSize);
      expect(defaulters.lastAreaId, isNull);
      expect(defaulters.lastSearch, isNull);
    });

    testWidgets('carries what an officer decides from', (
      WidgetTester tester,
    ) async {
      await pumpDefaulters(tester);

      // The holder leads: they are who the officer asks for at the shop.
      expect(find.text('Muhammad Iqbal'), findsOneWidget);
      expect(find.text('S-22 · Liaquat Bazaar'), findsOneWidget);
      // Printed from the string the server sent, never totalled in Dart.
      expect(find.text('Rs 187,450'), findsOneWidget);
      expect(find.text('14 months behind'), findsOneWidget);
      // The tenancy this unit is held under.
      expect(find.text('ALT-2019-041'), findsOneWidget);
      expect(find.text('Never paid'), findsNWidgets(2));
      expect(find.text('Case #204'), findsOneWidget);

      // The states are read off the card, one badge each — and a promise
      // carries the day it comes due, which is one fact and not two.
      expect(find.text('Promised · 5 Sep 2026'), findsOneWidget);
      expect(find.text('Sealed · SL-2026-0037'), findsOneWidget);

      // A unit nobody holds still owes rent, and still has to be listed.
      expect(find.text('No holder on record'), findsOneWidget);
    });

    testWidgets('offers the holder a call rather than digits to read', (
      WidgetTester tester,
    ) async {
      await pumpDefaulters(tester);

      // Four of the six rows have a number on the register.
      expect(find.widgetWithText(AppButton, 'Call'), findsNWidgets(4));
      expect(find.text('03001234511'), findsNothing);
    });

    testWidgets('the call button hands the number to the dialler', (
      WidgetTester tester,
    ) async {
      final _FakeDialer dialer = _FakeDialer();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaulterTile(card: defaultersFixture.first, dialer: dialer),
          ),
        ),
      );

      await tester.tap(find.text('Call'));
      await tester.pumpAndSettle();

      expect(dialer.dialled, <String>['03001234511']);
    });
  });

  group('searching', () {
    testWidgets('asks the server, once the typing has stopped', (
      WidgetTester tester,
    ) async {
      await pumpDefaulters(tester);
      final int beforeTyping = defaulters.defaultersCalls;

      await tester.enterText(find.byType(EditableText), 'Sam');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(EditableText), 'Samad');
      expect(
        defaulters.defaultersCalls,
        beforeTyping,
        reason:
            'a call per keystroke on a bazaar uplink answers one question '
            'five times',
      );

      await tester.pump(DefaultersController.searchDebounce);
      await settle(tester);

      expect(defaulters.defaultersCalls, beforeTyping + 1);
      expect(defaulters.lastSearch, 'Samad');
      expect(shopsOnScreen(tester), <String>['F-3']);
    });

    testWidgets('an empty result offers the way back out', (
      WidgetTester tester,
    ) async {
      await pumpDefaulters(tester);
      await searchFor(tester, 'nobody by that name');

      expect(find.byType(DefaulterTile), findsNothing);
      expect(find.text('No shops match'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pump(DefaultersController.searchDebounce);
      await settle(tester);

      expect(find.byType(DefaulterTile), findsNWidgets(6));
      expect(defaulters.lastSearch, isNull);
    });
  });

  group('the bazaar filter', () {
    testWidgets('offers the bazaars on the officer’s beat', (
      WidgetTester tester,
    ) async {
      await pumpDefaulters(tester);

      // The beat's scope is the published list of bazaars this officer is
      // posted to; the rows only name the ones that happen to owe something.
      expect(find.text('All bazaars'), findsOneWidget);

      await tester.tap(find.byType(AppDropdown<int>));
      await settle(tester);

      expect(find.text('Jinnah Road'), findsOneWidget);
      expect(find.text('Prince Road'), findsOneWidget);
    });

    testWidgets('asks the server for that bazaar alone', (
      WidgetTester tester,
    ) async {
      final DefaultersController controller = await pumpDefaulters(tester);

      await controller.setArea(2);
      await settle(tester);

      expect(defaulters.lastAreaId, 2);
      expect(shopsOnScreen(tester), <String>['F-3', 'F-11']);
    });
  });

  group('the state chips', () {
    testWidgets('say how many rows each of them holds', (
      WidgetTester tester,
    ) async {
      // Wider than a handset on purpose: the chip row scrolls horizontally on
      // a real one, and a chip that is off screen is not built to assert on.
      await pumpDefaulters(tester, width: 900);

      expect(find.text('Everyone · 6'), findsOneWidget);
      expect(find.text('Never paid · 2'), findsOneWidget);
      expect(find.text('Promised · 1'), findsOneWidget);
      expect(find.text('Sealed · 1'), findsOneWidget);
      expect(find.text('Open case · 2'), findsOneWidget);
    });

    testWidgets('re-count as soon as the server narrows the list', (
      WidgetTester tester,
    ) async {
      await pumpDefaulters(tester, width: 900);
      expect(find.text('Everyone · 6'), findsOneWidget);

      // A search and a bazaar are answered by the server, and neither of them
      // touches the chip selection — so the counts have to follow the rows
      // arriving, not the next tap on a chip.
      // A property code, which is one of the four fields the search covers —
      // a market name is not one of them.
      await searchFor(tester, 'PR-PM');
      expect(find.text('Everyone · 2'), findsOneWidget);
      expect(find.text('Never paid · 0'), findsOneWidget);
      expect(find.text('Sealed · 1'), findsOneWidget);

      await Get.find<DefaultersController>().setArea(1);
      await settle(tester);

      expect(find.text('Everyone · 0'), findsOneWidget);
    });

    testWidgets('filter the rows in hand, without a call', (
      WidgetTester tester,
    ) async {
      await pumpDefaulters(tester);
      final int beforeTap = defaulters.defaultersCalls;

      await tester.tap(find.text('Never paid · 2'));
      await settle(tester);

      expect(shopsOnScreen(tester), <String>['S-22', 'K-7']);
      expect(
        defaulters.defaultersCalls,
        beforeTap,
        reason: 'every row is already in hand; a state is not worth a call',
      );
    });

    testWidgets('an empty state is a dead end with a way out', (
      WidgetTester tester,
    ) async {
      defaulters = FakeDefaultersRepository(
        rows: defaultersFixture.where((card) => !card.isSealed).toList(),
      );
      // Wide enough that the fourth chip is built — see above.
      await pumpDefaulters(tester, width: 900);

      await tester.tap(find.text('Sealed · 0'));
      await settle(tester);

      expect(find.text('No shops match'), findsOneWidget);
      await tester.tap(find.text('Clear filters'));
      await settle(tester);

      expect(find.byType(DefaulterTile), findsNWidgets(5));
    });
  });

  group('when the bazaar has no signal', () {
    testWidgets('the failure is on screen with a way to retry', (
      WidgetTester tester,
    ) async {
      defaulters = FakeDefaultersRepository(failure: offline);
      dashboard = FakeDashboardRepository(failure: offline);
      await pumpDefaulters(tester);

      expect(find.text('Could not load the defaulters'), findsOneWidget);
      expect(find.text(offline.message), findsOneWidget);

      // Signal back, and the same button loads the list it failed on.
      defaulters.failure = null;
      dashboard.failure = null;
      await tester.tap(find.text('Try again'));
      await settle(tester);

      expect(find.byType(DefaulterTile), findsNWidgets(6));
      expect(find.text('Could not load the defaulters'), findsNothing);
    });

    testWidgets('a later failure is a note over the rows already up', (
      WidgetTester tester,
    ) async {
      final DefaultersController controller = await pumpDefaulters(tester);
      expect(find.byType(DefaulterTile), findsNWidgets(6));

      defaulters.failure = offline;
      await controller.load();
      await settle(tester);

      // The last good rows stay: an officer mid-round is not shown a wall
      // because one call missed.
      expect(find.byType(AppAlert), findsOneWidget);
      expect(find.byType(DefaulterTile), findsNWidgets(6));
    });
  });

  group('nobody behind at all', () {
    testWidgets('is said out loud, not left blank', (
      WidgetTester tester,
    ) async {
      defaulters = FakeDefaultersRepository(rows: const []);
      await pumpDefaulters(tester);

      expect(find.text('Nobody is behind'), findsOneWidget);
      expect(find.text('No shops match'), findsNothing);
    });
  });
}

/// A dialler a test can tap, since the platform has none.
class _FakeDialer extends Dialer {
  final List<String> dialled = <String>[];

  @override
  Future<bool> call(String mobileNo) async {
    dialled.add(mobileNo);
    return true;
  }
}
