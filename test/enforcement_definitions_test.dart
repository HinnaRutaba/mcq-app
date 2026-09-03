import 'package:flutter_test/flutter_test.dart';
import 'package:mcq_app/core/network/api_service.dart';
import 'package:mcq_app/data/repositories/definitions_repository.dart';
import 'package:mcq_app/data/repositories/enforcement_case_repository.dart';
import 'package:mcq_app/data/repositories/fine_repository.dart';
import 'package:mcq_app/data/repositories/person_repository.dart';
import 'package:mcq_app/models/models.dart';

import 'support/api_stub.dart';

/// The master data, the person lookup, and the two writes the enforcement
/// module gained: a fine on somebody with no MCQ unit, and opening a case from
/// the handset.
///
/// Every payload below is copied from the published API document, which
/// captured them from live calls. If the app can read these, it can read the
/// server.
void main() {
  late ApiStub adapter;
  late ApiService api;

  setUp(() {
    final stubbed = StubbedApi();
    adapter = stubbed.stub;
    api = stubbed.service;
  });

  group('master data', () {
    test('reads the fine types, with their provisions and amounts', () async {
      adapter.reply(_definitionsResponse);

      final definitions = await ApiDefinitionsRepository(
        api: api,
      ).definitions();

      expect(adapter.lastOptions!.path, '/api/v1/enforcement/definitions');
      expect(definitions.fineTypes, hasLength(5));

      final seal = definitions.fineType('seal_violation')!;
      expect(seal.id, 2);
      expect(seal.name, 'Breaking a seal');
      expect(seal.nameUr, 'سیل کی خلاف ورزی');
      expect(
        seal.defaultProvision,
        'Section 98, Balochistan Local Government Act 2010',
      );
      expect(
        seal.suggestedAmount,
        '25000.00',
        reason: 'a suggested amount is money, and money is a string',
      );
    });

    test('the one offence with no provision says so, rather than ""', () async {
      adapter.reply(_definitionsResponse);

      final definitions = await ApiDefinitionsRepository(
        api: api,
      ).definitions();

      // `other` is the category the officer has to write the section for
      // themselves; a blank provision cannot be enforced.
      expect(definitions.fineType('other')!.defaultProvision, isNull);
      expect(definitions.fineType('encroachment')!.defaultProvision, isNotNull);
    });

    test('an action type carries the form to draw for it', () async {
      adapter.reply(_definitionsResponse);

      final definitions = await ApiDefinitionsRepository(
        api: api,
      ).definitions();

      final promised = definitions.actionType('payment_promised')!;
      expect(promised.id, 5);
      expect(promised.fields.promiseDate, isTrue);
      expect(promised.fields.visitDate, isFalse);

      final revisit = definitions.actionType('reminder_visit_set')!;
      expect(revisit.fields.visitDate, isTrue);
      expect(revisit.fields.promiseDate, isFalse);

      // A plain visit needs nothing but a date and remarks.
      expect(definitions.actionType('site_visit')!.fields.hasAny, isFalse);
    });

    test('the entries the server writes itself are still listed', () async {
      adapter.reply(_definitionsResponse);

      final definitions = await ApiDefinitionsRepository(
        api: api,
      ).definitions();

      // `fine_imposed` and `seal` appear on a timeline but are not postable as
      // actions — so they are in the definitions and not in the enum.
      expect(definitions.actionType('fine_imposed')!.fields.amount, isTrue);
      expect(definitions.actionType('seal')!.fields.sealNo, isTrue);
      expect(
        EnforcementActionType.fromCode('fine_imposed'),
        isNull,
        reason: 'the fine endpoint raises it, not the action endpoint',
      );
      expect(
        EnforcementActionType.fromCode('payment_promised'),
        EnforcementActionType.paymentPromised,
      );
    });

    test('the status vocabularies arrive already toned', () async {
      adapter.reply(_definitionsResponse);

      final definitions = await ApiDefinitionsRepository(
        api: api,
      ).definitions();

      expect(definitions.caseStatuses, hasLength(8));
      final recovered = definitions.caseStatus('part_recovered')!;
      expect(recovered.label, 'Some money recovered');
      expect(recovered.tone, 'warning');

      expect(definitions.casePriority('critical')!.label, 'Urgent');
      expect(definitions.sealStatus('unsealed')!.label, 'Reopened');
      expect(definitions.fineStatus('billed')!.label, 'Added to a challan');
    });

    test('it is fetched once and then served from memory', () async {
      adapter.reply(_definitionsResponse);
      final repository = ApiDefinitionsRepository(api: api);

      expect(repository.cached, isNull, reason: 'nobody has asked yet');

      await repository.definitions();
      final firstCall = adapter.lastOptions;
      adapter.lastOptions = null;

      await repository.definitions();
      expect(
        adapter.lastOptions,
        isNull,
        reason: 'the drop-downs do not change while an officer walks a bazaar',
      );
      expect(repository.cached, isNotNull);
      expect(firstCall, isNotNull);
    });

    test('two screens asking at once share one call', () async {
      adapter.reply(_definitionsResponse);
      final repository = ApiDefinitionsRepository(api: api);

      var calls = 0;
      adapter.onRequest = (_) => calls++;

      final results = await Future.wait<EnforcementDefinitions>(
        <Future<EnforcementDefinitions>>[
          repository.definitions(),
          repository.definitions(),
        ],
      );

      expect(calls, 1);
      expect(results.first.fineTypes, hasLength(5));
      expect(results.last.fineTypes, hasLength(5));
    });

    test('a refresh goes back to the wire, and a forget clears it', () async {
      adapter.reply(_definitionsResponse);
      final repository = ApiDefinitionsRepository(api: api);

      await repository.definitions();
      var calls = 0;
      adapter.onRequest = (_) => calls++;

      await repository.definitions(refresh: true);
      expect(calls, 1);

      repository.forget();
      expect(
        repository.cached,
        isNull,
        reason: 'the next officer on this handset may be posted elsewhere',
      );
    });

    test('a failed fetch does not poison every later caller', () async {
      adapter.reply(<String, dynamic>{
        'message': 'Server error',
      }, statusCode: 500);
      final repository = ApiDefinitionsRepository(api: api);

      await expectLater(repository.definitions(), throwsA(anything));

      adapter.reply(_definitionsResponse);
      final recovered = await repository.definitions();
      expect(recovered.fineTypes, hasLength(5));
    });
  });

  group('who is this', () {
    test('reads the registers separately, and the suggestion', () async {
      adapter.reply(_personResponse);

      final person = await ApiPersonRepository(
        api: api,
      ).byCnic('5440010000000');

      expect(adapter.lastOptions!.path, '/api/v1/enforcement/field/person');
      expect(adapter.lastOptions!.queryParameters['cnic'], '5440010000000');

      expect(person.known, isTrue);
      expect(person.allottees.single.fullName, 'Haji Abdul Rauf Kakar');
      expect(person.allottees.single.fatherName, 'Abdul Ghafoor Kakar');
      expect(person.allottees.single.status, 'active');
      expect(person.isOnPropertyRegister, isTrue);
      expect(
        person.isOnTradeRegister,
        isFalse,
        reason: 'a licence and a tenancy are separate registers',
      );

      expect(person.suggested!.name, 'Haji Abdul Rauf Kakar');
      expect(person.suggested!.source, 'allottee');
    });

    test('a first offence is distinguishable from a fifth', () async {
      adapter.reply(_personResponse);

      final person = await ApiPersonRepository(
        api: api,
      ).byCnic('5440010000000');

      expect(person.fineCount, 0);
      expect(person.isRepeatOffender, isFalse);
    });

    test('a CNIC nobody holds is an answer, not a failure', () async {
      adapter.reply(<String, dynamic>{
        'data': <String, dynamic>{
          'searched': '5440099999999',
          'cnic': '5440099999999',
          'known': false,
          'allottees': <Object>[],
          'trade_licences': <Object>[],
          'previous_fines': <Object>[],
          'fine_count': 0,
          'suggested': null,
        },
      });

      final person = await ApiPersonRepository(
        api: api,
      ).byCnic('5440099999999');

      expect(person.known, isFalse);
      expect(person.suggested, isNull);
      expect(person.isOnPropertyRegister, isFalse);
    });

    test('the suggestion pre-fills the offender block on a fine', () async {
      adapter.reply(_personResponse);

      final person = await ApiPersonRepository(
        api: api,
      ).byCnic('5440010000000');
      final offender = FineOffender.fromSuggestion(
        person.suggested!,
        cnic: person.cnic,
      );

      expect(offender.name, 'Haji Abdul Rauf Kakar');
      expect(offender.fatherName, 'Abdul Ghafoor Kakar');
      expect(offender.mobileNo, '03368359506');
      expect(offender.cnic, '5440010000000');
      expect(
        offender.isComplete,
        isTrue,
        reason: 'name, father and mobile are required together',
      );
    });
  });

  group('a fine on somebody with no MCQ unit', () {
    test('goes to the city endpoint, scoped by the bazaar', () async {
      adapter.reply(_cityFineResponse, statusCode: 201);

      final fine = await ApiFineRepository(api: api).imposeInArea(
        request: FineRequest.inArea(
          areaId: 1,
          fineTypeId: 4,
          fineType: 'encroachment',
          fineAmount: '3000.00',
          legalProvision: 'Section 97, Balochistan Local Government Act 2010',
          offender: const FineOffender(
            name: 'Nadeem Hawker',
            fatherName: 'Abdul Rasheed',
            mobileNo: '03001112233',
            cnic: '5440011223344',
            address: 'Handcart, Circular Road',
          ),
          photoPath: 'enforcement/photos/01J.jpg',
          clientActionUuid: 'f1e2d3c4b5a69788',
        ),
      );

      expect(adapter.lastOptions!.path, '/api/v1/enforcement/fines');

      final body = adapter.lastOptions!.data as Map<String, dynamic>;
      expect(body['area_id'], 1);
      expect(body['fine_type'], 'encroachment');
      expect(body['fine_type_id'], 4);
      expect(body['offender_name'], 'Nadeem Hawker');
      expect(body['offender_father_name'], 'Abdul Rasheed');
      expect(body['offender_mobile_no'], '03001112233');
      expect(body['client_action_uuid'], 'f1e2d3c4b5a69788');
      expect(
        body.containsKey('allotment_id'),
        isFalse,
        reason: 'there is no tenancy to bill',
      );

      expect(fine.fineNo, 'MCQ-FN-2627-00009');
      expect(fine.fineTypeId, 4);
      expect(fine.payer!.isNamedOffender, isTrue);
      expect(fine.challan!.balanceAmount, '5000.00');
    });

    test('a fine on a unit sends the seal reference, not an area', () async {
      adapter.reply(_cityFineResponse, statusCode: 201);

      await ApiFineRepository(api: api).impose(
        propertyId: 8,
        request: FineRequest(
          fineType: 'seal_violation',
          fineAmount: '25000.00',
          legalProvision: 'Section 98, Balochistan Local Government Act 2010',
          fineTypeId: 2,
          propertySealId: 14,
        ),
      );

      expect(
        adapter.lastOptions!.path,
        '/api/v1/enforcement/properties/8/fines',
      );
      final body = adapter.lastOptions!.data as Map<String, dynamic>;
      expect(body['property_seal_id'], 14);
      expect(body.containsKey('area_id'), isFalse);
    });
  });

  group('opening a case from the handset', () {
    test('a recovery case names the tenancy and nothing else', () async {
      adapter.reply(_caseOpenedResponse, statusCode: 201);

      final opened = await ApiEnforcementCaseRepository(api: api).openCase(
        const FieldCaseRequest.recovery(
          allotmentId: 17,
          caseReason: 'Six months of rent unpaid after the final notice.',
        ),
      );

      expect(adapter.lastOptions!.path, '/api/v1/enforcement/field/cases');
      final body = adapter.lastOptions!.data as Map<String, dynamic>;
      expect(body['allotment_id'], 17);
      expect(
        body.containsKey('property_id'),
        isFalse,
        reason: 'sending both is refused rather than resolved',
      );
      expect(
        body.containsKey('priority'),
        isFalse,
        reason: 'the server derives it from what is owed',
      );

      expect(opened.caseNo, 'MCQ-EC-2627-00011');
      expect(opened.isConductCase, isFalse);
    });

    test('a conduct case names the unit and what it is about', () async {
      adapter.reply(_caseOpenedResponse, statusCode: 201);

      final request = FieldCaseRequest.conduct(
        propertyId: 1,
        caseType: 'unauthorised_use',
        caseReason: 'Trading in goods the agreement does not permit.',
        priority: 'normal',
        nextVisitDate: DateTime(2026, 9, 20),
      );
      await ApiEnforcementCaseRepository(api: api).openCase(request);

      final body = adapter.lastOptions!.data as Map<String, dynamic>;
      expect(body['property_id'], 1);
      expect(body['case_type'], 'unauthorised_use');
      expect(body['priority'], 'normal');
      expect(body['next_visit_date'], '2026-09-20');
      expect(body.containsKey('allotment_id'), isFalse);
      expect(request.isConductCase, isTrue);
    });
  });

  group('sealing a shop for a fine already on record', () {
    test('names the fine, which is what ties the seal to the debt', () async {
      adapter.reply(<String, dynamic>{
        'data': <String, dynamic>{
          'id': 4,
          'seal_no': 'MCQ-SL-2627-00004',
          'seal_status': <String, dynamic>{
            'value': 'sealed',
            'label': 'Sealed',
            'tone': 'danger',
          },
          'sealed_on': '2026-09-03',
          'ready_to_release': false,
        },
      }, statusCode: 201);

      final seal = await ApiEnforcementCaseRepository(api: api).seal(
        11,
        CaseSealRequest(
          sealReason: 'Arrears unpaid after final notice.',
          sealedOn: DateTime(2026, 9, 3),
          fineId: 26,
          clientActionUuid: 'c3d4e5f6a7b8c9d0',
        ),
      );

      expect(adapter.lastOptions!.path, '/api/v1/enforcement/cases/11/seal');
      final body = adapter.lastOptions!.data as Map<String, dynamic>;
      expect(body['seal_reason'], 'Arrears unpaid after final notice.');
      expect(body['sealed_on'], '2026-09-03');
      expect(
        body['fine_id'],
        26,
        reason:
            'the unseal queue works out from this that the seal may come '
            'off once the fine is settled',
      );

      expect(seal.sealNo, 'MCQ-SL-2627-00004');
      expect(seal.status!.label, 'Sealed');
      expect(seal.readyToRelease, isFalse);
    });

    test('a seal with no fine behind it sends no fine_id', () async {
      adapter.reply(<String, dynamic>{
        'data': <String, dynamic>{},
      }, statusCode: 201);

      await ApiEnforcementCaseRepository(
        api: api,
      ).seal(11, CaseSealRequest(sealReason: 'Trading from sealed premises.'));

      final body = adapter.lastOptions!.data as Map<String, dynamic>;
      expect(body.containsKey('fine_id'), isFalse);
    });
  });

  group('what the case and challan payloads gained', () {
    test('a case says whether it is about conduct or arrears', () async {
      adapter.reply(_caseOpenedResponse, statusCode: 201);

      final opened = await ApiEnforcementCaseRepository(
        api: api,
      ).openCase(const FieldCaseRequest.recovery(allotmentId: 17));

      expect(opened.isConductCase, isFalse);
      expect(
        opened.offender,
        isNull,
        reason: 'a recovery case bills the holder on the register',
      );
      expect(opened.allottee!.fullName, 'Naseem Akhtar Bugti');
    });

    test('an action carries the definitions id behind its label', () async {
      adapter.reply(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 3,
            'enforcement_case_id': 1,
            'action_type': <String, dynamic>{
              'value': 'fine_imposed',
              'label': 'Fine imposed',
              'tone': 'info',
            },
            'action_type_id': 7,
            'action_date': '2026-08-26',
            'amounts': <String, dynamic>{'fine_amount': '5000.00'},
          },
        ],
      });

      final action = (await ApiEnforcementCaseRepository(
        api: api,
      ).actions(1)).single;

      expect(action.actionTypeId, 7);
      expect(action.actionType!.value, 'fine_imposed');
    });

    test('a fine challan names its payer when nobody holds the unit', () {
      final challan = Challan.fromJson(<String, dynamic>{
        'id': 1211,
        'challan_no': 'MCQ-CH-2627-0000409',
        'challan_type': <String, dynamic>{
          'value': 'fine',
          'label': 'Fine',
          'tone': 'neutral',
        },
        'is_single_charge': true,
        'amounts': <String, dynamic>{'balance_amount': '5000.00'},
        'allotment': null,
        'allottee': null,
        'payer_name': 'Nadeem Ahmed',
        'payer_mobile_no': '03001234567',
      });

      expect(challan.isFine, isTrue);
      expect(challan.isSingleCharge, isTrue);
      expect(challan.allottee, isNull);
      expect(
        challan.payerName,
        'Nadeem Ahmed',
        reason: 'with no allottee this is the only name on the bill',
      );
      expect(challan.payerMobileNo, '03001234567');
    });
  });
}

// --- Captured payloads ---------------------------------------------------

/// `GET /api/v1/enforcement/definitions`, trimmed to the rows the tests read
/// but with every list at its captured length.
final Map<String, dynamic> _definitionsResponse = <String, dynamic>{
  'data': <String, dynamic>{
    'fine_types': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 1,
        'code': 'non_payment',
        'name': 'Non-payment of dues',
        'name_ur': 'واجبات کی عدم ادائیگی',
        'description':
            'Rent, tax or other dues left unpaid after the final notice.',
        'default_provision':
            'Section 96, Balochistan Local Government Act 2010',
        'suggested_amount': '5000.00',
      },
      <String, dynamic>{
        'id': 2,
        'code': 'seal_violation',
        'name': 'Breaking a seal',
        'name_ur': 'سیل کی خلاف ورزی',
        'description':
            'Trading from premises MCQ has sealed, or removing the seal.',
        'default_provision':
            'Section 98, Balochistan Local Government Act 2010',
        'suggested_amount': '25000.00',
      },
      <String, dynamic>{
        'id': 3,
        'code': 'unauthorised_use',
        'name': 'Unauthorised use',
        'name_ur': 'غیر مجاز استعمال',
        'default_provision':
            'Section 96, Balochistan Local Government Act 2010',
        'suggested_amount': '10000.00',
      },
      <String, dynamic>{
        'id': 4,
        'code': 'encroachment',
        'name': 'Encroachment',
        'name_ur': 'تجاوزات',
        'default_provision':
            'Section 97, Balochistan Local Government Act 2010',
        'suggested_amount': '3000.00',
      },
      <String, dynamic>{
        'id': 5,
        'code': 'other',
        'name': 'Other violation',
        'name_ur': 'دیگر خلاف ورزی',
        'default_provision': null,
        'suggested_amount': '2000.00',
      },
    ],
    'action_types': <Map<String, dynamic>>[
      _actionType(1, 'site_visit', 'Site visit'),
      _actionType(2, 'notice_served', 'Notice served'),
      _actionType(3, 'verbal_warning', 'Verbal warning'),
      _actionType(4, 'final_warning', 'Final warning'),
      _actionType(5, 'payment_promised', 'Payment promised', promiseDate: true),
      _actionType(6, 'reminder_visit_set', 'Revisit set', visitDate: true),
      _actionType(7, 'fine_imposed', 'Fine imposed', amount: true),
      _actionType(8, 'seal', 'Premises sealed', sealNo: true),
      _actionType(9, 'unseal', 'Seal released', sealNo: true),
      _actionType(10, 'referred_to_law', 'Referred to the Law Branch'),
      _actionType(11, 'case_closed', 'Case closed'),
    ],
    'case_statuses': <Map<String, dynamic>>[
      <String, dynamic>{'value': 'open', 'label': 'Open', 'tone': 'info'},
      <String, dynamic>{
        'value': 'notice_served',
        'label': 'Notice served',
        'tone': 'warning',
      },
      <String, dynamic>{
        'value': 'warned',
        'label': 'Warned',
        'tone': 'warning',
      },
      <String, dynamic>{'value': 'sealed', 'label': 'Sealed', 'tone': 'danger'},
      <String, dynamic>{
        'value': 'part_recovered',
        'label': 'Some money recovered',
        'tone': 'warning',
      },
      <String, dynamic>{
        'value': 'resolved',
        'label': 'Settled',
        'tone': 'success',
      },
      <String, dynamic>{
        'value': 'closed',
        'label': 'Closed',
        'tone': 'neutral',
      },
      <String, dynamic>{
        'value': 'referred_to_law',
        'label': 'With the law officer',
        'tone': 'danger',
      },
    ],
    'case_priorities': <Map<String, dynamic>>[
      <String, dynamic>{'value': 'low', 'label': 'Low', 'tone': 'neutral'},
      <String, dynamic>{
        'value': 'normal',
        'label': 'Normal',
        'tone': 'neutral',
      },
      <String, dynamic>{'value': 'high', 'label': 'High', 'tone': 'warning'},
      <String, dynamic>{
        'value': 'critical',
        'label': 'Urgent',
        'tone': 'danger',
      },
    ],
    'seal_statuses': <Map<String, dynamic>>[
      <String, dynamic>{'value': 'sealed', 'label': 'Sealed', 'tone': 'danger'},
      <String, dynamic>{
        'value': 'unseal_authorised',
        'label': 'Cleared for reopening',
        'tone': 'warning',
      },
      <String, dynamic>{
        'value': 'unsealed',
        'label': 'Reopened',
        'tone': 'success',
      },
      <String, dynamic>{
        'value': 'revoked',
        'label': 'Seal cancelled',
        'tone': 'danger',
      },
    ],
    'fine_statuses': <Map<String, dynamic>>[
      <String, dynamic>{'value': 'imposed', 'label': 'Imposed', 'tone': 'info'},
      <String, dynamic>{
        'value': 'billed',
        'label': 'Added to a challan',
        'tone': 'info',
      },
      <String, dynamic>{'value': 'paid', 'label': 'Paid', 'tone': 'success'},
      <String, dynamic>{
        'value': 'waived',
        'label': 'Waived',
        'tone': 'warning',
      },
      <String, dynamic>{
        'value': 'cancelled',
        'label': 'Cancelled',
        'tone': 'danger',
      },
    ],
  },
};

Map<String, dynamic> _actionType(
  int id,
  String code,
  String name, {
  bool promiseDate = false,
  bool visitDate = false,
  bool amount = false,
  bool sealNo = false,
}) => <String, dynamic>{
  'id': id,
  'code': code,
  'name': name,
  'fields': <String, dynamic>{
    'promise_date': promiseDate,
    'visit_date': visitDate,
    'amount': amount,
    'seal_no': sealNo,
  },
};

/// `GET /api/v1/enforcement/field/person?cnic=5440010000000`
const Map<String, dynamic> _personResponse = <String, dynamic>{
  'data': <String, dynamic>{
    'searched': '5440010000000',
    'cnic': '5440010000000',
    'known': true,
    'allottees': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': '1',
        'allottee_code': 'ALT-00001',
        'name': 'Haji Abdul Rauf Kakar',
        'father_name': 'Abdul Ghafoor Kakar',
        'mobile_no': '03368359506',
        'cnic': '5440010000000',
        'status': 'active',
      },
    ],
    'trade_licences': <Object>[],
    'previous_fines': <Object>[],
    'fine_count': 0,
    'suggested': <String, dynamic>{
      'name': 'Haji Abdul Rauf Kakar',
      'father_name': 'Abdul Ghafoor Kakar',
      'mobile_no': '03368359506',
      'source': 'allottee',
    },
  },
};

/// `POST /api/v1/enforcement/properties/{vacant_property}/fines` — the same
/// resource the city-wide endpoint returns.
const Map<String, dynamic> _cityFineResponse = <String, dynamic>{
  'data': <String, dynamic>{
    'id': 27,
    'fine_no': 'MCQ-FN-2627-00009',
    'fine_type': <String, dynamic>{
      'value': 'encroachment',
      'label': 'Encroachment',
      'tone': 'neutral',
    },
    'fine_type_id': 4,
    'status': <String, dynamic>{
      'value': 'billed',
      'label': 'Added to a challan',
      'tone': 'info',
    },
    'photo_path': null,
    'property_seal_id': null,
    'amounts': <String, dynamic>{
      'fine_amount': '5000.00',
      'field_limit': '10000.00',
    },
    'imposed_on': '2026-09-03',
    'legal_provision': 'Section 14 of the Local Government Act',
    'requires_approval': false,
    'is_effective': true,
    'can_cancel': true,
    'challan_id': 1211,
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
      'id': 1211,
      'challan_no': 'MCQ-CH-2627-0000409',
      'balance_amount': '5000.00',
      'due_date': '2026-09-18',
      'consumer_no': 'RUP7EVZS',
      'has_live_link': true,
    },
    'created_at': '2026-09-03T01:29:56+00:00',
    'seal': null,
  },
  'message': 'Fine imposed and payable. The allottee has been told.',
};

/// `POST /api/v1/enforcement/field/cases` — the case resource, as the list
/// returns it.
const Map<String, dynamic> _caseOpenedResponse = <String, dynamic>{
  'data': <String, dynamic>{
    'id': 11,
    'case_no': 'MCQ-EC-2627-00011',
    'status': <String, dynamic>{
      'value': 'open',
      'label': 'Open',
      'tone': 'info',
    },
    'priority': <String, dynamic>{
      'value': 'normal',
      'label': 'Normal',
      'tone': 'neutral',
    },
    'opened_on': '2026-09-03',
    'amounts': <String, dynamic>{'outstanding_at_open': '92400.00'},
    'position': <String, dynamic>{
      'outstanding_now': '92400.00',
      'direction': 'level',
    },
    'unpaid_months': 5,
    'is_live': true,
    'can_seal': true,
    'can_close': true,
    'property': <String, dynamic>{
      'id': 19,
      'property_code': 'MCQ-JR-000119',
      'display_name': 'Shop S-19, Liaquat Bazaar',
    },
    'allotment': <String, dynamic>{'id': 17, 'allotment_no': 'MCQ-AL-00017'},
    'allottee': <String, dynamic>{
      'id': 17,
      'allottee_code': 'ALT-00017',
      'full_name': 'Naseem Akhtar Bugti',
      'mobile_no': '03301000016',
    },
    'offender': null,
    'is_conduct_case': false,
    'area': <String, dynamic>{
      'id': 1,
      'area_code': 'JR',
      'area_name': 'Jinnah Road',
    },
    'magistrate': <String, dynamic>{'id': 5, 'name': 'Habibullah Tareen'},
    'is_assigned': true,
    'action_count': 0,
    'fine_count': 0,
  },
  'message': 'Case opened.',
};
