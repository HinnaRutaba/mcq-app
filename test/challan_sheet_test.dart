import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mcq_app/core/utils/map_launcher.dart';
import 'package:mcq_app/models/models.dart';
import 'package:mcq_app/views/magistrate/shared/widgets/challan_sheet.dart';
import 'package:mcq_app/widgets/widgets.dart';

import 'support/challan_fixtures.dart';

/// Every key `billing/challans` sends, read off a live response and checked
/// onto the screen. A field the model parses and the sheet never draws is a
/// field the officer does not have.
void main() {
  late _FakeMaps maps;

  setUp(() => maps = _FakeMaps());

  Future<void> pumpSheet(WidgetTester tester, Challan challan) async {
    tester.view
      ..physicalSize = const Size(420, 3000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChallanSheet(challan: challan, mapLauncher: maps),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The same bill with a fix on its property, which billing does not send
  /// today — the model reads one the moment it appears.
  Challan withFix() => Challan.fromJson(<String, dynamic>{
    ...challanOffTheWireJson,
    'property': <String, dynamic>{
      ...challanOffTheWireJson['property']! as Map<String, dynamic>,
      'latitude': '30.19788500',
      'longitude': '67.00838900',
    },
  });

  group('the payload off the wire', () {
    test('every key in the response reaches the model', () {
      final Challan c = challanOffTheWire;

      expect(c.id, 1377);
      expect(c.challanNo, 'MCQ-CH-2627-0000593');
      // Not in the published enum, and not a fine.
      expect(c.challanType?.value, 'combined');
      expect(c.challanType?.label, 'Everything owed');
      expect(c.isFine, isFalse);
      expect(c.isSingleCharge, isFalse);
      expect(c.surchargeExempt, isFalse);
      expect(c.status?.label, 'Draft');
      expect(c.issueDate, DateTime.parse('2026-11-25'));
      expect(c.dueDate, DateTime.parse('2026-12-05'));
      expect(c.isOverdue, isFalse);
      expect(c.daysOverdue, 0);

      // All eleven figures, as strings, untouched.
      expect(c.amounts.previousBalance, '0.00');
      expect(c.amounts.currentAmount, '40000.00');
      expect(c.amounts.arrearsAmount, '22222.22');
      expect(c.amounts.surchargeAmount, '0.00');
      expect(c.amounts.otherAmount, '0.00');
      expect(c.amounts.adjustmentAmount, '0.00');
      expect(c.amounts.totalAmount, '62222.22');
      expect(c.amounts.paidAmount, '0.00');
      expect(c.amounts.balanceAmount, '62222.22');
      expect(c.amounts.deferredAmount, '0.00');
      expect(c.amounts.payableNow, '62222.22');

      expect(c.isProrated, isFalse);
      expect(c.prorationDays, isNull);
      expect(c.isEdited, isFalse);
      expect(c.remarks, isNull);
      expect(c.consumerNumber, isNull);
      expect(c.linkShortCode, isNull);
      expect(c.linkExpiresAt, isNull);
      expect(c.hasLiveLink, isFalse);
      expect(c.canDefer, isFalse);
      expect(c.dispatchedAt, isNull);
      expect(c.firstPaidAt, isNull);
      expect(c.settledAt, isNull);
      expect(c.supersededByChallanId, isNull);
      expect(c.isSettled, isFalse);

      expect(c.billingPeriod?.periodCode, '2026-11');
      expect(c.billingPeriod?.fiscalYear, '2026-2027');

      expect(c.allotment?.allotmentNo, 'MCQ-AL-00210');
      // The field the model was missing: rent or lease lives here, not on
      // `challan_type`.
      expect(c.allotment?.allotmentType?.label, 'Rent');

      // Spelled `name` here and `full_name` elsewhere; both read.
      expect(c.allottee?.fullName, 'Abdul Malik Pirkani');
      expect(c.allottee?.allotteeCode, 'ALT-00012');
      expect(c.allottee?.mobileNo, '03301000011');
      expect(c.payerName, isNull);

      expect(c.property?.displayName, 'Jinnah Parking, Kandahari Bazaar');
      expect(c.property?.propertyCode, 'MCQ-JR-0009');
      expect(c.area?.name, 'Jinnah Road');
      expect(c.area?.code, 'JR');
      expect(c.createdAt, isNotNull);
      expect(c.updatedAt, isNotNull);
    });

    testWidgets('and every one worth reading reaches the sheet', (
      WidgetTester tester,
    ) async {
      await pumpSheet(tester, challanOffTheWire);

      expect(find.text('MCQ-CH-2627-0000593'), findsOneWidget);
      expect(
        find.text('Everything owed · 2026-11 · 2026-2027'),
        findsOneWidget,
      );
      expect(find.text('Draft'), findsOneWidget);

      // What is due today, then the charge that makes it up.
      expect(find.text('Payable now'), findsOneWidget);
      expect(
        find.text('Rs 62,222'),
        findsNWidgets(3),
      ); // payable, total, balance
      expect(find.text('Rs 40,000'), findsOneWidget);
      expect(find.text('Rs 22,222'), findsOneWidget);

      expect(find.text('25 Nov 2026'), findsOneWidget);
      expect(find.text('5 Dec 2026'), findsOneWidget);

      // The tenancy and its terms — the row that was missing entirely.
      expect(find.text('MCQ-AL-00210 · Rent'), findsOneWidget);
      expect(find.text('Abdul Malik Pirkani · ALT-00012'), findsOneWidget);
      expect(find.text('Jinnah Parking, Kandahari Bazaar'), findsOneWidget);
      expect(find.text('Jinnah Road'), findsOneWidget);
      expect(find.text('03301000011'), findsOneWidget);

      // Nothing invented where the server sent null or zero.
      expect(find.text('Consumer no'), findsNothing);
      expect(find.text('Link code'), findsNothing);
      expect(find.text('Surcharge'), findsNothing);
      expect(find.text('Paid'), findsNothing);
      expect(find.text('Worth knowing'), findsNothing);
      expect(find.text('Part of this bill may be deferred.'), findsNothing);
      expect(
        find.textContaining('No payment link is live on this bill.'),
        findsOneWidget,
      );
    });
  });

  group('finding the shop', () {
    testWidgets('a fix opens the map on the shop itself', (
      WidgetTester tester,
    ) async {
      final Challan pinned = withFix();
      expect(pinned.property?.location?.hasFix, isTrue);

      await pumpSheet(tester, pinned);
      await tester.tap(find.widgetWithText(AppButton, 'Directions'));
      await tester.pumpAndSettle();

      expect(maps.opened.single.point?.latitudeValue, 30.197885);
      expect(maps.opened.single.point?.longitudeValue, 67.008389);
    });

    testWidgets('without one it searches the shop and the bazaar', (
      WidgetTester tester,
    ) async {
      // What billing sends today: a property with no coordinates on it.
      await pumpSheet(tester, challanOffTheWire);

      // Worded differently, because a name search is not a pin.
      expect(find.widgetWithText(AppButton, 'Directions'), findsNothing);
      await tester.tap(find.widgetWithText(AppButton, 'Find'));
      await tester.pumpAndSettle();

      expect(maps.opened.single.point, isNull);
      expect(
        maps.opened.single.address,
        'Jinnah Parking, Kandahari Bazaar, Jinnah Road',
      );
    });

    testWidgets('a bill naming no place offers no map', (
      WidgetTester tester,
    ) async {
      final Challan placeless = Challan.fromJson(<String, dynamic>{
        'id': 1,
        'allottee': <String, dynamic>{'name': 'Somebody'},
        'amounts': <String, dynamic>{'payable_now': '100.00'},
      });

      await pumpSheet(tester, placeless);

      expect(find.widgetWithText(AppButton, 'Find'), findsNothing);
      expect(find.widgetWithText(AppButton, 'Directions'), findsNothing);
    });
  });
}

class _FakeMaps extends MapLauncher {
  final List<({GeoPoint? point, String? address})> opened =
      <({GeoPoint? point, String? address})>[];

  @override
  Future<bool> open({GeoPoint? point, String? address}) async {
    opened.add((point: point, address: address));
    return true;
  }
}
