import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

import 'package:mcq_app/controllers/auth_controller.dart';
import 'package:mcq_app/controllers/case_controller.dart';
import 'package:mcq_app/controllers/definitions_controller.dart';
import 'package:mcq_app/core/network/api_exception.dart';
import 'package:mcq_app/data/repositories/auth_repository.dart';
import 'package:mcq_app/data/repositories/definitions_repository.dart';
import 'package:mcq_app/models/api_refs.dart';
import 'package:mcq_app/models/unit_card.dart';

import 'support/api_stub.dart';
import 'support/definitions_fixtures.dart';
import 'support/person_fixtures.dart';
import 'support/property_profile_fixtures.dart';

/// The case form, from what the officer chooses to what goes on the wire.
///
/// `POST enforcement/field/cases` refuses to guess between the two kinds of
/// case, so the assertions that matter are: the unit travels as `property_id`
/// and never as an allotment, the kind is the register's own code, and the
/// server's refusal lands under the field it names.
void main() {
  late FakeEnforcementCaseRepository cases;
  late DefinitionsController definitions;

  const UnitCard heldUnit = UnitCard(
    propertyId: 77,
    shopNo: 'F-3',
    areaId: 2,
    areaName: 'Prince Road',
    marketName: 'Liaquat Bazaar',
    allotmentId: 12,
    allotteeName: 'Abdul Samad',
    outstanding: '4500.00',
  );

  /// The controller as the screen builds it, with the case kinds already in
  /// hand: `onInit` fetches them, so a form asserted on before that microtask
  /// has run is one no officer ever sees.
  Future<CaseController> build({
    UnitCard? unit = heldUnit,
    int? propertyId,
  }) async {
    final CaseController controller = CaseController(
      unit: unit,
      propertyId: propertyId,
      caseRepository: cases,
      reportingRepository: FakeReportingRepository(),
      personRepository: FakePersonRepository(),
      definitionsController: definitions,
    )..onInit();
    await Future<void>.delayed(Duration.zero);
    return controller;
  }

  /// The rest of what the server insists on: the person a notice on this case
  /// would be served on. The held shop's card names them, so only the two
  /// fields it does not carry are typed here.
  void nameThePerson(CaseController controller) {
    controller.offenderFatherController.text = 'Ghulam Nabi';
    controller.offenderMobileController.text = '03007654321';
    controller.markEdited();
  }

  setUp(() async {
    Get.reset();
    cases = FakeEnforcementCaseRepository();
    // The real definitions controller over a stubbed wire: the priorities an
    // officer picks from are the register's rows, and a case carries the value
    // of the one they chose.
    final StubbedApi api = StubbedApi();
    api.stub.reply(<String, dynamic>{'data': _registerWithNormalPriority()});
    definitions = DefinitionsController(
      definitionsRepository: ApiDefinitionsRepository(api: api.service),
      authController: AuthController(
        authRepository: ApiAuthRepository(
          api: api.service,
          storage: api.storage,
        ),
      ),
    );
    await definitions.load();
  });

  tearDown(Get.reset);

  group('what goes on the wire', () {
    test('the unit, the kind, the reason and the priority travel', () async {
      final CaseController controller = await build();
      // One kind on the register, so it is chosen for the officer; the words
      // are the only thing this form makes them type.
      controller.reasonController.text =
          'Trading in goods the agreement does not permit.';
      nameThePerson(controller);

      expect(await controller.open(), OpenCaseOutcome.success);

      final Map<String, dynamic> json = cases.openedWith!.toJson();
      expect(json['property_id'], 77);
      // The person a notice is served on. The name came off the shop's own
      // card rather than being typed again.
      expect(json['offender_name'], 'Abdul Samad');
      expect(json['offender_father_name'], 'Ghulam Nabi');
      expect(json['offender_mobile_no'], '03007654321');
      expect(json['case_type'], 'unauthorised_use');
      expect(
        json['case_reason'],
        'Trading in goods the agreement does not permit.',
      );
      expect(json['priority'], 'normal');
      // A conduct case names no tenancy: sending both is refused by the
      // server rather than resolved.
      expect(json['allotment_id'], isNull);
      expect(cases.openedWith!.isConductCase, isTrue);
    });

    test('the reason is trimmed, and the priority may be dropped', () async {
      final CaseController controller = await build();
      controller.reasonController.text = '  Sub-let to a tea stall.  ';
      nameThePerson(controller);
      controller.choosePriority(null);

      await controller.open();

      final Map<String, dynamic> json = cases.openedWith!.toJson();
      expect(json['case_reason'], 'Sub-let to a tea stall.');
      // Left unset, the server opens the case at its own priority — the app
      // does not invent one.
      expect(json['priority'], isNull);
    });

    test('the id off a bare route is enough to open a case', () async {
      // No card and no profile: the route carried an id, which is all
      // `property_id` needs.
      final CaseController controller = await build(
        unit: null,
        propertyId: 118,
      );
      controller.reasonController.text = 'Shutters replaced without approval.';
      // The profile fetched behind the id names the holder; the officer types
      // what its record does not carry.
      nameThePerson(controller);

      expect(await controller.open(), OpenCaseOutcome.success);
      final Map<String, dynamic> json = cases.openedWith!.toJson();
      expect(json['property_id'], 118);
      expect(json['offender_name'], 'Muhammad Iqbal');
    });
  });

  group('what it refuses to send', () {
    test('a case with no reason is not posted', () async {
      final CaseController controller = await build();

      expect(await controller.open(), OpenCaseOutcome.invalidForm);
      expect(cases.openedWith, isNull);
      expect(
        controller.validateReason(controller.reasonController.text),
        'Say why the case is being opened',
      );
    });

    test('a form with no shop on it is not posted', () async {
      final CaseController controller = await build(unit: null);
      controller.reasonController.text = 'Trading outside the agreement.';
      nameThePerson(controller);

      expect(await controller.open(), OpenCaseOutcome.invalidForm);
      expect(cases.openedWith, isNull);
      expect(controller.errorMessage.value, isNotNull);
    });

    test('the missing list names every empty field, in form order', () async {
      final CaseController controller = await build(unit: null);

      expect(controller.missing, <String>[
        'the shop',
        'why it is being opened',
        'the name of the person it is against',
        "their father's name",
        'their mobile number',
      ]);
    });
  });

  group('the person it is against', () {
    test('is filled in from the register, and can be corrected', () async {
      final CaseController controller = await build();

      // Off the shop's own card, so an officer standing at a held shop types
      // nothing the register already knows.
      expect(controller.offenderNameController.text, 'Abdul Samad');
      expect(controller.hasRegisteredPerson, isTrue);

      controller.offenderNameController.text = 'Noor Ahmed';
      controller.reasonController.text = 'Sub-let to a tea stall.';
      nameThePerson(controller);
      await controller.open();

      // The correction stands: the person in front of the officer is not
      // always the person on the register.
      expect(cases.openedWith!.toJson()['offender_name'], 'Noor Ahmed');
    });

    test('a case with nobody named is not posted', () async {
      final CaseController controller = await build();
      controller.reasonController.text = 'Trading outside the agreement.';

      // The card named the holder but carries no father's name or mobile.
      expect(await controller.open(), OpenCaseOutcome.invalidForm);
      expect(cases.openedWith, isNull);
      expect(
        controller.validateOffenderMobile(''),
        'A mobile number to reach them on is required',
      );
    });

    test("the server's refusal lands under the field it names", () async {
      cases.openFailure = const ApiException(
        message: 'The given data was invalid.',
        failure: ApiFailure.validation,
        statusCode: 422,
        errors: <String, List<String>>{
          'offender_mobile_no': <String>[
            'A mobile number to reach them on. Without it the only way to '
                'contact the person is to go back and find them.',
          ],
        },
      );
      final CaseController controller = await build();
      controller.reasonController.text = 'Trading outside the agreement.';
      nameThePerson(controller);

      expect(await controller.open(), OpenCaseOutcome.failed);
      expect(
        controller.validateOffenderMobile('03007654321'),
        startsWith('A mobile number to reach them on.'),
      );
    });
  });

  group('when the server refuses', () {
    test("its message for a field lands on that field", () async {
      cases.openFailure = const ApiException(
        message: 'The given data was invalid.',
        failure: ApiFailure.validation,
        statusCode: 422,
        errors: <String, List<String>>{
          'case_reason': <String>[
            'The case reason must be at least 10 characters.',
          ],
        },
      );
      final CaseController controller = await build();
      controller.reasonController.text = 'Sub-let.';
      nameThePerson(controller);

      expect(await controller.open(), OpenCaseOutcome.failed);
      expect(
        controller.validateReason('Sub-let.'),
        'The case reason must be at least 10 characters.',
      );
      // And the server's own sentence stays on the bar beside the button.
      expect(controller.errorMessage.value, 'The given data was invalid.');
    });

    test('a refused case can be sent again once it is corrected', () async {
      cases.openFailure = const ApiException(
        message: 'A case is already open on this property.',
        failure: ApiFailure.conflict,
        statusCode: 409,
      );
      final CaseController controller = await build();
      controller.reasonController.text = 'Trading outside the agreement.';
      nameThePerson(controller);

      expect(await controller.open(), OpenCaseOutcome.failed);

      cases.openFailure = null;
      expect(await controller.open(), OpenCaseOutcome.success);
      expect(controller.errorMessage.value, isNull);
      expect(controller.opened.value?.caseNo, 'MCQ-EC-2627-00512');
    });
  });

  group("the register's own rows", () {
    test('one kind of case is chosen without asking', () async {
      final CaseController controller = await build();

      expect(controller.caseTypes.length, 1);
      expect(controller.caseType.value?.code, 'unauthorised_use');
    });

    test(
      "the priorities are the register's, and normal is the default",
      () async {
        final CaseController controller = await build();

        expect(
          controller.priorities.map((LabelledValue row) => row.value),
          containsAll(<String>['normal', 'critical']),
        );
        expect(controller.priority.value?.value, 'normal');
      },
    );

    test('a case-kind list that would not load blocks the form', () async {
      cases.caseTypeFailure = const ApiException(
        message: 'No connection. The record is not saved yet.',
        failure: ApiFailure.network,
      );
      final CaseController controller = await build();

      expect(controller.caseTypes, isEmpty);
      expect(controller.caseTypesError.value, isNotNull);
      expect(controller.missing, contains('what the case is about'));
    });
  });
}

/// The fixtures' register with `normal` on it — the priority the form
/// pre-selects, which the shared fixture does not carry.
Map<String, dynamic> _registerWithNormalPriority() {
  final Map<String, dynamic> data = definitionsData();
  data['case_priorities'] = <Map<String, dynamic>>[
    <String, dynamic>{'value': 'normal', 'label': 'Normal', 'tone': 'info'},
    <String, dynamic>{'value': 'critical', 'label': 'Urgent', 'tone': 'danger'},
  ];
  return data;
}
