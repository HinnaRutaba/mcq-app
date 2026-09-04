import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
// `get` exports a `Response` of its own, which collides with dio's here.
import 'package:get/get.dart' hide Response;

import 'package:mcq_app/controllers/auth_controller.dart';
import 'package:mcq_app/controllers/dashboard_controller.dart';
import 'package:mcq_app/controllers/definitions_controller.dart';
import 'package:mcq_app/controllers/fine_controller.dart';
import 'package:mcq_app/core/capture/photo_capture.dart';
import 'package:mcq_app/core/network/api_exception.dart';
import 'package:mcq_app/data/repositories/auth_repository.dart';
import 'package:mcq_app/data/repositories/definitions_repository.dart';
import 'package:mcq_app/data/repositories/evidence_repository.dart';
import 'package:mcq_app/data/repositories/fine_repository.dart';
import 'package:mcq_app/models/enforcement_definitions.dart';
import 'package:mcq_app/models/field_beat.dart';
import 'package:mcq_app/models/evidence_upload.dart';
import 'package:mcq_app/models/fine.dart';
import 'package:mcq_app/models/fine_request.dart';
import 'package:mcq_app/models/unit_card.dart';

import 'support/api_stub.dart';
import 'support/dashboard_fixtures.dart';
import 'support/definitions_fixtures.dart';

/// The fine form, from what the officer types to what goes on the wire.
///
/// These are the assertions that matter on a bazaar's signal: the amount is
/// never turned into a number, the photograph goes up before the fine does, a
/// retry is the *same* fine and not a second one, and the server's refusal
/// lands under the field it names.
void main() {
  late FakeFineRepository fines;
  late FakeEvidenceRepository evidence;

  /// A shop somebody holds — the ordinary case, where the allottee is billed.
  const UnitCard heldUnit = UnitCard(
    propertyId: 77,
    shopNo: 'F-3',
    areaId: 2,
    areaName: 'Prince Road',
    marketName: 'Liaquat Bazaar',
    allotmentId: 12,
    allotteeName: 'Abdul Samad',
    mobileNo: '03007654321',
    cnic: '5440099887766',
    outstanding: '4500.00',
  );

  /// A shop with nobody on the register, where the server says the form has to
  /// name the person being fined.
  const UnitCard vacantUnit = UnitCard(
    propertyId: 78,
    shopNo: 'F-4',
    areaId: 2,
    areaName: 'Prince Road',
    marketName: 'Liaquat Bazaar',
    isVacant: true,
    outstanding: '0.00',
    needsOffenderDetails: true,
  );

  late DefinitionsController definitions;
  late DashboardController dashboard;

  FineController build({UnitCard unit = heldUnit}) => FineController(
    unit: unit,
    fineRepository: fines,
    evidenceRepository: evidence,
    definitionsController: definitions,
    dashboardController: dashboard,
    photoCapture: FakePhotoCapture(),
  )..onInit();

  /// The officer pressed the fine button with no shop in mind and switched to
  /// fining somebody in the bazaar.
  FineController buildInArea() => FineController(
    fineRepository: fines,
    evidenceRepository: evidence,
    definitionsController: definitions,
    dashboardController: dashboard,
    photoCapture: FakePhotoCapture(),
  )..onInit();

  /// Fills in only what the server insists on. `encroachment` is id 4 on the
  /// register the fixtures carry.
  void fillRequired(FineController controller, {String amount = '4500'}) {
    controller.chooseFineType(controller.fineTypes[1]);
    controller.amountController.text = amount;
    controller.provisionController.text = 'Section 96, Balochistan LG Act 2010';
  }

  setUp(() async {
    Get.reset();
    fines = FakeFineRepository();
    evidence = FakeEvidenceRepository();

    // The real definitions controller over a stubbed wire: both the bazaars
    // and the offences an officer picks from are the register's rows, and a
    // fine carries the ids of the ones they chose.
    final StubbedApi api = StubbedApi();
    api.stub.reply(definitionsResponse);
    final AuthController auth = AuthController(
      authRepository: ApiAuthRepository(api: api.service, storage: api.storage),
    );
    definitions = DefinitionsController(
      definitionsRepository: ApiDefinitionsRepository(api: api.service),
      authController: auth,
    );
    await definitions.load();

    // The bazaars come off `enforcement/field/beat`, which the home screen has
    // already fetched by the time an officer reaches this form — so the
    // controller holding it is handed over rather than rebuilt here.
    dashboard = DashboardController(
      dashboardRepository: FakeDashboardRepository(),
      defaultersRepository: FakeDefaultersRepository(),
      authController: auth,
    );
    dashboard.beat.value = beatFixture;
  });

  tearDown(Get.reset);

  group('what goes on the wire', () {
    test('the amount is sent exactly as it was typed', () async {
      final controller = build();
      // Two decimal places, a trailing zero, and a figure that would lose its
      // shape the moment anything parsed it into a double.
      fillRequired(controller, amount: '4500.50');

      expect(await controller.impose(), ImposeOutcome.success);

      final json = fines.lastRequest!.toJson();
      expect(json['fine_amount'], '4500.50');
      expect(json['fine_amount'], isA<String>());
    });

    test('the offence, the provision and the unit all travel', () async {
      final controller = build();
      fillRequired(controller);

      await controller.impose();

      final json = fines.lastRequest!.toJson();
      // The id is the whole of what the server is told about the offence, and
      // it is not something the app can invent.
      expect(json['fine_type_id'], 4);
      expect(json['legal_provision'], 'Section 96, Balochistan LG Act 2010');
      // The unit is the path, not a field.
      expect(fines.lastPropertyId, 77);
    });

    test('a fine sends these fields and no others', () async {
      final controller = build();
      fillRequired(controller);

      await controller.impose();

      // The endpoint's whole vocabulary. A fine carries no date, no location
      // fix, no signature, no witness and no remarks — if one appears here,
      // the form is collecting something the server will not take.
      // The register named the allottee but not their father, so no person
      // is named on this one — see "a half-named person is not sent at all".
      expect(fines.lastRequest!.toJson().keys.toSet(), <String>{
        'area_id',
        'fine_type_id',
        'fine_amount',
        'legal_provision',
        'photo_path',
        'client_action_uuid',
      });
    });

    test('every fine carries a client_action_uuid', () async {
      final controller = build();
      fillRequired(controller);

      await controller.impose();

      final uuid = fines.lastRequest!.toJson()['client_action_uuid'];
      expect(uuid, isA<String>());
      expect((uuid! as String).isNotEmpty, isTrue);
    });

    test('a blank optional field is left off rather than sent empty', () async {
      final controller = build();
      fillRequired(controller);

      await controller.impose();

      final json = fines.lastRequest!.toJson();
      expect(json['photo_path'], isNull);
      expect(json['offender_name'], isNull);
    });
  });

  group('a fine on a shop', () {
    test('who pays arrives filled in from the register', () {
      final controller = build();

      // The officer confirms or corrects it; they do not retype what the
      // register already knows.
      expect(controller.offenderNameController.text, 'Abdul Samad');
      expect(controller.offenderMobileController.text, '03007654321');
      expect(controller.offenderCnicController.text, '5440099887766');
      // Nothing is required of them: there is a tenancy to bill.
      expect(controller.needsOffenderDetails, isFalse);
      expect(controller.missing, isNot(contains("the offender's name")));
    });

    test('a shop whose record has no bazaar asks for one', () {
      // `area_id` is required on every fine, so a unit the register cannot
      // place has to be placed by the officer.
      const UnitCard unplaced = UnitCard(propertyId: 79, outstanding: '0.00');
      final controller = build(unit: unplaced);
      fillRequired(controller);

      expect(controller.targetAreaId, isNull);
      expect(controller.missing, contains('the bazaar'));
      expect(controller.isComplete, isFalse);

      controller.setArea(1);
      expect(controller.isComplete, isTrue);
      expect(controller.targetAreaId, 1);
    });

    test('the bazaar comes off the unit, not off a picker', () async {
      final controller = build();
      fillRequired(controller);

      await controller.impose();

      expect(fines.lastRequest!.toJson()['area_id'], 2);
    });

    test('a half-named person is not sent at all', () async {
      final controller = build();
      fillRequired(controller);

      // The register gave a name and a mobile but no father's name, and the
      // server refuses a person named by two of the three.
      await controller.impose();
      expect(fines.lastRequest!.toJson().containsKey('offender_name'), isFalse);

      // Completed by hand, the whole block travels.
      controller.offenderFatherController.text = 'Gul Muhammad';
      controller.markEdited();
      await controller.impose();

      final json = fines.lastRequest!.toJson();
      expect(json['offender_name'], 'Abdul Samad');
      expect(json['offender_father_name'], 'Gul Muhammad');
      expect(json['offender_mobile_no'], '03007654321');
    });

    test('a fine with no shop starts with nobody named', () {
      final controller = buildInArea();

      // There is no register behind it to fill the block in from, and the
      // officer cannot have arrived here from a shop.
      expect(controller.offenderNameController.text, isEmpty);
      expect(controller.offenderMobileController.text, isEmpty);
    });
  });

  group('the offence comes off the register', () {
    test('the picker is the rows the server sent', () {
      final controller = build();

      expect(
        controller.fineTypes.map((FineTypeDefinition t) => t.code),
        <String>['unauthorised_use', 'encroachment'],
      );
    });

    test('choosing one fills in its amount and its provision', () {
      final controller = build();
      controller.chooseFineType(controller.fineTypes.first);

      expect(controller.amountController.text, '10000.00');
      expect(
        controller.provisionController.text,
        'Section 96, Balochistan Local Government Act 2010',
      );

      // A second choice replaces a suggestion the officer left alone.
      controller.chooseFineType(controller.fineTypes[1]);
      expect(controller.amountController.text, '3000.00');
      expect(
        controller.provisionController.text,
        'Section 97, Balochistan Local Government Act 2010',
      );
    });

    test('an amount the officer typed is never overwritten', () {
      final controller = build();
      controller.chooseFineType(controller.fineTypes.first);
      controller.amountController.text = '7500';

      controller.chooseFineType(controller.fineTypes[1]);

      expect(controller.amountController.text, '7500');
      // The provision was left as the register suggested, so it still follows.
      expect(
        controller.provisionController.text,
        'Section 97, Balochistan Local Government Act 2010',
      );
    });
  });

  group('retrying after a dead signal', () {
    test('re-sends the same fine, not a second one', () async {
      final controller = build();
      fillRequired(controller);

      fines.failWith = const ApiExceptionFixture.network();
      expect(await controller.impose(), ImposeOutcome.failed);
      final first = fines.lastRequest!.clientActionUuid;

      // The officer presses again. Same object, same key: the server is being
      // told "this is the fine I already sent", not "here is another one".
      fines.failWith = null;
      expect(await controller.impose(), ImposeOutcome.success);

      expect(fines.lastRequest!.clientActionUuid, first);
      expect(fines.calls, 2);
    });

    test('editing the fine first makes it a different fine', () async {
      final controller = build();
      fillRequired(controller);

      fines.failWith = const ApiExceptionFixture.network();
      await controller.impose();
      final first = fines.lastRequest!.clientActionUuid;

      // A changed amount is not the same fine, so it must not reuse the key —
      // that would let the server discard the correction as a duplicate.
      fines.failWith = null;
      controller.amountController.text = '6000';
      controller.markEdited();
      await controller.impose();

      expect(fines.lastRequest!.clientActionUuid, isNot(first));
    });
  });

  group('the evidence', () {
    test(
      'the photograph goes up first, and the fine carries its path',
      () async {
        final controller = build();
        fillRequired(controller);

        expect(await controller.attachPhoto(), PhotoOutcome.taken);
        expect(evidence.uploads, <String>['/handset/shopfront.jpg']);
        expect(
          controller.photoUploadedPath.value,
          'evidence/2026/shopfront.jpg',
        );

        await controller.impose();

        // The server's path, never the handset's — `/handset/...` means nothing
        // to it.
        expect(
          fines.lastRequest!.toJson()['photo_path'],
          'evidence/2026/shopfront.jpg',
        );
      },
    );

    test('a photograph that will not upload does not block the fine', () async {
      final controller = build();
      fillRequired(controller);
      evidence.failWith = const ApiExceptionFixture.network();

      await controller.attachPhoto();

      expect(controller.photoLocalPath.value, isNotNull);
      expect(controller.photoUploadedPath.value, isNull);
      // A shopkeeper does not walk away unfined because a picture would not go
      // up over a bazaar's uplink.
      expect(await controller.impose(), ImposeOutcome.success);
      expect(fines.lastRequest!.toJson()['photo_path'], isNull);
    });
  });

  group('what the form refuses to send', () {
    test('an amount that is not a figure', () {
      final controller = build();
      expect(controller.validateAmount('45.678'), isNotNull);
      expect(controller.validateAmount('abc'), isNotNull);
      expect(controller.validateAmount('0'), isNotNull);
      expect(controller.validateAmount('4500'), isNull);
      expect(controller.validateAmount('4500.50'), isNull);
    });

    test('a fine with no section of law named', () {
      final controller = build();
      final message = controller.validateProvision('  ');
      expect(message, isNotNull);
      expect(message, contains('enforced'));
    });

    test('a vacant unit without the offender named', () {
      final controller = build(unit: vacantUnit);
      fillRequired(controller);

      // The server said this unit needs offender details; the form reads that
      // rather than deciding for itself from `is_vacant`.
      expect(controller.needsOffenderDetails, isTrue);
      expect(controller.isComplete, isFalse);
      expect(controller.missing, contains("the offender's name"));

      controller.offenderNameController.text = 'Noor Ahmed';
      controller.offenderFatherController.text = 'Gul Khan';
      controller.offenderMobileController.text = '03001234567';
      // The CNIC is asked for too wherever the officer names the person.
      expect(controller.missing, contains('their CNIC'));
      controller.offenderCnicController.text = '5440011223344';
      expect(controller.isComplete, isTrue);
    });

    test('the offender travels under the names the API uses', () async {
      final controller = build(unit: vacantUnit);
      fillRequired(controller);
      controller.offenderNameController.text = 'Noor Ahmed';
      controller.offenderFatherController.text = 'Gul Khan';
      controller.offenderMobileController.text = '03001234567';
      controller.offenderCnicController.text = '5440011223344';

      await controller.impose();

      final json = fines.lastRequest!.toJson();
      expect(json['offender_name'], 'Noor Ahmed');
      expect(json['offender_father_name'], 'Gul Khan');
      expect(json['offender_mobile_no'], '03001234567');
    });
  });

  group('a fine on somebody with no shop', () {
    test('the bazaar is searched for by name or code', () {
      final controller = buildInArea();

      controller.searchArea('prince');
      expect(controller.areaMatches.map((FieldArea a) => a.areaName), <String>[
        'Prince Road',
      ]);

      controller.searchArea('JR');
      expect(controller.areaMatches.map((FieldArea a) => a.areaName), <String>[
        'Jinnah Road',
      ]);

      // Chosen, and the search box goes back to empty for the next one.
      controller.setArea(controller.areaMatches.first.id);
      expect(controller.chosenArea!.areaName, 'Jinnah Road');
      expect(controller.areaQuery.value, isEmpty);
    });

    test('with no bazaars on the beat, the id is typed', () {
      // The offences arrived; the beat did not.
      dashboard.beat.value = null;
      final controller = buildInArea();
      fillRequired(controller);

      expect(controller.areaOptions, isEmpty);
      expect(controller.missing, contains('the bazaar'));

      controller.setAreaFromText('14');
      expect(controller.targetAreaId, 14);
      expect(controller.validateArea(controller.targetAreaId), isNull);
    });

    test('the bazaars come off the beat, by id', () {
      final controller = buildInArea();

      // `GET enforcement/definitions` is the only place an `area_id` may come
      // from — the same call the offences arrive on.
      expect(controller.areaOptions, <int>[1, 2]);
      expect(controller.areaLabel(2), 'Prince Road');
      // Two to choose between, so nothing is chosen for the officer.
      expect(controller.areaId.value, isNull);
    });

    test('it goes to the area endpoint, not to a unit', () async {
      final controller = buildInArea();
      controller.setArea(1);
      fillRequired(controller);
      controller.offenderNameController.text = 'Noor Ahmed';
      controller.offenderFatherController.text = 'Gul Khan';
      controller.offenderMobileController.text = '03001234567';
      controller.offenderCnicController.text = '5440011223344';
      controller.offenderAddressController.text = 'Footpath outside Shop 12';

      expect(await controller.impose(), ImposeOutcome.success);

      // `imposeInArea` posts to `enforcement/fines`; nothing was posted
      // against a unit.
      expect(fines.lastPropertyId, isNull);
      final json = fines.lastRequest!.toJson();
      // Both ids off the register: the bazaar and the offence.
      expect(json['area_id'], 1);
      expect(json['fine_type_id'], 4);
      expect(json['offender_name'], 'Noor Ahmed');
      expect(json['offender_address'], 'Footpath outside Shop 12');
      expect(json.keys.toSet(), <String>{
        'area_id',
        'fine_type_id',
        'fine_amount',
        'legal_provision',
        'offender_name',
        'offender_father_name',
        'offender_mobile_no',
        'offender_cnic',
        'offender_address',
        'photo_path',
        'client_action_uuid',
      });
    });

    test('the person has to be named, and the bazaar chosen', () async {
      final controller = buildInArea();
      fillRequired(controller);

      expect(controller.missing, contains('the bazaar'));
      expect(controller.needsOffenderDetails, isTrue);
      expect(controller.missing, contains("the offender's name"));
      expect(await controller.impose(), ImposeOutcome.invalidForm);
      expect(fines.calls, 0);
    });

    test('one bazaar on the beat is chosen rather than asked about', () {
      dashboard.beat.value = FieldBeat.fromJson(<String, dynamic>{
        'officer': <String, dynamic>{'name': 'Inspector'},
        'scope': <String, dynamic>{
          'areas': <Map<String, dynamic>>[
            <String, dynamic>{'id': 7, 'area_name': 'Liaquat Bazaar'},
          ],
        },
      });

      final controller = buildInArea();

      expect(controller.areaId.value, 7);
      expect(controller.areaLabel(7), 'Liaquat Bazaar');
    });

    test('arriving with no shop is what makes it an area fine', () {
      expect(buildInArea().isAreaFine, isTrue);
      // And arriving from a shop's screen is what makes it a unit fine: the
      // officer never chooses between them on the form.
      expect(build().isAreaFine, isFalse);
    });
  });

  group('when the server refuses it', () {
    test('a 422 lands under the field it names', () async {
      final controller = build();
      fillRequired(controller);
      fines.failWith = const ApiExceptionFixture.validation(
        <String, List<String>>{
          'fine_amount': <String>['The fine amount may not exceed 50000.'],
          'legal_provision': <String>['The legal provision field is required.'],
        },
      );

      expect(await controller.impose(), ImposeOutcome.failed);

      // The server's own sentence, verbatim under the field it belongs to.
      expect(
        controller.validateAmount('4500'),
        'The fine amount may not exceed 50000.',
      );
      expect(
        controller.validateProvision('Section 96'),
        'The legal provision field is required.',
      );
    });

    test('a refusal that is not a validation error is shown whole', () async {
      final controller = build();
      fillRequired(controller);
      fines.failWith = const ApiExceptionFixture.forbidden(
        'This unit is outside the bazaars you are posted to.',
      );

      expect(await controller.impose(), ImposeOutcome.failed);
      expect(
        controller.errorMessage.value,
        'This unit is outside the bazaars you are posted to.',
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Stand-ins
// ---------------------------------------------------------------------------

/// The failures a test wants to provoke, without building a [DioException] at
/// every call site.
class ApiExceptionFixture {
  const ApiExceptionFixture.network()
    : _statusCode = null,
      _message = 'No connection. The record is not saved yet.',
      _errors = const <String, List<String>>{};

  const ApiExceptionFixture.validation(Map<String, List<String>> errors)
    : _statusCode = 422,
      _message = 'Please check the details and try again.',
      _errors = errors;

  const ApiExceptionFixture.forbidden(String message)
    : _statusCode = 403,
      _message = message,
      _errors = const <String, List<String>>{};

  final int? _statusCode;
  final String _message;
  final Map<String, List<String>> _errors;

  /// Built through `ApiException.fromDio` rather than by hand, so a test is
  /// exercising the real decoding and not a second copy of it.
  DioException toDio() {
    final options = RequestOptions(path: '/x');
    if (_statusCode == null) {
      return DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return DioException(
      requestOptions: options,
      response: Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: _statusCode,
        data: <String, dynamic>{'message': _message, 'errors': _errors},
      ),
      type: DioExceptionType.badResponse,
    );
  }
}

class FakeFineRepository implements FineRepository {
  int calls = 0;
  int? lastPropertyId;
  FineRequest? lastRequest;
  ApiExceptionFixture? failWith;

  @override
  Future<Fine> impose({
    required int propertyId,
    required FineRequest request,
  }) async {
    lastPropertyId = propertyId;
    return _record(request);
  }

  @override
  Future<Fine> imposeInArea({required FineRequest request}) => _record(request);

  Future<Fine> _record(FineRequest request) async {
    calls++;
    lastRequest = request;

    final failure = failWith;
    if (failure != null) throw ApiException.fromDio(failure.toDio());

    return Fine.fromJson(<String, dynamic>{
      'id': 8,
      'fine_no': 'MCQ-FN-2627-00008',
      'amounts': <String, dynamic>{'fine_amount': request.fineAmount},
    });
  }
}

class FakeEvidenceRepository implements EvidenceRepository {
  final List<String> uploads = <String>[];
  ApiExceptionFixture? failWith;

  @override
  Future<EvidenceUpload> upload({
    required String filePath,
    String kind = EvidenceRepository.kindPhoto,
    String? mimeType,
    ProgressCallback? onProgress,
  }) async {
    final failure = failWith;
    if (failure != null) throw ApiException.fromDio(failure.toDio());

    uploads.add(filePath);
    return EvidenceUpload.fromJson(<String, dynamic>{
      'path': 'evidence/2026/${filePath.split('/').last}',
    });
  }
}

class FakePhotoCapture implements PhotoCapture {
  @override
  Future<PhotoCaptureResult> fromCamera() async =>
      const PhotoCaptureResult(PhotoOutcome.taken, '/handset/shopfront.jpg');

  @override
  Future<PhotoCaptureResult> fromGallery() => fromCamera();
}
