import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:go_router/go_router.dart';

import 'package:mcq_app/config/routes/app_routes.dart';
import 'package:mcq_app/controllers/auth_controller.dart';
import 'package:mcq_app/controllers/definitions_controller.dart';
import 'package:mcq_app/controllers/case_controller.dart';
import 'package:mcq_app/controllers/seal_controller.dart';
import 'package:mcq_app/core/network/api_exception.dart';
import 'package:mcq_app/data/repositories/auth_repository.dart';
import 'package:mcq_app/data/repositories/enforcement_case_repository.dart';
import 'package:mcq_app/data/repositories/person_repository.dart';
import 'package:mcq_app/data/repositories/reporting_repository.dart';
import 'package:mcq_app/data/mock/case_type_seed.dart';
import 'package:mcq_app/models/enforcement_case.dart';
import 'package:mcq_app/models/field_case_request.dart';
import 'package:mcq_app/models/seal_requests.dart';
import 'package:mcq_app/views/magistrate/shared/widgets/case_card.dart';
import 'package:mcq_app/views/magistrate/shared/create_case_screen.dart';
import 'package:mcq_app/views/magistrate/shared/create_seal_screen.dart';
import 'package:mcq_app/views/magistrate/shared/widgets/seal_applied_sheet.dart';
import 'package:mcq_app/widgets/widgets.dart';

import 'support/api_stub.dart';
import 'support/dashboard_fixtures.dart';
import 'support/definitions_fixtures.dart';
import 'support/person_fixtures.dart';
import 'support/property_profile_fixtures.dart';

/// Shutting a shop, end to end: which case the seal hangs on — one already
/// open, or one opened on the spot — and the write itself.
void main() {
  late FakeEnforcementCaseRepository caseRepository;

  const ApiException refused = ApiException(
    message: 'This case is with another magistrate.',
    failure: ApiFailure.server,
  );

  /// The live case on the fixture shop, which the profile would arrive with.
  List<EnforcementCase> propertyCases() => casesPageOneJson
      .map(EnforcementCase.fromJson)
      .where((EnforcementCase file) => file.property?.id == fixturePropertyId)
      .toList();

  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  /// The seal form over a real router, since it pushes the case form over
  /// itself and pops a seal back through it.
  Future<void> pumpSeal(
    WidgetTester tester, {
    List<EnforcementCase>? cases,
    int? caseId,
  }) async {
    tester.view
      ..physicalSize = const Size(500, 2200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: AppRoutes.createSealPath(
            propertyId: fixturePropertyId,
            caseId: caseId,
          ),
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.createSeal,
              builder: (BuildContext context, GoRouterState state) =>
                  CreateSealScreen(
                    propertyId: fixturePropertyId,
                    caseId: caseId,
                    cases: cases,
                  ),
            ),
            GoRoute(
              path: AppRoutes.createCase,
              builder: (BuildContext context, GoRouterState state) =>
                  CreateCaseScreen(propertyId: fixturePropertyId),
            ),
          ],
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> writeReason(
    WidgetTester tester, [
    String reason = 'Arrears unpaid after final notice.',
  ]) async {
    await tester.enterText(find.byType(AppTextField).first, reason);
    await settle(tester);
  }

  Future<void> press(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(AppButton, label));
    await settle(tester);
  }

  setUp(() {
    Get.reset();
    caseRepository = FakeEnforcementCaseRepository();

    final StubbedApi api = StubbedApi();
    final AuthController auth = AuthController(
      authRepository: ApiAuthRepository(api: api.service, storage: api.storage),
    );
    Get.put<AuthController>(auth, permanent: true);
    auth.officer.value = officerFixture;
    Get.put<DefinitionsController>(
      DefinitionsController(
        definitionsRepository: FakeDefinitionsRepository(),
        authController: auth,
      ),
      permanent: true,
    );

    Get.put<EnforcementCaseRepository>(caseRepository, permanent: true);
    Get.put<ReportingRepository>(FakeReportingRepository(), permanent: true);
    Get.put<PersonRepository>(FakePersonRepository(), permanent: true);
  });

  tearDown(Get.reset);

  testWidgets('takes the cases it was handed rather than reading them again', (
    WidgetTester tester,
  ) async {
    await pumpSeal(tester, cases: propertyCases());

    expect(find.byType(CaseCard), findsWidgets);
    // The shop's profile has already read four pages of them; asking again at
    // a shopfront is a wait for nothing.
    expect(caseRepository.pagesRequested, isEmpty);
  });

  testWidgets('a cold link with no cases reads the shop’s own', (
    WidgetTester tester,
  ) async {
    await pumpSeal(tester);

    expect(caseRepository.pagesRequested, isNotEmpty);
    expect(find.byType(CaseCard), findsWidgets);
  });

  testWidgets('seals the case the officer chose, with the reason and the day', (
    WidgetTester tester,
  ) async {
    final List<EnforcementCase> cases = propertyCases();
    await pumpSeal(tester, cases: cases, caseId: cases.first.id);

    await writeReason(tester);
    await press(tester, 'Seal the shop');

    expect(caseRepository.sealedCases, <int>[cases.first.id!]);
    final CaseSealRequest sent = caseRepository.sealedWith.single;
    expect(sent.sealReason, 'Arrears unpaid after final notice.');
    expect(sent.sealedOn, isNotNull);
    // The endpoint documents the day both ways round; both go.
    expect(sent.actionDate, sent.sealedOn);
    expect(sent.clientActionUuid, isNotEmpty);

    // The number is what goes on the physical seal, so it is read back.
    expect(find.byType(SealAppliedSheet), findsOneWidget);
    expect(find.text('MCQ-SL-2627-00088'), findsOneWidget);
  });

  testWidgets('opens a case on the spot and seals the file that came back', (
    WidgetTester tester,
  ) async {
    // A shop with nothing open on it: the officer has to make the case first,
    // which is the whole reason this screen asks the question.
    await pumpSeal(tester, cases: <EnforcementCase>[]);

    expect(
      find.text('No case has been opened on this shop yet'),
      findsOneWidget,
    );
    expect(Get.find<SealController>().selectedCaseId.value, isNull);

    await press(tester, 'Open a new case');
    expect(find.text('Open a case'), findsOneWidget);

    // The case form is a screen of its own with tests of its own; here it only
    // has to hand its file back, so it is filled through its controller.
    final CaseController form = Get.find<CaseController>();
    form.chooseCaseType(caseTypeSeed.first);
    form.reasonController.text = 'Trading outside the allotment.';
    form.offenderNameController.text = 'Muhammad Iqbal';
    form.offenderFatherController.text = 'Ghulam Rasool';
    form.offenderMobileController.text = '03001234511';
    await settle(tester);

    await press(tester, 'Open the case');
    // The opened file is read back before the officer is returned.
    await press(tester, 'Done');

    // Back on the seal form, with the new case adopted and chosen.
    final EnforcementCase opened = EnforcementCase.fromJson(openedCaseJson);
    expect(caseRepository.openedWith, isA<FieldCaseRequest>());
    expect(Get.find<SealController>().selectedCaseId.value, opened.id);

    await writeReason(tester);
    await press(tester, 'Seal the shop');

    expect(caseRepository.sealedCases, <int>[opened.id!]);
  });

  testWidgets('a reason too short to be a record is refused before sending', (
    WidgetTester tester,
  ) async {
    final List<EnforcementCase> cases = propertyCases();
    await pumpSeal(tester, cases: cases, caseId: cases.first.id);

    await writeReason(tester, 'no rent');
    await press(tester, 'Seal the shop');

    expect(caseRepository.sealedCases, isEmpty);
    expect(
      find.textContaining(
        'At least ${CaseSealRequest.reasonMinLength} characters',
      ),
      findsOneWidget,
    );
  });

  testWidgets('nothing may be sent until a case is chosen', (
    WidgetTester tester,
  ) async {
    await pumpSeal(tester, cases: <EnforcementCase>[]);

    await writeReason(tester);

    expect(
      find.textContaining('the case to seal against'),
      findsOneWidget,
      reason: 'the button says what it is still short of',
    );
    expect(
      tester
          .widget<AppButton>(find.widgetWithText(AppButton, 'Seal the shop'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('a refused seal is said, and the same request goes again', (
    WidgetTester tester,
  ) async {
    final List<EnforcementCase> cases = propertyCases();
    caseRepository.sealFailure = refused;
    await pumpSeal(tester, cases: cases, caseId: cases.first.id);

    await writeReason(tester);
    await press(tester, 'Seal the shop');

    expect(find.text(refused.message), findsWidgets);
    expect(find.byType(SealAppliedSheet), findsNothing);

    // Sent again untouched: the same idempotency key, so a seal that did land
    // on a dying signal is not applied twice.
    caseRepository.sealFailure = null;
    await press(tester, 'Send it again');

    expect(caseRepository.sealedWith, hasLength(2));
    expect(
      caseRepository.sealedWith.first.clientActionUuid,
      caseRepository.sealedWith.last.clientActionUuid,
    );
    expect(find.byType(SealAppliedSheet), findsOneWidget);
  });

  testWidgets('an edited reason is a different seal, and a new key', (
    WidgetTester tester,
  ) async {
    final List<EnforcementCase> cases = propertyCases();
    caseRepository.sealFailure = refused;
    await pumpSeal(tester, cases: cases, caseId: cases.first.id);

    await writeReason(tester);
    await press(tester, 'Seal the shop');

    caseRepository.sealFailure = null;
    await writeReason(tester, 'Seal broken and re-applied after a re-entry.');
    await press(tester, 'Send it again');

    expect(
      caseRepository.sealedWith.first.clientActionUuid,
      isNot(caseRepository.sealedWith.last.clientActionUuid),
    );
  });

  testWidgets('a case MCQ has not cleared is offered, with the warning', (
    WidgetTester tester,
  ) async {
    // `can_seal` is absent from a case the server has just opened, so refusing
    // to seal against one would strand the officer who just made it.
    final EnforcementCase fresh = EnforcementCase.fromJson(openedCaseJson);
    await pumpSeal(tester, cases: <EnforcementCase>[fresh], caseId: fresh.id);

    expect(fresh.canSeal, isFalse);
    expect(find.textContaining('has not cleared this case'), findsOneWidget);

    await writeReason(tester);
    await press(tester, 'Seal the shop');

    expect(caseRepository.sealedCases, <int>[fresh.id!]);
  });
}
