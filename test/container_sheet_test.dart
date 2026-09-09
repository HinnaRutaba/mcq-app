import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mcq_app/config/theme/app_radius.dart';
import 'package:mcq_app/widgets/widgets.dart';

/// The container transform behind the app's sheets: the control that was
/// pressed grows into the sheet, and closing runs it backwards.
///
/// The reveal is a clip over a sheet that is laid out at its final size from
/// the first frame — so these are about the clip, and about the sheet's own
/// rectangle never moving while the clip opens.
void main() {
  const Key sheetKey = Key('sheet');

  // A `ColoredBox` because it is opaque to hit tests, so a drag aimed at the
  // sheet lands on the sheet.
  Widget sheet() => const ColoredBox(
    key: sheetKey,
    color: Color(0xFFFFFFFF),
    child: SizedBox(height: 300, width: double.infinity),
  );

  /// The reveal clip, in the sheet's own coordinates.
  RRect clipOf(WidgetTester tester) {
    final Finder reveal = find.ancestor(
      of: find.byKey(sheetKey),
      matching: find.byWidgetPredicate(
        (Widget widget) => widget is ClipRRect && widget.clipper != null,
      ),
    );
    return (tester.widget(reveal) as ClipRRect).clipper!.getClip(
      tester.getSize(reveal),
    );
  }

  /// Opens the sheet out of a pill at the bottom right, the way the shop's
  /// Take Action button does.
  Future<GlobalKey> pumpAndOpen(
    WidgetTester tester, {
    bool fromButton = true,
  }) async {
    final GlobalKey pill = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: Builder(
            builder: (BuildContext context) => AppExtendedFab(
              key: pill,
              icon: Icons.bolt_rounded,
              label: 'Take Action',
              color: Colors.amber,
              foregroundColor: Colors.black,
              onTap: () => AppContainerSheet.show<void>(
                context,
                from: fromButton ? pill : null,
                fromColor: Colors.amber,
                builder: (BuildContext context) => sheet(),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AppExtendedFab));
    // The button holds the tap back so its own press can be seen first.
    await tester.pump(const Duration(milliseconds: 140));
    await tester.pump();

    return pill;
  }

  testWidgets('grows out of the rectangle of the control that was pressed', (
    WidgetTester tester,
  ) async {
    final GlobalKey pill = await pumpAndOpen(tester);
    final Rect button = AppContainerSheet.rectOf(pill)!;
    final Rect opened = tester.getRect(find.byKey(sheetKey));

    // Early: a pill-sized hole, still the width of the button rather than the
    // width of the sheet.
    await tester.pump(const Duration(milliseconds: 40));
    final RRect early = clipOf(tester);
    expect(early.width, lessThan(opened.width / 2));
    expect(early.height, lessThan(button.height * 2));
    // Round on every corner while it is still a floating pill.
    expect(early.blRadiusY, greaterThan(0));

    await tester.pumpAndSettle();
    final RRect open = clipOf(tester);
    expect(open.width, opened.width);
    expect(open.height, opened.height);
    // And square where it meets the bottom of the screen, with the sheet's
    // own lip on top.
    expect(open.tlRadiusY, AppRadius.xl);
    expect(open.blRadiusY, 0);
  });

  testWidgets('never moves the sheet while the clip opens', (
    WidgetTester tester,
  ) async {
    await pumpAndOpen(tester);

    await tester.pump(const Duration(milliseconds: 40));
    final Rect early = tester.getRect(find.byKey(sheetKey));
    await tester.pumpAndSettle();

    // Nothing is measured and nothing resizes: a sheet whose height arrived
    // late would drag its own contents around mid-transition.
    expect(tester.getRect(find.byKey(sheetKey)), early);
  });

  testWidgets('with no control to grow from, opens out of the bottom edge', (
    WidgetTester tester,
  ) async {
    await pumpAndOpen(tester, fromButton: false);

    await tester.pump(const Duration(milliseconds: 40));
    final RRect early = clipOf(tester);
    final Rect opened = tester.getRect(find.byKey(sheetKey));

    expect(early.width, lessThan(opened.width));
    // Centred, rather than off at the corner a button would have been in.
    expect(
      (early.center.dx - opened.width / 2).abs(),
      lessThan(opened.width / 10),
    );
  });

  testWidgets('a sheet thrown downwards is dismissed', (
    WidgetTester tester,
  ) async {
    await pumpAndOpen(tester);
    await tester.pumpAndSettle();

    await tester.fling(find.byKey(sheetKey), const Offset(0, 300), 1200);
    await tester.pumpAndSettle();

    expect(find.byKey(sheetKey), findsNothing);
  });

  testWidgets('a sheet nudged and let go springs back', (
    WidgetTester tester,
  ) async {
    await pumpAndOpen(tester);
    await tester.pumpAndSettle();
    final Rect resting = tester.getRect(find.byKey(sheetKey));

    await tester.drag(find.byKey(sheetKey), const Offset(0, 30));
    await tester.pumpAndSettle();

    expect(find.byKey(sheetKey), findsOneWidget);
    expect(tester.getRect(find.byKey(sheetKey)), resting);
  });

  testWidgets('tapping outside it closes it', (WidgetTester tester) async {
    await pumpAndOpen(tester);
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.byKey(sheetKey), findsNothing);
  });
}
