import 'package:mcq_app/data/repositories/dashboard_repository.dart';
import 'package:mcq_app/data/repositories/defaulters_repository.dart';
import 'package:mcq_app/models/auth_user.dart';
import 'package:mcq_app/models/field_activity.dart';
import 'package:mcq_app/models/defaulter_card.dart';
import 'package:mcq_app/models/field_beat.dart';
import 'package:mcq_app/models/round_group.dart';

/// The real payloads, copied from the staging server, parsed through the real
/// models — so a preview and a test are looking at what the handset actually
/// receives, nulls and string-typed money included.

const Map<String, dynamic> beatJson = <String, dynamic>{
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
};

const Map<String, dynamic> activityJson = <String, dynamic>{
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
};

/// Today's round, grouped by market. Several markets can sit in one area —
/// which is exactly why the screen charts markets and does not roll them up.
const List<Map<String, dynamic>> roundJson = <Map<String, dynamic>>[
  <String, dynamic>{
    'market_name': 'Liaquat Bazaar',
    'area_name': 'Jinnah Road',
    'area_id': 1,
    'shops': 25,
    'broken_promises': 0,
    'never_paid': 14,
    'sealed': 0,
    'outstanding': '887458.10',
    'stops': <dynamic>[],
  },
  <String, dynamic>{
    'market_name': 'Prince Road Market',
    'area_name': 'Prince Road',
    'area_id': 2,
    'shops': 21,
    'broken_promises': 2,
    'never_paid': 9,
    'sealed': 1,
    'outstanding': '1004812.55',
    'stops': <dynamic>[],
  },
  <String, dynamic>{
    'market_name': 'Kandahari Bazaar',
    'area_name': 'Jinnah Road',
    'area_id': 1,
    'shops': 9,
    'broken_promises': 1,
    'never_paid': 3,
    'sealed': 0,
    'outstanding': '321138.45',
    'stops': <dynamic>[],
  },
];

/// The defaulter list, as `enforcement/field/defaulters` returns it: worst
/// first, money as strings, and every state a row can be in represented at
/// least once — never paid, a promise on record, a sealed shop and a live
/// case. The bazaars are the ones on [beatJson]'s scope.
const List<Map<String, dynamic>> defaultersJson = <Map<String, dynamic>>[
  <String, dynamic>{
    'allotment_id': 41,
    'allotment_no': 'ALT-2019-041',
    'property_id': 118,
    'property_code': 'JR-LQ-118',
    'shop_no': 'S-22',
    'area_id': 1,
    'area_name': 'Jinnah Road',
    'market_name': 'Liaquat Bazaar',
    'allottee_id': 88,
    'allottee_name': 'Muhammad Iqbal',
    'mobile_no': '03001234511',
    'cnic': '5440012345671',
    'outstanding': '187450.00',
    'months_behind': 14,
    'days_overdue': 421,
    'never_paid': true,
    'last_payment_date': null,
    'commitment': null,
    'next_visit_date': null,
    'open_case_id': 204,
    'seal_no': null,
    'is_sealed': false,
    'map': <String, dynamic>{'lat': 30.1889, 'lng': 66.9987},
  },
  <String, dynamic>{
    'allotment_id': 57,
    'allotment_no': 'ALT-2021-057',
    'property_id': 132,
    'property_code': 'PR-PM-132',
    'shop_no': 'F-3',
    'area_id': 2,
    'area_name': 'Prince Road',
    'market_name': 'Prince Road Market',
    'allottee_id': 96,
    'allottee_name': 'Abdul Samad',
    'mobile_no': '03001234512',
    'cnic': '5440012345672',
    'outstanding': '96300.50',
    'months_behind': 7,
    'days_overdue': 214,
    'never_paid': false,
    'last_payment_date': '2026-02-11',
    'commitment': <String, dynamic>{
      'promised_amount': '20000.00',
      'promised_on': '2026-08-20',
    },
    'next_visit_date': '2026-09-05',
    'open_case_id': null,
    'seal_no': null,
    'is_sealed': false,
    'map': null,
  },
  <String, dynamic>{
    'allotment_id': 63,
    'allotment_no': 'ALT-2018-063',
    'property_id': 145,
    'property_code': 'PR-PM-145',
    'shop_no': 'F-11',
    'area_id': 2,
    'area_name': 'Prince Road',
    'market_name': 'Prince Road Market',
    'allottee_id': 101,
    'allottee_name': 'Noor Ahmed',
    'mobile_no': null,
    'cnic': '5440012345673',
    'outstanding': '74020.00',
    'months_behind': 6,
    'days_overdue': 181,
    'never_paid': false,
    'last_payment_date': '2026-03-02',
    'commitment': null,
    'next_visit_date': null,
    'open_case_id': 211,
    'seal_no': 'SL-2026-0037',
    'is_sealed': true,
    'map': null,
  },
  <String, dynamic>{
    'allotment_id': null,
    'allotment_no': null,
    'property_id': 151,
    'property_code': 'JR-KD-151',
    'shop_no': 'K-7',
    'area_id': 1,
    'area_name': 'Jinnah Road',
    'market_name': 'Kandahari Bazaar',
    'allottee_id': null,
    'allottee_name': null,
    'mobile_no': null,
    'cnic': null,
    'outstanding': '58900.00',
    'months_behind': null,
    'days_overdue': 96,
    'never_paid': true,
    'last_payment_date': null,
    'commitment': null,
    'next_visit_date': null,
    'open_case_id': null,
    'seal_no': null,
    'is_sealed': false,
    'map': null,
  },
  <String, dynamic>{
    'allotment_id': 72,
    'allotment_no': 'ALT-2023-072',
    'property_id': 160,
    'property_code': 'JR-LQ-160',
    'shop_no': 'S-4',
    'area_id': 1,
    'area_name': 'Jinnah Road',
    'market_name': 'Liaquat Bazaar',
    'allottee_id': 114,
    'allottee_name': 'Zubaida Bibi',
    'mobile_no': '03001234514',
    'cnic': '5440012345675',
    'outstanding': '31275.75',
    'months_behind': 3,
    'days_overdue': 88,
    'never_paid': false,
    'last_payment_date': '2026-06-09',
    'commitment': null,
    'next_visit_date': '2026-09-12',
    'open_case_id': null,
    'seal_no': null,
    'is_sealed': false,
    'map': null,
  },
  <String, dynamic>{
    'allotment_id': 80,
    'allotment_no': 'ALT-2024-080',
    'property_id': 173,
    'property_code': 'JR-KD-173',
    'shop_no': 'K-19',
    'area_id': 1,
    'area_name': 'Jinnah Road',
    'market_name': 'Kandahari Bazaar',
    'allottee_id': 121,
    'allottee_name': 'Sher Ali',
    'mobile_no': '03001234515',
    'cnic': '5440012345676',
    'outstanding': '12400.00',
    'months_behind': 2,
    'days_overdue': 47,
    'never_paid': false,
    'last_payment_date': '2026-07-18',
    'commitment': null,
    'next_visit_date': null,
    'open_case_id': null,
    'seal_no': null,
    'is_sealed': false,
    'map': null,
  },
];

/// The signed-in officer, as the login endpoint returns them.
const Map<String, dynamic> officerJson = <String, dynamic>{
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
  'last_login_at': '2026-09-01T13:51:20+00:00',
  'password_changed_at': '2026-08-29T02:47:00+00:00',
  'permissions': <String>[
    'enforcement.fine.impose',
    'enforcement.seal.apply',
    'enforcement.seal.release',
    'property.inspection.record',
    'reporting.dashboard.view',
  ],
  'roles': <String>['MAGISTRATE'],
  'created_at': '2026-08-28T13:51:13+00:00',
};

FieldBeat get beatFixture => FieldBeat.fromJson(beatJson);

/// The same beat with no amount on the defaulters queue — the case where the
/// share chart has no denominator it is allowed to use.
FieldBeat get beatWithoutTotalFixture => FieldBeat.fromJson(<String, dynamic>{
  ...beatJson,
  'queues': <dynamic>[
    for (final dynamic queue in beatJson['queues'] as List<dynamic>)
      <String, dynamic>{
        ...queue as Map<String, dynamic>,
        if (queue['key'] == 'defaulters') 'amount': null,
      },
  ],
});

FieldActivity get activityFixture => FieldActivity.fromJson(activityJson);

List<RoundGroup> get roundFixture =>
    roundJson.map(RoundGroup.fromJson).toList();

List<DefaulterCard> get defaultersFixture =>
    defaultersJson.map(DefaulterCard.fromJson).toList();

AuthUser get officerFixture => AuthUser.fromJson(officerJson);

/// Answers from the fixtures instead of the network.
///
/// [failure] makes both calls throw, for the states worth looking at that a
/// happy path never shows: the bazaar with no signal.
class FakeDashboardRepository implements DashboardRepository {
  FakeDashboardRepository({
    this.failure,
    this.activityByDays,
    this.beatOverride,
  });

  /// Stands in for [beatFixture] when a test needs a different beat.
  final FieldBeat? beatOverride;

  /// Mutable so a test can let the signal come back and retry.
  Object? failure;

  /// Lets a test prove the window actually reached the server.
  final Map<int, FieldActivity>? activityByDays;

  int? lastDaysRequested;

  @override
  Future<FieldBeat> beat() async {
    if (failure != null) throw failure!;
    return beatOverride ?? beatFixture;
  }

  @override
  Future<FieldActivity> activity({int days = 30}) async {
    lastDaysRequested = days;
    if (failure != null) throw failure!;
    return activityByDays?[days] ?? activityFixture;
  }
}

/// The defaulter endpoints, from the fixtures.
///
/// [defaulters] narrows the rows the way the server does, so a screen driving
/// `area_id`, `search` and `never_paid` is exercised through them rather than
/// merely asserted on — and the arguments it sent are kept for the assertion
/// that they were the right ones.
class FakeDefaultersRepository implements DefaultersRepository {
  FakeDefaultersRepository({this.failure, List<DefaulterCard>? rows})
    : rows = rows ?? defaultersFixture;

  /// Mutable so a test can let the signal come back and retry.
  Object? failure;

  final List<DefaulterCard> rows;

  int roundCalls = 0;
  int defaultersCalls = 0;
  int? lastAreaId;
  String? lastSearch;
  bool? lastNeverPaid;
  int? lastLimit;

  @override
  Future<List<RoundGroup>> round() async {
    roundCalls++;
    if (failure != null) throw failure!;
    return roundFixture;
  }

  @override
  Future<List<DefaulterCard>> defaulters({
    int? areaId,
    String? search,
    bool? neverPaid,
    int? limit,
  }) async {
    defaultersCalls++;
    lastAreaId = areaId;
    lastSearch = search;
    lastNeverPaid = neverPaid;
    lastLimit = limit;
    if (failure != null) throw failure!;
    return rows
        .where(
          (DefaulterCard card) =>
              (areaId == null || card.areaId == areaId) &&
              (neverPaid != true || card.neverPaid) &&
              (search == null || _matches(card, search)),
        )
        .toList();
  }

  @override
  Future<List<DefaulterCard>> followUps({FollowUpState? state}) async =>
      const <DefaulterCard>[];

  /// Shop number, property code, the holder's name or their CNIC — the four
  /// the published search covers.
  static bool _matches(DefaulterCard card, String search) {
    final String term = search.trim().toLowerCase();
    return <String?>[
      card.shopNo,
      card.propertyCode,
      card.allotteeName,
      card.cnic,
    ].any((String? field) => field?.toLowerCase().contains(term) ?? false);
  }
}
