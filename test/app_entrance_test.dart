import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mcq_app/widgets/widgets.dart';

/// The entrance animation, and the one case where it must not run.
void main() {
  Future<void> pump(WidgetTester tester, {required bool reduceMotion}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: const Scaffold(
            body: AppEntrance(index: 2, child: Text('Waiting for you')),
          ),
        ),
      ),
    );
  }

  testWidgets('brings its child in', (WidgetTester tester) async {
    await pump(tester, reduceMotion: false);

    expect(find.byType(Animate), findsOneWidget);

    // Mid-flight it is lifted off its resting place.
    await tester.pump(const Duration(milliseconds: 180));
    final midway = tester.getTopLeft(find.text('Waiting for you'));

    // And it finishes there: a child left part-slid, or never started because
    // the stagger timer went unhandled, is the failure worth catching.
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    final settled = tester.getTopLeft(find.text('Waiting for you'));

    // It lifted, and it came to rest.
    expect(settled.dy, lessThan(midway.dy));

    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester.getTopLeft(find.text('Waiting for you')),
      settled,
      reason: 'the entrance runs once and stops, it does not keep moving',
    );
  });

  testWidgets('stays still when the officer has asked it to', (
    WidgetTester tester,
  ) async {
    await pump(tester, reduceMotion: true);

    expect(
      find.byType(Animate),
      findsNothing,
      reason: 'reduce motion is an accessibility setting, not a preference',
    );
    expect(find.text('Waiting for you'), findsOneWidget);
  });
}
