import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:go_router/go_router.dart';

import 'package:mcq_app/config/routes/app_routes.dart';
import 'package:mcq_app/controllers/auth_controller.dart';
import 'package:mcq_app/controllers/case_controller.dart';
import 'package:mcq_app/controllers/challans_controller.dart';
import 'package:mcq_app/controllers/dashboard_controller.dart';
import 'package:mcq_app/controllers/defaulters_controller.dart';
import 'package:mcq_app/controllers/definitions_controller.dart';
import 'package:mcq_app/controllers/fine_controller.dart';
import 'package:mcq_app/controllers/trade_capture_controller.dart';
import 'package:mcq_app/controllers/trade_licences_controller.dart';
import 'package:mcq_app/data/repositories/auth_repository.dart';
import 'package:mcq_app/data/repositories/challan_repository.dart';
import 'package:mcq_app/data/repositories/dashboard_repository.dart';
import 'package:mcq_app/data/repositories/defaulters_repository.dart';
import 'package:mcq_app/data/repositories/definitions_repository.dart';
import 'package:mcq_app/data/repositories/enforcement_case_repository.dart';
import 'package:mcq_app/data/repositories/evidence_repository.dart';
import 'package:mcq_app/data/repositories/fine_repository.dart';
import 'package:mcq_app/data/repositories/person_repository.dart';
import 'package:mcq_app/data/repositories/reporting_repository.dart';
import 'package:mcq_app/data/repositories/trade_repository.dart';
import 'package:mcq_app/models/evidence_upload.dart';
import 'package:mcq_app/models/enforcement_case.dart';
import 'package:mcq_app/models/fine.dart';
import 'package:mcq_app/models/fine_request.dart';
import 'package:mcq_app/views/magistrate/property/property_profile_screen.dart';
import 'package:mcq_app/views/magistrate/shared/widgets/case_card.dart';
import 'package:mcq_app/views/magistrate/shared/create_case_screen.dart';
import 'package:mcq_app/views/magistrate/shared/create_fine_screen.dart';
import 'package:mcq_app/views/magistrate/shared/create_seal_screen.dart';
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

    /// Opens the fine form the way an officer does from a shop: the Take
    /// Action button, then the fine off the register's own action list.
    Future<void> openFineForm(WidgetTester tester) async {
      await tester.tap(find.byType(AppExtendedFab));
      await settle(tester);
      // The rows are held back before they stagger, on a plain `Timer`.
      await tester.pump(const Duration(seconds: 1));
      await settle(tester);
      await tester.tap(find.text('Impose a fine'));
      await settle(tester);
    }

    /// Writes a fine from the shop's own profile, the way an officer does:
    /// the action sheet, the offence, the send, and the receipt closed.
    Future<void> imposeFromProfile(WidgetTester tester) async {
      sizeTo(tester, height: 6000);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router()));
      await settle(tester);

      await openFineForm(tester);

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
      expect(find.byType(AppExtendedFab), findsOneWidget);
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

      await openFineForm(tester);
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

  group('a case', () {
    late FakeReportingRepository reporting;
    late FakeEnforcementCaseRepository cases;
    late FakeDefaultersRepository defaulters;

    /// The two screens a case is opened between: a shop's profile, and the
    /// form pushed over it. Real paths, so `AppRoutes.createCasePath` resolves.
    GoRouter router() => GoRouter(
      initialLocation: '/shop',
      routes: <RouteBase>[
        GoRoute(
          path: '/shop',
          builder: (BuildContext context, GoRouterState state) =>
              const PropertyProfileScreen(propertyId: fixturePropertyId),
        ),
        GoRoute(
          path: AppRoutes.createCase,
          builder: (BuildContext context, GoRouterState state) =>
              CreateCaseScreen(
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

      reporting = FakeReportingRepository();
      cases = FakeEnforcementCaseRepository();
      defaulters = FakeDefaultersRepository();
      Get.put<ReportingRepository>(reporting, permanent: true);
      Get.put<EnforcementCaseRepository>(cases, permanent: true);
      Get.put<PersonRepository>(FakePersonRepository(), permanent: true);
      Get.put<DefaultersRepository>(defaulters, permanent: true);
      Get.put<DashboardRepository>(FakeDashboardRepository(), permanent: true);
    });

    testWidgets('re-reads the shop it was opened on', (
      WidgetTester tester,
    ) async {
      // The Defaulters tab has been opened, so its rows — which carry the
      // case badge — are behind this and have to be told as well.
      Get.put<DefaultersController>(DefaultersController());
      await settle(tester);
      final int defaultersBefore = defaulters.defaultersCalls;

      sizeTo(tester, height: 6000);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router()));
      await settle(tester);

      // The way an officer gets here: the Take Action button, then the case
      // off the sheet. The rows are held back before they stagger, on a plain
      // `Timer`.
      await tester.tap(find.byType(AppExtendedFab));
      await settle(tester);
      await tester.pump(const Duration(seconds: 1));
      await settle(tester);
      await tester.tap(find.text('Create new case'));
      await settle(tester);

      // The kind is chosen for the officer while there is one of it, so the
      // words are all the form is short of.
      final CaseController file = Get.find<CaseController>();
      file.reasonController.text =
          'Trading in goods the agreement does not permit.';
      // The profile names the holder; the rest of the block is typed.
      file.offenderFatherController.text = 'Ghulam Nabi';
      file.offenderMobileController.text = '03007654321';
      file.markEdited();
      await settle(tester);

      await tester.tap(find.widgetWithText(AppButton, 'Open the case'));
      await settle(tester);
      await tapDone(tester);

      // The unit travels as `property_id`, and a conduct case names no
      // tenancy.
      expect(cases.openedWith!.toJson()['property_id'], fixturePropertyId);
      expect(cases.openedWith!.toJson()['allotment_id'], isNull);
      expect(cases.openedWith!.toJson()['offender_name'], 'Muhammad Iqbal');
      // Two reads before the write — the screen's own and the form's, which
      // fetches the shop behind a route that carried only an id — and a third
      // because the case landed on this shop's enforcement block.
      expect(reporting.profileCalls, 3);
      expect(defaulters.defaultersCalls, defaultersBefore + 1);
      expect(find.byType(AppExtendedFab), findsOneWidget);
    });

    testWidgets('leaves the shop alone when the form is abandoned', (
      WidgetTester tester,
    ) async {
      sizeTo(tester, height: 6000);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router()));
      await settle(tester);

      await tester.tap(find.byType(AppExtendedFab));
      await settle(tester);
      await tester.pump(const Duration(seconds: 1));
      await settle(tester);
      await tester.tap(find.text('Create new case'));
      await settle(tester);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await settle(tester);

      expect(cases.openedWith, isNull);
      // Nothing was written, so nothing is out of date: the form's own read of
      // the shop is the only call the trip cost.
      expect(reporting.profileCalls, 2);
    });

    testWidgets('the defaulter list is left unbuilt until its tab is opened', (
      WidgetTester tester,
    ) async {
      sizeTo(tester, height: 6000);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router()));
      await settle(tester);

      await tester.tap(find.byType(AppExtendedFab));
      await settle(tester);
      await tester.pump(const Duration(seconds: 1));
      await settle(tester);
      await tester.tap(find.text('Create new case'));
      await settle(tester);

      final CaseController file = Get.find<CaseController>();
      file.reasonController.text = 'Sub-let to a tea stall.';
      file.offenderFatherController.text = 'Ghulam Nabi';
      file.offenderMobileController.text = '03007654321';
      file.markEdited();
      await settle(tester);
      await tester.tap(find.widgetWithText(AppButton, 'Open the case'));
      await settle(tester);
      await tapDone(tester);

      // A list nobody has looked at is not stale — it fetches when the tab is
      // first opened, and building it here would put a call on the wire for a
      // screen that is not on it.
      expect(Get.isRegistered<DefaultersController>(), isFalse);
      expect(defaulters.defaultersCalls, 0);
    });
  });

  group('a seal', () {
    late FakeReportingRepository reporting;
    late FakeEnforcementCaseRepository cases;
    late FakeDefaultersRepository defaulters;

    /// The two screens a seal is written between: a shop's profile, and the
    /// form pushed over it. Real paths, so `AppRoutes.createSealPath` resolves.
    GoRouter router() => GoRouter(
      initialLocation: '/shop',
      routes: <RouteBase>[
        GoRoute(
          path: '/shop',
          builder: (BuildContext context, GoRouterState state) =>
              const PropertyProfileScreen(propertyId: fixturePropertyId),
        ),
        GoRoute(
          path: AppRoutes.createSeal,
          builder: (BuildContext context, GoRouterState state) =>
              CreateSealScreen(
                propertyId: int.parse(
                  state.uri.queryParameters['property'] ?? '0',
                ),
                caseId: int.tryParse(state.uri.queryParameters['case'] ?? ''),
                cases: state.extra is List<EnforcementCase>
                    ? state.extra! as List<EnforcementCase>
                    : null,
              ),
        ),
      ],
    );

    /// The register with a seal row on it. The shared fixture publishes three
    /// action types and `seal` is not one of them — and the Take Action sheet
    /// refuses a step MCQ has not published, which is the whole reason this
    /// group carries its own register.
    Map<String, dynamic> registerWithSeal() {
      final Map<String, dynamic> data = definitionsData();
      data['action_types'] = <Map<String, dynamic>>[
        ...(data['action_types']! as List<dynamic>)
            .cast<Map<String, dynamic>>(),
        <String, dynamic>{
          'code': 'seal',
          'name': 'Sealed',
          'fields': <String, dynamic>{'seal_no': true},
        },
      ];
      return <String, dynamic>{'data': data};
    }

    setUp(() async {
      final StubbedApi api = StubbedApi();
      api.stub.reply(registerWithSeal());

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

      reporting = FakeReportingRepository();
      cases = FakeEnforcementCaseRepository();
      defaulters = FakeDefaultersRepository();
      Get.put<ReportingRepository>(reporting, permanent: true);
      Get.put<EnforcementCaseRepository>(cases, permanent: true);
      Get.put<PersonRepository>(FakePersonRepository(), permanent: true);
      Get.put<DefaultersRepository>(defaulters, permanent: true);
      Get.put<DashboardRepository>(FakeDashboardRepository(), permanent: true);
    });

    /// Opens the seal form the way an officer does: the Take Action button,
    /// then the seal off the sheet.
    Future<void> openSealForm(WidgetTester tester) async {
      await tester.tap(find.byType(AppExtendedFab));
      await settle(tester);
      // The rows are held back before they stagger, on a plain `Timer`.
      await tester.pump(const Duration(seconds: 1));
      await settle(tester);
      await tester.tap(find.text('Seal the shop'));
      await settle(tester);
    }

    testWidgets('re-reads the shop it was sealed on', (
      WidgetTester tester,
    ) async {
      // The Defaulters tab has been opened, so its rows — which carry the seal
      // badge — are behind this and have to be told as well.
      Get.put<DefaultersController>(DefaultersController());
      await settle(tester);
      final int defaultersBefore = defaulters.defaultersCalls;

      sizeTo(tester, height: 6000);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router()));
      await settle(tester);
      // Every page the profile read for itself, before the form is opened.
      final int pagesRead = cases.pagesRequested.length;

      await openSealForm(tester);

      // The shop's own cases came with it, so the form asks for none of them
      // again — and the live one is already chosen.
      expect(cases.pagesRequested.length, pagesRead);
      expect(find.byType(CaseCard), findsWidgets);

      await tester.enterText(
        find.byType(AppTextField).first,
        'Arrears unpaid after final notice.',
      );
      await settle(tester);
      await tester.tap(find.widgetWithText(AppButton, 'Seal the shop'));
      await settle(tester);
      await tapDone(tester);

      expect(cases.sealedCases, <int>[fixtureLiveCaseId]);
      expect(
        cases.sealedWith.single.sealReason,
        'Arrears unpaid after final notice.',
      );
      // Two profile reads before the write, and a third because the seal
      // landed on this shop's enforcement block.
      expect(reporting.profileCalls, 2);
      expect(defaulters.defaultersCalls, defaultersBefore + 1);
      expect(find.byType(AppExtendedFab), findsOneWidget);
    });

    testWidgets('leaves the shop alone when the form is abandoned', (
      WidgetTester tester,
    ) async {
      sizeTo(tester, height: 6000);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router()));
      await settle(tester);
      final int profileCallsBefore = reporting.profileCalls;

      await openSealForm(tester);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await settle(tester);

      expect(cases.sealedCases, isEmpty);
      expect(reporting.profileCalls, profileCallsBefore);
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
                areaId: int.tryParse(state.uri.queryParameters['area'] ?? ''),
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

      final TradeCaptureController capture = Get.find<TradeCaptureController>();
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
