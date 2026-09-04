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
import 'package:mcq_app/data/repositories/person_repository.dart';
import 'package:mcq_app/data/repositories/reporting_repository.dart';
import 'package:mcq_app/models/evidence_upload.dart';
import 'package:mcq_app/models/fine.dart';
import 'package:mcq_app/models/fine_request.dart';
import 'package:mcq_app/views/magistrate/shared/create_fine_screen.dart';
import 'package:mcq_app/widgets/widgets.dart';

import 'support/api_stub.dart';
import 'support/dashboard_fixtures.dart';
import 'support/definitions_fixtures.dart';
import 'support/person_fixtures.dart';
import 'support/property_profile_fixtures.dart';

/// The fine form on screen. Only what a still of the widget tree cannot show:
/// the area's suggestions, which open under the search box, close when one is
/// taken, and open again when the choice is cancelled.
void main() {
  late FakePersonRepository people;
  late StubbedApi api;
  late DefinitionsController definitions;

  setUp(() async {
    Get.reset();
    api = StubbedApi();
    api.stub.reply(definitionsResponse);

    final AuthController auth = AuthController(
      authRepository: ApiAuthRepository(api: api.service, storage: api.storage),
    );
    Get.put<AuthController>(auth, permanent: true);

    definitions = DefinitionsController(
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
    people = FakePersonRepository();
    Get.put<PersonRepository>(people, permanent: true);
    Get.put<ReportingRepository>(FakeReportingRepository(), permanent: true);
  });

  tearDown(Get.reset);

  Future<FineController> pumpForm(
    WidgetTester tester, {
    int? propertyId,
    int? allotmentId,
  }) async {
    tester.view
      ..physicalSize = const Size(400, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: CreateFineScreen(
          propertyId: propertyId,
          allotmentId: allotmentId,
        ),
      ),
    );
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
    expect(find.text('The fine will be posted here'), findsOneWidget);
    expect(find.text('Zone 1 - Zarghoon'), findsOneWidget);
  });

  testWidgets('a whole CNIC is looked up, and the answer fills who pays', (
    WidgetTester tester,
  ) async {
    final FineController controller = await pumpForm(tester);
    final Finder cnic = find.widgetWithText(AppTextField, "Offender's CNIC");

    // Half a CNIC is not a search: nothing goes on the wire until all
    // thirteen digits are there — and the field says so, rather than sitting
    // there looking broken.
    await tester.enterText(cnic, '544001000');
    await tester.pumpAndSettle();
    expect(people.searched, isEmpty);
    expect(find.text('Haji Abdul Rauf Kakar'), findsNothing);
    expect(
      find.text('4 more digits and the register is searched'),
      findsOneWidget,
    );

    await tester.enterText(cnic, '5440010000000');
    await tester.pumpAndSettle();

    expect(people.searched, <String>['5440010000000']);
    // Offered with what the register holds, and which register that is.
    expect(find.text('Haji Abdul Rauf Kakar'), findsOneWidget);
    expect(find.text('On the property register'), findsOneWidget);
    expect(find.text('S/O Abdul Ghafoor Kakar'), findsOneWidget);

    await tester.tap(find.text('Tap to fill in who pays'));
    await tester.pumpAndSettle();

    // Taken: the identity fields are filled in and the card has given way to
    // what it filled in.
    expect(controller.offenderNameController.text, 'Haji Abdul Rauf Kakar');
    expect(controller.offenderFatherController.text, 'Abdul Ghafoor Kakar');
    expect(controller.offenderMobileController.text, '03368359506');
    expect(find.text('Tap to fill in who pays'), findsNothing);
  });

  testWidgets('a CNIC nobody holds is said out loud', (
    WidgetTester tester,
  ) async {
    people.known = false;
    await pumpForm(tester);

    await tester.enterText(
      find.widgetWithText(AppTextField, "Offender's CNIC"),
      '5440010000000',
    );
    await tester.pumpAndSettle();

    // Not an error — a hawker nobody has written up before. The officer types
    // the details themselves, and the field says so rather than going quiet.
    expect(people.searched, <String>['5440010000000']);
    expect(
      find.text('No record for this CNIC. Fill the details in below.'),
      findsOneWidget,
    );
  });

  testWidgets('a shop\'s allottee arrives with their CNIC in the field', (
    WidgetTester tester,
  ) async {
    final FineController controller = await pumpForm(
      tester,
      propertyId: fixturePropertyId,
    );

    // Everything the register holds about the person to bill, the CNIC
    // included — it is the field the officer would otherwise retype off a
    // card they are already holding.
    expect(controller.offenderCnicController.text, '5440012345671');
    expect(controller.offenderNameController.text, 'Muhammad Iqbal');
    expect(controller.offenderMobileController.text, '03001234511');
    expect(find.text('5440012345671'), findsOneWidget);

    // And it was not mistaken for something the officer typed: no lookup went
    // out behind their back.
    expect(people.searched, isEmpty);
  });

  testWidgets('the section of law is the offence\'s, and is never typed', (
    WidgetTester tester,
  ) async {
    // Through `runAsync`: the call behind the register is a real one over the
    // stubbed adapter, and a widget test's fake clock never advances it.
    await tester.runAsync(() async {
      api.stub.reply(<String, dynamic>{
        'data': definitionsDataWithOtherOffence(),
      });
      await definitions.reload();
    });
    final FineController controller = await pumpForm(tester);

    // No field for it: the provision is a fact about the offence, so there is
    // nothing on the form to type it into.
    expect(find.widgetWithText(AppTextField, 'Provision of law'), findsNothing);

    controller.chooseFineType(definitions.fineType('encroachment'));
    await tester.pumpAndSettle();

    // Read off the register's row, and shown as the fine will read.
    expect(
      controller.provision,
      'Section 97, Balochistan Local Government Act 2010',
    );
    expect(
      find.text(
        'Raised under Section 97, Balochistan Local Government Act 2010',
      ),
      findsOneWidget,
    );

    // And the offence that carries none says so where the choice was made,
    // rather than leaving the officer at a button that will not press.
    controller.chooseFineType(definitions.fineType('other'));
    await tester.pumpAndSettle();

    expect(controller.provision, isNull);
    expect(
      find.textContaining('no section of law for this offence'),
      findsOneWidget,
    );
    expect(
      controller.missing,
      contains('an offence the register gives a section of law for'),
    );
  });

  testWidgets('a shop\'s fine takes a remark', (WidgetTester tester) async {
    final FineController controller = await pumpForm(
      tester,
      propertyId: fixturePropertyId,
      allotmentId: 41,
    );

    // Last on the form and optional: the officer's own words on the fine,
    // read back later against the tenancy it was billed to.
    await tester.scrollUntilVisible(
      find.text('Remarks'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Remarks'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(
        AppTextField,
        'e.g. Refused to remove the display after two warnings',
      ),
      'Display back on the footpath',
    );
    await tester.pumpAndSettle();
    expect(controller.remarksController.text, 'Display back on the footpath');
    // Nothing was made compulsory by asking for it.
    expect(controller.missing, isNot(contains('remarks')));
  });

  testWidgets('a area\'s fine is not asked for a remark', (
    WidgetTester tester,
  ) async {
    // No tenancy behind it, so there is nothing for the remark to be read
    // against later and the form does not ask for one.
    await pumpForm(tester);
    expect(find.text('Remarks'), findsNothing);
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
    expect(find.text('The fine will be posted here'), findsNothing);
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
