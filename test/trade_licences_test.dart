import 'package:flutter_test/flutter_test.dart';
import 'package:mcq_app/core/network/api_config.dart';
import 'package:mcq_app/core/network/api_service.dart';
import 'package:mcq_app/data/repositories/trade_repository.dart';
import 'package:mcq_app/models/models.dart';

import 'support/api_stub.dart';

/// Trade licences — a different register from the enforcement module, and the
/// second job an officer does in the same bazaar.
///
/// Every payload below is copied from the published API document, which
/// captured them from live calls.
void main() {
  late ApiStub adapter;
  late ApiService api;
  late ApiTradeRepository trade;

  setUp(() {
    final stubbed = StubbedApi();
    adapter = stubbed.stub;
    api = stubbed.service;
    trade = ApiTradeRepository(api: api);
  });

  group('the licensing home screen', () {
    test('reads the bazaars and the three queues', () async {
      adapter.reply(_beatResponse);

      final beat = await trade.beat();

      expect(adapter.lastOptions!.path, '/api/v1/trade/field/beat');
      expect(beat.scope.restricted, isTrue);
      expect(beat.scope.areas, hasLength(2));
      expect(beat.queues.map((FieldQueue q) => q.key), <String>[
        'expiring',
        'lapsed',
        'live',
      ]);
      expect(beat.queue('live')!.count, 1);
      expect(beat.generatedAt, isNotNull);
    });

    test('says which bazaars the counts cover, though the server '
        'sends no area_names here', () async {
      adapter.reply(_beatResponse);

      final beat = await trade.beat();

      // The enforcement beat sends `area_names`; this one does not. A screen
      // that cannot name the bazaars invites the reader to take the counts for
      // city-wide, so the names are derived from `areas`.
      expect(beat.scope.areaNames, <String>['Jinnah Road', 'Prince Road']);
      expect(beat.scope.areaSentence, 'Jinnah Road and Prince Road');
      expect(beat.scope.zoneNames, <String>[
        'Zone 1 - Zarghoon',
      ], reason: 'two bazaars share the zone; naming it twice reads as a bug');
      expect(beat.scope.hasAreas, isTrue);
    });

    test('every licensing queue is area-scoped and carries no money', () async {
      adapter.reply(_beatResponse);

      final beat = await trade.beat();

      for (final queue in beat.queues) {
        expect(queue.areaScoped, isTrue);
        expect(queue.hasAmount, isFalse);
        expect(queue.tone, isNull);
      }
    });

    test('a queue endpoint arrives absolute and still resolves', () async {
      adapter.reply(_beatResponse);

      final beat = await trade.beat();
      final resolved = ApiPaths.resolve(beat.queue('lapsed')!.endpoint);

      // The enforcement beat sends `enforcement/field/defaulters`; this one
      // sends `/api/v1/trade/field/lapsed`. Routing from the payload has to
      // read both without doubling the prefix.
      expect(resolved.path, '/api/v1/trade/field/lapsed');
      expect(resolved.query, isEmpty);
    });
  });

  group('the doorway lookup', () {
    test('reads the licence, and is not area-scoped', () async {
      adapter.reply(_lookupResponse);

      final lookup = await trade.lookup('03304100000');

      expect(adapter.lastOptions!.path, '/api/v1/trade/field/lookup');
      expect(adapter.lastOptions!.queryParameters['q'], '03304100000');
      expect(
        adapter.lastOptions!.queryParameters.containsKey('area_id'),
        isFalse,
        reason: 'a licence issued in the next bazaar is still valid',
      );

      final licence = lookup.licences.single;
      expect(licence.licenceNo, 'MCQ-TL-000001');
      expect(licence.verificationCode, 'TL-1W8J-QKIP');
      expect(licence.holderName, 'Hafeez Ullah');
      expect(licence.businessName, 'Quetta Kabab House');
      expect(licence.trade, 'Restaurant');
      expect(licence.validTo, DateTime(2027, 5, 28));
      expect(licence.daysRemaining, 267);
      expect(licence.isValid, isTrue);
      expect(
        licence.mapPin,
        isNull,
        reason: 'this register is not the property register',
      );
    });

    test(
      'found-and-lapsed is a different answer from never-licensed',
      () async {
        adapter.reply(_lookupResponse);
        final valid = await trade.lookup('03304100000');

        expect(valid.hasValidLicence, isTrue);
        expect(valid.isLapsed, isFalse);
        expect(valid.isUnlicensed, isFalse);
        expect(valid.liveLicence, isNotNull);

        adapter.reply(<String, dynamic>{
          'data': <String, dynamic>{
            'searched': '03301111111',
            'found': true,
            'has_valid_licence': false,
            'licences': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': '14',
                'licence_no': 'MCQ-TL-000002',
                'holder_name': 'Abdul Karim',
                'valid_to': '2026-06-30',
                'days_remaining': -65,
                'is_valid': false,
                'status': 'expired',
              },
            ],
          },
        });
        final lapsed = await trade.lookup('03301111111');

        // A renewal, not an application — and the difference is a different
        // conversation to have with the shopkeeper.
        expect(lapsed.found, isTrue);
        expect(lapsed.isLapsed, isTrue);
        expect(lapsed.isUnlicensed, isFalse);
        expect(lapsed.liveLicence, isNull);
        expect(lapsed.licences.single.hasLapsed, isTrue);
        expect(
          lapsed.licences.single.daysRemaining,
          -65,
          reason: 'a lapsed licence counts days the wrong way',
        );

        adapter.reply(<String, dynamic>{
          'data': <String, dynamic>{
            'searched': '03309999999',
            'found': false,
            'has_valid_licence': false,
            'licences': <Object>[],
          },
        });
        final unknown = await trade.lookup('03309999999');

        expect(unknown.isUnlicensed, isTrue);
        expect(unknown.isLapsed, isFalse);
      },
    );
  });

  group('the round lists', () {
    test('lapsed and expiring come back empty without complaint', () async {
      adapter.reply(<String, dynamic>{'data': <Object>[]});
      expect(await trade.lapsed(), isEmpty);
      expect(adapter.lastOptions!.path, '/api/v1/trade/field/lapsed');

      adapter.reply(<String, dynamic>{'data': <Object>[]});
      expect(await trade.expiring(), isEmpty);
      expect(adapter.lastOptions!.path, '/api/v1/trade/field/expiring');
    });

    test('the officer own captures come back empty too', () async {
      adapter.reply(<String, dynamic>{'data': <Object>[]});

      expect(await trade.pending(), isEmpty);
      expect(adapter.lastOptions!.path, '/api/v1/trade/field/pending');
    });

    test('a pending capture keeps its payload for the fields not '
        'yet modelled', () async {
      // The published spec captured this list only while it was empty, so a row
      // is read leniently and the untouched payload is kept.
      adapter.reply(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 3,
            'applicant_name': 'Abdul Karim',
            'business_name': 'Al Madina Naan Shop',
            'fee_amount': '6000.00',
            'challan_no': 'MCQ-CH-2627-0000410',
            'has_live_link': true,
            'some_field_added_later': 'kept',
          },
        ],
      });

      final capture = (await trade.pending()).single;

      expect(capture.applicantName, 'Abdul Karim');
      expect(capture.feeAmount, '6000.00');
      expect(capture.hasLiveLink, isTrue);
      expect(capture.raw['some_field_added_later'], 'kept');
    });
  });

  group('the tariff', () {
    test('reads the zone the price actually hangs off', () async {
      adapter.reply(_tariffResponse);

      final tariff = await trade.tariff(areaId: 1);

      expect(adapter.lastOptions!.path, '/api/v1/trade/field/tariff');
      expect(adapter.lastOptions!.queryParameters['area_id'], 1);

      expect(tariff.area!.areaName, 'Jinnah Road');
      expect(tariff.area!.areaCode, 'JR');
      expect(tariff.zone!.zoneCode, 'Z1');
      expect(tariff.areas, hasLength(2));
      expect(tariff.terms.minYears, 1);
      expect(tariff.terms.maxYears, 10);
      expect(tariff.terms.allows(10), isTrue);
      expect(tariff.terms.allows(11), isFalse);
      expect(tariff.priced, 98);
    });

    test('groups the trades for a picker, with their Urdu names', () async {
      adapter.reply(_tariffResponse);

      final tariff = await trade.tariff(areaId: 1);

      expect(tariff.groups, hasLength(2));
      expect(tariff.groups.first.label, 'Food and hospitality');
      expect(tariff.groups.last.label, 'Vehicles and workshops');

      final naan = tariff.category(40)!;
      expect(naan.categoryCode, 'NAAN_SHOP');
      expect(naan.categoryName, 'Naan Shop / Tandoor');
      expect(naan.categoryNameUr, 'نان شاپ / تندور');
      expect(
        naan.annualFee,
        '6000.00',
        reason: 'a fee is money, and money is a string',
      );
      expect(naan.canQuote, isTrue);
    });

    test('an unpriced trade is not free, and cannot be captured', () async {
      adapter.reply(<String, dynamic>{
        'data': <String, dynamic>{
          'terms': <String, dynamic>{'min_years': 1, 'max_years': 10},
          'groups': <Map<String, dynamic>>[
            <String, dynamic>{
              'group': <String, dynamic>{
                'value': 'other',
                'label': 'Other',
                'tone': 'neutral',
              },
              'categories': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 134,
                  'category_code': 'OTHER_TRADE',
                  'category_name': 'Other Trade',
                  'annual_fee': null,
                  'is_priced': false,
                },
              ],
            },
          ],
          'priced': 97,
          'unpriced': 1,
        },
      });

      final tariff = await trade.tariff();
      final unpriced = tariff.category(134)!;

      // Rendering a null fee as 0.00 would quote a shopkeeper a free licence.
      expect(unpriced.annualFee, isNull);
      expect(unpriced.isPriced, isFalse);
      expect(unpriced.canQuote, isFalse);
      expect(tariff.hasUnpriced, isTrue);
      expect(tariff.unpriced, 1);
    });

    test('flattens for a search over the picker', () async {
      adapter.reply(_tariffResponse);

      final tariff = await trade.tariff(areaId: 1);

      expect(tariff.categories, hasLength(4));
      expect(tariff.category(9999), isNull);
    });
  });

  group('capturing an unlicensed shop', () {
    test('sends the trade and the term, and never a fee', () async {
      adapter.reply(_applicationResponse, statusCode: 201);

      final capture = await trade.submitApplication(
        const TradeApplicationRequest(
          tradeCategoryId: 40,
          areaId: 1,
          years: 1,
          applicantName: 'Abdul Karim',
          fatherName: 'Muhammad Yousaf',
          mobileNo: '03001234567',
          cnic: '5440112233445',
          businessName: 'Al Madina Naan Shop',
          shopAddress: 'Shop 14, Circular Road, Quetta',
        ),
      );

      expect(adapter.lastOptions!.path, '/api/v1/trade/applications/field');

      final body = adapter.lastOptions!.data as Map<String, dynamic>;
      expect(body['trade_category_id'], 40);
      expect(body['area_id'], 1);
      expect(body['years'], 1);
      expect(body['applicant_name'], 'Abdul Karim');
      expect(body['mobile_no'], '03001234567');
      expect(body['business_name'], 'Al Madina Naan Shop');
      expect(
        body.keys.where((String key) => key.contains('fee')),
        isEmpty,
        reason: 'the server quotes the fee from (trade x zone)',
      );
      // Fields the officer left blank are simply not sent.
      expect(body.containsKey('email'), isFalse);
      expect(body.containsKey('property_id'), isFalse);

      expect(capture.applicationNo, 'MCQ-TA-2627-00014');
      expect(capture.feeAmount, '6000.00');
      expect(capture.consumerNo, 'K4M2PQTX');
      expect(capture.hasLiveLink, isTrue);
    });

    test('carries the officer fix and the shop it sits in, when there '
        'is one', () async {
      adapter.reply(_applicationResponse, statusCode: 201);

      await trade.submitApplication(
        const TradeApplicationRequest(
          tradeCategoryId: 37,
          areaId: 1,
          years: 3,
          applicantName: 'Hafeez Ullah',
          fatherName: 'Abdul Ghani',
          mobileNo: '03304100000',
          businessName: 'Quetta Kabab House',
          shopAddress: 'Quetta Kabab House, JR, Quetta',
          marketId: 2,
          propertyId: 8,
          latitude: 30.1897234,
          longitude: 67.0101876,
          remarks: 'Trading without a licence since the last round.',
        ),
      );

      final body = adapter.lastOptions!.data as Map<String, dynamic>;
      expect(body['market_id'], 2);
      expect(body['property_id'], 8);
      expect(body['latitude'], 30.1897234);
      expect(body['longitude'], 67.0101876);
      expect(body['years'], 3);
      expect(
        body.containsKey('client_action_uuid'),
        isFalse,
        reason: 'this endpoint accepts none, so a resend is not made safe',
      );
    });

    test('the server own validation rules travel with the request', () {
      // Transcribed from the endpoint's parameter table, so a form uses the
      // server's rules rather than reinventing them.
      expect(
        TradeApplicationRequest.mobilePattern.hasMatch('03001234567'),
        isTrue,
      );
      expect(
        TradeApplicationRequest.mobilePattern.hasMatch('3001234567'),
        isFalse,
      );
      expect(
        TradeApplicationRequest.mobilePattern.hasMatch('0300123456'),
        isFalse,
      );

      expect(
        TradeApplicationRequest.cnicPattern.hasMatch('5440112233445'),
        isTrue,
      );
      expect(
        TradeApplicationRequest.cnicPattern.hasMatch('54401-1223344-5'),
        isFalse,
        reason: 'a licence application wants 13 bare digits, unlike a fine',
      );

      expect(
        TradeApplicationRequest.namePattern.hasMatch('Abdul Karim'),
        isTrue,
      );
      expect(
        TradeApplicationRequest.namePattern.hasMatch("D'Souza-Khan"),
        isTrue,
      );
      expect(
        TradeApplicationRequest.namePattern.hasMatch('عبدالکریم'),
        isFalse,
        reason: 'the server refuses an Urdu name, and the form has to say so',
      );

      expect(
        TradeApplicationRequest.businessNamePattern.hasMatch(
          'Al Madina Naan Shop & Co. (Branch #2)',
        ),
        isTrue,
      );
    });
  });
}

// --- Captured payloads ---------------------------------------------------

/// `GET /api/v1/trade/field/beat`
const Map<String, dynamic> _beatResponse = <String, dynamic>{
  'data': <String, dynamic>{
    'scope': <String, dynamic>{
      'restricted': true,
      'areas': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': '1',
          'area_name': 'Jinnah Road',
          'zone_name': 'Zone 1 - Zarghoon',
        },
        <String, dynamic>{
          'id': '2',
          'area_name': 'Prince Road',
          'zone_name': 'Zone 1 - Zarghoon',
        },
      ],
    },
    'queues': <Map<String, dynamic>>[
      <String, dynamic>{
        'key': 'expiring',
        'count': 0,
        'endpoint': '/api/v1/trade/field/expiring',
        'area_scoped': true,
      },
      <String, dynamic>{
        'key': 'lapsed',
        'count': 0,
        'endpoint': '/api/v1/trade/field/lapsed',
        'area_scoped': true,
      },
      <String, dynamic>{
        'key': 'live',
        'count': 1,
        'endpoint': '/api/v1/trade/field/expiring',
        'area_scoped': true,
      },
    ],
    'generated_at': '2026-09-03T01:29:56+00:00',
  },
};

/// `GET /api/v1/trade/field/lookup?q=03304100000`
const Map<String, dynamic> _lookupResponse = <String, dynamic>{
  'data': <String, dynamic>{
    'searched': '03304100000',
    'found': true,
    'has_valid_licence': true,
    'licences': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': '13',
        'licence_no': 'MCQ-TL-000001',
        'verification_code': 'TL-1W8J-QKIP',
        'holder_name': 'Hafeez Ullah',
        'father_name': 'Abdul Ghani',
        'cnic': '5440020000000',
        'mobile_no': '03304100000',
        'business_name': 'Quetta Kabab House',
        'shop_address': 'Quetta Kabab House, JR, Quetta',
        'trade': 'Restaurant',
        'area_name': 'Jinnah Road',
        'zone_name': 'Zone 1 - Zarghoon',
        'status': 'active',
        'issued_on': '2024-05-28',
        'valid_from': '2024-05-28',
        'valid_to': '2027-05-28',
        'days_remaining': 267,
        'is_valid': true,
        'map_pin': null,
      },
    ],
  },
};

/// `GET /api/v1/trade/field/tariff?area_id=1`, trimmed to two groups.
const Map<String, dynamic> _tariffResponse = <String, dynamic>{
  'data': <String, dynamic>{
    'area': <String, dynamic>{
      'id': 1,
      'area_code': 'JR',
      'area_name': 'Jinnah Road',
      'zone_id': 1,
      'zone_name': 'Zone 1 - Zarghoon',
    },
    'zone': <String, dynamic>{
      'id': 1,
      'zone_code': 'Z1',
      'zone_name': 'Zone 1 - Zarghoon',
    },
    'areas': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 1,
        'area_code': 'JR',
        'area_name': 'Jinnah Road',
        'zone_id': 1,
        'zone_name': 'Zone 1 - Zarghoon',
      },
      <String, dynamic>{
        'id': 2,
        'area_code': 'PR',
        'area_name': 'Prince Road',
        'zone_id': 1,
        'zone_name': 'Zone 1 - Zarghoon',
      },
    ],
    'terms': <String, dynamic>{'min_years': 1, 'max_years': 10},
    'groups': <Map<String, dynamic>>[
      <String, dynamic>{
        'group': <String, dynamic>{
          'value': 'food_service',
          'label': 'Food and hospitality',
          'tone': 'neutral',
        },
        'categories': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 37,
            'category_code': 'RESTAURANT',
            'category_name': 'Restaurant',
            'category_name_ur': 'ریستوران',
            'annual_fee': '12000.00',
            'is_priced': true,
          },
          <String, dynamic>{
            'id': 40,
            'category_code': 'NAAN_SHOP',
            'category_name': 'Naan Shop / Tandoor',
            'category_name_ur': 'نان شاپ / تندور',
            'annual_fee': '6000.00',
            'is_priced': true,
          },
          <String, dynamic>{
            'id': 48,
            'category_code': 'MARRIAGE_HALL',
            'category_name': 'Marriage Hall',
            'category_name_ur': 'شادی ہال',
            'annual_fee': '50000.00',
            'is_priced': true,
          },
        ],
      },
      <String, dynamic>{
        'group': <String, dynamic>{
          'value': 'automotive',
          'label': 'Vehicles and workshops',
          'tone': 'neutral',
        },
        'categories': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 67,
            'category_code': 'PETROL_PUMP',
            'category_name': 'Petrol Pump',
            'category_name_ur': 'پیٹرول پمپ',
            'annual_fee': '50000.00',
            'is_priced': true,
          },
        ],
      },
    ],
    'priced': 98,
    'unpriced': 0,
    'generated_at': '2026-09-03T01:29:56+00:00',
  },
};

/// `POST /api/v1/trade/applications/field` — not captured by the generator,
/// which does not run writes. Read leniently for exactly that reason.
const Map<String, dynamic> _applicationResponse = <String, dynamic>{
  'data': <String, dynamic>{
    'id': 14,
    'application_no': 'MCQ-TA-2627-00014',
    'applicant_name': 'Abdul Karim',
    'father_name': 'Muhammad Yousaf',
    'mobile_no': '03001234567',
    'business_name': 'Al Madina Naan Shop',
    'shop_address': 'Shop 14, Circular Road, Quetta',
    'trade': 'Naan Shop / Tandoor',
    'area_name': 'Jinnah Road',
    'status': 'pending',
    'years': 1,
    'fee_amount': '6000.00',
    'challan_no': 'MCQ-CH-2627-0000410',
    'consumer_no': 'K4M2PQTX',
    'has_live_link': true,
    'created_at': '2026-09-03T01:29:56+00:00',
  },
  'message': 'Application captured. The shopkeeper has been texted the link.',
};
