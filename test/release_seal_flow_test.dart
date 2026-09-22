import 'package:dio/dio.dart' show ProgressCallback;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:go_router/go_router.dart';

import 'package:mcq_app/config/routes/app_routes.dart';
import 'package:mcq_app/controllers/auth_controller.dart';
import 'package:mcq_app/controllers/definitions_controller.dart';
import 'package:mcq_app/controllers/release_seal_controller.dart';
import 'package:mcq_app/core/network/api_exception.dart';
import 'package:mcq_app/data/repositories/auth_repository.dart';
import 'package:mcq_app/data/repositories/dashboard_repository.dart';
import 'package:mcq_app/data/repositories/defaulters_repository.dart';
import 'package:mcq_app/data/repositories/definitions_repository.dart';
import 'package:mcq_app/data/repositories/enforcement_case_repository.dart';
import 'package:mcq_app/data/repositories/evidence_repository.dart';
import 'package:mcq_app/data/repositories/field_seal_repository.dart';
import 'package:mcq_app/data/repositories/person_repository.dart';
import 'package:mcq_app/data/repositories/reporting_repository.dart';
import 'package:mcq_app/models/evidence_upload.dart';
import 'package:mcq_app/models/field_seal.dart';
import 'package:mcq_app/views/magistrate/property/property_profile_screen.dart';
import 'package:mcq_app/views/magistrate/shared/release_seal_screen.dart';
import 'package:mcq_app/views/magistrate/shared/widgets/seal_released_sheet.dart';
import 'package:mcq_app/views/magistrate/shared/widgets/seal_tile.dart';
import 'package:mcq_app/widgets/widgets.dart';

import 'support/api_stub.dart';
import 'support/dashboard_fixtures.dart';
import 'support/definitions_fixtures.dart';
import 'support/person_fixtures.dart';
import 'support/property_profile_fixtures.dart';
import 'support/seal_fixtures.dart';

/// Taking a seal off, end to end: the row on the Take Action sheet, the form
/// it opens, and `POST enforcement/field/seals/{seal}/release`.
///
/// The release hangs off the seal's own id, which a shop's profile does not
/// carry — so the assertions that matter are that the form finds the unit's
/// seal at all, and that a seal MCQ has not cleared cannot come off without
/// the override the server insists on.
void main() {
  late FakeFieldSealRepository seals;

  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  void sizeTo(WidgetTester tester, {double height = 4000}) {
    tester.view
      ..physicalSize = Size(460, height)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// The register with the seal rows on it. The shared fixture publishes
  /// neither, and the Take Action sheet refuses a step MCQ has not published.
  Map<String, dynamic> registerWithSealRows() {
    final Map<String, dynamic> data = definitionsData();
    data['action_types'] = <Map<String, dynamic>>[
      ...(data['action_types']! as List<dynamic>).cast<Map<String, dynamic>>(),
      <String, dynamic>{
        'code': 'seal',
        'name': 'Sealed',
        'fields': <String, dynamic>{'seal_no': true},
      },
      <String, dynamic>{
        'code': 'unseal',
        'name': 'Seal released',
        'fields': <String, dynamic>{'seal_no': true},
      },
    ];
    return <String, dynamic>{'data': data};
  }

  /// The shop's profile and the form pushed over it, on real paths so
  /// `AppRoutes.releaseSealPath` resolves.
  GoRouter router() => GoRouter(
    initialLocation: '/shop',
    routes: <RouteBase>[
      GoRoute(
        path: '/shop',
        builder: (BuildContext context, GoRouterState state) =>
            const PropertyProfileScreen(propertyId: fixturePropertyId),
      ),
      GoRoute(
        path: AppRoutes.releaseSeal,
        builder: (BuildContext context, GoRouterState state) =>
            ReleaseSealScreen(
              propertyId: int.parse(
                state.uri.queryParameters['property'] ?? '0',
              ),
              sealId: int.tryParse(state.uri.queryParameters['seal'] ?? ''),
            ),
      ),
    ],
  );

  Future<void> pumpForm(WidgetTester tester) async {
    sizeTo(tester);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: AppRoutes.releaseSealPath(
            propertyId: fixturePropertyId,
          ),
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.releaseSeal,
              builder: (BuildContext context, GoRouterState state) =>
                  const ReleaseSealScreen(propertyId: fixturePropertyId),
            ),
          ],
        ),
      ),
    );
    await settle(tester);
  }

  /// Swaps the seal register a test runs against.
  ///
  /// Deleted first: `Get.put` is put-if-absent, so putting a second fake over
  /// the one `setUp` registered would leave the first in place and the test
  /// asserting against a register it never set.
  void useSeals({
    required List<FieldSeal> all,
    List<FieldSeal> ready = const <FieldSeal>[],
  }) {
    Get.delete<FieldSealRepository>(force: true);
    seals = FakeFieldSealRepository(seals: all, ready: ready);
    Get.put<FieldSealRepository>(seals, permanent: true);
  }

  Future<void> writeReason(
    WidgetTester tester, [
    String reason = 'Fine paid in full, receipt MCQ-RC-2627-00123.',
  ]) async {
    await tester.enterText(find.byType(AppTextField).first, reason);
    await settle(tester);
  }

  setUp(() async {
    Get.reset();
    final StubbedApi api = StubbedApi();
    api.stub.reply(registerWithSealRows());

    final AuthController auth = AuthController(
      authRepository: ApiAuthRepository(api: api.service, storage: api.storage),
    );
    Get.put<AuthController>(auth, permanent: true);
    auth.officer.value = officerFixture;

    final DefinitionsController definitions = DefinitionsController(
      definitionsRepository: ApiDefinitionsRepository(api: api.service),
      authController: auth,
    );
    await definitions.load();
    Get.put<DefinitionsController>(definitions, permanent: true);

    // The shop stands sealed, so the sheet offers a release rather than a
    // seal — the two are never both on it.
    seals = FakeFieldSealRepository(
      seals: <FieldSeal>[sealOnProperty(fixturePropertyId)],
      ready: <FieldSeal>[],
    );
    Get.put<FieldSealRepository>(seals, permanent: true);
    Get.put<ReportingRepository>(
      FakeReportingRepository(profile: sealedPropertyProfileFixture),
      permanent: true,
    );
    Get.put<EnforcementCaseRepository>(
      FakeEnforcementCaseRepository(),
      permanent: true,
    );
    Get.put<DefaultersRepository>(FakeDefaultersRepository(), permanent: true);
    Get.put<DashboardRepository>(FakeDashboardRepository(), permanent: true);
    Get.put<PersonRepository>(FakePersonRepository(), permanent: true);
    Get.put<EvidenceRepository>(_FakeEvidenceRepository(), permanent: true);
  });

  tearDown(Get.reset);

  testWidgets('the sheet’s unseal row opens the release form', (
    WidgetTester tester,
  ) async {
    sizeTo(tester, height: 6000);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router()));
    await settle(tester);

    await tester.tap(find.byType(AppExtendedFab));
    await settle(tester);
    // The rows are held back before they stagger, on a plain `Timer`.
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);

    // A sealed shop is offered the release, never the seal.
    expect(find.text('Seal the shop'), findsNothing);
    await tester.tap(find.text('Unseal the shop'));
    await settle(tester);

    expect(find.byType(ReleaseSealScreen), findsOneWidget);
  });

  testWidgets('finds the unit’s own seal out of the officer’s list', (
    WidgetTester tester,
  ) async {
    // A seal on somebody else's shop rides along in the same list.
    useSeals(
      all: <FieldSeal>[
        sealStillOwing,
        sealOnProperty(fixturePropertyId, id: 88),
      ],
    );

    await pumpForm(tester);

    expect(find.byType(SealTile), findsOneWidget);
    expect(Get.find<ReleaseSealController>().selectedSealId.value, 88);
  });

  testWidgets('a seal MCQ has cleared comes off with a reason alone', (
    WidgetTester tester,
  ) async {
    final FieldSeal cleared = sealOnProperty(fixturePropertyId, id: 88);
    // The queue is the server's own answer to which seals are clear.
    useSeals(all: <FieldSeal>[cleared], ready: <FieldSeal>[cleared]);

    await pumpForm(tester);
    expect(find.text('Why open it before MCQ has cleared it'), findsNothing);

    await writeReason(tester);
    await tester.tap(find.widgetWithText(AppButton, 'Unseal the shop'));
    await settle(tester);

    expect(seals.releasedSeals, <int>[88]);
    final Map<String, dynamic> body = seals.releasedWith.single.toJson();
    expect(body['unseal_reason'], 'Fine paid in full, receipt MCQ-RC-2627-00123.');
    // Nothing to justify, so nothing is claimed.
    expect(body['override_reason'], isNull);
    expect(body['unsealed_on'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    expect(body['client_action_uuid'], isNotEmpty);

    expect(find.byType(SealReleasedSheet), findsOneWidget);
  });

  testWidgets('one MCQ has not cleared will not come off without the override', (
    WidgetTester tester,
  ) async {
    await pumpForm(tester);

    // The shop still owes, so the server has not cleared it — said where the
    // seal was chosen, and asked for under the reason.
    expect(
      find.textContaining('MCQ has not cleared this seal'),
      findsWidgets,
    );

    await writeReason(tester);
    expect(
      find.textContaining('why it is coming off before MCQ cleared it'),
      findsOneWidget,
    );
    final AppButton button = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Unseal the shop'),
    );
    expect(button.onPressed, isNull);
    expect(seals.releasedWith, isEmpty);
  });

  testWidgets('the override travels once it is given', (
    WidgetTester tester,
  ) async {
    await pumpForm(tester);
    await writeReason(tester);

    await tester.enterText(
      find.byType(AppTextField).at(1),
      'Deputy Commissioner’s order of 12 Sep 2026 to reopen pending appeal.',
    );
    await settle(tester);
    await tester.tap(find.widgetWithText(AppButton, 'Unseal the shop'));
    await settle(tester);

    final Map<String, dynamic> body = seals.releasedWith.single.toJson();
    expect(
      body['override_reason'],
      'Deputy Commissioner’s order of 12 Sep 2026 to reopen pending appeal.',
    );
  });

  testWidgets('a refused release is said, and the same request goes again', (
    WidgetTester tester,
  ) async {
    const ApiException refused = ApiException(
      message: 'This seal is with another magistrate.',
      failure: ApiFailure.server,
    );
    final FieldSeal cleared = sealOnProperty(fixturePropertyId, id: 88);
    useSeals(all: <FieldSeal>[cleared], ready: <FieldSeal>[cleared]);
    seals.releaseFailure = refused;

    await pumpForm(tester);
    await writeReason(tester);
    await tester.tap(find.widgetWithText(AppButton, 'Unseal the shop'));
    await settle(tester);

    expect(find.text(refused.message), findsOneWidget);

    seals.releaseFailure = null;
    await tester.tap(find.widgetWithText(AppButton, 'Send it again'));
    await settle(tester);

    expect(seals.releasedWith, hasLength(2));
    // The same uuid both times: the server reads the resend as the release it
    // already has, not as a second one.
    expect(
      seals.releasedWith.first.clientActionUuid,
      seals.releasedWith.last.clientActionUuid,
    );
  });

  testWidgets('a shop MCQ holds no seal on says so rather than emptying', (
    WidgetTester tester,
  ) async {
    useSeals(all: <FieldSeal>[sealStillOwing]);

    await pumpForm(tester);

    expect(find.byType(SealTile), findsNothing);
    expect(find.textContaining('MCQ holds no seal on this shop'), findsOneWidget);
    expect(seals.releasedWith, isEmpty);
  });
}

class _FakeEvidenceRepository implements EvidenceRepository {
  @override
  Future<EvidenceUpload> upload({
    required String filePath,
    String kind = EvidenceRepository.kindPhoto,
    String? mimeType,
    ProgressCallback? onProgress,
  }) async => const EvidenceUpload(path: 'evidence/seals/shutter.jpg');
}
