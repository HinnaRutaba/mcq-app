import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:mcq_app/controllers/seals_controller.dart';
import 'package:mcq_app/core/network/api_exception.dart';
import 'package:mcq_app/models/field_seal.dart';
import 'package:mcq_app/views/magistrate/more/sealed_screen.dart';
import 'package:mcq_app/views/magistrate/more/widgets/seal_tile.dart';
import 'package:mcq_app/widgets/widgets.dart';

import 'support/seal_fixtures.dart';

/// The seal register, end to end from the payload: the controller asks for
/// both readings of the list, the screen shows the one the chips are on, and
/// what may come off is the server's answer rather than the handset's.
void main() {
  late FakeFieldSealRepository seals;

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
  Future<SealsController> pumpSeals(
    WidgetTester tester, {
    double height = 2400,
    double width = 400,
  }) async {
    tester.view
      ..physicalSize = Size(width, height)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final SealsController controller = Get.put<SealsController>(
      SealsController(sealRepository: seals),
    );
    await tester.pumpWidget(const MaterialApp(home: SealedScreen()));
    await settle(tester);
    return controller;
  }

  List<String> sealsOnScreen(WidgetTester tester) => tester
      .widgetList<SealTile>(find.byType(SealTile))
      .map((SealTile tile) => tile.seal.sealNo ?? '?')
      .toList();

  SealTile tileFor(WidgetTester tester, String sealNo) => tester
      .widgetList<SealTile>(find.byType(SealTile))
      .firstWhere((SealTile tile) => tile.seal.sealNo == sealNo);

  /// Taps a chip by name. The count is what tells it apart from the badge of
  /// the same words on a row.
  Future<void> showQueue(WidgetTester tester, String label) async {
    await tester.tap(find.textContaining('$label ·'));
    await settle(tester);
  }

  setUp(() {
    Get.reset();
    seals = FakeFieldSealRepository();
  });

  tearDown(Get.reset);

  group('the register', () {
    testWidgets('lists what the server sent, in its order', (
      WidgetTester tester,
    ) async {
      await pumpSeals(tester);

      expect(sealsOnScreen(tester), <String>[
        'MCQ-SL-2627-00001',
        'MCQ-SL-2627-00002',
        'MCQ-SL-2627-00003',
        'MCQ-SL-2627-00004',
      ]);
      expect(find.text('Abdul Samad'), findsOneWidget);
      expect(find.text('S-12 · Liaquat Bazaar'), findsOneWidget);
    });

    testWidgets('asks for both readings, and only one of them with ready=1', (
      WidgetTester tester,
    ) async {
      await pumpSeals(tester);

      expect(seals.asked, <bool>[false, true]);
    });

    testWidgets('the chips count what tapping them would show', (
      WidgetTester tester,
    ) async {
      await pumpSeals(tester);

      expect(find.text('Sealed · 4'), findsOneWidget);
      expect(find.text('Ready to release · 2'), findsOneWidget);
    });

    testWidgets('a pull to refresh asks both again', (
      WidgetTester tester,
    ) async {
      final SealsController controller = await pumpSeals(tester);

      await controller.load();
      await settle(tester);

      expect(seals.asked, <bool>[false, true, false, true]);
    });
  });

  group('what may come off', () {
    testWidgets('is the queue the server returned, not a sum of the rows', (
      WidgetTester tester,
    ) async {
      await pumpSeals(tester);
      await showQueue(tester, 'Ready to release');

      expect(sealsOnScreen(tester), <String>[
        'MCQ-SL-2627-00002',
        'MCQ-SL-2627-00003',
      ]);
    });

    testWidgets('badges a row the queue returned even where its own key is '
        'missing', (WidgetTester tester) async {
      await pumpSeals(tester);

      // Nothing on this payload says it is ready; `ready=1` returning it is
      // the whole of the evidence.
      expect(sealSettledQuietly.readyToRelease, isFalse);
      expect(tileFor(tester, 'MCQ-SL-2627-00003').readyToRelease, isTrue);
      expect(find.text('Ready to release'), findsNWidgets(2));
    });

    testWidgets('says nothing of the kind about a seal already off', (
      WidgetTester tester,
    ) async {
      await pumpSeals(tester);

      expect(tileFor(tester, 'MCQ-SL-2627-00004').readyToRelease, isFalse);
      expect(find.text('Reopened'), findsOneWidget);
    });

    testWidgets('an empty queue is an answer, not a dead end', (
      WidgetTester tester,
    ) async {
      seals = FakeFieldSealRepository(ready: const <FieldSeal>[]);
      await pumpSeals(tester);
      await showQueue(tester, 'Ready to release');

      expect(find.text('Nothing to release'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Clear search'), findsNothing);
    });
  });

  group('the search box', () {
    Future<void> searchFor(WidgetTester tester, String term) async {
      await tester.enterText(find.byType(EditableText), term);
      await settle(tester);
    }

    testWidgets('narrows the rows in hand without calling', (
      WidgetTester tester,
    ) async {
      await pumpSeals(tester);
      await searchFor(tester, 'Bashir');

      expect(sealsOnScreen(tester), <String>['MCQ-SL-2627-00003']);
      // The endpoint takes no search term: two calls in, two calls out.
      expect(seals.calls, 2);
    });

    testWidgets('finds a shop by its seal number', (WidgetTester tester) async {
      await pumpSeals(tester);
      await searchFor(tester, '2627-00002');

      expect(sealsOnScreen(tester), <String>['MCQ-SL-2627-00002']);
    });

    testWidgets('narrows the queue it is on, and its chip counts', (
      WidgetTester tester,
    ) async {
      await pumpSeals(tester);
      await showQueue(tester, 'Ready to release');
      await searchFor(tester, 'Noor');

      expect(sealsOnScreen(tester), <String>['MCQ-SL-2627-00002']);
      expect(find.text('Sealed · 1'), findsOneWidget);
      expect(find.text('Ready to release · 1'), findsOneWidget);
    });

    testWidgets('offers the way out of the dead end it made', (
      WidgetTester tester,
    ) async {
      await pumpSeals(tester);
      await searchFor(tester, 'nobody at all');

      expect(find.text('No seals match'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, 'Clear search'));
      await settle(tester);

      expect(sealsOnScreen(tester).length, 4);
    });
  });

  group('a dead radio', () {
    testWidgets('offers a retry, and the rows arrive on it', (
      WidgetTester tester,
    ) async {
      seals = FakeFieldSealRepository(failure: offline);
      await pumpSeals(tester);

      expect(find.text('Could not load the seals'), findsOneWidget);
      expect(find.text(offline.message), findsOneWidget);

      seals.failure = null;
      await tester.tap(find.widgetWithText(AppButton, 'Try again'));
      await settle(tester);

      expect(sealsOnScreen(tester).length, 4);
      expect(find.text('Could not load the seals'), findsNothing);
    });

    testWidgets('rides over rows already up rather than replacing them', (
      WidgetTester tester,
    ) async {
      final SealsController controller = await pumpSeals(tester);

      seals.failure = offline;
      await controller.load();
      await settle(tester);

      expect(find.byType(AppAlert), findsOneWidget);
      expect(sealsOnScreen(tester).length, 4);
    });
  });

  testWidgets('a row leads through to the shop the seal is on', (
    WidgetTester tester,
  ) async {
    await pumpSeals(tester);

    expect(tileFor(tester, 'MCQ-SL-2627-00001').onTap, isNotNull);
  });
}
