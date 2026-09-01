import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:mcq_app/controllers/auth_controller.dart';
import 'package:mcq_app/controllers/dashboard_controller.dart';
import 'package:mcq_app/core/network/api_exception.dart';
import 'package:mcq_app/data/repositories/auth_repository.dart';
import 'package:mcq_app/config/theme/app_series_colors.dart';
import 'package:mcq_app/views/magistrate/magistrate_home_screen.dart';
import 'package:mcq_app/views/magistrate/widgets/beat_queue_tile.dart';
import 'package:mcq_app/widgets/widgets.dart';

import 'support/api_stub.dart';
import 'support/dashboard_fixtures.dart';

/// Home, end to end from the payload: the controller fetches, the screen shows
/// the officer the token was issued for and the figures the beat returned.
void main() {
  late StubbedApi api;
  late AuthController auth;
  late FakeDashboardRepository repository;
  late FakeDefaultersRepository defaulters;

  /// Builds the screen over [repository], having registered everything it
  /// resolves through GetX.
  Future<void> pumpHome(WidgetTester tester, {double height = 4000}) async {
    // A phone's width, but tall enough that the whole page is laid out — a
    // `ListView` does not build what is below the fold, and on the default
    // 800x600 surface the activity half simply would not exist to assert on.
    tester.view
      ..physicalSize = Size(400, height)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Get.put<DashboardController>(
      DashboardController(
        dashboardRepository: repository,
        defaultersRepository: defaulters,
        authController: auth,
      ),
    );
    await tester.pumpWidget(
      const MaterialApp(home: MagistrateHomeScreen()),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    Get.reset();
    api = StubbedApi();
    auth = AuthController(
      authRepository: ApiAuthRepository(api: api.service, storage: api.storage),
    );
    auth.officer.value = officerFixture;
    Get.put<AuthController>(auth, permanent: true);
    repository = FakeDashboardRepository();
    defaulters = FakeDefaultersRepository();
  });

  tearDown(Get.reset);

  group('the signed-in officer', () {
    testWidgets('is greeted in the header, and nothing more', (
      WidgetTester tester,
    ) async {
      await pumpHome(tester);

      expect(find.text('Habibullah Tareen'), findsOneWidget);
      expect(find.text('Municipal Magistrate'), findsOneWidget);

      // The account details are the profile page's job now. Home is for the
      // work waiting, not for telling officers their own username.
      expect(find.text('magistrate@mcq.test'), findsNothing);
      expect(find.text('MAGISTRATE'), findsNothing);
    });
  });

  group('the beat', () {
    testWidgets('says which bazaars the figures cover', (
      WidgetTester tester,
    ) async {
      await pumpHome(tester);

      // The one thing that must never be missing: without it the totals read
      // as city-wide.
      expect(find.text('Jinnah Road · Prince Road'), findsOneWidget);
      expect(find.text('Your beat'), findsOneWidget);
      expect(find.text('Zone 1 - Zarghoon'), findsOneWidget);
    });

    testWidgets('shows every queue, with its amount formatted', (
      WidgetTester tester,
    ) async {
      await pumpHome(tester);

      expect(find.text('Defaulters'), findsOneWidget);
      expect(find.text('55'), findsOneWidget);
      expect(find.text('Rs 2,213,409'), findsOneWidget);
      expect(find.text('Follow-ups due'), findsOneWidget);
      expect(find.text('Awaiting unseal'), findsOneWidget);
      expect(find.text('Sealed shops'), findsOneWidget);
      expect(find.text('Open cases'), findsOneWidget);
      expect(find.text('Assigned to me'), findsOneWidget);
    });
  });

  group('the page itself', () {
    testWidgets('the header collapses to the name and stays put', (
      WidgetTester tester,
    ) async {
      // A real handset's worth of screen, so there is something to scroll.
      await pumpHome(tester, height: 800);

      // The sliver itself is not a box; measure the block it paints.
      double headerHeight() => tester
          .getSize(
            find
                .descendant(
                  of: find.byType(AppSliverHeroHeader),
                  matching: find.byType(ClipRect),
                )
                .first,
          )
          .height;

      final expanded = headerHeight();
      expect(find.text('Municipal Magistrate'), findsOneWidget);
      expect(find.text('Your beat'), findsOneWidget);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      // Pinned: still there, and shorter than it was.
      expect(find.byType(AppSliverHeroHeader), findsOneWidget);
      expect(headerHeight(), lessThan(expanded));
      expect(headerHeight(), kToolbarHeight);

      // The name survives; everything around it has gone.
      expect(find.text('Habibullah Tareen'), findsOneWidget);
      expect(
        tester.widget<Opacity>(
          find.ancestor(
            of: find.text('Municipal Magistrate'),
            matching: find.byType(Opacity),
          ),
        ).opacity,
        0,
        reason: 'the designation is faded out, not left ghosted over the bar',
      );
      expect(
        tester.widget<Opacity>(
          find.ancestor(
            of: find.text('Your beat'),
            matching: find.byType(Opacity),
          ),
        ).opacity,
        0,
      );
    });

    testWidgets('the header comes back on the way up', (
      WidgetTester tester,
    ) async {
      await pumpHome(tester, height: 800);

      double headerHeight() => tester
          .getSize(
            find
                .descendant(
                  of: find.byType(AppSliverHeroHeader),
                  matching: find.byType(ClipRect),
                )
                .first,
          )
          .height;

      final expanded = headerHeight();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(headerHeight(), expanded);
      expect(find.text('Your beat'), findsOneWidget);
    });

    testWidgets('the queues sit three to a row', (WidgetTester tester) async {
      await pumpHome(tester);

      double top(int index) =>
          tester.getTopLeft(find.byType(BeatQueueTile).at(index)).dy;

      expect(find.byType(BeatQueueTile), findsNWidgets(6));
      expect(top(0), top(1));
      expect(top(1), top(2));
      expect(
        top(3),
        greaterThan(top(2)),
        reason: 'the fourth queue starts the second row',
      );
    });
  });

  group('the defaulters', () {
    /// Finds [text] inside the ranked bar list, not the share legend above
    /// it — both name the same bazaars.
    Finder inList(String text) => find.descendant(
      of: find.byType(AppBarList),
      matching: find.text(text),
    );

    testWidgets('breaks the arrears down by bazaar, worst first', (
      WidgetTester tester,
    ) async {
      await pumpHome(tester);

      expect(find.text('Outstanding by bazaar'), findsOneWidget);
      for (final String bazaar in <String>[
        'Prince Road Market',
        'Liaquat Bazaar',
        'Kandahari Bazaar',
      ]) {
        expect(inList(bazaar), findsOneWidget, reason: bazaar);
      }

      // Each market's own total, as the server sent it — never two added
      // together, which is why two markets in Jinnah Road stay two rows.
      expect(inList('Rs 1,004,813'), findsOneWidget);
      expect(inList('Rs 887,458'), findsOneWidget);
      expect(inList('Rs 321,138'), findsOneWidget);

      expect(find.text('25 shops behind · Jinnah Road'), findsOneWidget);
    });

    testWidgets('bars run longest first', (WidgetTester tester) async {
      await pumpHome(tester);

      double y(String label) => tester.getTopLeft(inList(label)).dy;

      expect(y('Prince Road Market'), lessThan(y('Liaquat Bazaar')));
      expect(y('Liaquat Bazaar'), lessThan(y('Kandahari Bazaar')));
    });

    testWidgets('shows each bazaar as a share of the beat total', (
      WidgetTester tester,
    ) async {
      await pumpHome(tester);

      expect(find.text('Share of the arrears'), findsOneWidget);
      // The denominator is the server's own figure from the defaulters queue,
      // never the three market amounts added up in Dart.
      expect(
        find.text('Of Rs 2,213,409 owed across your beat.'),
        findsOneWidget,
      );
      expect(find.text('45%'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      expect(find.text('15%'), findsOneWidget);
      expect(find.byType(AppCompositionBar), findsOneWidget);
    });

    testWidgets('a bazaar keeps one colour across both charts', (
      WidgetTester tester,
    ) async {
      await pumpHome(tester);

      final expected = AppSeriesColors.of(Brightness.light).take(3).toList();

      // The share bar's segments, in the order the controller ranked them.
      final segments = tester
          .widgetList<ColoredBox>(
            find.descendant(
              of: find.byType(AppCompositionBar),
              matching: find.byType(ColoredBox),
            ),
          )
          .map((ColoredBox box) => box.color)
          .toList();
      expect(segments.take(3), expected);

      // And the same three in the ranked list below, or the colour is
      // decoration rather than a way to follow one bazaar down the screen.
      final barFills = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(AppBarList),
              matching: find.byType(Container),
            ),
          )
          .map((Container c) => (c.decoration as BoxDecoration?)?.color)
          .toSet();
      for (final Color colour in expected) {
        expect(barFills, contains(colour));
      }
    });

    testWidgets('no server total means no share chart, not a guessed one', (
      WidgetTester tester,
    ) async {
      // The beat without an amount on its defaulters queue.
      repository = FakeDashboardRepository(
        beatOverride: beatWithoutTotalFixture,
      );

      await pumpHome(tester);

      expect(find.byType(AppCompositionBar), findsNothing);
      expect(
        find.byType(AppBarList),
        findsWidgets,
        reason: 'the ranked list does not need a total and still draws',
      );
    });

    testWidgets('totals the counts across markets', (
      WidgetTester tester,
    ) async {
      await pumpHome(tester);

      expect(find.text('Broken promises'), findsOneWidget);
      expect(find.text('3'), findsWidgets); // 0 + 2 + 1
      expect(find.text('Never paid'), findsOneWidget);
      expect(find.text('26'), findsOneWidget); // 14 + 9 + 3
      expect(find.text('Sealed'), findsOneWidget);
    });
  });

  group('the officer\'s own work', () {
    testWidgets('shows the tallies and the action breakdown', (
      WidgetTester tester,
    ) async {
      await pumpHome(tester);

      expect(find.text('27'), findsOneWidget);
      expect(find.text('Visits'), findsOneWidget);
      expect(find.text('Fines imposed'), findsNWidgets(2)); // tile + breakdown
      expect(find.text('Notices served'), findsOneWidget);
      expect(find.text('Site visits'), findsOneWidget);
    });

    testWidgets('labels the collected money as the server does, with the caveat', (
      WidgetTester tester,
    ) async {
      await pumpHome(tester);

      expect(find.text('Collected in your areas'), findsOneWidget);
      expect(find.text('Rs 224,506'), findsOneWidget);
      expect(
        find.text('Everything paid in these bazaars — not only what you recovered.'),
        findsOneWidget,
        reason: 'the figure is not a personal recovery total and must not read as one',
      );
      expect(find.text('Rs 15,000'), findsOneWidget);
    });

    testWidgets('a different window refetches only the activity', (
      WidgetTester tester,
    ) async {
      await pumpHome(tester);
      expect(repository.lastDaysRequested, 30);

      await tester.tap(find.text('Last 7'));
      await tester.pumpAndSettle();

      expect(repository.lastDaysRequested, 7);
      expect(
        defaulters.roundCalls,
        1,
        reason: 'the round does not depend on the activity window',
      );
      expect(
        find.text('Jinnah Road · Prince Road'),
        findsOneWidget,
        reason: 'the beat does not depend on the window and must not be refetched away',
      );
    });
  });

  group('when the calls fail', () {
    testWidgets('nothing loaded shows a retry, not an empty page', (
      WidgetTester tester,
    ) async {
      repository = FakeDashboardRepository(failure: _offline);
      defaulters = FakeDefaultersRepository(failure: _offline);

      await pumpHome(tester);

      expect(find.text('Could not load your beat'), findsOneWidget);
      expect(find.text('No connection.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      // The officer is still named — that comes from the token, not the call.
      expect(find.text('Habibullah Tareen'), findsOneWidget);
    });

    testWidgets('a retry that works replaces the error with the figures', (
      WidgetTester tester,
    ) async {
      repository = FakeDashboardRepository(failure: _offline);
      defaulters = FakeDefaultersRepository(failure: _offline);
      await pumpHome(tester);
      expect(find.text('Try again'), findsOneWidget);

      // The signal comes back, and the officer taps retry themselves.
      repository.failure = null;
      defaulters.failure = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Try again'), findsNothing);
      expect(find.text('Jinnah Road · Prince Road'), findsOneWidget);
      expect(find.text('55'), findsOneWidget);
    });
  });
}

const ApiException _offline = ApiException(
  message: 'No connection.',
  failure: ApiFailure.network,
);
