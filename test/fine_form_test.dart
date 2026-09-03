import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mcq_app/controllers/fine_controller.dart';
import 'package:mcq_app/core/capture/location_capture.dart';
import 'package:mcq_app/core/capture/photo_capture.dart';
import 'package:mcq_app/core/network/api_exception.dart';
import 'package:mcq_app/data/repositories/evidence_repository.dart';
import 'package:mcq_app/data/repositories/fine_repository.dart';
import 'package:mcq_app/data/repositories/units_repository.dart';
import 'package:mcq_app/models/evidence_upload.dart';
import 'package:mcq_app/models/fine.dart';
import 'package:mcq_app/models/fine_request.dart';
import 'package:mcq_app/models/unit_card.dart';

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
    marketName: 'Prince Road',
    allotmentId: 12,
    allotteeName: 'Abdul Samad',
    outstanding: '4500.00',
  );

  /// A shop with nobody on the register, where the server says the form has to
  /// name the person being fined.
  const UnitCard vacantUnit = UnitCard(
    propertyId: 78,
    shopNo: 'F-4',
    marketName: 'Prince Road',
    isVacant: true,
    outstanding: '0.00',
    needsOffenderDetails: true,
  );

  FineController build({UnitCard unit = heldUnit}) => FineController(
    unit: unit,
    fineRepository: fines,
    evidenceRepository: evidence,
    unitsRepository: FakeUnitsRepository(),
    photoCapture: FakePhotoCapture(),
    locationCapture: const FakeLocationCapture(),
  )..onInit();

  /// Fills in only what the server insists on.
  void fillRequired(FineController controller, {String amount = '4500'}) {
    controller.fineType.value = FineType.all.first;
    controller.amountController.text = amount;
    controller.provisionController.text = 'Section 96, Balochistan LG Act 2010';
  }

  setUp(() {
    fines = FakeFineRepository();
    evidence = FakeEvidenceRepository();
  });

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
      expect(json['fine_type'], 'unauthorised_use');
      expect(json['legal_provision'], 'Section 96, Balochistan LG Act 2010');
      expect(json['allotment_id'], 12);
      expect(fines.lastPropertyId, 77);
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
      expect(json['witness_name'], isNull);
      expect(json['remarks'], isNull);
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

    test('a fix travels as both coordinates and its accuracy', () async {
      final controller = build();
      fillRequired(controller);

      expect(await controller.attachLocation(), LocationOutcome.fixed);
      await controller.impose();

      final json = fines.lastRequest!.toJson();
      expect(json['latitude'], 30.1798);
      expect(json['longitude'], 66.9750);
      expect(json['location_accuracy_m'], 5.0);
    });

    test('with no fix, neither coordinate is sent', () async {
      final controller = build();
      fillRequired(controller);

      await controller.impose();

      final json = fines.lastRequest!.toJson();
      // Half a fix is not a fix; the API refuses a write carrying one.
      expect(json['latitude'], isNull);
      expect(json['longitude'], isNull);
    });

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
      expect(controller.isComplete, isTrue);
    });

    test('the offender travels under the names the API uses', () async {
      final controller = build(unit: vacantUnit);
      fillRequired(controller);
      controller.offenderNameController.text = 'Noor Ahmed';
      controller.offenderFatherController.text = 'Gul Khan';
      controller.offenderMobileController.text = '03001234567';

      await controller.impose();

      final json = fines.lastRequest!.toJson();
      expect(json['offender_name'], 'Noor Ahmed');
      expect(json['offender_father_name'], 'Gul Khan');
      expect(json['offender_mobile_no'], '03001234567');
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

class FakeUnitsRepository implements UnitsRepository {
  @override
  Future<List<UnitCard>> units({
    int? areaId,
    String? search,
    int? limit,
  }) async => const <UnitCard>[];
}

class FakePhotoCapture implements PhotoCapture {
  @override
  Future<PhotoCaptureResult> fromCamera() async =>
      const PhotoCaptureResult(PhotoOutcome.taken, '/handset/shopfront.jpg');

  @override
  Future<PhotoCaptureResult> fromGallery() => fromCamera();
}

class FakeLocationCapture implements LocationCapture {
  const FakeLocationCapture();

  @override
  Future<LocationResult> fix() async => const LocationResult(
    LocationOutcome.fixed,
    LocationFix(latitude: 30.1798, longitude: 66.9750, accuracyM: 5),
  );
}
