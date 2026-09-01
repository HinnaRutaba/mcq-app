import 'package:flutter_test/flutter_test.dart';
import 'package:mcq_app/models/common/money.dart';
import 'package:mcq_app/models/field/beat.dart';
import 'package:mcq_app/models/field/field_activity.dart';
import 'package:mcq_app/models/field/field_card.dart';
import 'package:mcq_app/models/field/field_seal.dart';
import 'package:mcq_app/models/field/follow_up.dart';
import 'package:mcq_app/models/field/map_unit.dart';
import 'package:mcq_app/models/field/round.dart';

/// The rules in the field module that are easy to break silently, and
/// expensive when they are.
///
/// Every one of these is a fact the officer acts on differently depending
/// on the answer — absent against zero, a promise standing against a
/// promise broken, a queue measured in rupees against one that is not.
void main() {
  group('FieldCard — absent is not zero', () {
    test('a vacant unit has a null outstanding, never 0.00', () {
      final card = FieldCard.fromJson(const {
        'property_id': 7,
        'property_code': 'MCQ-CR-001007',
        'shop_no': 'P-7',
        'area_name': 'Circular Road',
        'is_vacant': true,
        'outstanding': null,
        'occupancy_status': 'vacant',
      });

      expect(card.outstanding, isNull);
      expect(card.isVacant, isTrue);
      // Nobody holds it, so the fine cannot go through the tenancy and the
      // form must collect the offender instead.
      expect(card.canFineHolder, isFalse);
      expect(card.needsOffenderDetails, isTrue);
    });

    test('a null days_overdue stays null — nothing is past due yet', () {
      final card = FieldCard.fromJson(const {
        'property_id': 1,
        'outstanding': '1200.00',
        'days_overdue': null,
      });
      expect(card.daysOverdue, isNull);
      expect(card.outstanding, const Money('1200.00'));
    });

    test('an amount is kept as the server\'s own string', () {
      final card = FieldCard.fromJson(const {
        'property_id': 1,
        'outstanding': '263100.00',
      });
      expect(card.outstanding!.raw, '263100.00');
      expect(card.outstanding!.format(), '263,100.00');
    });
  });

  group('FieldCard — the commitment pill', () {
    test('a standing promise is not a broken one', () {
      final card = FieldCard.fromJson(const {
        'property_id': 1,
        'commitment': {
          'promised_payment_date': '2026-09-06',
          'days_remaining': 8,
          'broken': false,
        },
      });
      expect(card.promiseStanding, isTrue);
      expect(card.promiseBroken, isFalse);
      expect(card.commitment!.lapsesToday, isFalse);
    });

    test('broken is the server\'s judgement, and carries how long ago', () {
      final card = FieldCard.fromJson(const {
        'property_id': 1,
        'commitment': {
          'promised_payment_date': '2026-08-24',
          'days_remaining': -5,
          'broken': true,
        },
      });
      expect(card.promiseBroken, isTrue);
      expect(card.commitment!.daysSinceBroken, 5);
    });

    test('a promise lapsing today is flagged for the pulse', () {
      final card = FieldCard.fromJson(const {
        'property_id': 1,
        'commitment': {'days_remaining': 0, 'broken': false},
      });
      expect(card.commitment!.lapsesToday, isTrue);
    });

    test('no commitment block means no pill at all', () {
      final card = FieldCard.fromJson(const {'property_id': 1});
      expect(card.commitment, isNull);
      expect(card.promiseStanding, isFalse);
      expect(card.promiseBroken, isFalse);
    });
  });

  group('FieldCard — the labels a card is built from', () {
    test('unit and place read the way MCQ writes them', () {
      final card = FieldCard.fromJson(const {
        'property_id': 101,
        'property_code': 'MCQ-CR-001001',
        'shop_no': 'P-1',
        'area_name': 'Circular Road',
        'market_name': 'Liaquat Market',
      });
      expect(card.unitLabel, 'MCQ-CR-001001 · P-1');
      expect(card.placeLabel, 'Liaquat Market, Circular Road');
    });

    test('a missing market falls back to the area alone', () {
      final card = FieldCard.fromJson(const {
        'property_id': 1,
        'property_code': 'MCQ-CR-000001',
        'area_name': 'Circular Road',
      });
      expect(card.placeLabel, 'Circular Road');
      expect(card.unitLabel, 'MCQ-CR-000001');
    });

    test('a coordinate is both or neither', () {
      expect(
        FieldCard.fromJson(const {
          'property_id': 1,
          'map': {'latitude': '30.1798000', 'longitude': null},
        }).map,
        isNull,
      );
      final located = FieldCard.fromJson(const {
        'property_id': 1,
        'map': {'latitude': '30.1798000', 'longitude': '66.9750000'},
      });
      expect(located.map, isNotNull);
      expect(located.map!.lat, closeTo(30.1798, 0.0001));
    });
  });

  group('BeatQueue — a queue not measured in money', () {
    test('amount null stays null, and never becomes 0.00', () {
      final queue = BeatQueue.fromJson(const {
        'key': 'follow_ups_due',
        'count': 4,
        'amount': null,
        'endpoint': 'enforcement/field/follow-ups?state=due',
        'tone': 'warning',
      });
      expect(queue.amount, isNull);
      expect(queue.isClear, isFalse);
    });

    test('a money queue carries the server\'s string', () {
      final queue = BeatQueue.fromJson(const {
        'key': 'defaulters',
        'count': 113,
        'amount': '7616662.00',
        'endpoint': 'enforcement/field/defaulters',
        'tone': 'danger',
      });
      expect(queue.amount!.raw, '7616662.00');
    });

    test('a zero count is good news, whatever tone the server sent', () {
      final queue = BeatQueue.fromJson(const {
        'key': 'follow_ups_due',
        'count': 0,
        'tone': 'danger',
      });
      expect(queue.isClear, isTrue);
    });
  });

  group('BeatScope — the areas must be printable', () {
    test('area_names is the authority', () {
      final beat = FieldBeat.fromJson(const {
        'officer': {'id': '5', 'name': 'Habibullah Tareen'},
        'scope': {
          'restricted': true,
          'areas': [
            {'id': 3, 'area_name': 'Circular Road', 'zone_name': 'Zone A'},
          ],
          'area_names': ['Circular Road', 'Liaquat Bazaar'],
          'zone_names': ['Zone A'],
        },
        'queues': [],
      });
      expect(beat.scope.areaNames, ['Circular Road', 'Liaquat Bazaar']);
      expect(beat.scope.zoneNames, ['Zone A']);
      expect(beat.scope.hasPosting, isTrue);
      expect(beat.officer.name, 'Habibullah Tareen');
    });

    test('falls back to the area objects when area_names is absent', () {
      final beat = FieldBeat.fromJson(const {
        'scope': {
          'areas': [
            {'id': 3, 'area_name': 'Circular Road'},
          ],
        },
      });
      expect(beat.scope.areaNames, ['Circular Road']);
    });

    test('an officer with no posting is a fact, not an empty list', () {
      final beat = FieldBeat.fromJson(const {'scope': {'areas': []}});
      expect(beat.scope.hasPosting, isFalse);
    });
  });

  group('FollowUp — the two balances', () {
    FollowUp of(String then, String now) => FollowUp.fromJson({
          'action_id': 55,
          'kind': 'payment_promised',
          'state': 'overdue',
          'days_remaining': -5,
          'allottee_name': 'Nadeem Ahmed',
          'property_id': 101,
          'outstanding_at_promise': then,
          'outstanding_now': now,
        });

    test('a balance that came down means the promise was partly kept', () {
      final row = of('263100.00', '260100.00');
      expect(row.hasPaidSomething, isTrue);
      expect(row.hasNotMoved, isFalse);
    });

    test('a balance that has not moved is the other conversation', () {
      final row = of('263100.00', '263100.00');
      expect(row.hasPaidSomething, isFalse);
      expect(row.hasNotMoved, isTrue);
    });

    test('states map to the three treatments', () {
      expect(
        FollowUp.fromJson(const {'state': 'overdue'}).state,
        FollowUpState.overdue,
      );
      expect(
        FollowUp.fromJson(const {'state': 'due_today'}).state,
        FollowUpState.dueToday,
      );
      expect(
        FollowUp.fromJson(const {'state': 'upcoming'}).state,
        FollowUpState.upcoming,
      );
      // An unknown state must not crash a bazaar round.
      expect(
        FollowUp.fromJson(const {'state': 'something_new'}).state,
        FollowUpState.upcoming,
      );
    });

    test('days overdue is read from the negative remainder', () {
      expect(of('1.00', '1.00').daysOverdue, 5);
    });
  });

  group('FieldSeal — ready_to_release is the server\'s rule', () {
    test('it is read, never recomputed from the balance', () {
      final seal = FieldSeal.fromJson(const {
        'seal_id': 7,
        'seal_no': 'SEAL-2627-0007',
        'property_id': 101,
        'allottee_name': 'Nadeem Ahmed',
        'outstanding_at_seal': '263100.00',
        // Still owing, and still ready: the fine is what the seal answered.
        'outstanding_now': '260100.00',
        'fines_unpaid': 0,
        'fines_paid': 1,
        'ready_to_release': true,
      });
      expect(seal.readyToRelease, isTrue);
      expect(seal.outstandingNow!.raw, '260100.00');
    });

    test('an absent flag means not ready', () {
      expect(
        FieldSeal.fromJson(const {'seal_id': 1}).readyToRelease,
        isFalse,
      );
    });
  });

  group('RoundMarket — the server\'s order is kept', () {
    test('stops parse as the same card shape as a defaulter', () {
      final markets = RoundMarket.listFrom(const [
        {
          'market_name': 'Liaquat Market',
          'area_name': 'Circular Road',
          'shops': 9,
          'broken_promises': 3,
          'never_paid': 4,
          'sealed': 1,
          'outstanding': '840500.00',
          'stops': [
            {'property_id': 101, 'outstanding': '263100.00'},
          ],
        },
      ]);
      expect(markets, hasLength(1));
      expect(markets.first.brokenPromises, 3);
      expect(markets.first.outstanding!.raw, '840500.00');
      expect(markets.first.stops.first, isA<FieldCard>());
    });
  });

  group('FieldActivity — the money is labelled, never claimed', () {
    test('the breakdown sorts busiest first and scales to itself', () {
      final activity = FieldActivity.fromJson(const {
        'period_days': 30,
        'visits': 34,
        'by_action_type': {
          'site_visit': 21,
          'verbal_warning': 6,
          'payment_promised': 5,
        },
        'fines_imposed': 4,
        'fines_amount': '18000.00',
        'collected_in_your_areas': '412300.00',
        'receipts_in_your_areas': 26,
      });
      expect(activity.breakdown.first.key, 'site_visit');
      expect(activity.busiest, 21);
      expect(activity.collectedInAreas!.raw, '412300.00');
      expect(activity.isEmpty, isFalse);
    });
  });

  group('MapUnits — a unit with no coordinate is counted, not dropped', () {
    test('the missing ones are reported', () {
      final units = MapUnits.fromList(const [
        {
          'property_id': 1,
          'map': {'latitude': '30.18', 'longitude': '66.97'},
          'outstanding': '100.00',
        },
        {'property_id': 2, 'outstanding': '100.00'},
        {'property_id': 3, 'map': {'latitude': '30.19', 'longitude': null}},
      ]);
      expect(units.units, hasLength(1));
      expect(units.withoutLocation, 2);
      expect(units.units.first.state, MapUnitState.owing);
    });

    test('a sealed unit is sealed whatever it owes', () {
      final units = MapUnits.fromList(const [
        {
          'property_id': 1,
          'is_sealed': true,
          'outstanding': '100.00',
          'map': {'latitude': '30.18', 'longitude': '66.97'},
        },
      ]);
      expect(units.units.first.state, MapUnitState.sealed);
    });
  });
}
