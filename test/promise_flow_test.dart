import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:go_router/go_router.dart';

import 'package:mcq_app/config/routes/app_routes.dart';
import 'package:mcq_app/controllers/auth_controller.dart';
import 'package:mcq_app/controllers/definitions_controller.dart';
import 'package:mcq_app/controllers/record_action_controller.dart';
import 'package:mcq_app/core/network/api_exception.dart';
import 'package:mcq_app/data/repositories/auth_repository.dart';
import 'package:mcq_app/data/repositories/enforcement_case_repository.dart';
import 'package:mcq_app/data/repositories/person_repository.dart';
import 'package:mcq_app/data/repositories/reporting_repository.dart';
import 'package:mcq_app/models/enforcement_action_request.dart';
import 'package:mcq_app/models/enforcement_case.dart';
import 'package:mcq_app/views/magistrate/shared/create_case_screen.dart';
import 'package:mcq_app/views/magistrate/shared/record_action_screen.dart';
import 'package:mcq_app/views/magistrate/shared/widgets/action_recorded_sheet.dart';
import 'package:mcq_app/views/magistrate/shared/widgets/case_card.dart';
import 'package:mcq_app/widgets/widgets.dart';

import 'support/api_stub.dart';
import 'support/dashboard_fixtures.dart';
import 'support/definitions_fixtures.dart';
import 'support/person_fixtures.dart';
import 'support/property_profile_fixtures.dart';

/// Taking a promise to pay, end to end:
/// `POST enforcement/cases/{case}/actions` with `action_type`
/// `payment_promised` and the day the shopkeeper named.
void main() {
  late FakeEnforcementCaseRepository caseRepository;

  const ApiException refused = ApiException(
    message: 'This case is with another magistrate.',
    failure: ApiFailure.server,
  );

  /// The cases on the fixture shop, which the profile would arrive with.
  List<EnforcementCase> propertyCases() => casesPageOneJson
      .map(EnforcementCase.fromJson)
      .where((EnforcementCase file) => file.property?.id == fixturePropertyId)
      .toList();

  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  /// The form over a real router, since it pushes the case form over itself
  /// and pops the new file back through it.
  Future<void> pumpPromise(
    WidgetTester tester, {
    List<EnforcementCase>? cases,
    int? caseId,
    String actionCode = 'payment_promised',
  }) async {
    tester.view
      ..physicalSize = const Size(500, 2200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: AppRoutes.recordActionPath(
            propertyId: fixturePropertyId,
            actionCode: actionCode,
            caseId: caseId,
          ),
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.recordAction,
              builder: (BuildContext context, GoRouterState state) =>
                  RecordActionScreen(
                    propertyId: fixturePropertyId,
                    actionCode: actionCode,
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

  /// The day the shopkeeper named. A tap on the field opens the platform
  /// picker; what it hands back lands here, which is the part worth testing.
  Future<void> promiseDay(WidgetTester tester, DateTime day) async {
    Get.find<RecordActionController>().setPromisedPaymentDate(day);
    await settle(tester);
  }

  Future<void> writeRemarks(
    WidgetTester tester, [
    String remarks = 'Said he would pay after the wedding season.',
  ]) async {
    // The last on the form: the date fields above are `AppDateField`, each
    // wrapping an `AppTextField` of its own.
    await tester.enterText(find.byType(AppTextField).last, remarks);
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

  testWidgets('posts the promise against the chosen case, as the API spells '
      'it', (WidgetTester tester) async {
    final List<EnforcementCase> cases = propertyCases();
    await pumpPromise(tester, cases: cases, caseId: cases.first.id);

    await promiseDay(tester, DateTime(2026, 9, 19));
    await writeRemarks(tester);
    await press(tester, 'Take promise to pay');

    expect(caseRepository.actionedCases, <int>[cases.first.id!]);

    final EnforcementActionRequest sent = caseRepository.actionedWith.single;
    final Map<String, dynamic> body = sent.toJson();

    expect(body['action_type'], 'payment_promised');
    expect(body['promised_payment_date'], '2026-09-19');
    expect(body['remarks'], 'Said he would pay after the wedding season.');
    // Date-only, in the officer's own day rather than shifted into UTC.
    expect(body['action_date'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    // The idempotency key, in the shape the API accepts.
    expect(body['client_action_uuid'], matches(RegExp(r'^[A-Za-z0-9_\-]{8,64}$')));
    // Not a step that carries one, so it is not claimed.
    expect(body['next_visit_date'], isNull);
  });

  testWidgets('reads the record back, with the day they were held to', (
    WidgetTester tester,
  ) async {
    final List<EnforcementCase> cases = propertyCases();
    await pumpPromise(tester, cases: cases, caseId: cases.first.id);

    await promiseDay(tester, DateTime(2026, 9, 19));
    await press(tester, 'Take promise to pay');

    expect(find.byType(ActionRecordedSheet), findsOneWidget);
    expect(find.textContaining('19 Sep 2026'), findsWidgets);
  });

  testWidgets('will not send a promise with no day on it', (
    WidgetTester tester,
  ) async {
    final List<EnforcementCase> cases = propertyCases();
    await pumpPromise(tester, cases: cases, caseId: cases.first.id);

    await writeRemarks(tester);

    // The whole point of the record is the date, so the button says what is
    // missing rather than failing at a shop counter.
    expect(
      find.textContaining('the day they promised to pay'),
      findsOneWidget,
    );
    final AppButton button = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Take promise to pay'),
    );
    expect(button.onPressed, isNull);
    expect(caseRepository.actionedWith, isEmpty);
  });

  testWidgets('a retry resends the same record rather than a second promise', (
    WidgetTester tester,
  ) async {
    final List<EnforcementCase> cases = propertyCases();
    caseRepository.actionFailure = refused;
    await pumpPromise(tester, cases: cases, caseId: cases.first.id);

    await promiseDay(tester, DateTime(2026, 9, 19));
    await press(tester, 'Take promise to pay');
    expect(find.text(refused.message), findsOneWidget);

    caseRepository.actionFailure = null;
    await press(tester, 'Send it again');

    expect(caseRepository.actionedWith, hasLength(2));
    // The same uuid both times: the server reads the resend as the record it
    // already has, not as a second visit to the shop.
    expect(
      caseRepository.actionedWith.first.clientActionUuid,
      caseRepository.actionedWith.last.clientActionUuid,
    );
  });

  testWidgets('editing after a refusal sends a new record', (
    WidgetTester tester,
  ) async {
    final List<EnforcementCase> cases = propertyCases();
    caseRepository.actionFailure = refused;
    await pumpPromise(tester, cases: cases, caseId: cases.first.id);

    await promiseDay(tester, DateTime(2026, 9, 19));
    await press(tester, 'Take promise to pay');

    // A different day is a different promise, so it may not land under the
    // key the refused one carried.
    caseRepository.actionFailure = null;
    await promiseDay(tester, DateTime(2026, 9, 25));
    await press(tester, 'Send it again');

    expect(
      caseRepository.actionedWith.first.clientActionUuid,
      isNot(caseRepository.actionedWith.last.clientActionUuid),
    );
    expect(caseRepository.actionedWith.last.toJson()['promised_payment_date'],
        '2026-09-25');
  });

  testWidgets('the register decides which date the form asks for', (
    WidgetTester tester,
  ) async {
    final List<EnforcementCase> cases = propertyCases();
    // `site_visit` is published carrying neither date, so the form asks for
    // the day of the visit and nothing else — and the button is live at once.
    await pumpPromise(
      tester,
      cases: cases,
      caseId: cases.first.id,
      actionCode: 'site_visit',
    );

    expect(find.text('The day they will pay'), findsNothing);
    expect(find.text('The day you called'), findsOneWidget);

    await press(tester, 'Record a visit');
    expect(
      caseRepository.actionedWith.single.toJson()['promised_payment_date'],
      isNull,
    );
  });

  testWidgets('a shop with no case opens one and records against it', (
    WidgetTester tester,
  ) async {
    await pumpPromise(tester, cases: <EnforcementCase>[]);

    expect(
      find.text('No case has been opened on this shop yet'),
      findsOneWidget,
    );
    expect(Get.find<RecordActionController>().selectedCaseId.value, isNull);

    await press(tester, 'Open a new case');
    expect(find.byType(CreateCaseScreen), findsOneWidget);
  });

  testWidgets('takes the cases it was handed rather than reading them again', (
    WidgetTester tester,
  ) async {
    await pumpPromise(tester, cases: propertyCases());

    expect(find.byType(CaseCard), findsWidgets);
    expect(caseRepository.pagesRequested, isEmpty);
  });
}
