import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:go_router/go_router.dart';

import 'package:mcq_app/config/routes/app_routes.dart';
import 'package:mcq_app/controllers/auth_controller.dart';
import 'package:mcq_app/controllers/challans_controller.dart';
import 'package:mcq_app/controllers/dashboard_controller.dart';
import 'package:mcq_app/controllers/definitions_controller.dart';
import 'package:mcq_app/controllers/fine_controller.dart';
import 'package:mcq_app/controllers/trade_capture_controller.dart';
import 'package:mcq_app/controllers/trade_licences_controller.dart';
import 'package:mcq_app/data/repositories/auth_repository.dart';
import 'package:mcq_app/data/repositories/challan_repository.dart';
import 'package:mcq_app/data/repositories/definitions_repository.dart';
import 'package:mcq_app/data/repositories/enforcement_case_repository.dart';
import 'package:mcq_app/data/repositories/evidence_repository.dart';
import 'package:mcq_app/data/repositories/fine_repository.dart';
import 'package:mcq_app/data/repositories/person_repository.dart';
import 'package:mcq_app/data/repositories/reporting_repository.dart';
import 'package:mcq_app/data/repositories/trade_repository.dart';
import 'package:mcq_app/models/evidence_upload.dart';
import 'package:mcq_app/models/fine.dart';
import 'package:mcq_app/models/fine_request.dart';
import 'package:mcq_app/views/magistrate/property/property_profile_screen.dart';
import 'package:mcq_app/views/magistrate/shared/create_fine_screen.dart';
import 'package:mcq_app/views/magistrate/trade/trade_capture_screen.dart';
import 'package:mcq_app/views/magistrate/trade/trade_licences_screen.dart';
import 'package:mcq_app/views/magistrate/trade/widgets/capture_tile.dart';
import 'package:mcq_app/widgets/widgets.dart';

import 'support/api_stub.dart';
import 'support/challan_fixtures.dart';
import 'support/dashboard_fixtures.dart';
import 'support/definitions_fixtures.dart';
import 'support/person_fixtures.dart';
import 'support/property_profile_fixtures.dart';
import 'support/trade_fixtures.dart';

/// What a write leaves behind it. A form that posts something is pushed over
/// the list it changes, so the list has to be told — otherwise an officer pops
/// back to a screen that still shows the world as it was before they wrote to
/// it, and writes the same fine or the same capture again.
void main() {
  /// Settles the frame *and* the entrance animations, which `flutter_animate`
  /// schedules on a plain `Timer` that `pumpAndSettle` does not advance.
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  void sizeTo(WidgetTester tester, {double height = 3000, double width = 420}) {
    tester.view
      ..physicalSize = Size(width, height)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// Closes the receipt the form shows before it pops.
  Future<void> tapDone(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(AppButton, 'Done'));
    await settle(tester);
  }

  setUp(Get.reset);
  tearDown(Get.reset);

  group('a fine', () {
    late FakeReportingRepository reporting;
    late FakeChallanRepository challans;

    /// The two screens a fine is written between: a shop's profile, and the
    /// form pushed over it. Real paths, so `AppRoutes.createFinePath` resolves.
    GoRouter router() => GoRouter(
      initialLocation: '/shop',
      routes: <RouteBase>[
        GoRoute(
          path: '/shop',
          builder: (BuildContext context, GoRouterState state) =>
              const PropertyProfileScreen(propertyId: fixturePropertyId),
        ),
        GoRoute(
          path: AppRoutes.createFine,
          builder: (BuildContext context, GoRouterState state) =>
              CreateFineScreen(
                propertyId: int.tryParse(
                  state.uri.queryParameters['property'] ?? '',
                ),
              ),
        ),
      ],
    );

    setUp(() async {
      final StubbedApi api = StubbedApi();
      api.stub.reply(definitionsResponse);

      final AuthController auth = AuthController(
        authRepository: ApiAuthRepository(
          api: api.service,
          storage: api.storage,
        ),
      );
      Get.put<AuthController>(auth, permanent: true);

      final DefinitionsController definitions = DefinitionsController(
        definitionsRepository: ApiDefinitionsRepository(api: api.service),
        authController: auth,
      );
      await definitions.load();
      Get.put<DefinitionsController>(definitions, permanent: true);

      // The beat is where the fine's area comes from: the profile fixture
      // names the bazaar without an id, and this is what the name is matched
      // against.
      final DashboardController dashboard = DashboardController(
        dashboardRepository: FakeDashboardRepository(),
        defaultersRepository: FakeDefaultersRepository(),
        authController: auth,
      );
      dashboard.beat.value = beatFixture;
      Get.put<DashboardController>(dashboard, permanent: true);

      reporting = FakeReportingRepository();
      challans = FakeChallanRepository();
      Get.put<ReportingRepository>(reporting, permanent: true);
      Get.put<EnforcementCaseRepository>(
        FakeEnforcementCaseRepository(),
        permanent: true,
      );
      Get.put<FineRepository>(_FakeFineRepository(), permanent: true);
      Get.put<EvidenceRepository>(_FakeEvidenceRepository(), permanent: true);
      Get.put<PersonRepository>(FakePersonRepository(), permanent: true);
      Get.put<ChallanRepository>(challans, permanent: true);
    });

    /// Writes a fine from the shop's own profile, the way an officer does:
    /// the floating button, the offence, the send, and the receipt closed.
    Future<void> imposeFromProfile(WidgetTester tester) async {
      sizeTo(tester, height: 6000);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router()));
      await settle(tester);

      await tester.tap(find.byType(AppFab));
      await settle(tester);

      // The offence prefills the amount and the provision off the register,
      // which is everything else the form insists on.
      final FineController fine = Get.find<FineController>();
      fine.chooseFineType(fine.fineTypes.first);
      await settle(tester);

      await tester.tap(find.widgetWithText(AppButton, 'Impose a fine'));
      await settle(tester);
      await tapDone(tester);
    }

    testWidgets('re-reads the shop it was imposed on', (
      WidgetTester tester,
    ) async {
      // The Challans tab has been opened, so its list is on screen behind
      // this and has to be told as well.
      Get.put<ChallansController>(
        ChallansController(challanRepository: challans),
      );
      await settle(tester);
      final int challansBefore = challans.calls;

      await imposeFromProfile(tester);

      // Two profile reads before the write — the screen's own and the form's,
      // which fetches the shop behind a route that carried only an id — and a
      // third because the fine landed on this shop's bills.
      expect(reporting.profileCalls, 3);
      expect(challans.calls, challansBefore + 1);
      expect(find.byType(AppFab), findsOneWidget);
    });

    testWidgets('leaves the shop alone when the form is abandoned', (
      WidgetTester tester,
    ) async {
      Get.put<ChallansController>(
        ChallansController(challanRepository: challans),
      );
      await settle(tester);
      final int challansBefore = challans.calls;

      sizeTo(tester, height: 6000);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router()));
      await settle(tester);

      await tester.tap(find.byType(AppFab));
      await settle(tester);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await settle(tester);

      // Nothing was written, so nothing is out of date: the form's own read of
      // the shop is the only call the trip cost.
      expect(reporting.profileCalls, 2);
      expect(challans.calls, challansBefore);
    });

    testWidgets('the challan list is left unbuilt until its tab is opened', (
      WidgetTester tester,
    ) async {
      await imposeFromProfile(tester);

      // A list nobody has looked at is not stale — it fetches when the tab is
      // first opened, and building it here would put a call on the wire for a
      // screen that is not on it.
      expect(Get.isRegistered<ChallansController>(), isFalse);
      expect(challans.calls, 0);
    });
  });

  group('a captured shop', () {
    late FakeTradeRepository trade;

    GoRouter router() => GoRouter(
      initialLocation: AppRoutes.magistrateTradeLicences,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.magistrateTradeLicences,
          builder: (BuildContext context, GoRouterState state) =>
              const TradeLicencesScreen(),
        ),
        GoRoute(
          path: AppRoutes.tradeCapture,
          builder: (BuildContext context, GoRouterState state) =>
              TradeCaptureScreen(
                searched: state.uri.queryParameters['q'],
                areaId: int.tryParse(
                  state.uri.queryParameters['area'] ?? '',
                ),
              ),
        ),
      ],
    );

    setUp(() {
      trade = FakeTradeRepository();
      Get.put<TradeRepository>(trade, permanent: true);
    });

    /// Everything the server insists on, filled the way the form does.
    void fill(TradeCaptureController capture) {
      capture
        ..cnicController.text = '5440112233445'
        ..applicantController.text = 'Abdul Karim'
        ..fatherController.text = 'Muhammad Yousaf'
        ..mobileController.text = '03001234567'
        ..businessController.text = 'Al Madina Naan Shop'
        ..addressController.text = 'Shop 14, Circular Road, Quetta';
      capture.chooseCategory(tradeTariffFixture.category(40)!);
    }

    testWidgets('turns up on the licences screen it was captured from', (
      WidgetTester tester,
    ) async {
      sizeTo(tester);
      final TradeLicencesController licences = Get.put<TradeLicencesController>(
        TradeLicencesController(tradeRepository: trade),
      );
      // A bazaar first, so the form arrives priced: the fee is quoted per
      // bazaar and the capture button carries the one being filtered by.
      licences.setArea(1);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router()));
      await settle(tester);

      final int capturesBefore = trade.pendingCalls;

      await tester.tap(find.byIcon(Icons.add_business_outlined));
      await settle(tester);

      final TradeCaptureController capture =
          Get.find<TradeCaptureController>();
      expect(capture.areaId.value, 1);
      fill(capture);
      await settle(tester);

      await tester.tap(find.widgetWithText(AppButton, 'Capture this shop'));
      await settle(tester);
      await tapDone(tester);

      // Back on the licences screen, on the queue the shop just joined, with
      // the officer's own captures read again.
      expect(trade.pendingCalls, capturesBefore + 1);
      expect(licences.queue.value, TradeQueue.captures);
      expect(find.byType(CaptureTile), findsWidgets);
    });

    testWidgets('an abandoned capture costs the queue nothing', (
      WidgetTester tester,
    ) async {
      sizeTo(tester);
      final TradeLicencesController licences = Get.put<TradeLicencesController>(
        TradeLicencesController(tradeRepository: trade),
      );
      licences.setArea(1);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router()));
      await settle(tester);

      final int capturesBefore = trade.pendingCalls;

      await tester.tap(find.byIcon(Icons.add_business_outlined));
      await settle(tester);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await settle(tester);

      expect(trade.pendingCalls, capturesBefore);
      expect(licences.queue.value, TradeQueue.expiring);
    });
  });
}

class _FakeFineRepository implements FineRepository {
  @override
  Future<Fine> impose({
    required int propertyId,
    required FineRequest request,
  }) async => _fine;

  @override
  Future<Fine> imposeInArea({required FineRequest request}) async => _fine;

  static final Fine _fine = Fine.fromJson(<String, dynamic>{
    'id': 9,
    'fine_no': 'MCQ-FN-2627-00009',
    'amounts': <String, dynamic>{'fine_amount': '3000.00'},
  });
}

class _FakeEvidenceRepository implements EvidenceRepository {
  @override
  Future<EvidenceUpload> upload({
    required String filePath,
    String kind = EvidenceRepository.kindPhoto,
    String? mimeType,
    ProgressCallback? onProgress,
  }) async => EvidenceUpload.fromJson(<String, dynamic>{'path': 'evidence/1'});
}
