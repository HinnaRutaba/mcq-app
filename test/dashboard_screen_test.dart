import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:mcq_app/controllers/auth_controller.dart';
import 'package:mcq_app/controllers/dashboard_controller.dart';
import 'package:mcq_app/core/network/api_exception.dart';
import 'package:mcq_app/data/repositories/auth_repository.dart';
import 'package:mcq_app/views/magistrate/magistrate_home_screen.dart';

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
  Future<void> pumpHome(WidgetTester tester) async {
    // A phone's width, but tall enough that the whole page is laid out — a
    // `ListView` does not build what is below the fold, and on the default
    // 800x600 surface the activity half simply would not exist to assert on.
    tester.view
      ..physicalSize = const Size(400, 4000)
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

  group('the defaulters', () {
    testWidgets('breaks the arrears down by bazaar, worst first', (
      WidgetTester tester,
    ) async {
      await pumpHome(tester);

      expect(find.text('Outstanding by bazaar'), findsOneWidget);
      expect(find.text('Prince Road Market'), findsOneWidget);
      expect(find.text('Liaquat Bazaar'), findsOneWidget);
      expect(find.text('Kandahari Bazaar'), findsOneWidget);

      // Each market's own total, as the server sent it — never two added
      // together, which is why two markets in Jinnah Road stay two rows.
      expect(find.text('Rs 1,004,813'), findsOneWidget);
      expect(find.text('Rs 887,458'), findsOneWidget);
      expect(find.text('Rs 321,138'), findsOneWidget);

      expect(find.text('25 shops behind · Jinnah Road'), findsOneWidget);
    });

    testWidgets('bars run longest first', (WidgetTester tester) async {
      await pumpHome(tester);

      double y(String label) => tester.getTopLeft(find.text(label)).dy;

      expect(y('Prince Road Market'), lessThan(y('Liaquat Bazaar')));
      expect(y('Liaquat Bazaar'), lessThan(y('Kandahari Bazaar')));
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
