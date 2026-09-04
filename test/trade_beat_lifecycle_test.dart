import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:mcq_app/controllers/auth_controller.dart';
import 'package:mcq_app/controllers/trade_beat_controller.dart';
import 'package:mcq_app/controllers/trade_capture_controller.dart';
import 'package:mcq_app/controllers/trade_licences_controller.dart';
import 'package:mcq_app/data/repositories/auth_repository.dart';
import 'package:mcq_app/views/magistrate/trade/trade_licences_screen.dart';
import 'package:mcq_app/widgets/widgets.dart';

import 'support/api_stub.dart';
import 'support/dashboard_fixtures.dart';
import 'support/trade_fixtures.dart';

/// When the officer's bazaars are fetched, and how long they last.
///
/// They are a posting, not a queue: they do not change between screens, and
/// two licensing screens are drawn from them. So they are fetched once a
/// session and kept, which is what stops an officer opening the Licences tab
/// onto a spinner for a list that was already in hand.
void main() {
  late StubbedApi api;
  late AuthController auth;
  late FakeTradeRepository trade;
  late TradeBeatController beat;

  setUp(() {
    Get.reset();
    api = StubbedApi();
    auth = AuthController(
      authRepository: ApiAuthRepository(api: api.service, storage: api.storage),
    );
    Get.put<AuthController>(auth, permanent: true);

    trade = FakeTradeRepository();
    beat = TradeBeatController(tradeRepository: trade, authController: auth);
  });

  tearDown(Get.reset);

  /// Registers it the way `setupDependencies` does — permanently, which is
  /// what runs `onInit` and arms the session watcher.
  void register() => Get.put<TradeBeatController>(beat, permanent: true);

  test('nothing goes out before an officer is signed in', () async {
    register();
    await Future<void>.delayed(Duration.zero);

    // A call here would carry no bearer token, and its 401 would clear the
    // keychain out from under the splash screen.
    expect(trade.beatCalls, 0);
    expect(beat.isReady, isFalse);
  });

  test('the bazaars are fetched as soon as the session is usable', () async {
    register();
    auth.officer.value = officerFixture;
    await Future<void>.delayed(Duration.zero);

    expect(trade.beatCalls, 1);
    expect(beat.areas.map((dynamic a) => a.areaName), <String>[
      'Jinnah Road',
      'Prince Road',
    ]);
  });

  test('a licences screen opened afterwards starts warm and costs nothing', () {
    register();
    auth.officer.value = officerFixture;

    return Future<void>.delayed(Duration.zero).then((_) {
      // Built now, as the tab is first opened. The bazaars are on it before
      // anything is awaited — this is what the picker draws from on the first
      // frame.
      final TradeLicencesController licences = TradeLicencesController(
        tradeRepository: trade,
      );

      expect(licences.beat.value, isNotNull);
      expect(licences.hasAreaChoice, isTrue);
      expect(licences.hasData, isTrue);
      // The form the officer reaches from it is drawn from the same copy.
      expect(
        TradeCaptureController(tradeRepository: trade).beat.value,
        isNotNull,
      );
      expect(trade.beatCalls, 1);
    });
  });

  test('a pull is the one thing that re-reads them', () async {
    register();
    auth.officer.value = officerFixture;
    await Future<void>.delayed(Duration.zero);

    final TradeLicencesController licences = TradeLicencesController(
      tradeRepository: trade,
    );
    licences.onInit();
    await Future<void>.delayed(Duration.zero);
    expect(trade.beatCalls, 1, reason: 'opening the screen serves the cache');

    await licences.load();
    expect(trade.beatCalls, 2);
  });

  test('signing out throws them away', () async {
    register();
    auth.officer.value = officerFixture;
    await Future<void>.delayed(Duration.zero);

    auth.officer.value = null;
    await Future<void>.delayed(Duration.zero);

    // The next officer on this handset is posted to their own bazaars.
    expect(trade.cachedBeat, isNull);
    expect(beat.beat.value, isNull);
  });

  testWidgets('a warm screen opens on the bazaars, not on a spinner', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(400, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // What `TradeBeatController` has already done by the time the officer
    // reaches this tab. Awaited directly rather than through the session
    // watcher: a `Future.delayed` never fires under a widget test's clock.
    await trade.beat();

    Get.put<TradeLicencesController>(
      TradeLicencesController(tradeRepository: trade),
    );
    await tester.pumpWidget(const MaterialApp(home: TradeLicencesScreen()));
    // The very first frame, before any of the three queue calls have landed.
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(AppDropdown<int>), findsOneWidget);
    expect(find.text('All bazaars'), findsOneWidget);

    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  });
}
