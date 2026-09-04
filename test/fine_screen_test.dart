import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

import 'package:mcq_app/controllers/auth_controller.dart';
import 'package:mcq_app/controllers/dashboard_controller.dart';
import 'package:mcq_app/controllers/definitions_controller.dart';
import 'package:mcq_app/controllers/fine_controller.dart';
import 'package:mcq_app/data/repositories/auth_repository.dart';
import 'package:mcq_app/data/repositories/definitions_repository.dart';
import 'package:mcq_app/data/repositories/evidence_repository.dart';
import 'package:mcq_app/data/repositories/fine_repository.dart';
import 'package:mcq_app/models/evidence_upload.dart';
import 'package:mcq_app/models/fine.dart';
import 'package:mcq_app/models/fine_request.dart';
import 'package:mcq_app/views/magistrate/shared/create_fine_screen.dart';
import 'package:mcq_app/widgets/widgets.dart';

import 'support/api_stub.dart';
import 'support/dashboard_fixtures.dart';
import 'support/definitions_fixtures.dart';

/// The fine form on screen. Only what a still of the widget tree cannot show:
/// the area's suggestions, which open under the search box, close when one is
/// taken, and open again when the choice is cancelled.
void main() {
  setUp(() async {
    Get.reset();
    final StubbedApi api = StubbedApi();
    api.stub.reply(definitionsResponse);

    final AuthController auth = AuthController(
      authRepository: ApiAuthRepository(api: api.service, storage: api.storage),
    );
    Get.put<AuthController>(auth, permanent: true);

    final DefinitionsController definitions = DefinitionsController(
      definitionsRepository: ApiDefinitionsRepository(api: api.service),
      authController: auth,
    );
    await definitions.load();
    Get.put<DefinitionsController>(definitions, permanent: true);

    final DashboardController dashboard = DashboardController(
      dashboardRepository: FakeDashboardRepository(),
      defaultersRepository: FakeDefaultersRepository(),
      authController: auth,
    );
    dashboard.beat.value = beatFixture;
    Get.put<DashboardController>(dashboard, permanent: true);

    Get.put<FineRepository>(_FakeFineRepository(), permanent: true);
    Get.put<EvidenceRepository>(_FakeEvidenceRepository(), permanent: true);
  });

  tearDown(Get.reset);

  Future<FineController> pumpForm(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(400, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: CreateFineScreen()));
    await tester.pumpAndSettle();
    return Get.find<FineController>();
  }

  testWidgets('the areas are offered under the search box', (
    WidgetTester tester,
  ) async {
    final FineController controller = await pumpForm(tester);

    // Nothing is offered until the box is asked: the form is not a list of
    // areas with a form under it.
    expect(find.text('Jinnah Road'), findsNothing);

    await tester.tap(find.byType(AppSearchField));
    await tester.pumpAndSettle();

    // The whole beat, under the box.
    expect(find.text('Jinnah Road'), findsOneWidget);
    expect(find.text('Prince Road'), findsOneWidget);

    await tester.enterText(find.byType(AppSearchField), 'prince');
    await tester.pumpAndSettle();
    expect(find.text('Jinnah Road'), findsNothing);
    expect(find.text('Prince Road'), findsOneWidget);

    await tester.tap(find.text('Prince Road'));
    await tester.pumpAndSettle();

    // Taken: it is on the request, the suggestions closed behind it, and the
    // box stayed — emptied, not hidden.
    expect(controller.targetAreaId, 2);
    expect(find.byType(AppSearchField), findsOneWidget);
    expect(controller.areaSearchController.text, isEmpty);
    expect(find.text('Jinnah Road'), findsNothing);
    // Its own tile, with what the beat knows about it.
    expect(find.text('Zone 1 - Zarghoon'), findsOneWidget);
    expect(find.text('Area 2'), findsOneWidget);
  });

  testWidgets('cancelling the area puts the officer back in the box', (
    WidgetTester tester,
  ) async {
    final FineController controller = await pumpForm(tester);

    await tester.tap(find.byType(AppSearchField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prince Road'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(controller.targetAreaId, isNull);
    // Focused again, so the next area is one tap away: the suggestions are
    // open without the officer touching the box.
    expect(find.text('Jinnah Road'), findsOneWidget);
    expect(find.text('Area 2'), findsNothing);
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
    'id': 1,
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
