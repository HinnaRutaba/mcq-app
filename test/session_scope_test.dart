import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mcq_app/app/session_scope.dart';
import 'package:mcq_app/controllers/auth_controller.dart';
import 'package:mcq_app/controllers/challans_controller.dart';
import 'package:mcq_app/controllers/dashboard_controller.dart';
import 'package:mcq_app/controllers/defaulters_controller.dart';
import 'package:mcq_app/controllers/trade_licences_controller.dart';
import 'package:mcq_app/data/repositories/auth_repository.dart';
import 'package:mcq_app/data/repositories/challan_repository.dart';
import 'package:mcq_app/data/repositories/dashboard_repository.dart';
import 'package:mcq_app/data/repositories/defaulters_repository.dart';
import 'package:mcq_app/data/repositories/trade_repository.dart';
import 'package:mcq_app/models/auth_user.dart';

import 'support/api_stub.dart';
import 'support/challan_fixtures.dart';
import 'support/dashboard_fixtures.dart';
import 'support/trade_fixtures.dart';

/// What the tab controllers do when the handset changes hands.
///
/// Each of them fetches once and then holds what it fetched, so a second
/// officer signing in on the same handset would otherwise read the first one's
/// beat, queues and bills until they thought to pull to refresh.
void main() {
  late StubbedApi api;
  late ApiStub adapter;
  late AuthController auth;
  late FakeDashboardRepository dashboard;
  late FakeDefaultersRepository defaulters;
  late FakeChallanRepository challans;
  late FakeTradeRepository trade;

  setUp(() {
    Get.reset();
    api = StubbedApi();
    adapter = api.stub;

    auth = AuthController(
      authRepository: ApiAuthRepository(api: api.service, storage: api.storage),
    );
    Get.put<AuthController>(auth, permanent: true);

    dashboard = FakeDashboardRepository();
    defaulters = FakeDefaultersRepository();
    challans = FakeChallanRepository();
    trade = FakeTradeRepository();
    Get.put<DashboardRepository>(dashboard, permanent: true);
    Get.put<DefaultersRepository>(defaulters, permanent: true);
    Get.put<ChallanRepository>(challans, permanent: true);
    Get.put<TradeRepository>(trade, permanent: true);

    // Registered the way `setupDependencies` does: lazily, and `fenix`, so a
    // dropped one is rebuilt when its tab next asks.
    Get.lazyPut<DashboardController>(DashboardController.new, fenix: true);
    Get.lazyPut<DefaultersController>(DefaultersController.new, fenix: true);
    Get.lazyPut<TradeLicencesController>(
      TradeLicencesController.new,
      fenix: true,
    );
    Get.lazyPut<ChallansController>(ChallansController.new, fenix: true);

    watchSessionScope();
  });

  tearDown(Get.reset);

  /// Signs an officer in the way the splash screen does — a stored token the
  /// server confirms.
  Future<void> signIn({String username = 'magistrate'}) async {
    api.keychain['mcq.auth.bearer_token'] = 'a-live-token';
    adapter.reply(sessionResponse(username: username));
    await auth.restoreSession();
  }

  Future<void> signOut() async {
    adapter.reply(<String, dynamic>{});
    await auth.signOut();
  }

  /// Opens every tab, and waits for the fetch each one starts in `onInit`.
  Future<void> openEveryTab() async {
    Get.find<DashboardController>();
    Get.find<DefaultersController>();
    Get.find<TradeLicencesController>();
    Get.find<ChallansController>();
    await pumpEventQueue();
  }

  group('an officer signs out and another signs in', () {
    test('every tab is rebuilt rather than handed on', () async {
      await signIn();
      await openEveryTab();
      final DashboardController home = Get.find<DashboardController>();
      final DefaultersController owed = Get.find<DefaultersController>();
      final TradeLicencesController licences =
          Get.find<TradeLicencesController>();
      final ChallansController bills = Get.find<ChallansController>();

      await signOut();
      await signIn(username: 'inspector');

      expect(Get.find<DashboardController>(), isNot(same(home)));
      expect(Get.find<DefaultersController>(), isNot(same(owed)));
      expect(Get.find<TradeLicencesController>(), isNot(same(licences)));
      expect(Get.find<ChallansController>(), isNot(same(bills)));
    });

    test('the figures are fetched again for whoever is signed in now', () async {
      await signIn();
      await openEveryTab();
      expect(defaulters.roundCalls, 1);
      expect(challans.calls, 1);

      await signOut();
      await signIn(username: 'inspector');
      await openEveryTab();

      expect(defaulters.roundCalls, 2, reason: 'Home is the last one\'s beat');
      expect(challans.calls, 2);
    });

    test('the last officer\'s filters and search box go with it', () async {
      await signIn();
      final DefaultersController owed = Get.find<DefaultersController>();
      await pumpEventQueue();
      owed.showState(DefaulterState.sealed);
      owed.searchController.text = 'Ahmed';
      expect(owed.isNarrowed, isTrue);

      await signOut();
      await signIn(username: 'inspector');
      final DefaultersController fresh = Get.find<DefaultersController>();

      expect(fresh.stateFilter.value, DefaulterState.everyone);
      expect(fresh.searchController.text, isEmpty);
      expect(fresh.isNarrowed, isFalse);
    });

    test('nothing goes on the wire until a tab asks', () async {
      await signIn();
      await openEveryTab();
      final int roundCalls = defaulters.roundCalls;
      final int challanCalls = challans.calls;

      await signOut();
      await pumpEventQueue();

      // Dropping them must not rebuild them: a fetch here would go out with no
      // bearer token behind it.
      expect(defaulters.roundCalls, roundCalls);
      expect(challans.calls, challanCalls);
    });
  });

  group('the same officer', () {
    test('keeps their tabs through a forced password change', () async {
      await signIn();
      await openEveryTab();
      final DashboardController home = Get.find<DashboardController>();

      // What `changePassword` does once the new password is in: the same
      // officer, on a new token.
      auth.officer.value = AuthUser.fromJson(
        userJson(username: 'magistrate'),
      );

      expect(Get.find<DashboardController>(), same(home));
      expect(defaulters.roundCalls, 1);
    });
  });
}

Map<String, dynamic> userJson({required String username}) => <String, dynamic>{
  'id': '5',
  'username': username,
  'name': 'Habibullah Tareen',
  'designation': 'Municipal Magistrate',
  'must_change_password': false,
  'is_active': true,
  'roles': <String>['MAGISTRATE'],
};

Map<String, dynamic> sessionResponse({required String username}) =>
    <String, dynamic>{
      'data': <String, dynamic>{
        'user': userJson(username: username),
        'token_expires_at': null,
      },
    };
