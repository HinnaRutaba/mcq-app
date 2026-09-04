import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:mcq_app/controllers/challans_controller.dart';
import 'package:mcq_app/core/network/api_exception.dart';
import 'package:mcq_app/data/repositories/challan_repository.dart';
import 'package:mcq_app/models/models.dart';
import 'package:mcq_app/views/magistrate/challans/challans_screen.dart';
import 'package:mcq_app/views/magistrate/challans/widgets/challan_tile.dart';
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
            tile.challan.allottee?.fullName ??
            tile.challan.payerName ??
            '?',
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

    testWidgets('narrows rent in the app rather than guessing at the enum', (
      WidgetTester tester,
    ) async {
      await pumpChallans(tester);
      await chooseFilter(tester, 'Rent');

      // The same request as "All", so no second call goes out.
      expect(billing.calls, 1);
      expect(namesOnScreen(tester), <String>['Abdul Karim', 'Noor Muhammad']);
      expect(find.text('rent bills · loaded so far'), findsOneWidget);
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
        tester.widget<Opacity>(
          find.ancestor(
            of: find.text('challans · 25 showing'),
            matching: find.byType(Opacity),
          ).first,
        ).opacity,
        0.0,
      );
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
