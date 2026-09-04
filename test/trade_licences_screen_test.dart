import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:mcq_app/controllers/trade_capture_controller.dart';
import 'package:mcq_app/controllers/trade_licences_controller.dart';
import 'package:mcq_app/core/network/api_exception.dart';
import 'package:mcq_app/data/repositories/trade_repository.dart';
import 'package:mcq_app/models/models.dart';
import 'package:mcq_app/views/magistrate/trade/trade_capture_screen.dart';
import 'package:mcq_app/views/magistrate/trade/trade_licences_screen.dart';
import 'package:mcq_app/views/magistrate/trade/widgets/capture_tile.dart';
import 'package:mcq_app/views/magistrate/shared/widgets/amount_field.dart';
import 'package:mcq_app/views/magistrate/shared/widgets/still_needed_note.dart';
import 'package:mcq_app/views/magistrate/trade/widgets/licence_tile.dart';
import 'package:mcq_app/views/magistrate/trade/widgets/lookup_answer.dart';
import 'package:mcq_app/widgets/widgets.dart';

import 'support/trade_fixtures.dart';

/// Trade licences, end to end from the payload: the controller reads the beat
/// and the three queues, the screen lists what came back, and the search box
/// asks the doorway question of the whole city rather than filtering the list.
void main() {
  late FakeTradeRepository trade;

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

  Future<TradeLicencesController> pumpLicences(
    WidgetTester tester, {
    double width = 400,
  }) async {
    sizeTo(tester, width: width);
    final TradeLicencesController controller = Get.put<TradeLicencesController>(
      TradeLicencesController(tradeRepository: trade),
    );
    await tester.pumpWidget(const MaterialApp(home: TradeLicencesScreen()));
    await settle(tester);
    return controller;
  }

  /// Types into the search box and waits out the debounce.
  Future<void> lookUp(WidgetTester tester, String term) async {
    await tester.enterText(find.byType(EditableText).first, term);
    await tester.pump(TradeLicencesController.searchDebounce);
    await settle(tester);
  }

  List<String> shopsOnScreen(WidgetTester tester) => tester
      .widgetList<LicenceTile>(find.byType(LicenceTile))
      .map((LicenceTile tile) => tile.licence.businessName ?? '?')
      .toList();

  setUp(() {
    Get.reset();
    trade = FakeTradeRepository();
  });

  tearDown(Get.reset);

  group('the queues', () {
    testWidgets('opens on what is running out, in the server order', (
      WidgetTester tester,
    ) async {
      await pumpLicences(tester);

      expect(shopsOnScreen(tester), <String>[
        'Quetta Kabab House',
        'Al Madina Naan Shop',
        'Zarghoon Auto Workshop',
      ]);
      // The beat's own figure, which no list here repeats.
      expect(find.text('41 live licences'), findsOneWidget);
      // Said out loud, or the counts read as city-wide.
      expect(find.text('Jinnah Road and Prince Road'), findsOneWidget);
    });

    testWidgets('the chips carry the count of each queue', (
      WidgetTester tester,
    ) async {
      // Wider than a handset on purpose: the chip row scrolls horizontally on
      // a real one, and a chip that is off screen is not built to assert on —
      // more so here, where the test font is wider than the real one.
      await pumpLicences(tester, width: 900);

      expect(find.text('Expiring · 3'), findsOneWidget);
      expect(find.text('Lapsed · 2'), findsOneWidget);
      expect(find.text('My captures · 2'), findsOneWidget);
    });

    testWidgets('switching queue draws rows already in hand, with no '
        'second call', (WidgetTester tester) async {
      // Wide enough that the third chip is built — see above.
      final TradeLicencesController controller = await pumpLicences(
        tester,
        width: 900,
      );
      final int callsBefore = trade.pendingCalls;

      await tester.tap(find.text('Lapsed · 2'));
      await settle(tester);

      expect(shopsOnScreen(tester), <String>[
        'Karim Cloth House',
        'City Marriage Hall',
      ]);

      await tester.tap(find.text('My captures · 2'));
      await settle(tester);

      expect(find.byType(LicenceTile), findsNothing);
      expect(find.byType(CaptureTile), findsNWidgets(2));
      expect(
        trade.pendingCalls,
        callsBefore,
        reason: 'all three queues arrived on the first load',
      );
      expect(controller.queue.value, TradeQueue.captures);
    });

    testWidgets('the bazaar narrows the rows in hand — neither list '
        'endpoint takes an area', (WidgetTester tester) async {
      final TradeLicencesController controller = await pumpLicences(tester);

      controller.setArea(2);
      await settle(tester);

      expect(shopsOnScreen(tester), <String>['Al Madina Naan Shop']);
      expect(find.text('Expiring · 1'), findsOneWidget);
      expect(find.text('Lapsed · 1'), findsOneWidget);
    });

    testWidgets('an empty queue offers the way out of its own dead end', (
      WidgetTester tester,
    ) async {
      trade = FakeTradeRepository(lapsed: const <TradeLicence>[]);
      final TradeLicencesController controller = await pumpLicences(tester);

      controller.showQueue(TradeQueue.lapsed);
      controller.setArea(2);
      await settle(tester);

      expect(find.text('Nothing lapsed'), findsOneWidget);
      // The filters that emptied the list are above this, but the way out of a
      // dead end belongs in the dead end.
      await tester.tap(find.text('Clear filters'));
      await settle(tester);

      expect(controller.queue.value, TradeQueue.expiring);
      expect(controller.areaId.value, TradeLicencesController.allAreas);
      expect(shopsOnScreen(tester), hasLength(3));
    });
  });

  group('a bazaar with no signal', () {
    testWidgets('nothing up means the whole screen is the failure', (
      WidgetTester tester,
    ) async {
      trade.failure = offline;
      await pumpLicences(tester);

      expect(find.text('Could not load the licence queues'), findsOneWidget);
      expect(find.text(offline.message), findsOneWidget);

      trade.failure = null;
      await tester.tap(find.text('Try again'));
      await settle(tester);

      expect(shopsOnScreen(tester), hasLength(3));
    });

    testWidgets('rows already up stay up, with a note over them', (
      WidgetTester tester,
    ) async {
      final TradeLicencesController controller = await pumpLicences(tester);

      trade.failure = offline;
      await controller.load();
      await settle(tester);

      expect(find.byType(AppAlert), findsOneWidget);
      expect(
        shopsOnScreen(tester),
        hasLength(3),
        reason: 'the last good rows are better than a blank page',
      );
    });
  });

  group('the doorway lookup', () {
    testWidgets('half a number is not a question, and is not asked', (
      WidgetTester tester,
    ) async {
      await pumpLicences(tester);

      await lookUp(tester, '033');

      expect(trade.lookupCalls, 0);
      expect(find.text('Keep going'), findsOneWidget);
      expect(find.byType(LicenceTile), findsNothing);
    });

    testWidgets('a whole number replaces the queues with an answer', (
      WidgetTester tester,
    ) async {
      await pumpLicences(tester);

      await lookUp(tester, '03304100000');

      expect(trade.lastQuery, '03304100000');
      expect(find.text('Licensed'), findsOneWidget);
      expect(
        find.text('This shop may trade today. Nothing to do here.'),
        findsOneWidget,
      );
      // The licence itself, under the verdict.
      expect(shopsOnScreen(tester), <String>['Quetta Kabab House']);
      // The queues are gone, and so is the bazaar picker over them: the lookup
      // is not area-scoped.
      expect(find.text('Expiring · 3'), findsNothing);
      expect(find.text('All bazaars'), findsNothing);
    });

    testWidgets('found-and-lapsed is a renewal, not a capture', (
      WidgetTester tester,
    ) async {
      await pumpLicences(tester);

      await lookUp(tester, '5440112233445');

      expect(find.text('Licence lapsed'), findsOneWidget);
      expect(find.text('Capture this shop'), findsNothing);
      expect(shopsOnScreen(tester), <String>['Karim Cloth House']);
    });

    testWidgets('never-licensed is the one that becomes a capture', (
      WidgetTester tester,
    ) async {
      await pumpLicences(tester);

      await lookUp(tester, '03309999999');

      expect(find.text('Not on the register'), findsOneWidget);
      expect(find.text('Capture this shop'), findsOneWidget);
      expect(find.byType(LookupAnswer), findsOneWidget);
      expect(find.byType(LicenceTile), findsNothing);
    });

    testWidgets('emptying the box brings the queues back', (
      WidgetTester tester,
    ) async {
      await pumpLicences(tester);
      await lookUp(tester, '03304100000');
      expect(find.text('Licensed'), findsOneWidget);

      await lookUp(tester, '');

      expect(find.text('Licensed'), findsNothing);
      expect(find.text('Expiring · 3'), findsOneWidget);
      expect(shopsOnScreen(tester), hasLength(3));
    });
  });

  group('capturing an unlicensed shop', () {
    Future<TradeCaptureController> pumpCapture(
      WidgetTester tester, {
      String? searched,
      int? areaId = 1,
    }) async {
      sizeTo(tester, height: 3000);
      Get.put<TradeRepository>(trade);
      await tester.pumpWidget(
        MaterialApp(
          home: TradeCaptureScreen(searched: searched, areaId: areaId),
        ),
      );
      await settle(tester);
      return Get.find<TradeCaptureController>();
    }

    /// Everything the server insists on, filled the way the form does.
    void fill(TradeCaptureController capture) {
      capture
        ..cnicController.text = '5440112233445'
        ..applicantController.text = 'Abdul Karim'
        ..fatherController.text = 'Muhammad Yousaf'
        ..mobileController.text = '03001234567'
        ..businessController.text = 'Al Madina Naan Shop'
        ..addressController.text = 'Shop 14, Circular Road, Quetta';
      capture.chooseCategory(tradeTariffFixture.category(40)!);
    }

    testWidgets('reads the tariff for the bazaar and offers only priced '
        'trades', (WidgetTester tester) async {
      final TradeCaptureController capture = await pumpCapture(tester);

      expect(trade.lastTariffAreaId, 1);
      expect(capture.zoneName, 'Zone 1 - Zarghoon');
      // 134 is unpriced in this zone, so the picker must not carry it.
      final List<TradeCategory> offered = <TradeCategory>[
        for (final TradeCategoryGroup group in capture.quotableGroups)
          ...group.categories,
      ];
      expect(offered.map((TradeCategory c) => c.id), <int>[37, 40, 48, 67]);
      expect(capture.unpricedCount, 1);
    });

    testWidgets('a chosen trade shows what the tariff holds about it', (
      WidgetTester tester,
    ) async {
      final TradeCaptureController capture = await pumpCapture(tester);
      capture.chooseCategory(tradeTariffFixture.category(40)!);
      await settle(tester);

      // The group is on the group, not on the category — the officer still
      // needs to see which heading the trade was priced under.
      expect(capture.categoryGroup, 'Food and hospitality');
      expect(find.text('Food and hospitality'), findsOneWidget);
      expect(find.text('NAAN_SHOP'), findsOneWidget);
      expect(find.text('نان شاپ / تندور'), findsOneWidget);
      // The zone is the answer to "why that figure?".
      expect(find.text('Priced for Zone 1 - Zarghoon'), findsOneWidget);

      // The fee, prefilled off the tariff into the field the officer may
      // correct — the same block the fine's amount uses.
      expect(find.byType(AmountField), findsOneWidget);
      expect(capture.feeController.text, '6000.00');
      expect(
        find.text(
          "Rs 6000.00 is what MCQ's tariff for this trade suggests. Change "
          'it if the fee should be more or less.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('nothing is priced until a bazaar is named', (
      WidgetTester tester,
    ) async {
      // The filter was "All bazaars", so none was carried onto the form.
      final TradeCaptureController capture = await pumpCapture(
        tester,
        areaId: null,
      );

      // `tariff?area_id=` prices one bazaar; there is nothing to ask it yet.
      expect(trade.lastTariffAreaId, isNull);
      expect(capture.tariff.value, isNull);
      expect(
        find.text(
          'Name the bazaar first — the prices are the ones MCQ charges there.',
        ),
        findsOneWidget,
      );
      // The bazaars come off the beat, which is the only list that can be read
      // without naming one.
      expect(capture.areaOptions, <int>[1, 2]);

      await capture.setArea(2);
      await settle(tester);

      expect(trade.lastTariffAreaId, 2);
      expect(capture.zoneName, 'Zone 1 - Zarghoon');
      expect(find.text('Licence term'), findsOneWidget);
    });

    testWidgets('dropping the bazaar drops the prices with it', (
      WidgetTester tester,
    ) async {
      final TradeCaptureController capture = await pumpCapture(tester);
      capture.chooseCategory(tradeTariffFixture.category(40)!);
      await settle(tester);

      capture.clearArea();
      await settle(tester);

      // They were that bazaar's prices, and a fee quoted from nowhere is how a
      // shopkeeper is charged the wrong figure.
      expect(capture.tariff.value, isNull);
      expect(capture.category.value, isNull);
      expect(capture.missing, contains('the bazaar'));
    });

    testWidgets('a tariff that will not load leaves no price behind', (
      WidgetTester tester,
    ) async {
      final TradeCaptureController capture = await pumpCapture(tester);
      capture.chooseCategory(tradeTariffFixture.category(40)!);
      expect(capture.annualFee, '6000.00');

      trade.failure = offline;
      await capture.setArea(2);
      await settle(tester);

      // Rs 6,000 was Jinnah Road's price. Left on screen under Prince Road it
      // is a figure an officer would read out to a shopkeeper.
      expect(capture.annualFee, isNull);
      expect(capture.tariff.value, isNull);
      expect(find.text('Load the prices'), findsOneWidget);
      expect(find.text(offline.message), findsOneWidget);
    });

    testWidgets('puts the number that came back "not on the register" '
        'where it belongs', (WidgetTester tester) async {
      final TradeCaptureController capture = await pumpCapture(
        tester,
        searched: '03309999999',
      );

      expect(capture.mobileController.text, '03309999999');
      expect(capture.cnicController.text, isEmpty);
    });

    testWidgets('sends the trade, the term and the fee as typed', (
      WidgetTester tester,
    ) async {
      final TradeCaptureController capture = await pumpCapture(tester);
      fill(capture);
      await settle(tester);

      await tester.tap(find.text('Capture this shop'));
      await settle(tester);

      final TradeApplicationRequest? sent = trade.lastRequest;
      expect(sent, isNotNull);
      expect(sent!.tradeCategoryId, 40);
      expect(sent.areaId, 1);
      // A year, and the form does not offer another — so the term is stated on
      // it rather than picked.
      expect(sent.years, 1);
      expect(find.text('Licence term'), findsOneWidget);
      expect(
        find.text('One year — the only term issued in the field'),
        findsOneWidget,
      );
      expect(sent.applicantName, 'Abdul Karim');
      expect(sent.cnic, '5440112233445');
      expect(sent.mobileNo, '03001234567');
      // Prefilled off the tariff and sent as a string, exactly as typed.
      expect(sent.feeAmount, '6000.00');
      expect(sent.toJson()['fee_amount'], '6000.00');
      // What came back, in front of the shopkeeper.
      expect(find.text('Shop captured'), findsOneWidget);
      expect(find.text('K4M2PQTX'), findsOneWidget);
    });

    testWidgets('a corrected fee is the figure that travels', (
      WidgetTester tester,
    ) async {
      final TradeCaptureController capture = await pumpCapture(tester);
      fill(capture);
      capture.feeController.text = '4500';
      capture.markEdited();
      await settle(tester);

      // Said out loud on the field, so nobody takes the tariff's figure for
      // what the shopkeeper was quoted.
      expect(
        find.text('Changed from the suggested Rs 6000.00.'),
        findsOneWidget,
      );
      expect(find.text('Rs 4500'), findsOneWidget);

      await tester.tap(find.text('Capture this shop'));
      await settle(tester);

      expect(trade.lastRequest!.feeAmount, '4500');
    });

    testWidgets('a shop cannot be captured without a fee', (
      WidgetTester tester,
    ) async {
      final TradeCaptureController capture = await pumpCapture(tester);
      fill(capture);
      capture.feeController.clear();
      capture.markEdited();
      await settle(tester);

      // The whole list, highlighted, rather than a truncated line: a button
      // that will not press has to say what it is waiting on.
      expect(capture.missing, contains('the licence fee'));
      expect(find.byType(StillNeededNote), findsOneWidget);
      expect(find.text('Still needed: the licence fee'), findsOneWidget);
      expect(trade.lastRequest, isNull);
    });

    testWidgets('a shop cannot be captured without a CNIC', (
      WidgetTester tester,
    ) async {
      final TradeCaptureController capture = await pumpCapture(tester);
      fill(capture);
      capture.cnicController.clear();
      capture.markEdited();
      await settle(tester);

      // A licence is keyed on a CNIC, so the button does not press — and says
      // which field it is waiting on.
      expect(capture.missing, contains("the shopkeeper's CNIC"));
      expect(capture.isValid, isFalse);
      expect(trade.lastRequest, isNull);
    });

    testWidgets('an Urdu name is refused before it reaches the server', (
      WidgetTester tester,
    ) async {
      final TradeCaptureController capture = await pumpCapture(tester);
      fill(capture);
      capture.applicantController.text = 'عبدالکریم';
      await settle(tester);

      await tester.tap(find.text('Capture this shop'));
      await settle(tester);

      expect(trade.lastRequest, isNull);
      expect(
        find.text(
          'English letters only — the register will not take Urdu here',
        ),
        findsOneWidget,
      );
    });

    testWidgets("the server's own refusal lands under the field it names", (
      WidgetTester tester,
    ) async {
      trade.captureFailure = const ApiException(
        message: 'Please check the details and try again.',
        failure: ApiFailure.validation,
        statusCode: 422,
        errors: <String, List<String>>{
          'mobile_no': <String>['This number already holds a licence.'],
        },
      );
      final TradeCaptureController capture = await pumpCapture(tester);
      fill(capture);
      await settle(tester);

      await tester.tap(find.text('Capture this shop'));
      await settle(tester);

      expect(find.text('This number already holds a licence.'), findsOneWidget);
      expect(capture.mayHaveLanded.value, isFalse);
    });

    testWidgets('a call that never came back is not offered a blind retry', (
      WidgetTester tester,
    ) async {
      trade.captureFailure = const ApiException(
        message: 'The server took too long to answer.',
        failure: ApiFailure.timeout,
      );
      final TradeCaptureController capture = await pumpCapture(tester);
      fill(capture);
      await settle(tester);

      await tester.tap(find.text('Capture this shop'));
      await settle(tester);

      // This endpoint carries no `client_action_uuid`, so the shop may already
      // be on the register — the only honest next step is to go and look.
      expect(capture.mayHaveLanded.value, isTrue);
      expect(find.text('Check my captures'), findsOneWidget);
      expect(find.text('Send it again'), findsOneWidget);
      expect(find.text('Capture this shop'), findsNothing);
    });

    testWidgets('editing after that is a different capture, not a resend', (
      WidgetTester tester,
    ) async {
      trade.captureFailure = const ApiException(
        message: 'The server took too long to answer.',
        failure: ApiFailure.timeout,
      );
      final TradeCaptureController capture = await pumpCapture(tester);
      fill(capture);
      await settle(tester);
      await tester.tap(find.text('Capture this shop'));
      await settle(tester);
      expect(capture.mayHaveLanded.value, isTrue);

      capture.businessController.text = 'Al Madina Naan Shop and Bakery';
      capture.markEdited();
      await settle(tester);

      expect(capture.mayHaveLanded.value, isFalse);
      expect(find.text('Capture this shop'), findsOneWidget);
    });
  });
}
