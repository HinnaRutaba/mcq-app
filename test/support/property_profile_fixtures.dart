import 'package:mcq_app/data/repositories/enforcement_case_repository.dart';
import 'package:mcq_app/data/repositories/reporting_repository.dart';
import 'package:mcq_app/models/api_response.dart';
import 'package:mcq_app/models/enforcement_action.dart';
import 'package:mcq_app/models/enforcement_action_request.dart';
import 'package:mcq_app/models/enforcement_case.dart';
import 'package:mcq_app/models/field_case_request.dart';
import 'package:mcq_app/models/field_seal.dart';
import 'package:mcq_app/models/map_pins.dart';
import 'package:mcq_app/models/property_profile.dart';
import 'package:mcq_app/models/seal_requests.dart';

/// The three payloads behind the property profile, in the shapes the staging
/// server sends them: `reporting/properties/{id}/profile`,
/// `enforcement/cases` and `enforcement/cases/{id}/actions`.
///
/// This is the same shop as the first row of `defaultersJson` — S-22 in
/// Liaquat Bazaar, held by Muhammad Iqbal, Rs 187,450 behind, case #204 — so
/// a preview or a test can follow one unit from the list into its profile.
const int fixturePropertyId = 118;
const int fixtureLiveCaseId = 204;
const int fixtureClosedCaseId = 187;

const Map<String, dynamic> propertyProfileJson = <String, dynamic>{
  'property': <String, dynamic>{
    'id': fixturePropertyId,
    'property_code': 'MCQ-JR-000118',
    'category_name': 'Shop',
    'zone_name': 'Zone 1 - Zarghoon',
    'area_name': 'Jinnah Road',
    'market_name': 'Liaquat Bazaar',
    'shop_no': 'S-22',
    'street_address': 'Shop S-22, Liaquat Bazaar, Jinnah Road, Quetta',
    'latitude': '30.1889120',
    'longitude': '66.9987450',
    'has_coordinates': true,
    'occupancy_status': 'allotted',
    'physical_status': 'open',
    'register_949_ref': '949/JR/0118',
  },
  'allotment': <String, dynamic>{'id': 41, 'allotment_no': 'ALT-2019-041'},
  'allottee': <String, dynamic>{
    'id': 88,
    'allottee_code': 'ALT-00088',
    'full_name': 'Muhammad Iqbal',
    'mobile_no': '03001234511',
    'cnic': '5440012345671',
  },
  'position': <String, dynamic>{
    'current_due': '13500.00',
    'arrears_due': '162700.00',
    'surcharge_due': '11250.00',
    'total_outstanding': '187450.00',
    'total_collected': '0.00',
    'last_payment_date': null,
    'unpaid_months': 14,
  },
  'enforcement': <String, dynamic>{
    'seal_no': null,
    'sealed_on': null,
    'seal_status': null,
    'is_sealed': false,
    'open_case_no': 'MCQ-EC-2627-00204',
    'case_status': 'warned',
    'open_legal_cases': 1,
  },
  'challans': <dynamic>[
    <String, dynamic>{
      'id': 9012,
      'challan_no': 'MCQ-CH-2627-09012',
      'challan_type': <String, dynamic>{
        'value': 'rent',
        'label': 'Rent',
        'tone': 'neutral',
      },
      'is_single_charge': false,
      'status': <String, dynamic>{
        'value': 'sent',
        'label': 'Sent out',
        'tone': 'info',
      },
      'issue_date': '2026-08-01',
      'due_date': '2026-08-15',
      'is_overdue': true,
      'days_overdue': 18,
      'amounts': <String, dynamic>{
        'current_amount': '13500.00',
        'arrears_amount': '162700.00',
        'surcharge_amount': '11250.00',
        'total_amount': '187450.00',
        'paid_amount': '0.00',
        'balance_amount': '187450.00',
        'payable_now': '187450.00',
      },
      'consumer_number': '11800000118',
      'has_live_link': true,
    },
  ],
  'payments': <dynamic>[],
  'arrears_plan': null,
};

/// Two cases on this property and one on another, spread over two pages —
/// the case list publishes no property filter, so the profile has to read
/// pages and keep the rows that name its own property.
const List<Map<String, dynamic>> casesPageOneJson = <Map<String, dynamic>>[
  <String, dynamic>{
    'id': fixtureLiveCaseId,
    'case_no': 'MCQ-EC-2627-00204',
    'status': <String, dynamic>{
      'value': 'warned',
      'label': 'Warned',
      'tone': 'warning',
    },
    'priority': <String, dynamic>{
      'value': 'high',
      'label': 'High',
      'tone': 'danger',
    },
    'opened_on': '2026-06-12',
    'closed_on': null,
    'next_visit_date': '2026-08-28',
    'amounts': <String, dynamic>{'outstanding_at_open': '150200.00'},
    'position': <String, dynamic>{
      'outstanding_now': '187450.00',
      'direction': 'up',
    },
    'unpaid_months': 14,
    'closing_remarks': null,
    'is_live': true,
    'is_sealed': false,
    'visit_overdue': true,
    'can_seal': true,
    'can_close': false,
    'property': <String, dynamic>{
      'id': fixturePropertyId,
      'property_code': 'MCQ-JR-000118',
      'display_name': 'Shop S-22, Liaquat Bazaar',
      'physical_status': <String, dynamic>{
        'value': 'open',
        'label': 'Open',
        'tone': 'info',
      },
    },
    'allotment': <String, dynamic>{'id': 41, 'allotment_no': 'ALT-2019-041'},
    'allottee': <String, dynamic>{
      'id': 88,
      'allottee_code': 'ALT-00088',
      'full_name': 'Muhammad Iqbal',
      'mobile_no': '03001234511',
    },
    'area': <String, dynamic>{
      'id': 1,
      'area_code': 'JR',
      'area_name': 'Jinnah Road',
    },
    'magistrate': <String, dynamic>{'id': 5, 'name': 'Habibullah Tareen'},
    'is_assigned': true,
    'action_count': 4,
    'fine_count': 1,
    'created_at': '2026-06-12T05:11:02+00:00',
    'updated_at': '2026-08-26T09:14:41+00:00',
  },
  // A different shop entirely. It shares the page and must not show up on
  // this property's profile.
  <String, dynamic>{
    'id': 900,
    'case_no': 'MCQ-EC-2627-00900',
    'status': <String, dynamic>{
      'value': 'opened',
      'label': 'Opened',
      'tone': 'neutral',
    },
    'priority': null,
    'opened_on': '2026-08-01',
    'closed_on': null,
    'next_visit_date': null,
    'amounts': <String, dynamic>{'outstanding_at_open': '74020.00'},
    'position': <String, dynamic>{
      'outstanding_now': '74020.00',
      'direction': 'level',
    },
    'unpaid_months': 6,
    'closing_remarks': null,
    'is_live': true,
    'is_sealed': true,
    'visit_overdue': false,
    'can_seal': false,
    'can_close': false,
    'property': <String, dynamic>{
      'id': 145,
      'property_code': 'PR-PM-145',
      'display_name': 'Shop F-11, Prince Road Market',
    },
    'allotment': null,
    'allottee': null,
    'area': null,
    'magistrate': null,
    'is_assigned': false,
    'action_count': 2,
    'fine_count': 0,
    'created_at': '2026-08-01T05:11:02+00:00',
    'updated_at': '2026-08-01T05:11:02+00:00',
  },
];

const List<Map<String, dynamic>> casesPageTwoJson = <Map<String, dynamic>>[
  <String, dynamic>{
    'id': fixtureClosedCaseId,
    'case_no': 'MCQ-EC-2526-00187',
    'status': <String, dynamic>{
      'value': 'closed',
      'label': 'Closed',
      'tone': 'neutral',
    },
    'priority': <String, dynamic>{
      'value': 'normal',
      'label': 'Normal',
      'tone': 'neutral',
    },
    'opened_on': '2025-09-02',
    'closed_on': '2025-11-20',
    'next_visit_date': null,
    'amounts': <String, dynamic>{'outstanding_at_open': '42000.00'},
    'position': <String, dynamic>{
      'outstanding_now': '187450.00',
      'direction': 'up',
    },
    'unpaid_months': null,
    'closing_remarks': 'Paid in full after the second notice.',
    'is_live': false,
    'is_sealed': false,
    'visit_overdue': false,
    'can_seal': false,
    'can_close': false,
    'property': <String, dynamic>{
      'id': fixturePropertyId,
      'property_code': 'MCQ-JR-000118',
      'display_name': 'Shop S-22, Liaquat Bazaar',
    },
    'allotment': <String, dynamic>{'id': 41, 'allotment_no': 'ALT-2019-041'},
    'allottee': <String, dynamic>{
      'id': 88,
      'allottee_code': 'ALT-00088',
      'full_name': 'Muhammad Iqbal',
      'mobile_no': '03001234511',
    },
    'area': <String, dynamic>{
      'id': 1,
      'area_code': 'JR',
      'area_name': 'Jinnah Road',
    },
    'magistrate': <String, dynamic>{'id': 5, 'name': 'Habibullah Tareen'},
    'is_assigned': true,
    'action_count': 2,
    'fine_count': 0,
    'created_at': '2025-09-02T05:11:02+00:00',
    'updated_at': '2025-11-20T05:11:02+00:00',
  },
];

/// The live case's timeline, oldest first — including one entry written in a
/// bazaar with no signal and synced two and a half hours later.
const List<Map<String, dynamic>> liveCaseActionsJson = <Map<String, dynamic>>[
  <String, dynamic>{
    'id': 811,
    'enforcement_case_id': fixtureLiveCaseId,
    'action_type': <String, dynamic>{
      'value': 'site_visit',
      'label': 'Visited the shop',
      'tone': 'info',
    },
    'action_date': '2026-06-12',
    'amounts': <String, dynamic>{
      'outstanding_at_action': '150200.00',
      'fine_amount': null,
    },
    'promised_payment_date': null,
    'next_visit_date': '2026-07-02',
    'seal_no': null,
    'location': <String, dynamic>{
      'latitude': '30.1889120',
      'longitude': '66.9987450',
      'accuracy_m': 8.4,
      'has_fix': true,
    },
    'photo_path': null,
    'signature_path': null,
    'witness_name': null,
    'remarks': 'Shop open. Holder not present; spoke to the next-door tenant.',
    'sync': <String, dynamic>{
      'recorded_offline': false,
      'device_recorded_at': null,
      'synced_at': '2026-06-12T06:20:11+00:00',
      'lag_minutes': null,
      'client_action_uuid': null,
    },
    'performed_by': <String, dynamic>{'id': 5, 'name': 'Habibullah Tareen'},
  },
  <String, dynamic>{
    'id': 842,
    'enforcement_case_id': fixtureLiveCaseId,
    'action_type': <String, dynamic>{
      'value': 'verbal_warning',
      'label': 'Warned in person',
      'tone': 'warning',
    },
    'action_date': '2026-07-02',
    'amounts': <String, dynamic>{
      'outstanding_at_action': '162700.00',
      'fine_amount': null,
    },
    'promised_payment_date': '2026-07-20',
    'next_visit_date': '2026-08-05',
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
    'remarks': 'Holder present. Said the arrears would be cleared by the 20th.',
    'sync': <String, dynamic>{
      'recorded_offline': false,
      'device_recorded_at': null,
      'synced_at': '2026-07-02T07:02:00+00:00',
      'lag_minutes': null,
      'client_action_uuid': null,
    },
    'performed_by': <String, dynamic>{'id': 5, 'name': 'Habibullah Tareen'},
  },
  <String, dynamic>{
    'id': 877,
    'enforcement_case_id': fixtureLiveCaseId,
    'action_type': <String, dynamic>{
      'value': 'notice_served',
      'label': 'Notice handed over',
      'tone': 'warning',
    },
    'action_date': '2026-08-05',
    'amounts': <String, dynamic>{
      'outstanding_at_action': '175100.00',
      'fine_amount': null,
    },
    'promised_payment_date': null,
    'next_visit_date': '2026-08-28',
    'seal_no': null,
    'location': <String, dynamic>{
      'latitude': '30.1889120',
      'longitude': '66.9987450',
      'accuracy_m': 12.0,
      'has_fix': true,
    },
    'photo_path': 'enforcement/evidence/2026/08/notice-877.jpg',
    'signature_path': 'enforcement/evidence/2026/08/sign-877.png',
    'witness_name': 'Ghulam Rasool',
    'remarks': 'Notice served and signed for. Promise of the 20th not kept.',
    'sync': <String, dynamic>{
      'recorded_offline': true,
      'device_recorded_at': '2026-08-05T06:40:00+00:00',
      'synced_at': '2026-08-05T09:12:00+00:00',
      'lag_minutes': 152,
      'client_action_uuid': '8f1c5c22-1f0e-4a3a-9d55-2a0c7f0b1e77',
    },
    'performed_by': <String, dynamic>{'id': 5, 'name': 'Habibullah Tareen'},
  },
  <String, dynamic>{
    'id': 903,
    'enforcement_case_id': fixtureLiveCaseId,
    'action_type': <String, dynamic>{
      'value': 'fine_imposed',
      'label': 'Fine imposed',
      'tone': 'danger',
    },
    'action_date': '2026-08-26',
    'amounts': <String, dynamic>{
      'outstanding_at_action': '187450.00',
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
    'photo_path': 'enforcement/evidence/2026/08/fine-903.jpg',
    'signature_path': null,
    'witness_name': null,
    'remarks': 'Unauthorised extension of the shop front onto the walkway.',
    'sync': <String, dynamic>{
      'recorded_offline': false,
      'device_recorded_at': null,
      'synced_at': '2026-08-26T09:14:41+00:00',
      'lag_minutes': null,
      'client_action_uuid': null,
    },
    'performed_by': <String, dynamic>{'id': 5, 'name': 'Habibullah Tareen'},
  },
];

const List<Map<String, dynamic>> closedCaseActionsJson = <Map<String, dynamic>>[
  <String, dynamic>{
    'id': 402,
    'enforcement_case_id': fixtureClosedCaseId,
    'action_type': <String, dynamic>{
      'value': 'notice_served',
      'label': 'Notice handed over',
      'tone': 'warning',
    },
    'action_date': '2025-10-14',
    'amounts': <String, dynamic>{
      'outstanding_at_action': '42000.00',
      'fine_amount': null,
    },
    'promised_payment_date': '2025-11-15',
    'next_visit_date': null,
    'seal_no': null,
    'location': <String, dynamic>{'has_fix': false},
    'photo_path': null,
    'signature_path': null,
    'witness_name': null,
    'remarks': 'Second notice served.',
    'sync': <String, dynamic>{'recorded_offline': false},
    'performed_by': <String, dynamic>{'id': 5, 'name': 'Habibullah Tareen'},
  },
];

PropertyProfile get propertyProfileFixture =>
    PropertyProfile.fromJson(propertyProfileJson);

/// The profile of a property nobody holds, which is a different screen: no
/// holder card, no tenancy, and money that may still be owed.
PropertyProfile get vacantPropertyProfileFixture =>
    PropertyProfile.fromJson(<String, dynamic>{
      ...propertyProfileJson,
      'allotment': null,
      'allottee': null,
      'property': <String, dynamic>{
        ...propertyProfileJson['property']! as Map<String, dynamic>,
        'occupancy_status': 'vacant',
      },
    });

/// The property profile itself, from the fixtures.
class FakeReportingRepository implements ReportingRepository {
  FakeReportingRepository({this.failure, PropertyProfile? profile})
    : profile = profile ?? propertyProfileFixture;

  /// Mutable so a test can let the signal come back and retry.
  Object? failure;

  final PropertyProfile profile;

  int profileCalls = 0;
  int? lastPropertyId;

  @override
  Future<PropertyProfile> propertyProfile(int propertyId) async {
    profileCalls++;
    lastPropertyId = propertyId;
    if (failure != null) throw failure!;
    return profile;
  }

  @override
  Future<MapPins> mapPins({bool defaultersOnly = false, int? limit}) async =>
      throw UnimplementedError('the property profile does not read the map');
}

/// The case list and the timelines, from the fixtures.
///
/// The list is paged the way the endpoint pages it, so the profile's own
/// page-reading is exercised rather than assumed.
class FakeEnforcementCaseRepository implements EnforcementCaseRepository {
  FakeEnforcementCaseRepository({this.failure, this.timelineFailure});

  /// Mutable so a test can let the signal come back and retry.
  Object? failure;

  /// A timeline that fails while the rest of the screen loads.
  Object? timelineFailure;

  final List<int> pagesRequested = <int>[];
  final List<int> timelinesRequested = <int>[];

  static final List<List<Map<String, dynamic>>> _pages =
      <List<Map<String, dynamic>>>[casesPageOneJson, casesPageTwoJson];

  @override
  Future<Paginated<EnforcementCase>> cases({
    int? page,
    int? perPage,
    bool assignedToMe = false,
  }) async {
    final int wanted = page ?? 1;
    pagesRequested.add(wanted);
    if (failure != null) throw failure!;
    final List<Map<String, dynamic>> rows = wanted <= _pages.length
        ? _pages[wanted - 1]
        : const <Map<String, dynamic>>[];
    return Paginated<EnforcementCase>(
      items: rows.map(EnforcementCase.fromJson).toList(),
      meta: PageMeta(
        currentPage: wanted,
        perPage: perPage ?? 50,
        lastPage: _pages.length,
        total: casesPageOneJson.length + casesPageTwoJson.length,
      ),
    );
  }

  @override
  Future<EnforcementCase> openCase(FieldCaseRequest request) async =>
      throw UnimplementedError('the property profile does not open cases');

  @override
  Future<List<EnforcementAction>> actions(int caseId) async {
    timelinesRequested.add(caseId);
    if (timelineFailure != null) throw timelineFailure!;
    if (failure != null) throw failure!;
    final List<Map<String, dynamic>> rows = switch (caseId) {
      fixtureLiveCaseId => liveCaseActionsJson,
      fixtureClosedCaseId => closedCaseActionsJson,
      _ => const <Map<String, dynamic>>[],
    };
    return rows.map(EnforcementAction.fromJson).toList();
  }

  @override
  Future<EnforcementAction> recordAction(
    int caseId,
    EnforcementActionRequest request,
  ) async => throw UnimplementedError('the profile records nothing yet');

  @override
  Future<FieldSeal> seal(int caseId, CaseSealRequest request) async =>
      throw UnimplementedError('the profile seals nothing yet');
}
