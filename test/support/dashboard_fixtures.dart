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

AuthUser get officerFixture => AuthUser.fromJson(officerJson);

/// Answers from the fixtures instead of the network.
///
/// [failure] makes both calls throw, for the states worth looking at that a
/// happy path never shows: the bazaar with no signal.
class FakeDashboardRepository implements DashboardRepository {
  FakeDashboardRepository({this.failure, this.activityByDays, this.beatOverride});

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

/// The round, from the fixtures. Only [round] is used by the dashboard; the
/// rest of the contract is not reachable from that screen.
class FakeDefaultersRepository implements DefaultersRepository {
  FakeDefaultersRepository({this.failure});

  /// Mutable so a test can let the signal come back and retry.
  Object? failure;

  int roundCalls = 0;

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
  }) async => const <DefaulterCard>[];

  @override
  Future<List<DefaulterCard>> followUps({FollowUpState? state}) async =>
      const <DefaulterCard>[];
}
