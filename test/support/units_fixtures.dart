import 'package:mcq_app/data/repositories/units_repository.dart';
import 'package:mcq_app/models/map_pins.dart';
import 'package:mcq_app/models/unit_card.dart';

/// `enforcement/field/units` as the staging server returns it — the search
/// behind Home's box, which is every unit on the register and not only the
/// ones that owe something.
///
/// Copied from the wire and parsed through the real model, so a preview and a
/// test are looking at what the handset actually receives: money as a string,
/// `last_payment_date` null on a shop that has never paid, a seal number only
/// where one is on.
const List<Map<String, dynamic>> unitsJson = <Map<String, dynamic>>[
  <String, dynamic>{
    'property_id': 51,
    'property_code': 'MCQ-BDP-0051',
    'shop_no': '29',
    'occupancy_status': 'allotted',
    'area_id': 1,
    'area_name': 'Jinnah Road',
    'market_name': 'Baldia Plaza',
    'is_vacant': false,
    'allotment_id': 51,
    'allotment_no': 'MCQ-AL-00051',
    'allottee_id': 45,
    'allottee_name': 'Muhammad Ashraf',
    'mobile_no': '03413897024',
    'cnic': '5440083159425',
    'outstanding': '483600.00',
    'last_payment_date': null,
    'open_case_id': 15,
    'seal_no': 'MCQ-SL-2627-00001',
    'is_sealed': true,
    'can_fine_holder': true,
    'needs_offender_details': false,
    'map': <String, dynamic>{
      'latitude': '30.1955030',
      'longitude': '67.0164490',
    },
  },
  <String, dynamic>{
    'property_id': 55,
    'property_code': 'MCQ-BDP-0055',
    'shop_no': '33',
    'occupancy_status': 'allotted',
    'area_id': 1,
    'area_name': 'Jinnah Road',
    'market_name': 'Baldia Plaza',
    'is_vacant': false,
    'allotment_id': 55,
    'allotment_no': 'MCQ-AL-00055',
    'allottee_id': 49,
    'allottee_name': 'Haji Anwar',
    'mobile_no': '03300217424',
    'cnic': '5999900055412',
    'outstanding': '454302.00',
    'last_payment_date': '2026-06-30',
    'open_case_id': null,
    'seal_no': null,
    'is_sealed': false,
    'can_fine_holder': true,
    'needs_offender_details': false,
    'map': <String, dynamic>{
      'latitude': '30.1954860',
      'longitude': '67.0164130',
    },
  },
  <String, dynamic>{
    'property_id': 20,
    'property_code': 'MCQ-BDP-0020',
    'shop_no': '2',
    'occupancy_status': 'allotted',
    'area_id': 1,
    'area_name': 'Jinnah Road',
    'market_name': 'Baldia Plaza',
    'is_vacant': false,
    'allotment_id': 20,
    'allotment_no': 'MCQ-AL-00020',
    'allottee_id': 19,
    'allottee_name': 'Abdul Ghafoor',
    'mobile_no': '03137880090',
    'cnic': '5430140378557',
    'outstanding': '426000.00',
    'last_payment_date': null,
    'open_case_id': null,
    'seal_no': null,
    'is_sealed': false,
    'can_fine_holder': true,
    'needs_offender_details': false,
    'map': <String, dynamic>{
      'latitude': '30.1952590',
      'longitude': '67.0168050',
    },
  },
  <String, dynamic>{
    'property_id': 302,
    'property_code': 'MCQ-KJC-0302',
    'shop_no': '67',
    'occupancy_status': 'allotted',
    'area_id': 1,
    'area_name': 'Jinnah Road',
    'market_name': 'Kandahari Jamia Cabins',
    'is_vacant': false,
    'allotment_id': 302,
    'allotment_no': 'MCQ-AL-00302',
    'allottee_id': 249,
    'allottee_name': 'Abdul Zahir',
    'mobile_no': '03013744675',
    'cnic': '5440011089011',
    'outstanding': '410200.00',
    'last_payment_date': '2026-09-14',
    'open_case_id': 14,
    'seal_no': null,
    'is_sealed': false,
    'can_fine_holder': true,
    'needs_offender_details': false,
    'map': <String, dynamic>{
      'latitude': '30.1949340',
      'longitude': '67.0161060',
    },
  },
  <String, dynamic>{
    'property_id': 230,
    'property_code': 'MCQ-CTC-0230',
    'shop_no': '31',
    'occupancy_status': 'allotted',
    'area_id': 1,
    'area_name': 'Jinnah Road',
    'market_name': 'City Thana Cabins',
    'is_vacant': false,
    'allotment_id': 230,
    'allotment_no': 'MCQ-AL-00230',
    'allottee_id': 198,
    'allottee_name': 'Evaz Ali',
    'mobile_no': '03218127043',
    'cnic': '5440043761355',
    'outstanding': '373000.00',
    'last_payment_date': null,
    'open_case_id': null,
    'seal_no': null,
    'is_sealed': false,
    'can_fine_holder': true,
    'needs_offender_details': false,
    'map': <String, dynamic>{
      'latitude': '30.1952910',
      'longitude': '67.0161490',
    },
  },
  <String, dynamic>{
    'property_id': 675,
    'property_code': 'MCQ-JCM-0675',
    'shop_no': '25',
    'occupancy_status': 'allotted',
    'area_id': 1,
    'area_name': 'Jinnah Road',
    'market_name': 'Jinnah Cloth Market',
    'is_vacant': false,
    'allotment_id': 675,
    'allotment_no': 'MCQ-AL-00675',
    'allottee_id': 503,
    'allottee_name': 'Raja',
    'mobile_no': '03218009149',
    'cnic': '5440005129599',
    'outstanding': '344300.00',
    'last_payment_date': null,
    'open_case_id': null,
    'seal_no': null,
    'is_sealed': false,
    'can_fine_holder': true,
    'needs_offender_details': false,
    'map': <String, dynamic>{
      'latitude': '30.1979700',
      'longitude': '67.0131220',
    },
  },
  <String, dynamic>{
    'property_id': 679,
    'property_code': 'MCQ-JCM-0679',
    'shop_no': '29',
    'occupancy_status': 'allotted',
    'area_id': 1,
    'area_name': 'Jinnah Road',
    'market_name': 'Jinnah Cloth Market',
    'is_vacant': false,
    'allotment_id': 679,
    'allotment_no': 'MCQ-AL-00679',
    'allottee_id': 507,
    'allottee_name': 'Muhammad Sadiq',
    'mobile_no': '03342400447',
    'cnic': '5999900001187',
    'outstanding': '319631.00',
    'last_payment_date': '2026-06-30',
    'open_case_id': null,
    'seal_no': null,
    'is_sealed': false,
    'can_fine_holder': true,
    'needs_offender_details': false,
    'map': <String, dynamic>{
      'latitude': '30.1979830',
      'longitude': '67.0129610',
    },
  },
  <String, dynamic>{
    'property_id': 203,
    'property_code': 'MCQ-CTC-0203',
    'shop_no': '4',
    'occupancy_status': 'allotted',
    'area_id': 1,
    'area_name': 'Jinnah Road',
    'market_name': 'City Thana Cabins',
    'is_vacant': false,
    'allotment_id': 203,
    'allotment_no': 'MCQ-AL-00203',
    'allottee_id': 175,
    'allottee_name': 'Muhammad Asghar Or (Muhammad Rauf) Name Issue',
    'mobile_no': '03458168789',
    'cnic': '5440010753237',
    'outstanding': '238200.00',
    'last_payment_date': null,
    'open_case_id': null,
    'seal_no': null,
    'is_sealed': false,
    'can_fine_holder': true,
    'needs_offender_details': false,
    'map': <String, dynamic>{
      'latitude': '30.1946910',
      'longitude': '67.0163490',
    },
  },
  <String, dynamic>{
    'property_id': 839,
    'property_code': 'MCQ-PRS-0839',
    'shop_no': '2',
    'occupancy_status': 'allotted',
    'area_id': 2,
    'area_name': 'Prince Road',
    'market_name': 'Prince Road Shops',
    'is_vacant': false,
    'allotment_id': 839,
    'allotment_no': 'MCQ-AL-00839',
    'allottee_id': 618,
    'allottee_name': 'Nazim Khorak',
    'mobile_no': '03300610835',
    'cnic': '5999900448823',
    'outstanding': '210600.00',
    'last_payment_date': null,
    'open_case_id': null,
    'seal_no': null,
    'is_sealed': false,
    'can_fine_holder': true,
    'needs_offender_details': false,
    'map': <String, dynamic>{
      'latitude': '30.1913740',
      'longitude': '67.0112840',
    },
  },
  // The two states this list has that the defaulter list cannot, and which
  // the sample payload happened not to include: a unit nobody holds, and one
  // that is paid up. Written here rather than copied, and shaped exactly as
  // the published `units` row is.
  <String, dynamic>{
    'property_id': 61,
    'property_code': 'MCQ-BDP-0061',
    'shop_no': '39',
    'occupancy_status': 'vacant',
    'area_id': 1,
    'area_name': 'Jinnah Road',
    'market_name': 'Baldia Plaza',
    'is_vacant': true,
    'allotment_id': null,
    'allotment_no': null,
    'allottee_id': null,
    'allottee_name': null,
    'mobile_no': null,
    'cnic': null,
    'outstanding': '0.00',
    'last_payment_date': null,
    'open_case_id': null,
    'seal_no': null,
    'is_sealed': false,
    'can_fine_holder': false,
    'needs_offender_details': true,
    'map': <String, dynamic>{
      'latitude': '30.1955110',
      'longitude': '67.0164610',
    },
  },
  <String, dynamic>{
    'property_id': 268,
    'property_code': 'MCQ-KJC-0268',
    'shop_no': '33',
    'occupancy_status': 'allotted',
    'area_id': 1,
    'area_name': 'Jinnah Road',
    'market_name': 'Kandahari Jamia Cabins',
    'is_vacant': false,
    'allotment_id': 268,
    'allotment_no': 'MCQ-AL-00268',
    'allottee_id': 222,
    'allottee_name': 'Muhammad Iqbal',
    'mobile_no': '03337000111',
    'cnic': '5440022334455',
    'outstanding': '0.00',
    'last_payment_date': '2026-09-01',
    'open_case_id': null,
    'seal_no': null,
    'is_sealed': false,
    'can_fine_holder': true,
    'needs_offender_details': false,
    'map': <String, dynamic>{
      'latitude': '30.1953340',
      'longitude': '67.0165060',
    },
  },
];

List<UnitCard> get unitsFixture => unitsJson.map(UnitCard.fromJson).toList();

/// `reporting/map` — the same shops as [unitsJson], placed.
///
/// Fewer than the rows on purpose, and that is the payload's own shape: the
/// endpoint drops whatever the register holds no coordinates for and reports
/// the shortfall in `meta.unmapped`, which the map has to say out loud rather
/// than implying it is showing everything.
const Map<String, dynamic> mapPinsJson = <String, dynamic>{
  'pins': <Map<String, dynamic>>[
    <String, dynamic>{
      'property_id': 51,
      'property_code': 'MCQ-BDP-0051',
      'shop_no': '29',
      'lat': '30.1955030',
      'lng': '67.0164490',
      'category_name': 'Building / Plaza Unit',
      'area_name': 'Jinnah Road',
      'market_name': 'Baldia Plaza',
      'occupancy_status': 'allotted',
      'physical_status': 'closed',
      'outstanding': '483600.00',
      'unpaid_months': 26,
      'sealed': true,
      'severity': 'owing',
    },
    <String, dynamic>{
      'property_id': 55,
      'property_code': 'MCQ-BDP-0055',
      'shop_no': '33',
      'lat': '30.1954860',
      'lng': '67.0164130',
      'category_name': 'Building / Plaza Unit',
      'area_name': 'Jinnah Road',
      'market_name': 'Baldia Plaza',
      'occupancy_status': 'allotted',
      'physical_status': 'open',
      'outstanding': '454302.00',
      'unpaid_months': 24,
      'sealed': false,
      'severity': 'owing',
    },
    <String, dynamic>{
      'property_id': 20,
      'property_code': 'MCQ-BDP-0020',
      'shop_no': '2',
      'lat': '30.1952590',
      'lng': '67.0168050',
      'category_name': 'Building / Plaza Unit',
      'area_name': 'Jinnah Road',
      'market_name': 'Baldia Plaza',
      'occupancy_status': 'allotted',
      'physical_status': 'open',
      'outstanding': '426000.00',
      'unpaid_months': 22,
      'sealed': false,
      'severity': 'owing',
    },
    <String, dynamic>{
      'property_id': 302,
      'property_code': 'MCQ-KJC-0302',
      'shop_no': '67',
      'lat': '30.1949340',
      'lng': '67.0161060',
      'category_name': 'Kiosk / Cabin',
      'area_name': 'Jinnah Road',
      'market_name': 'Kandahari Jamia Cabins',
      'occupancy_status': 'allotted',
      'physical_status': 'open',
      'outstanding': '410200.00',
      'unpaid_months': 21,
      'sealed': false,
      'severity': 'owing',
    },
    <String, dynamic>{
      'property_id': 230,
      'property_code': 'MCQ-CTC-0230',
      'shop_no': '31',
      'lat': '30.1952910',
      'lng': '67.0161490',
      'category_name': 'Kiosk / Cabin',
      'area_name': 'Jinnah Road',
      'market_name': 'City Thana Cabins',
      'occupancy_status': 'allotted',
      'physical_status': 'open',
      'outstanding': '373000.00',
      'unpaid_months': 19,
      'sealed': false,
      'severity': 'owing',
    },
    <String, dynamic>{
      'property_id': 61,
      'property_code': 'MCQ-BDP-0061',
      'shop_no': '39',
      'lat': '30.1955110',
      'lng': '67.0164610',
      'category_name': 'Building / Plaza Unit',
      'area_name': 'Jinnah Road',
      'market_name': 'Baldia Plaza',
      'occupancy_status': 'vacant',
      'physical_status': 'closed',
      'outstanding': '0.00',
      'unpaid_months': 0,
      'sealed': false,
      'severity': null,
    },
  ],
  'meta': <String, dynamic>{
    'returned': 6,
    'total': 6,
    'truncated': false,
    'limit': 500,
    'unmapped': 5,
  },
};

MapPins get mapPinsFixture => MapPins.fromJson(mapPinsJson);

class FakeUnitsRepository implements UnitsRepository {
  FakeUnitsRepository({this.failure, List<UnitCard>? rows})
    : rows = rows ?? unitsFixture;

  /// Mutable so a test can let the signal come back and retry.
  Object? failure;

  final List<UnitCard> rows;

  int calls = 0;
  int? lastAreaId;
  String? lastSearch;
  int? lastLimit;

  @override
  Future<List<UnitCard>> units({int? areaId, String? search, int? limit}) async {
    calls++;
    lastAreaId = areaId;
    lastSearch = search;
    lastLimit = limit;
    if (failure != null) throw failure!;
    return rows
        .where(
          (UnitCard unit) =>
              (areaId == null || unit.areaId == areaId) &&
              (search == null || _matches(unit, search)),
        )
        .toList();
  }

  /// Shop number, property code, the holder's name or their CNIC — the four
  /// the published search covers.
  static bool _matches(UnitCard unit, String search) {
    final String term = search.trim().toLowerCase();
    return <String?>[
      unit.shopNo,
      unit.propertyCode,
      unit.allotteeName,
      unit.cnic,
    ].any((String? field) => field?.toLowerCase().contains(term) ?? false);
  }
}
