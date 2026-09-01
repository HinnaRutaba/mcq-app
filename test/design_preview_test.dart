@Tags(['preview'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcq_app/config/theme/app_colors.dart';
import 'package:mcq_app/config/theme/app_theme.dart';
import 'package:mcq_app/l10n/app_localizations.dart';
import 'package:mcq_app/models/common/money.dart';
import 'package:mcq_app/models/field/beat.dart';
import 'package:mcq_app/models/field/field_activity.dart';
import 'package:mcq_app/models/field/field_card.dart';
import 'package:mcq_app/views/magistrate/field/widgets/activity_summary_card.dart';
import 'package:mcq_app/views/magistrate/field/widgets/beat_queue_tile.dart';
import 'package:mcq_app/views/magistrate/field/widgets/field_card_tile.dart';
import 'package:mcq_app/widgets/widgets.dart';

/// Renders the app's surfaces to PNGs so they can actually be looked at,
/// in both brightnesses, and fails if any of them throws while doing it.
///
///     flutter test test/design_preview_test.dart
///
/// The images land in `build/design_preview/`. **Look at them**: an
/// analyser cannot see a tile whose label is cut in half, a chart that
/// colours by rank instead of by entity, or a skeleton that is invisible
/// against its own card — all three of which this caught.
///
/// Two things it has to do that a normal widget test does not:
///
/// * **Load fonts.** `flutter test` renders every glyph as a box
///   otherwise, which hides exactly the overflow this is looking for.
/// * **`runAsync` around `toImage`.** That call is a real GPU round trip;
///   inside the test binding's fake async zone it completes for a trivial
///   layer tree and simply never completes for a chart, which looks
///   exactly like a hung test.
///
/// It never calls `pumpAndSettle`: the shimmer sweep, the header's ambient
/// glow and the attention pulse repeat forever by design, so nothing ever
/// settles.
/// The Material icon font lives in the Flutter SDK's own cache. `flutter
/// test` does not load it, so without this every glyph is a box — which is
/// useless for judging an interface built out of icons, and worse, hides
/// overflow. The path is derived from the running tester rather than
/// hardcoded, so this works on any machine.
String? _materialIconFont() {
  // .../bin/cache/artifacts/engine/<platform>/flutter_tester
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 6; i++) {
    final candidate =
        File('${dir.path}/material_fonts/MaterialIcons-Regular.otf');
    if (candidate.existsSync()) return candidate.path;
    dir = dir.parent;
  }
  return null;
}

/// The app's own faces, from `assets/fonts/`. They are bundled rather than
/// fetched precisely so that they are available everywhere — including
/// here.
const Map<String, List<String>> _appFonts = {
  'PlusJakartaSans': [
    'assets/fonts/PlusJakartaSans-Regular.ttf',
    'assets/fonts/PlusJakartaSans-Medium.ttf',
    'assets/fonts/PlusJakartaSans-SemiBold.ttf',
    'assets/fonts/PlusJakartaSans-Bold.ttf',
    'assets/fonts/PlusJakartaSans-ExtraBold.ttf',
  ],
  'NotoNastaliqUrdu': ['assets/fonts/NotoNastaliqUrdu-Variable.ttf'],
};

void main() {
  setUpAll(() async {
    Future<void> load(String family, Iterable<String> paths) async {
      final loader = FontLoader(family);
      var any = false;
      for (final path in paths) {
        final file = File(path);
        if (!file.existsSync()) continue;
        any = true;
        loader.addFont(
          Future.value(file.readAsBytesSync().buffer.asByteData()),
        );
      }
      if (any) await loader.load();
    }

    for (final entry in _appFonts.entries) {
      await load(entry.key, entry.value);
    }
    final icons = _materialIconFont();
    if (icons != null) await load('MaterialIcons', [icons]);
  });

  for (final brightness in Brightness.values) {
    final mode = brightness == Brightness.dark ? 'dark' : 'light';

    testWidgets('dashboard tiles · $mode', (tester) async {
      await _shoot(
        tester,
        'dashboard-$mode',
        brightness,
        height: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(
              title: t('beat.queuesTitle'),
              subtitle: t('beat.queuesSub'),
              icon: Icons.checklist_rounded,
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 246,
              children: [
                for (final queue in _queues)
                  BeatQueueTile(queue: queue, onTap: () {}, animate: false),
              ],
            ),
            const SizedBox(height: 22),
            AppSectionHeader(
              title: t('beat.quickActions'),
              icon: Icons.bolt_rounded,
            ),
            Row(
              children: [
                Expanded(
                  child: AppQuickAction(
                    icon: Icons.search_rounded,
                    label: t('nav.find'),
                    onTap: () {},
                  ),
                ),
                Expanded(
                  child: AppQuickAction(
                    icon: Icons.handshake_rounded,
                    label: t('followUps.short'),
                    tone: AppTone.warning,
                    onTap: () {},
                  ),
                ),
                Expanded(
                  child: AppQuickAction(
                    icon: Icons.insights_rounded,
                    label: t('activity.short'),
                    tone: AppTone.info,
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });

    testWidgets('defaulters list · $mode', (tester) async {
      await _shoot(
        tester,
        'defaulters-$mode',
        brightness,
        height: 1000,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FieldCardTile(card: _card(), onTap: () {}, onCall: () {}),
            const SizedBox(height: 12),
            FieldCardTile(card: _card(broken: true), onTap: () {}, onCall: () {}),
            const SizedBox(height: 12),
            FieldCardTile(card: _card(vacant: true), onTap: () {}),
          ],
        ),
      );
    });

    testWidgets('charts · $mode', (tester) async {
      await _shoot(
        tester,
        'charts-$mode',
        brightness,
        height: 1150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ActivitySummaryCard(
              activity: _activity,
              onTap: () {},
              animate: false,
            ),
            const SizedBox(height: 14),
            AppOrdinalBarChart(
              title: t('activity.breakdown'),
              subtitle: t('activity.breakdownSub'),
              animate: false,
              entries: [
                for (final entry in ActivityShareDonut.ordered(_activity))
                  ChartBarEntry(
                    label: tEnum('actionType', entry.key),
                    value: entry.value,
                    icon: ActivityShareDonut.glyphs[entry.key],
                  ),
              ],
            ),
          ],
        ),
      );
    });

    testWidgets('states and controls · $mode', (tester) async {
      await _shoot(
        tester,
        'controls-$mode',
        brightness,
        height: 1150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppMoneyPanel(
              label: t('profile.owesNow'),
              amount: const Money('263100.00'),
              absentLabel: t('card.vacant'),
              facts: [
                AppPill(
                  icon: Icons.event_busy_rounded,
                  tone: AppTone.warning,
                  label: t('card.monthsBehind', args: {'months': '5'}),
                ),
                AppPill(
                  icon: Icons.block_rounded,
                  tone: AppTone.danger,
                  emphasis: true,
                  label: t('card.neverPaid'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const AppButton(label: 'Seal the shop', variant: AppButtonVariant.danger, onPressed: _noop),
            const SizedBox(height: 10),
            const AppButton(label: 'Record a visit', onPressed: _noop),
            const SizedBox(height: 10),
            const AppButton(label: 'Share the payment link', variant: AppButtonVariant.accent, onPressed: _noop),
            const SizedBox(height: 10),
            const AppButton(label: 'Set a reminder', variant: AppButtonVariant.tonal, onPressed: _noop),
            const SizedBox(height: 10),
            const AppButton(label: 'Try again', variant: AppButtonVariant.outline, onPressed: _noop),
            const SizedBox(height: 18),
            AppTimeline(
              animate: false,
              entries: [
                AppTimelineEntry(
                  icon: Icons.lock_rounded,
                  tone: AppTone.danger,
                  emphasis: true,
                  child: AppCard(child: AppText.body('Shop sealed · 12 Aug')),
                ),
                AppTimelineEntry(
                  icon: Icons.handshake_rounded,
                  tone: AppTone.warning,
                  child: AppCard(child: AppText.body('Promise to pay · 2 Aug')),
                ),
                AppTimelineEntry(
                  icon: Icons.directions_walk_rounded,
                  tone: AppTone.info,
                  child: AppCard(child: AppText.body('Visit · 28 Jul')),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const AppSkeletonList(count: 2),
          ],
        ),
      );
    });

    testWidgets('empty state · $mode', (tester) async {
      await _shoot(
        tester,
        'empty-$mode',
        brightness,
        height: 620,
        child: AppEmptyState(
          illustration: AppIllustrationKind.allClear,
          title: t('defaulters.allClear'),
          message: t('defaulters.allClearHelp'),
          actionLabel: t('common.refresh'),
          onAction: () {},
        ),
      );
    });
  }
}

void _noop() {}

Future<void> _shoot(
  WidgetTester tester,
  String name,
  Brightness brightness, {
  required Widget child,
  double height = 900,
  double width = 400,
}) async {
  AppTranslations.use(AppLocale.en);
  tester.view.physicalSize = Size(width * 2, height * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(brightness),
        home: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  // Not pumpAndSettle: the shimmer sweep, the ambient glow and the
  // attention pulse repeat forever by design, so settling never happens.
  // Pump past the entrance animations instead and shoot the frame.
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }

  // The darkroom doubles as a regression test: an overflow, a bad
  // constraint or a missing asset throws during layout or paint, and it
  // throws here whether or not anybody looks at the PNG afterwards.
  expect(tester.takeException(), isNull, reason: 'while rendering $name');

  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  // `toImage` is a real GPU round trip. Inside the test binding's fake
  // async zone it can complete for a trivial layer tree and simply never
  // complete for a complex one — a chart, a tooltip, anything with its own
  // shader — which looks exactly like a hung test. `runAsync` gives it the
  // real event loop.
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data;
  });

  final dir = Directory('build/design_preview')..createSync(recursive: true);
  File('${dir.path}/$name.png').writeAsBytesSync(
    bytes!.buffer.asUint8List(),
  );
}

// ---------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------

final List<BeatQueue> _queues = [
  BeatQueue.fromJson(const {
    'key': 'defaulters',
    'count': 42,
    'amount': '2198409.10',
    'endpoint': 'enforcement/field/defaulters',
    'tone': 'danger',
  }),
  BeatQueue.fromJson(const {
    'key': 'follow_ups_due',
    'count': 7,
    'endpoint': 'x',
    'tone': 'warning',
  }),
  BeatQueue.fromJson(const {
    'key': 'awaiting_unseal',
    'count': 2,
    'endpoint': 'x',
    'tone': 'success',
  }),
  BeatQueue.fromJson(const {
    'key': 'sealed_shops',
    'count': 5,
    'amount': '410500.00',
    'endpoint': 'x',
    'tone': 'danger',
  }),
  BeatQueue.fromJson(const {
    'key': 'open_cases',
    'count': 0,
    'endpoint': 'x',
    'tone': 'info',
  }),
  BeatQueue.fromJson(const {
    'key': 'assigned_to_me',
    'count': 3,
    'endpoint': 'x',
    'tone': 'primary',
  }),
];

FieldCard _card({bool broken = false, bool vacant = false}) =>
    FieldCard.fromJson({
      'property_id': broken ? 2 : (vacant ? 3 : 1),
      'property_code': 'MCQ-CR-001001',
      'shop_no': '14-B',
      'market_name': 'Liaquat Bazaar',
      'area_name': 'Circular Road',
      'allotment_no': 'MCQ-AL-00089',
      'allottee_name': vacant ? null : 'Nadeem Ahmed',
      'mobile_no': vacant ? null : '03001234567',
      'outstanding': vacant ? null : '263100.00',
      'months_behind': vacant ? 0 : 5,
      'days_overdue': vacant ? null : 96,
      'never_paid': !vacant,
      'is_vacant': vacant,
      'open_case_id': vacant ? null : 12,
      if (!vacant)
        'commitment': {
          'promised_payment_date': '2026-09-06',
          'days_remaining': broken ? -5 : 8,
          'broken': broken,
        },
    });

final FieldActivity _activity = FieldActivity.fromJson(const {
  'period_days': 30,
  'visits': 34,
  'fines_imposed': 4,
  'fines_amount': '48000.00',
  'shops_sealed': 2,
  'seals_released': 1,
  'collected_in_your_areas': '412750.00',
  'receipts_in_your_areas': 19,
  'by_action_type': {
    'site_visit': 21,
    'verbal_warning': 6,
    'payment_promised': 4,
    'notice_served': 3,
    'seal': 2,
    'unseal': 1,
  },
});
