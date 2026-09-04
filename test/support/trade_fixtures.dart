import 'package:mcq_app/data/repositories/trade_repository.dart';
import 'package:mcq_app/models/models.dart';

/// The licensing module's payloads, for a preview or a screen test.
///
/// The beat, the lookup, the tariff and the capture response are the published
/// ones — copied from the API document, which captured them from live calls.
/// The two round lists were captured **empty**, so their rows here are built out
/// of the licence shape the lookup does publish rather than invented keys.

/// `GET /api/v1/trade/field/beat`
final TradeBeat tradeBeatFixture = TradeBeat.fromJson(<String, dynamic>{
  'scope': <String, dynamic>{
    'restricted': true,
    'areas': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': '1',
        'area_code': 'JR',
        'area_name': 'Jinnah Road',
        'zone_id': 1,
        'zone_name': 'Zone 1 - Zarghoon',
      },
      <String, dynamic>{
        'id': '2',
        'area_code': 'PR',
        'area_name': 'Prince Road',
        'zone_id': 1,
        'zone_name': 'Zone 1 - Zarghoon',
      },
    ],
  },
  'queues': <Map<String, dynamic>>[
    <String, dynamic>{
      'key': 'expiring',
      'count': 3,
      'endpoint': '/api/v1/trade/field/expiring',
      'area_scoped': true,
    },
    <String, dynamic>{
      'key': 'lapsed',
      'count': 2,
      'endpoint': '/api/v1/trade/field/lapsed',
      'area_scoped': true,
    },
    <String, dynamic>{
      'key': 'live',
      'count': 41,
      'endpoint': '/api/v1/trade/field/expiring',
      'area_scoped': true,
    },
  ],
  'generated_at': '2026-09-03T01:29:56+00:00',
});

/// One licence, in the shape `trade/field/lookup` publishes.
Map<String, dynamic> _licence({
  required int id,
  required String licenceNo,
  required String code,
  required String holder,
  required String business,
  required String trade,
  required String area,
  required String validTo,
  required int daysRemaining,
  required bool isValid,
  String? mobile,
}) => <String, dynamic>{
  'id': '$id',
  'licence_no': licenceNo,
  'verification_code': code,
  'holder_name': holder,
  'father_name': 'Abdul Ghani',
  'cnic': '5440020000000',
  'mobile_no': mobile,
  'business_name': business,
  'shop_address': '$business, $area, Quetta',
  'trade': trade,
  'area_name': area,
  'zone_name': 'Zone 1 - Zarghoon',
  'status': isValid ? 'active' : 'expired',
  'issued_on': '2024-05-28',
  'valid_from': '2024-05-28',
  'valid_to': validTo,
  'days_remaining': daysRemaining,
  'is_valid': isValid,
  'map_pin': null,
};

/// `GET /api/v1/trade/field/expiring` — licences running out inside 30 days.
final List<TradeLicence> tradeExpiringFixture = <Map<String, dynamic>>[
  _licence(
    id: 21,
    licenceNo: 'MCQ-TL-000021',
    code: 'TL-7K2M-QP4R',
    holder: 'Hafeez Ullah',
    business: 'Quetta Kabab House',
    trade: 'Restaurant',
    area: 'Jinnah Road',
    validTo: '2026-09-11',
    daysRemaining: 8,
    isValid: true,
    mobile: '03304100000',
  ),
  _licence(
    id: 22,
    licenceNo: 'MCQ-TL-000022',
    code: 'TL-9W1D-LZ8B',
    holder: 'Noor Muhammad',
    business: 'Al Madina Naan Shop',
    trade: 'Naan Shop / Tandoor',
    area: 'Prince Road',
    validTo: '2026-09-24',
    daysRemaining: 21,
    isValid: true,
    mobile: '03337712045',
  ),
  _licence(
    id: 23,
    licenceNo: 'MCQ-TL-000023',
    code: 'TL-3H6V-XN2K',
    holder: 'Shahzad Ahmed',
    business: 'Zarghoon Auto Workshop',
    trade: 'Workshop / Denting and Painting',
    area: 'Jinnah Road',
    validTo: '2026-10-01',
    daysRemaining: 28,
    isValid: true,
  ),
].map(TradeLicence.fromJson).toList();

/// `GET /api/v1/trade/field/lapsed` — ran out in the last 90 days and was not
/// renewed. `days_remaining` runs negative here, which is the point.
final List<TradeLicence> tradeLapsedFixture = <Map<String, dynamic>>[
  _licence(
    id: 31,
    licenceNo: 'MCQ-TL-000031',
    code: 'TL-5R8T-MK1Q',
    holder: 'Abdul Karim',
    business: 'Karim Cloth House',
    trade: 'Cloth Merchant',
    area: 'Jinnah Road',
    validTo: '2026-06-30',
    daysRemaining: -65,
    isValid: false,
    mobile: '03001234567',
  ),
  _licence(
    id: 32,
    licenceNo: 'MCQ-TL-000032',
    code: 'TL-2P4L-WD9F',
    holder: 'Bilal Ahmed',
    business: 'City Marriage Hall',
    trade: 'Marriage Hall',
    area: 'Prince Road',
    validTo: '2026-08-14',
    daysRemaining: -20,
    isValid: false,
    mobile: '03123456789',
  ),
].map(TradeLicence.fromJson).toList();

/// `GET /api/v1/trade/field/pending` — this officer's own captures, unpaid.
final List<TradeApplication> tradePendingFixture = <TradeApplication>[
  TradeApplication.fromJson(<String, dynamic>{
    'id': 3,
    'application_no': 'MCQ-TA-2627-00003',
    'applicant_name': 'Abdul Karim',
    'father_name': 'Muhammad Yousaf',
    'mobile_no': '03001234567',
    'cnic': '5440112233445',
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
    'created_at': '2026-09-01T09:14:00+00:00',
  }),
  TradeApplication.fromJson(<String, dynamic>{
    'id': 4,
    'application_no': 'MCQ-TA-2627-00004',
    'applicant_name': 'Gul Muhammad',
    'mobile_no': '03337712045',
    'business_name': 'Gul Fruit Stall',
    'trade': 'Fruit and Vegetable Shop',
    'area_name': 'Prince Road',
    'status': 'pending',
    'years': 3,
    'fee_amount': '9000.00',
    'challan_no': 'MCQ-CH-2627-0000418',
    'consumer_no': 'R7T1XBQM',
    'has_live_link': false,
    'created_at': '2026-08-28T11:02:00+00:00',
  }),
];

/// `GET /api/v1/trade/field/lookup?q=…` — a shop with a live licence.
final TradeLicenceLookup tradeLookupLiveFixture = TradeLicenceLookup.fromJson(
  <String, dynamic>{
    'searched': '03304100000',
    'found': true,
    'has_valid_licence': true,
    'licences': <Map<String, dynamic>>[
      _licence(
        id: 13,
        licenceNo: 'MCQ-TL-000001',
        code: 'TL-1W8J-QKIP',
        holder: 'Hafeez Ullah',
        business: 'Quetta Kabab House',
        trade: 'Restaurant',
        area: 'Jinnah Road',
        validTo: '2027-05-28',
        daysRemaining: 267,
        isValid: true,
        mobile: '03304100000',
      ),
    ],
  },
);

/// On the register, but nothing live — a renewal, not an application.
final TradeLicenceLookup tradeLookupLapsedFixture = TradeLicenceLookup.fromJson(
  <String, dynamic>{
    'searched': '5440112233445',
    'found': true,
    'has_valid_licence': false,
    'licences': <Map<String, dynamic>>[
      _licence(
        id: 31,
        licenceNo: 'MCQ-TL-000031',
        code: 'TL-5R8T-MK1Q',
        holder: 'Abdul Karim',
        business: 'Karim Cloth House',
        trade: 'Cloth Merchant',
        area: 'Jinnah Road',
        validTo: '2026-06-30',
        daysRemaining: -65,
        isValid: false,
        mobile: '03001234567',
      ),
    ],
  },
);

/// Nothing on the register at all. The one that becomes a field capture.
final TradeLicenceLookup tradeLookupUnknownFixture =
    TradeLicenceLookup.fromJson(<String, dynamic>{
      'searched': '03309999999',
      'found': false,
      'has_valid_licence': false,
      'licences': <Object>[],
    });

/// `GET /api/v1/trade/field/tariff?area_id=1`, trimmed to three groups.
final TradeTariff tradeTariffFixture = TradeTariff.fromJson(<String, dynamic>{
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
    // An unpriced trade, which the picker must not offer: null is not zero,
    // and a free licence is not a thing MCQ issues.
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
  'generated_at': '2026-09-03T01:29:56+00:00',
});

/// `POST /api/v1/trade/applications/field` — the write's answer.
final TradeApplication tradeCapturedFixture =
    TradeApplication.fromJson(<String, dynamic>{
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
    });

/// The licensing endpoints, from the fixtures above.
///
/// [lookupAnswers] is keyed by what was searched, so a screen driving the
/// doorway lookup gets the three different answers rather than one — the
/// fall-through is "not on the register", which is what an unknown number
/// really returns.
class FakeTradeRepository implements TradeRepository {
  FakeTradeRepository({
    this.failure,
    this.captureFailure,
    TradeBeat? beat,
    List<TradeLicence>? expiring,
    List<TradeLicence>? lapsed,
    List<TradeApplication>? pending,
    TradeTariff? tariff,
    Map<String, TradeLicenceLookup>? lookupAnswers,
  }) : _beat = beat ?? tradeBeatFixture,
       _expiring = expiring ?? tradeExpiringFixture,
       _lapsed = lapsed ?? tradeLapsedFixture,
       _pending = pending ?? tradePendingFixture,
       _tariff = tariff ?? tradeTariffFixture,
       _lookupAnswers =
           lookupAnswers ??
           <String, TradeLicenceLookup>{
             '03304100000': tradeLookupLiveFixture,
             '5440112233445': tradeLookupLapsedFixture,
           };

  /// Mutable so a test can let the signal come back and retry.
  Object? failure;

  /// Thrown by [submitApplication] alone — a refused write over queues that
  /// loaded perfectly well.
  Object? captureFailure;

  final TradeBeat _beat;
  final List<TradeLicence> _expiring;
  final List<TradeLicence> _lapsed;
  final List<TradeApplication> _pending;
  final TradeTariff _tariff;
  final Map<String, TradeLicenceLookup> _lookupAnswers;

  String? lastQuery;
  int? lastTariffAreaId;
  TradeApplicationRequest? lastRequest;
  int lookupCalls = 0;
  int pendingCalls = 0;

  @override
  Future<TradeBeat> beat() async {
    if (failure != null) throw failure!;
    return _beat;
  }

  @override
  Future<List<TradeLicence>> expiring() async {
    if (failure != null) throw failure!;
    return _expiring;
  }

  @override
  Future<List<TradeLicence>> lapsed() async {
    if (failure != null) throw failure!;
    return _lapsed;
  }

  @override
  Future<List<TradeApplication>> pending() async {
    pendingCalls++;
    if (failure != null) throw failure!;
    return _pending;
  }

  @override
  Future<TradeLicenceLookup> lookup(String query) async {
    lookupCalls++;
    lastQuery = query;
    if (failure != null) throw failure!;
    return _lookupAnswers[query] ??
        TradeLicenceLookup.fromJson(<String, dynamic>{
          'searched': query,
          'found': false,
          'has_valid_licence': false,
          'licences': <Object>[],
        });
  }

  @override
  Future<TradeTariff> tariff({required int areaId}) async {
    lastTariffAreaId = areaId;
    if (failure != null) throw failure!;
    return _tariff;
  }

  @override
  Future<TradeApplication> submitApplication(
    TradeApplicationRequest request,
  ) async {
    lastRequest = request;
    if (captureFailure != null) throw captureFailure!;
    if (failure != null) throw failure!;
    return tradeCapturedFixture;
  }
}
