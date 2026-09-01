import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcq_app/core/network/api_config.dart';
import 'package:mcq_app/core/network/api_exception.dart';
import 'package:mcq_app/core/network/api_file.dart';
import 'package:mcq_app/core/network/api_service.dart';
import 'package:mcq_app/core/storage/secure_storage_service.dart';
import 'package:mcq_app/data/repositories/auth_repository.dart';
import 'package:mcq_app/data/repositories/challan_repository.dart';
import 'package:mcq_app/data/repositories/dashboard_repository.dart';
import 'package:mcq_app/data/repositories/defaulters_repository.dart';
import 'package:mcq_app/data/repositories/enforcement_case_repository.dart';
import 'package:mcq_app/data/repositories/evidence_repository.dart';
import 'package:mcq_app/data/repositories/field_seal_repository.dart';
import 'package:mcq_app/data/repositories/fine_repository.dart';
import 'package:mcq_app/data/repositories/reporting_repository.dart';
import 'package:mcq_app/data/repositories/units_repository.dart';
import 'package:mcq_app/models/models.dart';

import 'support/api_stub.dart';

/// Every payload below is copied from the published API document, which
/// captured them from live calls. If the app can read these, it can read the
/// server.
void main() {
  late ApiStub adapter;
  late ApiService api;
  late SecureStorageService storage;

  setUp(() {
    final stubbed = StubbedApi();
    adapter = stubbed.stub;
    storage = stubbed.storage;
    api = stubbed.service;
  });

  group('envelope', () {
    test('unwraps data and message, and keeps money as sent', () async {
      adapter.reply(<String, dynamic>{
        'data': <String, dynamic>{'outstanding': '263100.00'},
        'message': 'Fine imposed and payable. The allottee has been told.',
      });

      final response = await api.get('/anything');

      expect(response.dataMap['outstanding'], '263100.00');
      expect(response.message, contains('The allottee has been told.'));
    });

    test('reads a bare body that has no data key', () async {
      adapter.reply(<String, dynamic>{'pins': <dynamic>[]});
      final response = await api.get('/anything');
      expect(response.dataMap.containsKey('pins'), isTrue);
    });

    test('turns a 422 into per-field errors', () async {
      adapter.reply(<String, dynamic>{
        'message': 'The given data was invalid.',
        'code': 'VALIDATION_FAILED',
        'errors': <String, dynamic>{
          'offender_father_name': <String>['The offender father name field is required.'],
          'offender_mobile_no': <String>['The offender mobile no field is required.'],
        },
      }, statusCode: 422);

      await expectLater(
        api.post('/anything'),
        throwsA(
          isA<ApiException>()
              .having((ApiException e) => e.isValidation, 'isValidation', isTrue)
              .having((ApiException e) => e.code, 'code', 'VALIDATION_FAILED')
              .having(
                (ApiException e) => e.errorFor('offender_mobile_no'),
                'field error',
                contains('required'),
              ),
        ),
      );
    });

    test('maps a lost connection to a retryable network failure', () async {
      adapter.fail(DioExceptionType.connectionError);
      await expectLater(
        api.get('/anything'),
        throwsA(
          isA<ApiException>()
              .having((ApiException e) => e.failure, 'failure', ApiFailure.network)
              .having((ApiException e) => e.isRetryable, 'isRetryable', isTrue),
        ),
      );
    });
  });

  group('bearer token', () {
    test('is attached to an authenticated call and withheld from sign-in', () async {
      await storage.saveSession(token: 'live-token');

      adapter.reply(<String, dynamic>{'data': <String, dynamic>{}});
      await api.get('/authenticated');
      expect(adapter.lastOptions!.headers['Authorization'], 'Bearer live-token');

      adapter.reply(<String, dynamic>{'data': <String, dynamic>{}});
      await api.post('/sign-in', requiresAuth: false);
      expect(adapter.lastOptions!.headers.containsKey('Authorization'), isFalse);
    });

    test('a 401 on an authenticated call clears the keychain', () async {
      await storage.saveSession(token: 'dead-token');
      adapter.reply(<String, dynamic>{'message': 'Unauthenticated.'}, statusCode: 401);

      await expectLater(api.get('/authenticated'), throwsA(isA<ApiException>()));
      expect(await storage.readToken(), isNull);
    });

    test('a 401 from the sign-in call leaves an existing session alone', () async {
      await storage.saveSession(token: 'live-token');
      adapter.reply(
        <String, dynamic>{'message': 'These credentials do not match.'},
        statusCode: 401,
      );

      await expectLater(
        api.post('/sign-in', requiresAuth: false),
        throwsA(isA<ApiException>()),
      );
      expect(await storage.readToken(), 'live-token');
    });
  });

  group('request bodies', () {
    test('drops fields the officer left blank', () async {
      adapter.reply(<String, dynamic>{'data': <String, dynamic>{}});
      await api.post(
        '/anything',
        body: <String, dynamic>{'kept': 'yes', 'blank': null},
      );

      final body = adapter.lastOptions!.data as Map<String, dynamic>;
      expect(body, <String, dynamic>{'kept': 'yes'});
    });

    test('flattens a nested body into bracket notation for multipart', () async {
      final file = File(
        '${Directory.systemTemp.createTempSync('mcq').path}/shopfront.jpg',
      )..writeAsBytesSync(<int>[1, 2, 3]);

      adapter.reply(<String, dynamic>{'data': <String, dynamic>{'path': 'evidence/1.jpg'}});
      await api.post(
        '/anything',
        body: <String, dynamic>{
          'fine_amount': '3000.00',
          'recorded_offline': true,
          'seal': <String, dynamic>{'seal_reason': 'Arrears unpaid after notice.'},
        },
        files: <ApiFile>[ApiFile(path: file.path, mimeType: 'image/jpeg')],
      );

      final form = adapter.lastOptions!.data as FormData;
      final fields = Map<String, String>.fromEntries(form.fields);
      expect(fields['seal[seal_reason]'], 'Arrears unpaid after notice.');
      expect(fields['fine_amount'], '3000.00');
      expect(fields['recorded_offline'], '1');
      expect(form.files.single.key, 'file');
      expect(form.files.single.value.filename, 'shopfront.jpg');
    });
  });

  group('signing in', () {
    test('stores the token in the keychain and remembers the username', () async {
      adapter.reply(<String, dynamic>{
        'data': <String, dynamic>{
          'token': 'secret-token',
          'token_expires_at': null,
          'user': _sessionUser,
        },
      });

      final repository = ApiAuthRepository(api: api, storage: storage);
      final session = await repository.signIn(
        username: 'magistrate',
        password: 'password',
        deviceName: 'Pixel 8',
      );

      expect(session.user.name, 'Habibullah Tareen');
      expect(session.user.designation, 'Municipal Magistrate');
      expect(session.user.id, 5, reason: 'the API sends this id as the string "5"');
      expect(session.user.can('enforcement.fine.impose'), isTrue);
      expect(session.user.can('billing.payment.record'), isFalse);
      expect(session.user.hasRole('MAGISTRATE'), isTrue);
      expect(session.mustChangePassword, isFalse);

      expect(await storage.readToken(), 'secret-token');
      expect(await storage.readUsername(), 'magistrate');
      expect(await storage.readDeviceName(), 'Pixel 8');
    });

    test('signing out clears the token even when the call fails', () async {
      await storage.saveSession(token: 'live-token');
      adapter.fail(DioExceptionType.connectionError);

      final repository = ApiAuthRepository(api: api, storage: storage);
      await expectLater(repository.signOut(), throwsA(isA<ApiException>()));
      expect(await storage.readToken(), isNull);
    });

    test('changing the password clears the token, because the server revokes it',
        () async {
      await storage.saveSession(token: 'live-token');
      adapter.reply(<String, dynamic>{'message': 'Password updated.'});

      final repository = ApiAuthRepository(api: api, storage: storage);
      await repository.changePassword(
        currentPassword: 'password',
        newPassword: 'Quetta-Revenue-2026!',
        confirmPassword: 'Quetta-Revenue-2026!',
      );

      expect(adapter.lastOptions!.method, 'PUT');
      expect(await storage.readToken(), isNull);
    });
  });

  group('home', () {
    test('reads the beat: officer, scope and queues', () async {
      adapter.reply(_beatResponse);

      final beat = await ApiDashboardRepository(api: api).beat();

      expect(beat.officer.name, 'Habibullah Tareen');
      expect(beat.scope.restricted, isTrue);
      expect(beat.scope.areaNames, <String>['Jinnah Road', 'Prince Road']);
      expect(beat.scope.areas.first.zoneName, 'Zone 1 - Zarghoon');
      expect(beat.queues, hasLength(6));

      final defaulters = beat.queue('defaulters')!;
      expect(defaulters.count, 55);
      expect(defaulters.amount, '2213409.10');
      expect(defaulters.tone, 'danger');
      expect(defaulters.endpoint, 'enforcement/field/defaulters');

      final awaitingUnseal = beat.queue('awaiting_unseal')!;
      expect(awaitingUnseal.hasAmount, isFalse, reason: 'a count, not a sum');
      expect(awaitingUnseal.isEmpty, isTrue);
    });

    test('a queue endpoint resolves to a path and query', () {
      final routed = ApiPaths.resolve('enforcement/field/seals?ready=1');
      expect(routed.path, '/api/v1/enforcement/field/seals');
      expect(routed.query, <String, String>{'ready': '1'});

      final assigned = ApiPaths.resolve('enforcement/cases?magistrate_id=me');
      expect(assigned.path, '/api/v1/enforcement/cases');
      expect(assigned.query, <String, String>{'magistrate_id': 'me'});
    });

    test('reads the activity tally', () async {
      adapter.reply(<String, dynamic>{
        'data': <String, dynamic>{
          'period_days': 30,
          'since': '2026-08-01',
          'visits': 27,
          'by_action_type': <String, dynamic>{
            'final_warning': 3,
            'fine_imposed': 3,
            'notice_served': 9,
            'site_visit': 9,
            'verbal_warning': 3,
          },
          'fines_imposed': 3,
          'fines_amount': '15000.00',
          'shops_sealed': 0,
          'seals_released': 0,
          'collected_in_your_areas': '224505.90',
          'receipts_in_your_areas': 21,
        },
      });

      final activity = await ApiDashboardRepository(api: api).activity();

      expect(adapter.lastOptions!.queryParameters['days'], 30);
      expect(activity.visits, 27);
      expect(activity.byActionType['notice_served'], 9);
      expect(activity.collectedInYourAreas, '224505.90');
      expect(activity.finesAmount, '15000.00');
      expect(activity.since, DateTime.parse('2026-08-01'));
    });
  });

  group('defaulters', () {
    test('reads a card whole, with the amount left as text', () async {
      adapter.reply(<String, dynamic>{'data': <dynamic>[_defaulterCard]});

      final cards = await ApiDefaultersRepository(api: api).defaulters();
      final card = cards.single;

      expect(card.allotmentNo, 'MCQ-AL-00077');
      expect(card.shopNo, 'F-3');
      expect(card.marketName, 'Prince Road Market');
      expect(card.allotteeName, 'Abdul Sattar Tareen (4)');
      expect(card.outstanding, '175200.00');
      expect(card.monthsBehind, 5);
      expect(card.neverPaid, isTrue);
      expect(card.hasOpenCase, isFalse);
      expect(card.isSealed, isFalse);
      expect(card.map!.latitude, '30.1889400');
      expect(card.map!.latitudeValue, closeTo(30.18894, 0.000001));
    });

    test('sends never_paid as 1 and omits the filters left unset', () async {
      adapter.reply(<String, dynamic>{'data': <dynamic>[]});

      await ApiDefaultersRepository(api: api).defaulters(
        neverPaid: true,
        areaId: 2,
      );

      final query = adapter.lastOptions!.queryParameters;
      expect(query['never_paid'], 1);
      expect(query['area_id'], 2);
      expect(query.containsKey('search'), isFalse);
      expect(query.containsKey('limit'), isFalse);
    });

    test('reads the round grouped by bazaar', () async {
      adapter.reply(<String, dynamic>{
        'data': <dynamic>[
          <String, dynamic>{
            'market_name': 'Liaquat Bazaar',
            'area_name': 'Jinnah Road',
            'area_id': 1,
            'shops': 25,
            'broken_promises': 0,
            'never_paid': 14,
            'sealed': 0,
            'outstanding': '887458.10',
            'stops': <dynamic>[_defaulterCard],
          },
        ],
      });

      final round = await ApiDefaultersRepository(api: api).round();

      expect(round.single.marketName, 'Liaquat Bazaar');
      expect(round.single.shops, 25);
      expect(round.single.outstanding, '887458.10');
      expect(round.single.stops.single.outstanding, '175200.00');
    });

    test('follow-ups pass the state through', () async {
      adapter.reply(<String, dynamic>{'data': <dynamic>[]});
      await ApiDefaultersRepository(api: api).followUps(state: FollowUpState.due);
      expect(adapter.lastOptions!.queryParameters['state'], 'due');
    });
  });

  group('search and map', () {
    test('a unit card says when the fine form must collect an offender', () async {
      adapter.reply(<String, dynamic>{
        'data': <dynamic>[
          <String, dynamic>{
            'property_id': 87,
            'property_code': 'MCQ-PR-000803',
            'shop_no': 'F-3',
            'occupancy_status': 'allotted',
            'area_id': 2,
            'area_name': 'Prince Road',
            'market_name': 'Prince Road Market',
            'is_vacant': false,
            'allotment_id': 77,
            'allotment_no': 'MCQ-AL-00077',
            'allottee_id': 77,
            'allottee_name': 'Abdul Sattar Tareen (4)',
            'mobile_no': '03301000076',
            'cnic': '5440010010412',
            'outstanding': '175200.00',
            'last_payment_date': null,
            'open_case_id': null,
            'seal_no': null,
            'is_sealed': false,
            'can_fine_holder': true,
            'needs_offender_details': false,
            'map': <String, dynamic>{
              'latitude': '30.1889400',
              'longitude': '67.0123300',
            },
          },
        ],
      });

      final unit = (await ApiUnitsRepository(api: api).units(search: 'F-3')).single;

      expect(adapter.lastOptions!.queryParameters['search'], 'F-3');
      expect(unit.canFineHolder, isTrue);
      expect(unit.needsOffenderDetails, isFalse);
      expect(unit.isVacant, isFalse);
      expect(unit.outstanding, '175200.00');
    });

    test('map pins read lat/lng and carry the truncation warning', () async {
      adapter.reply(<String, dynamic>{
        'data': <String, dynamic>{
          'pins': <dynamic>[
            <String, dynamic>{
              'property_id': 87,
              'property_code': 'MCQ-PR-000803',
              'shop_no': 'F-3',
              'lat': '30.1889400',
              'lng': '67.0123300',
              'category_name': 'Building / Plaza Unit',
              'area_name': 'Prince Road',
              'market_name': 'Prince Road Market',
              'occupancy_status': 'allotted',
              'physical_status': 'open',
              'outstanding': '175200.00',
              'unpaid_months': 0,
              'sealed': false,
              'severity': 'owing',
            },
          ],
          'meta': <String, dynamic>{
            'returned': 55,
            'total': 55,
            'truncated': false,
            'limit': 2000,
            'unmapped': 0,
          },
        },
      });

      final pins = await ApiReportingRepository(api: api).mapPins(defaultersOnly: true);

      expect(adapter.lastOptions!.queryParameters['defaulters_only'], 1);
      expect(pins.pins.single.severity, 'owing');
      expect(pins.pins.single.hasFix, isTrue);
      expect(pins.pins.single.outstanding, '175200.00');
      expect(pins.meta.total, 55);
      expect(pins.meta.truncated, isFalse);
    });

    test('a vacant unit profile parses with no holder', () async {
      adapter.reply(_profileResponse);

      final profile = await ApiReportingRepository(api: api).propertyProfile(8);

      expect(adapter.lastOptions!.path, '/api/v1/reporting/properties/8/profile');
      expect(profile.property.propertyCode, 'MCQ-JR-000108');
      expect(profile.property.register949Ref, '949/JR/0108');
      expect(profile.isVacant, isTrue);
      expect(profile.allottee, isNull);
      expect(profile.position.totalOutstanding, '0.00');
      expect(profile.position.hasEverPaid, isFalse);
      expect(profile.enforcement.isSealed, isFalse);
      expect(profile.enforcement.hasOpenCase, isFalse);
      expect(profile.challans, isEmpty);
      expect(profile.arrearsPlan, isNull);
    });
  });

  group('cases and the timeline', () {
    test('reads a paged case list and its labelled statuses', () async {
      adapter.reply(_casesResponse);

      final page = await ApiEnforcementCaseRepository(api: api).cases(perPage: 2);
      final first = page.items.first;

      expect(page.meta.total, 12);
      expect(page.meta.lastPage, 6);
      expect(page.hasMore, isTrue);
      expect(page.nextPage, 2);

      expect(first.caseNo, 'MCQ-EC-2627-00011');
      expect(first.status!.label, 'Warned');
      expect(first.status!.tone, 'warning');
      expect(first.amounts.outstandingAtOpen, '92400.00');
      expect(first.position.outstandingNow, '92400.00');
      expect(first.position.direction, 'level');
      expect(first.canSeal, isTrue);
      expect(first.property!.displayName, 'Shop S-19, Liaquat Bazaar');
      expect(first.property!.physicalStatus!.label, 'Open');
      expect(first.allottee!.fullName, 'Naseem Akhtar Bugti');
      expect(first.area!.code, 'JR', reason: 'a case spells this area_code');
      expect(first.magistrate!.name, 'Habibullah Tareen');
      expect(first.actionCount, 3);
    });

    test('assignedToMe sends magistrate_id=me', () async {
      adapter.reply(<String, dynamic>{'data': <dynamic>[], 'meta': <String, dynamic>{}});
      await ApiEnforcementCaseRepository(api: api).cases(assignedToMe: true);
      expect(adapter.lastOptions!.queryParameters['magistrate_id'], 'me');
    });

    test('reads the visit timeline', () async {
      adapter.reply(<String, dynamic>{
        'data': <dynamic>[
          <String, dynamic>{
            'id': 3,
            'enforcement_case_id': 1,
            'action_type': <String, dynamic>{
              'value': 'fine_imposed',
              'label': 'Fine imposed',
              'tone': 'info',
            },
            'action_date': '2026-08-26',
            'amounts': <String, dynamic>{
              'outstanding_at_action': null,
              'fine_amount': '5000.00',
            },
            'promised_payment_date': null,
            'next_visit_date': null,
            'seal_no': null,
            'location': <String, dynamic>{
              'latitude': null,
              'longitude': null,
              'accuracy_m': null,
              'has_fix': false,
            },
            'photo_path': null,
            'signature_path': null,
            'witness_name': null,
            'remarks': 'Demonstration fine.',
            'sync': <String, dynamic>{
              'recorded_offline': false,
              'device_recorded_at': null,
              'synced_at': '2026-08-26T08:42:09+00:00',
              'lag_minutes': null,
              'client_action_uuid': null,
            },
            'performed_by': <String, dynamic>{'id': 5, 'name': 'Habibullah Tareen'},
          },
        ],
      });

      final action =
          (await ApiEnforcementCaseRepository(api: api).actions(1)).single;

      expect(adapter.lastOptions!.path, '/api/v1/enforcement/cases/1/actions');
      expect(action.actionType!.label, 'Fine imposed');
      expect(action.amounts.fineAmount, '5000.00');
      expect(action.location.hasFix, isFalse);
      expect(action.sync.recordedOffline, isFalse);
      expect(action.performedBy!.name, 'Habibullah Tareen');
    });

    test('records a promise to pay and echoes the idempotency key', () async {
      adapter.reply(_actionCreatedResponse, statusCode: 201);

      final request = EnforcementActionRequest(
        actionType: EnforcementActionType.paymentPromised,
        actionDate: DateTime(2026, 8, 31),
        promisedPaymentDate: DateTime(2026, 9, 10),
        remarks: 'Said he would pay after the wedding season.',
        clientActionUuid: 'a1b2c3d4e5f6a7b8',
      );

      final action = await ApiEnforcementCaseRepository(
        api: api,
      ).recordAction(1, request);

      final body = adapter.lastOptions!.data as Map<String, dynamic>;
      expect(body['action_type'], 'payment_promised');
      expect(body['action_date'], '2026-08-31');
      expect(body['promised_payment_date'], '2026-09-10');
      expect(body['client_action_uuid'], 'a1b2c3d4e5f6a7b8');
      expect(body.containsKey('next_visit_date'), isFalse);

      expect(action.actionType!.label, 'Promised to pay');
      expect(action.amounts.outstandingAtAction, '6241.10');
      expect(action.sync.clientActionUuid, 'a1b2c3d4e5f6a7b8');
    });

    test('a retry of the same request reuses its uuid', () {
      final request = EnforcementActionRequest(
        actionType: EnforcementActionType.siteVisit,
      );

      final first = request.toJson()['client_action_uuid'] as String;
      final second = request.toJson()['client_action_uuid'] as String;

      expect(first, second);
      expect(first, matches(RegExp(r'^[A-Za-z0-9_\-]{8,64}$')));
      expect(
        EnforcementActionRequest(
          actionType: EnforcementActionType.siteVisit,
        ).clientActionUuid,
        isNot(first),
        reason: 'a rebuilt request is a different write',
      );
    });
  });

  group('fines', () {
    test('imposes a fine on the holder and reads the challan back', () async {
      adapter.reply(_fineCreatedResponse, statusCode: 201);

      final fine = await ApiFineRepository(api: api).impose(
        propertyId: 2,
        request: FineRequest(
          fineType: 'unauthorised_use',
          fineAmount: '3000.00',
          legalProvision: 'Section 12(3) of the Local Government Act',
          imposedOn: DateTime(2026, 8, 31),
          remarks: 'Trading outside the permitted hours.',
          clientActionUuid: 'b2c3d4e5f6a7b8c9',
        ),
      );

      expect(adapter.lastOptions!.path, '/api/v1/enforcement/properties/2/fines');
      final body = adapter.lastOptions!.data as Map<String, dynamic>;
      expect(body['fine_amount'], '3000.00');
      expect(body['imposed_on'], '2026-08-31');
      expect(body.containsKey('seal'), isFalse);
      expect(body.containsKey('offender_name'), isFalse);

      expect(fine.fineNo, 'MCQ-FN-2627-00008');
      expect(fine.fineType!.label, 'Used the unit without permission');
      expect(fine.amounts.fineAmount, '3000.00');
      expect(fine.amounts.fieldLimit, '10000.00');
      expect(fine.requiresApproval, isFalse);
      expect(fine.payer!.isNamedOffender, isFalse);
      expect(fine.payer!.name, 'Muhammad Iqbal Achakzai');
      expect(fine.challan!.challanNo, 'MCQ-CH-2627-0000404');
      expect(fine.challan!.balanceAmount, '3000.00');
      expect(fine.challan!.hasLiveLink, isTrue);
      expect(
        fine.sealApplied,
        isFalse,
        reason: 'no seal was asked for on this one',
      );
    });

    test('an offender fine sends all three identity fields together', () async {
      adapter.reply(_offenderFineResponse, statusCode: 201);

      final fine = await ApiFineRepository(api: api).impose(
        propertyId: 8,
        request: FineRequest(
          fineType: 'encroachment',
          fineAmount: '5000.00',
          legalProvision: 'Section 14 of the Local Government Act',
          offender: const FineOffender(
            name: 'Nadeem Ahmed',
            fatherName: 'Abdul Rasheed',
            mobileNo: '03001234567',
            cnic: '54400-1234567-1',
            business: 'Fruit stall, handcart',
            address: 'Footpath outside Shop 12, Liaquat Bazaar',
          ),
        ),
      );

      final body = adapter.lastOptions!.data as Map<String, dynamic>;
      expect(body['offender_name'], 'Nadeem Ahmed');
      expect(body['offender_father_name'], 'Abdul Rasheed');
      expect(body['offender_mobile_no'], '03001234567');

      expect(fine.payer!.isNamedOffender, isTrue);
      expect(fine.payer!.fatherName, 'Abdul Rasheed');
      expect(fine.allotment, isNull);
    });

    test('a fine with a seal nests the seal under its own key', () async {
      adapter.reply(_fineCreatedResponse, statusCode: 201);

      await ApiFineRepository(api: api).impose(
        propertyId: 2,
        request: FineRequest(
          fineType: 'unauthorised_use',
          fineAmount: '3000.00',
          legalProvision: 'Section 12(3) of the Local Government Act',
          seal: FineSealRequest(
            sealReason: 'Arrears unpaid after final notice.',
            sealedOn: DateTime(2026, 8, 31),
          ),
        ),
      );

      final body = adapter.lastOptions!.data as Map<String, dynamic>;
      final seal = body['seal'] as Map<String, dynamic>;
      expect(seal['seal_reason'], 'Arrears unpaid after final notice.');
      expect(seal['sealed_on'], '2026-08-31');
    });

    test('uploads evidence as multipart before the write that cites it', () async {
      final file = File(
        '${Directory.systemTemp.createTempSync('mcq').path}/seal.jpg',
      )..writeAsBytesSync(<int>[9, 9, 9]);

      adapter.reply(<String, dynamic>{
        'data': <String, dynamic>{'path': 'evidence/2026/08/seal.jpg', 'kind': 'photo'},
      }, statusCode: 201);

      final upload = await ApiEvidenceRepository(api: api).upload(
        filePath: file.path,
        mimeType: 'image/jpeg',
      );

      expect(adapter.lastOptions!.path, '/api/v1/enforcement/evidence');
      final form = adapter.lastOptions!.data as FormData;
      expect(Map<String, String>.fromEntries(form.fields)['kind'], 'photo');
      expect(upload.hasPath, isTrue);
      expect(upload.path, 'evidence/2026/08/seal.jpg');
    });
  });

  group('seals', () {
    test('the unseal queue asks for ready=1', () async {
      adapter.reply(<String, dynamic>{'data': <dynamic>[]});
      await ApiFieldSealRepository(api: api).seals(readyOnly: true);
      expect(adapter.lastOptions!.queryParameters['ready'], 1);

      adapter.reply(<String, dynamic>{'data': <dynamic>[]});
      await ApiFieldSealRepository(api: api).seals();
      expect(adapter.lastOptions!.queryParameters.containsKey('ready'), isFalse);
    });

    test('a seal row reads leniently and keeps the raw payload', () async {
      adapter.reply(<String, dynamic>{
        'data': <dynamic>[
          <String, dynamic>{
            'id': 4,
            'seal_no': 'MCQ-SL-2627-00004',
            'seal_status': 'applied',
            'sealed_on': '2026-08-28',
            'seal_reason': 'Arrears unpaid after final notice.',
            'ready_to_release': true,
            'property_id': 19,
            'shop_no': 'S-19',
            'area_name': 'Jinnah Road',
            'allottee_name': 'Naseem Akhtar Bugti',
            'outstanding': '92400.00',
            'some_field_not_yet_modelled': 'kept in raw',
          },
        ],
      });

      final seal = (await ApiFieldSealRepository(api: api).seals()).single;

      expect(seal.sealNo, 'MCQ-SL-2627-00004');
      expect(seal.status!.value, 'applied');
      expect(seal.readyToRelease, isTrue);
      expect(seal.outstanding, '92400.00');
      expect(seal.raw['some_field_not_yet_modelled'], 'kept in raw');
    });

    test('releasing a seal sends the reason and the override', () async {
      adapter.reply(<String, dynamic>{'data': <String, dynamic>{'id': 4}});

      await ApiFieldSealRepository(api: api).release(
        4,
        SealReleaseRequest(
          unsealReason: 'Fine paid in full, receipt MCQ-RC-2627-00123.',
          overrideReason: 'Deputy Commissioner directed release pending appeal.',
          unsealedOn: DateTime(2026, 8, 31),
        ),
      );

      expect(adapter.lastOptions!.path, '/api/v1/enforcement/seals/4/release');
      final body = adapter.lastOptions!.data as Map<String, dynamic>;
      expect(body['unseal_reason'], contains('MCQ-RC-2627-00123'));
      expect(body['override_reason'], contains('Deputy Commissioner'));
      expect(body['unsealed_on'], '2026-08-31');
    });

    test('sealing a case sends the reason', () async {
      adapter.reply(<String, dynamic>{'data': <String, dynamic>{'id': 5}}, statusCode: 201);

      await ApiEnforcementCaseRepository(api: api).seal(
        11,
        CaseSealRequest(
          sealReason: 'Arrears unpaid after final notice.',
          sealedOn: DateTime(2026, 8, 31),
        ),
      );

      expect(adapter.lastOptions!.path, '/api/v1/enforcement/cases/11/seal');
      final body = adapter.lastOptions!.data as Map<String, dynamic>;
      expect(body['seal_reason'], 'Arrears unpaid after final notice.');
      expect(body['sealed_on'], '2026-08-31');
    });

    test('a too-short reason is rejected before it reaches the server', () {
      expect(
        () => CaseSealRequest(sealReason: 'unpaid'),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => SealReleaseRequest(unsealReason: 'paid', overrideReason: null),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('challans', () {
    test('a fine challan reads as one charge, not a rent breakdown', () async {
      adapter.reply(_challansResponse);

      final page = await ApiChallanRepository(api: api).challans(
        perPage: 1,
        challanType: ChallanRepository.typeFine,
      );
      final challan = page.items.single;

      expect(adapter.lastOptions!.queryParameters['challan_type'], 'fine');
      expect(challan.challanNo, 'MCQ-CH-2627-0000405');
      expect(challan.isFine, isTrue);
      expect(challan.isSingleCharge, isTrue);
      expect(challan.status!.label, 'Sent out');
      expect(challan.amounts.otherAmount, '5000.00');
      expect(challan.amounts.currentAmount, '0.00');
      expect(challan.amounts.payableNow, '5000.00');
      expect(challan.hasLiveLink, isTrue);
      expect(challan.linkShortCode, 'RUP7EVZS');
      expect(challan.isSettled, isFalse);
      expect(challan.allottee, isNull, reason: 'raised against a named offender');
      expect(challan.area!.code, 'JR', reason: 'a challan spells this plain code');
      expect(challan.billingPeriod!.periodCode, '2026-08');
      expect(page.meta.total, 193);
    });
  });
}

// --- Captured payloads, copied from the published API document. ---

const Map<String, dynamic> _sessionUser = <String, dynamic>{
  'id': '5',
  'username': 'magistrate',
  'name': 'Habibullah Tareen',
  'employee_no': null,
  'designation': 'Municipal Magistrate',
  'mobile_no': '03001234504',
  'email': 'magistrate@mcq.test',
  'branch_id': null,
  'locale': 'ur',
  'avatar_url': null,
  'must_change_password': false,
  'is_active': true,
  'is_locked': false,
  'last_login_at': null,
  'password_changed_at': null,
  'permissions': <String>[
    'allotment.view',
    'billing.challan.view',
    'enforcement.action.record',
    'enforcement.fine.impose',
    'enforcement.seal.apply',
    'enforcement.seal.release',
    'property.view',
    'reporting.dashboard.view',
  ],
  'roles': <String>['MAGISTRATE'],
  'created_at': '2026-08-26T08:40:34+00:00',
};

const Map<String, dynamic> _defaulterCard = <String, dynamic>{
  'allotment_id': 77,
  'allotment_no': 'MCQ-AL-00077',
  'property_id': 87,
  'property_code': 'MCQ-PR-000803',
  'shop_no': 'F-3',
  'area_id': 2,
  'area_name': 'Prince Road',
  'market_name': 'Prince Road Market',
  'allottee_id': 77,
  'allottee_name': 'Abdul Sattar Tareen (4)',
  'mobile_no': '03301000076',
  'cnic': '5440010010412',
  'outstanding': '175200.00',
  'months_behind': 5,
  'days_overdue': null,
  'never_paid': true,
  'last_payment_date': null,
  'commitment': null,
  'next_visit_date': null,
  'open_case_id': null,
  'seal_no': null,
  'is_sealed': false,
  'map': <String, dynamic>{'latitude': '30.1889400', 'longitude': '67.0123300'},
};

const Map<String, dynamic> _beatResponse = <String, dynamic>{
  'data': <String, dynamic>{
    'officer': <String, dynamic>{
      'id': '5',
      'name': 'Habibullah Tareen',
      'designation': 'Municipal Magistrate',
      'mobile_no': '03001234504',
    },
    'scope': <String, dynamic>{
      'restricted': true,
      'areas': <dynamic>[
        <String, dynamic>{
          'id': 1,
          'area_name': 'Jinnah Road',
          'area_code': 'JR',
          'zone_id': 1,
          'zone_name': 'Zone 1 - Zarghoon',
        },
        <String, dynamic>{
          'id': 2,
          'area_name': 'Prince Road',
          'area_code': 'PR',
          'zone_id': 1,
          'zone_name': 'Zone 1 - Zarghoon',
        },
      ],
      'area_names': <String>['Jinnah Road', 'Prince Road'],
      'zone_names': <String>['Zone 1 - Zarghoon'],
    },
    'queues': <dynamic>[
      <String, dynamic>{
        'key': 'defaulters',
        'count': 55,
        'amount': '2213409.10',
        'endpoint': 'enforcement/field/defaulters',
        'tone': 'danger',
      },
      <String, dynamic>{
        'key': 'follow_ups_due',
        'count': 0,
        'amount': null,
        'endpoint': 'enforcement/field/follow-ups?state=due',
        'tone': 'warning',
      },
      <String, dynamic>{
        'key': 'awaiting_unseal',
        'count': 0,
        'amount': null,
        'endpoint': 'enforcement/field/seals?ready=1',
        'tone': 'info',
      },
      <String, dynamic>{
        'key': 'sealed_shops',
        'count': 0,
        'amount': null,
        'endpoint': 'enforcement/field/seals',
        'tone': 'neutral',
      },
      <String, dynamic>{
        'key': 'open_cases',
        'count': 12,
        'amount': null,
        'endpoint': 'enforcement/cases',
        'tone': 'neutral',
      },
      <String, dynamic>{
        'key': 'assigned_to_me',
        'count': 12,
        'amount': null,
        'endpoint': 'enforcement/cases?magistrate_id=me',
        'tone': 'primary',
      },
    ],
    'generated_at': '2026-08-31T23:48:34+00:00',
  },
};

const Map<String, dynamic> _profileResponse = <String, dynamic>{
  'data': <String, dynamic>{
    'property': <String, dynamic>{
      'id': 8,
      'property_code': 'MCQ-JR-000108',
      'category_name': 'Shop',
      'zone_name': 'Zone 1 - Zarghoon',
      'area_name': 'Jinnah Road',
      'market_name': 'Liaquat Bazaar',
      'shop_no': 'S-8',
      'street_address': 'Shop S-8, Liaquat Bazaar, Jinnah Road, Quetta',
      'latitude': '30.1897234',
      'longitude': '67.0101876',
      'has_coordinates': true,
      'occupancy_status': 'vacant',
      'physical_status': 'open',
      'register_949_ref': '949/JR/0108',
    },
    'allotment': null,
    'allottee': null,
    'position': <String, dynamic>{
      'current_due': '0.00',
      'arrears_due': '0.00',
      'surcharge_due': '0.00',
      'total_outstanding': '0.00',
      'total_collected': '0.00',
      'last_payment_date': null,
      'unpaid_months': 0,
    },
    'enforcement': <String, dynamic>{
      'seal_no': null,
      'sealed_on': null,
      'seal_status': null,
      'is_sealed': false,
      'open_case_no': null,
      'case_status': null,
      'open_legal_cases': 0,
    },
    'challans': <dynamic>[],
    'payments': <dynamic>[],
    'arrears_plan': null,
  },
};

const Map<String, dynamic> _casesResponse = <String, dynamic>{
  'data': <dynamic>[
    <String, dynamic>{
      'id': 11,
      'case_no': 'MCQ-EC-2627-00011',
      'status': <String, dynamic>{
        'value': 'warned',
        'label': 'Warned',
        'tone': 'warning',
      },
      'priority': <String, dynamic>{
        'value': 'normal',
        'label': 'Normal',
        'tone': 'neutral',
      },
      'opened_on': '2026-08-26',
      'closed_on': null,
      'next_visit_date': null,
      'amounts': <String, dynamic>{'outstanding_at_open': '92400.00'},
      'position': <String, dynamic>{
        'outstanding_now': '92400.00',
        'direction': 'level',
      },
      'unpaid_months': 5,
      'closing_remarks': null,
      'is_live': true,
      'is_sealed': false,
      'visit_overdue': false,
      'can_seal': true,
      'can_close': true,
      'property': <String, dynamic>{
        'id': 19,
        'property_code': 'MCQ-JR-000119',
        'display_name': 'Shop S-19, Liaquat Bazaar',
        'physical_status': <String, dynamic>{
          'value': 'open',
          'label': 'Open',
          'tone': 'info',
        },
      },
      'allotment': <String, dynamic>{'id': 17, 'allotment_no': 'MCQ-AL-00017'},
      'allottee': <String, dynamic>{
        'id': 17,
        'allottee_code': 'ALT-00017',
        'full_name': 'Naseem Akhtar Bugti',
        'mobile_no': '03301000016',
      },
      'area': <String, dynamic>{
        'id': 1,
        'area_code': 'JR',
        'area_name': 'Jinnah Road',
      },
      'magistrate': <String, dynamic>{'id': 5, 'name': 'Habibullah Tareen'},
      'is_assigned': true,
      'action_count': 3,
      'fine_count': 0,
      'created_at': '2026-08-26T08:42:09+00:00',
      'updated_at': '2026-08-26T08:42:09+00:00',
    },
  ],
  'meta': <String, dynamic>{
    'current_page': 1,
    'per_page': 2,
    'from': 1,
    'to': 2,
    'last_page': 6,
    'total': 12,
  },
};

const Map<String, dynamic> _actionCreatedResponse = <String, dynamic>{
  'data': <String, dynamic>{
    'id': 30,
    'enforcement_case_id': 1,
    'action_type': <String, dynamic>{
      'value': 'payment_promised',
      'label': 'Promised to pay',
      'tone': 'neutral',
    },
    'action_date': '2026-08-31',
    'amounts': <String, dynamic>{
      'outstanding_at_action': '6241.10',
      'fine_amount': null,
    },
    'promised_payment_date': '2026-09-10',
    'next_visit_date': null,
    'seal_no': null,
    'location': <String, dynamic>{
      'latitude': null,
      'longitude': null,
      'accuracy_m': null,
      'has_fix': false,
    },
    'photo_path': null,
    'signature_path': null,
    'witness_name': null,
    'remarks': 'Said he would pay after the wedding season.',
    'sync': <String, dynamic>{
      'recorded_offline': false,
      'device_recorded_at': null,
      'synced_at': '2026-08-31T23:48:35+00:00',
      'lag_minutes': null,
      'client_action_uuid': 'a1b2c3d4e5f6a7b8',
    },
    'performed_by': <String, dynamic>{'id': 5, 'name': 'Habibullah Tareen'},
  },
  'message': 'Action recorded.',
};

const Map<String, dynamic> _fineCreatedResponse = <String, dynamic>{
  'data': <String, dynamic>{
    'id': 8,
    'fine_no': 'MCQ-FN-2627-00008',
    'fine_type': <String, dynamic>{
      'value': 'unauthorised_use',
      'label': 'Used the unit without permission',
      'tone': 'neutral',
    },
    'status': <String, dynamic>{
      'value': 'billed',
      'label': 'Added to a challan',
      'tone': 'info',
    },
    'amounts': <String, dynamic>{
      'fine_amount': '3000.00',
      'field_limit': '10000.00',
    },
    'imposed_on': '2026-08-31',
    'legal_provision': 'Section 12(3) of the Local Government Act',
    'remarks': 'Trading outside the permitted hours.',
    'requires_approval': false,
    'is_effective': true,
    'can_cancel': true,
    'challan_id': 1188,
    'waiver_adjustment_id': null,
    'payer': <String, dynamic>{
      'kind': 'allottee',
      'allottee_id': 2,
      'name': 'Muhammad Iqbal Achakzai',
      'mobile_no': '03362849049',
      'cnic': null,
    },
    'imposed_by': <String, dynamic>{'id': 5, 'name': 'Habibullah Tareen'},
    'property': <String, dynamic>{
      'id': 2,
      'property_code': 'MCQ-JR-000102',
      'display_name': 'Shop S-2, Liaquat Bazaar',
    },
    'allotment': <String, dynamic>{'id': 2, 'allotment_no': 'MCQ-AL-00002'},
    'enforcement_case': null,
    'challan': <String, dynamic>{
      'id': 1188,
      'challan_no': 'MCQ-CH-2627-0000404',
      'balance_amount': '3000.00',
      'due_date': '2026-09-15',
      'consumer_no': 'DRTRMNMD',
      'has_live_link': true,
    },
    'created_at': '2026-08-31T23:48:34+00:00',
    'seal': null,
  },
  'message': 'Fine imposed and payable. The allottee has been told.',
};

const Map<String, dynamic> _offenderFineResponse = <String, dynamic>{
  'data': <String, dynamic>{
    'id': 9,
    'fine_no': 'MCQ-FN-2627-00009',
    'fine_type': <String, dynamic>{
      'value': 'encroachment',
      'label': 'Encroachment',
      'tone': 'neutral',
    },
    'status': <String, dynamic>{
      'value': 'billed',
      'label': 'Added to a challan',
      'tone': 'info',
    },
    'amounts': <String, dynamic>{
      'fine_amount': '5000.00',
      'field_limit': '10000.00',
    },
    'imposed_on': '2026-08-31',
    'legal_provision': 'Section 14 of the Local Government Act',
    'remarks': 'Selling on the footpath, obstructing the walkway.',
    'requires_approval': false,
    'is_effective': true,
    'can_cancel': true,
    'challan_id': 1189,
    'waiver_adjustment_id': null,
    'payer': <String, dynamic>{
      'kind': 'named',
      'allottee_id': null,
      'name': 'Nadeem Ahmed',
      'father_name': 'Abdul Rasheed',
      'mobile_no': '03001234567',
      'cnic': '54400-1234567-1',
      'business': 'Fruit stall, handcart',
      'address': 'Footpath outside Shop 12, Liaquat Bazaar',
    },
    'imposed_by': <String, dynamic>{'id': 5, 'name': 'Habibullah Tareen'},
    'property': <String, dynamic>{
      'id': 8,
      'property_code': 'MCQ-JR-000108',
      'display_name': 'Shop S-8, Liaquat Bazaar',
    },
    'allotment': null,
    'enforcement_case': null,
    'challan': <String, dynamic>{
      'id': 1189,
      'challan_no': 'MCQ-CH-2627-0000405',
      'balance_amount': '5000.00',
      'due_date': '2026-09-15',
      'consumer_no': 'RUP7EVZS',
      'has_live_link': true,
    },
    'created_at': '2026-08-31T23:48:34+00:00',
    'seal': null,
  },
  'message': 'Fine imposed and payable. The allottee has been told.',
};

const Map<String, dynamic> _challansResponse = <String, dynamic>{
  'data': <dynamic>[
    <String, dynamic>{
      'id': 1189,
      'challan_no': 'MCQ-CH-2627-0000405',
      'challan_type': <String, dynamic>{
        'value': 'fine',
        'label': 'Fine',
        'tone': 'neutral',
      },
      'is_single_charge': true,
      'surcharge_exempt': false,
      'surcharge_exempt_reason': null,
      'status': <String, dynamic>{
        'value': 'dispatched',
        'label': 'Sent out',
        'tone': 'info',
      },
      'issue_date': '2026-08-31',
      'due_date': '2026-09-15',
      'is_overdue': false,
      'days_overdue': 0,
      'amounts': <String, dynamic>{
        'previous_balance': '0.00',
        'current_amount': '0.00',
        'arrears_amount': '0.00',
        'surcharge_amount': '0.00',
        'other_amount': '5000.00',
        'adjustment_amount': '0.00',
        'total_amount': '5000.00',
        'paid_amount': '0.00',
        'balance_amount': '5000.00',
        'deferred_amount': '0.00',
        'payable_now': '5000.00',
      },
      'is_prorated': false,
      'proration_days': null,
      'is_edited': false,
      'remarks':
          'Enforcement fine MCQ-FN-2627-00009. Payable in full by the due date shown.',
      'consumer_number': '00000RUP7EVZS',
      'link_short_code': 'RUP7EVZS',
      'link_expires_at': '2026-10-15T23:48:34+00:00',
      'has_live_link': true,
      'can_defer': false,
      'dispatched_at': '2026-08-31T23:48:34+00:00',
      'first_paid_at': null,
      'settled_at': null,
      'superseded_by_challan_id': null,
      'billing_period': <String, dynamic>{
        'id': 6,
        'period_code': '2026-08',
        'fiscal_year': '2026-2027',
      },
      'allotment': null,
      'allottee': null,
      'property': <String, dynamic>{
        'id': 8,
        'property_code': 'MCQ-JR-000108',
        'display_name': 'Shop S-8, Liaquat Bazaar',
      },
      'area': <String, dynamic>{'id': 1, 'code': 'JR', 'name': 'Jinnah Road'},
      'created_at': '2026-08-31T23:48:34+00:00',
      'updated_at': '2026-08-31T23:48:34+00:00',
    },
  ],
  'meta': <String, dynamic>{
    'current_page': 1,
    'per_page': 1,
    'from': 1,
    'to': 1,
    'last_page': 193,
    'total': 193,
  },
};
