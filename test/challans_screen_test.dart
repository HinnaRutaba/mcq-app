import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:mcq_app/config/routes/app_routes.dart';
import 'package:mcq_app/controllers/challans_controller.dart';
import 'package:mcq_app/controllers/property_profile_controller.dart';
import 'package:mcq_app/core/network/api_exception.dart';
import 'package:mcq_app/data/repositories/challan_repository.dart';
import 'package:mcq_app/models/models.dart';
import 'package:mcq_app/views/magistrate/challans/challans_screen.dart';
import 'package:mcq_app/views/magistrate/challans/widgets/challan_tile.dart';
import 'package:mcq_app/views/magistrate/shared/widgets/challan_sheet.dart';
import 'package:mcq_app/widgets/widgets.dart';

import 'support/challan_fixtures.dart';

/// Challans, end to end from the payload: the controller walks the paged
/// endpoint, the screen lists what came back, and neither of them ever adds a
/// fine's balance to a rent bill's.
void main() {
  late FakeChallanRepository billing;

  const ApiException offline = ApiException(
    message: 'No connection. Check your signal and try again.',
    failure: ApiFailure.network,
  );

  /// Settles the frame *and* the entrance animations, which `flutter_animate`
  /// schedules on a plain `Timer` that `pumpAndSettle` does not advance.
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  /// A phone's width, but tall enough that every row is laid out — a sliver
  /// list does not build what is below the fold.
  void sizeTo(WidgetTester tester, {double height = 2400, double width = 400}) {
    tester.view
      ..physicalSize = Size(width, height)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<ChallansController> pumpChallans(
    WidgetTester tester, {
    double height = 2400,
  }) async {
    sizeTo(tester, height: height);
    final ChallansController controller = Get.put<ChallansController>(
      ChallansController(challanRepository: billing),
    );
    await tester.pumpWidget(const MaterialApp(home: ChallansScreen()));
    await settle(tester);
    return controller;
  }

  List<String> namesOnScreen(WidgetTester tester) => tester
      .widgetList<ChallanTile>(find.byType(ChallanTile))
      .map(
        (ChallanTile tile) =>
            tile.challan.allottee?.fullName ?? tile.challan.payerName ?? '?',
      )
      .toList();

  Future<void> chooseFilter(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await settle(tester);
  }

  setUp(() {
    Get.reset();
    billing = FakeChallanRepository();
  });

  tearDown(Get.reset);

  group('the list', () {
    testWidgets('opens on every bill, in the server order', (
      WidgetTester tester,
    ) async {
      await pumpChallans(tester);

      expect(namesOnScreen(tester), <String>[
        'Abdul Karim',
        'Noor Muhammad',
        // A fine raised against somebody who is not on the register: the payer
        // name is the only name on it.
        'Gul Hassan',
        'Shahid Iqbal',
      ]);
      expect(billing.pagesAsked, <int?>[1]);
      expect(billing.typesAsked, <String?>[null]);
    });

    testWidgets('counts the bills and never totals them', (
      WidgetTester tester,
    ) async {
      await pumpChallans(tester);

      expect(find.text('4'), findsOneWidget);
      expect(find.text('challans'), findsOneWidget);
      // Rs 18,450 + Rs 5,000 is not a debt anybody owes; only the per-bill
      // figures are ever drawn.
      expect(find.text('Rs 18,450'), findsOneWidget);
      expect(find.text('Rs 5,000'), findsOneWidget);
      expect(find.text('Rs 35,550'), findsNothing);
    });

    testWidgets('says how overdue a bill is, in the server\'s own count', (
      WidgetTester tester,
    ) async {
      await pumpChallans(tester);

      expect(find.text('19 days overdue'), findsOneWidget);
      expect(find.text('14 days overdue'), findsOneWidget);
    });
  });

  group('the filters', () {
    testWidgets('asks the server for the penalties', (
      WidgetTester tester,
    ) async {
      await pumpChallans(tester);
      await chooseFilter(tester, 'Fines');

      expect(billing.typesAsked, <String?>[null, ChallanRepository.typeFine]);
      expect(namesOnScreen(tester), <String>['Gul Hassan', 'Shahid Iqbal']);
    });

    testWidgets('narrows bills in the app rather than guessing at the enum', (
      WidgetTester tester,
    ) async {
      await pumpChallans(tester);
      await chooseFilter(tester, 'Bills');

      // The same request as "All", so no second call goes out.
      expect(billing.calls, 1);
      expect(namesOnScreen(tester), <String>['Abdul Karim', 'Noor Muhammad']);
      expect(find.text('bills · loaded so far'), findsOneWidget);
    });

    testWidgets('offers the way back out of an empty filter', (
      WidgetTester tester,
    ) async {
      billing = FakeChallanRepository(
        challans: challansFixture
            .where((Challan challan) => !challan.isFine)
            .toList(),
      );
      final ChallansController controller = await pumpChallans(tester);
      await chooseFilter(tester, 'Fines');

      expect(find.text('No fines'), findsOneWidget);
      await tester.tap(find.text('Show all bills'));
      await settle(tester);

      expect(controller.filter.value, ChallanFilter.all);
      expect(find.byType(ChallanTile), findsNWidgets(2));
    });
  });

  group('the pages', () {
    testWidgets('walks the cursor and stops where the server does', (
      WidgetTester tester,
    ) async {
      billing = FakeChallanRepository(challans: challanRun(30));
      final ChallansController controller = await pumpChallans(
        tester,
        height: 6000,
      );

      expect(controller.challans.length, ChallansController.pageSize);
      expect(controller.hasMore, isTrue);

      await tester.tap(find.text('Load more'));
      await settle(tester);

      expect(billing.pagesAsked, <int?>[1, 2]);
      expect(controller.challans.length, 30);
      expect(controller.hasMore, isFalse);
      expect(find.text('End of the list · 30 in all'), findsOneWidget);
    });

    testWidgets('leads with the whole count, not the part fetched', (
      WidgetTester tester,
    ) async {
      billing = FakeChallanRepository(challans: challanRun(30));
      await pumpChallans(tester, height: 6000);

      // 30 is what the bazaar owes; 25 is where the scroll has got to.
      expect(find.text('30'), findsOneWidget);
      expect(find.text('challans · 25 showing'), findsOneWidget);
    });

    testWidgets('the count goes with the header when it collapses', (
      WidgetTester tester,
    ) async {
      billing = FakeChallanRepository(challans: challanRun(30));
      await pumpChallans(tester, height: 900);

      expect(find.text('challans · 25 showing'), findsOneWidget);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await settle(tester);

      // Faded out with the rest of the expanded block — the title alone rides
      // the collapsed bar.
      expect(
        tester
            .widget<Opacity>(
              find
                  .ancestor(
                    of: find.text('challans · 25 showing'),
                    matching: find.byType(Opacity),
                  )
                  .first,
            )
            .opacity,
        0.0,
      );
    });
  });

  group('the shapes the server sends', () {
    test('a challan summary carries its figures on itself', () {
      // What `billing/challans` nests under `amounts`, a challan embedded in
      // another record carries flat — see `FineChallanRef`. Both have to read.
      final Challan flat = Challan.fromJson(<String, dynamic>{
        'id': 1377,
        'challan_no': 'MCQ-CH-2627-0000593',
        'balance_amount': '62222.22',
        'consumer_no': 'DRTRMNMD',
        'has_live_link': true,
      });

      expect(flat.amounts.balanceAmount, '62222.22');
      expect(flat.consumerNumber, 'DRTRMNMD');
      expect(flat.hasLiveLink, isTrue);
    });

    test('a nested amounts map still wins', () {
      final Challan nested = Challan.fromJson(<String, dynamic>{
        'id': 1377,
        // Top-level decoys: where the map exists, it is the record.
        'balance_amount': '1.00',
        'amounts': <String, dynamic>{
          'balance_amount': '62222.22',
          'payable_now': '62222.22',
        },
      });

      expect(nested.amounts.balanceAmount, '62222.22');
      expect(nested.amounts.payableNow, '62222.22');
    });

    test('a combined demand is not a fine', () {
      // The live server's commonest type, which the published enum omitted.
      final Challan combined = Challan.fromJson(<String, dynamic>{
        'id': 1377,
        'challan_type': <String, dynamic>{
          'value': 'combined',
          'label': 'Everything owed',
          'tone': 'neutral',
        },
        'amounts': <String, dynamic>{'payable_now': '62222.22'},
      });

      expect(combined.isFine, isFalse);
      // So it lands under Bills, whose label does not claim it is rent.
      expect(ChallanFilter.bills.label, 'Bills');
      expect(ChallanFilter.bills.challanType, isNull);
    });
  });

  group('opening a bill', () {
    testWidgets('a tapped row shows the whole bill, off the row in hand', (
      WidgetTester tester,
    ) async {
      billing = FakeChallanRepository(
        challans: <Challan>[challanOffTheWire, ...challansFixture],
      );
      await pumpChallans(tester);

      await tester.tap(find.byType(ChallanTile).first);
      await tester.pumpAndSettle();

      expect(find.byType(ChallanSheet), findsOneWidget);

      Finder inSheet(String text) => find.descendant(
        of: find.byType(ChallanSheet),
        matching: find.text(text),
      );

      // The breakdown the list response already carried — no second call.
      expect(billing.calls, 1);
      expect(inSheet('Payable now'), findsOneWidget);
      expect(inSheet('Rs 40,000'), findsOneWidget);
      expect(inSheet('Rs 22,222'), findsOneWidget);
      expect(inSheet('MCQ-AL-00210 · Rent'), findsOneWidget);
    });

    testWidgets('the shop behind it is one more press', (
      WidgetTester tester,
    ) async {
      billing = FakeChallanRepository(challans: <Challan>[challanOffTheWire]);
      await pumpChallans(tester);
      await tester.tap(find.byType(ChallanTile).first);
      await tester.pumpAndSettle();

      expect(find.text('Open the shop'), findsOneWidget);
    });

    testWidgets('a fine on somebody off the register still opens', (
      WidgetTester tester,
    ) async {
      await pumpChallans(tester);

      // Gul Hassan is not on the property register, so there is no shop to
      // offer — but the bill itself still reads.
      final Finder fine = find.ancestor(
        of: find.text('Gul Hassan'),
        matching: find.byType(ChallanTile),
      );
      await tester.tap(fine);
      await tester.pumpAndSettle();

      expect(find.byType(ChallanSheet), findsOneWidget);
      expect(find.text('Open the shop'), findsNothing);
    });

    testWidgets('the link names the tab the bills live on', (
      WidgetTester tester,
    ) async {
      expect(
        AppRoutes.propertyProfilePath(501, tab: ProfileTab.owed.name),
        '/magistrate/property/501?tab=owed',
      );
      expect(ProfileTab.byName('owed'), ProfileTab.owed);
      // A stale link opens the profile rather than failing on it.
      expect(ProfileTab.byName('nonsense'), isNull);
    });
  });

  group('when the radio is dead', () {
    testWidgets('a first page that fails offers a retry that works', (
      WidgetTester tester,
    ) async {
      billing = FakeChallanRepository(failure: offline);
      final ChallansController controller = await pumpChallans(tester);

      expect(find.text('Could not load the challans'), findsOneWidget);
      expect(find.byType(ChallanTile), findsNothing);

      billing.failure = null;
      await controller.load();
      await settle(tester);

      expect(find.byType(ChallanTile), findsNWidgets(4));
    });

    testWidgets('a next page that fails leaves the rows standing', (
      WidgetTester tester,
    ) async {
      billing = FakeChallanRepository(challans: challanRun(30));
      final ChallansController controller = await pumpChallans(
        tester,
        height: 6000,
      );

      billing.failure = offline;
      await controller.loadMore();
      await settle(tester);

      // A note over the last good rows, not a wall over them.
      expect(find.byType(AppAlert), findsOneWidget);
      expect(controller.challans.length, ChallansController.pageSize);
    });
  });
}
