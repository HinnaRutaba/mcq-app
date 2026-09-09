import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mcq_app/widgets/widgets.dart';

/// The wide floating pill. Its press has to be *seen* — a button that opens a
/// sheet over itself gets about a tenth of a second to acknowledge the finger,
/// so these are about the scale actually moving, not merely being asked to.
void main() {
  /// The x scale the pill is drawn at. Read off the matrix directly:
  /// `getMaxScaleOnAxis` reports the largest axis, and z stays 1, so it
  /// answers 1.0 for every shrink there is.
  double scaleOf(WidgetTester tester) {
    final Transform transform = tester
        .widgetList<Transform>(
          find.descendant(
            of: find.byType(AppExtendedFab),
            matching: find.byType(Transform),
          ),
        )
        .first;
    return transform.transform.entry(0, 0);
  }

  /// Frame by frame, the way a handset runs it: a single long `pump` delivers
  /// one frame, and a ticker's first tick reports no elapsed time at all.
  Future<void> run(WidgetTester tester, {int ms = 400}) async {
    for (int elapsed = 0; elapsed < ms; elapsed += 16) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Future<void> pumpFab(WidgetTester tester, {VoidCallback? onTap}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppExtendedFab(
              icon: Icons.bolt_rounded,
              label: 'Take Action',
              color: Colors.amber,
              foregroundColor: Colors.black,
              onTap: onTap ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('sinks under the finger and springs back past full size', (
    WidgetTester tester,
  ) async {
    await pumpFab(tester);
    expect(scaleOf(tester), 1);

    final TestGesture press = await tester.startGesture(
      tester.getCenter(find.byType(AppExtendedFab)),
    );
    await run(tester, ms: 200);
    expect(scaleOf(tester), lessThan(0.95));

    await press.up();
    // The overshoot is the release: without it the button stops being pressed
    // rather than letting go.
    double peak = 0;
    for (int elapsed = 0; elapsed < 400; elapsed += 16) {
      await tester.pump(const Duration(milliseconds: 16));
      peak = peak > scaleOf(tester) ? peak : scaleOf(tester);
    }
    expect(peak, greaterThan(1));
    expect(scaleOf(tester), 1);
  });

  testWidgets('a press that slides off the button springs back unpressed', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await pumpFab(tester, onTap: () => taps++);

    final TestGesture press = await tester.startGesture(
      tester.getCenter(find.byType(AppExtendedFab)),
    );
    await run(tester, ms: 200);
    await press.moveBy(const Offset(0, 300));
    await press.up();
    await run(tester);

    expect(scaleOf(tester), 1);
    expect(taps, 0);
  });

  testWidgets('holds the tap back so the press is seen first', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await pumpFab(tester, onTap: () => taps++);

    await tester.tap(find.byType(AppExtendedFab));
    await tester.pump();
    // Nothing yet: whatever this opens would cover the pill mid-press.
    expect(taps, 0);

    await run(tester, ms: 300);
    expect(taps, 1);
  });

  testWidgets('a second press during that wait opens nothing twice', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await pumpFab(tester, onTap: () => taps++);

    await tester.tap(find.byType(AppExtendedFab));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(find.byType(AppExtendedFab));
    await run(tester, ms: 400);

    expect(taps, 1);
  });

  testWidgets('an officer who has turned animations off is not made to wait', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Center(
              child: AppExtendedFab(
                icon: Icons.bolt_rounded,
                label: 'Take Action',
                color: Colors.amber,
                foregroundColor: Colors.black,
                onTap: () => taps++,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AppExtendedFab));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('sits at the height the bar and the page were laid out for', (
    WidgetTester tester,
  ) async {
    await pumpFab(tester);

    expect(tester.getSize(find.byType(AppExtendedFab)).height, 44);
  });
}
