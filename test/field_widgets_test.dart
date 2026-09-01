import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcq_app/config/theme/app_text_theme_locale.dart';
import 'package:mcq_app/config/theme/app_theme.dart';
import 'package:mcq_app/l10n/app_localizations.dart';
import 'package:mcq_app/models/field/beat.dart';
import 'package:mcq_app/models/field/field_card.dart';
import 'package:mcq_app/models/field/field_seal.dart';
import 'package:mcq_app/models/field/follow_up.dart';
import 'package:mcq_app/views/magistrate/field/widgets/beat_queue_tile.dart';
import 'package:mcq_app/views/magistrate/field/widgets/field_card_tile.dart';
import 'package:mcq_app/views/magistrate/field/widgets/field_seal_card.dart';
import 'package:mcq_app/views/magistrate/field/widgets/follow_up_card.dart';

/// The card is the app. It is rendered on six screens, in two languages,
/// in two brightnesses, from three different endpoints — so these are the
/// tests that stop one of those combinations quietly breaking.
///
/// A widget that renders without an exception is most of the assertion;
/// the rest checks the facts the officer acts on differently — "Vacant"
/// where there is no figure, and no "0 days overdue" pill where nothing is
/// past due.
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  AppLocale locale = AppLocale.en,
  Brightness brightness = Brightness.light,
}) async {
  AppTranslations.use(locale);
  final base = brightness == Brightness.dark ? AppTheme.dark : AppTheme.light;
  await tester.pumpWidget(
    MaterialApp(
      theme: base.copyWith(
        textTheme: LocalisedTextTheme.of(locale, brightness),
      ),
      home: Directionality(
        textDirection: locale.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          body: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

FieldCard _defaulter({
  bool broken = false,
  bool vacant = false,
  int? daysOverdue = 148,
}) =>
    FieldCard.fromJson({
      'property_id': 101,
      'property_code': 'MCQ-CR-001001',
      'shop_no': 'P-1',
      'area_name': 'Circular Road',
      'market_name': 'Liaquat Market',
      'allotment_no': 'MCQ-AL-00089',
      'allottee_name': vacant ? null : 'Nadeem Ahmed',
      'mobile_no': vacant ? null : '03001234567',
      'outstanding': vacant ? null : '263100.00',
      'months_behind': vacant ? 0 : 5,
      'days_overdue': daysOverdue,
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

void main() {
  tearDown(() => AppTranslations.use(AppLocale.en));

  group('FieldCardTile', () {
    testWidgets('draws the amount, the place and the commitment',
        (tester) async {
      await _pump(tester, FieldCardTile(card: _defaulter(), onTap: () {}));

      expect(tester.takeException(), isNull);
      expect(find.textContaining('263,100.00'), findsOneWidget);
      expect(find.textContaining('MCQ-CR-001001'), findsOneWidget);
      expect(find.textContaining('MCQ-AL-00089'), findsOneWidget);
      // The commitment pill — the most valuable thing on the card.
      expect(find.textContaining('8 days left'), findsOneWidget);
    });

    testWidgets('a broken promise says so, not just in red', (tester) async {
      await _pump(tester, FieldCardTile(card: _defaulter(broken: true)));
      expect(find.textContaining('Promise broken'), findsOneWidget);
    });

    testWidgets('a vacant unit reads "Vacant", never a zero', (tester) async {
      await _pump(tester, FieldCardTile(card: _defaulter(vacant: true)));

      expect(tester.takeException(), isNull);
      expect(find.text('Vacant'), findsWidgets);
      expect(find.textContaining('0.00'), findsNothing);
      // Nobody holds it, so there is nobody to call.
      expect(find.text('Call'), findsNothing);
    });

    testWidgets('nothing past due draws no overdue pill at all',
        (tester) async {
      await _pump(tester, FieldCardTile(card: _defaulter(daysOverdue: null)));
      expect(find.textContaining('days overdue'), findsNothing);
    });

    testWidgets('renders in Urdu, right to left', (tester) async {
      await _pump(
        tester,
        FieldCardTile(card: _defaulter()),
        locale: AppLocale.ur,
      );

      expect(tester.takeException(), isNull);
      // Amounts stay in Western digits, in both languages.
      expect(find.textContaining('263,100.00'), findsOneWidget);
    });

    testWidgets('renders in dark mode', (tester) async {
      await _pump(
        tester,
        FieldCardTile(card: _defaulter(broken: true)),
        brightness: Brightness.dark,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('BeatQueueTile', () {
    testWidgets('a queue with work shows its count and amount',
        (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 190,
          child: BeatQueueTile(
            queue: BeatQueue.fromJson(const {
              'key': 'defaulters',
              'count': 113,
              'amount': '7616662.00',
              'tone': 'danger',
            }),
            onTap: () {},
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      expect(find.text('113'), findsOneWidget);
      expect(find.textContaining('7,616,662.00'), findsOneWidget);
      expect(find.text('Shops behind on payment'), findsOneWidget);
    });

    testWidgets('a cleared queue is good news, not a grey zero',
        (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 190,
          child: BeatQueueTile(
            queue: BeatQueue.fromJson(const {
              'key': 'follow_ups_due',
              'count': 0,
              'tone': 'danger',
            }),
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Nothing to chase today'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('a queue not measured in money shows no figure',
        (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 190,
          child: BeatQueueTile(
            queue: BeatQueue.fromJson(const {
              'key': 'follow_ups_due',
              'count': 4,
              'amount': null,
            }),
            onTap: () {},
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('4'), findsOneWidget);
      expect(find.textContaining('0.00'), findsNothing);
    });
  });

  group('FollowUpCard', () {
    FollowUp of(String state, String now) => FollowUp.fromJson({
          'action_id': 55,
          'kind': 'payment_promised',
          'state': state,
          'days_remaining': state == 'overdue' ? -5 : 8,
          'allottee_name': 'Nadeem Ahmed',
          'property_id': 101,
          'property_code': 'MCQ-CR-001001',
          'shop_no': 'P-1',
          'area_name': 'Circular Road',
          'remarks': 'Said he would pay after Eid',
          'outstanding_at_promise': '263100.00',
          'outstanding_now': now,
        });

    testWidgets('an overdue promise offers escalation and shows both figures',
        (tester) async {
      await _pump(
        tester,
        FollowUpCard(
          followUp: of('overdue', '260100.00'),
          onCall: () {},
          onEscalate: () {},
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Promise broken 5 days ago'), findsOneWidget);
      expect(find.textContaining('263,100.00'), findsOneWidget);
      expect(find.textContaining('260,100.00'), findsOneWidget);
      // The movement is stated in words; the app never computes the
      // difference between two server amounts.
      expect(find.textContaining('come down'), findsOneWidget);
      expect(find.text('What next'), findsOneWidget);
    });

    testWidgets('a balance that has not moved says so', (tester) async {
      await _pump(
        tester,
        FollowUpCard(followUp: of('overdue', '263100.00')),
      );
      expect(find.textContaining('has not moved'), findsOneWidget);
    });

    testWidgets('an upcoming promise offers no escalation', (tester) async {
      await _pump(
        tester,
        FollowUpCard(followUp: of('upcoming', '263100.00')),
      );
      expect(find.text('What next'), findsNothing);
    });
  });

  group('FieldSealCard', () {
    FieldSeal seal({required bool ready}) => FieldSeal.fromJson({
          'seal_id': 7,
          'seal_no': 'SEAL-2627-0007',
          'sealed_on': '2026-07-14',
          'property_id': 101,
          'property_code': 'MCQ-CR-001001',
          'shop_no': 'P-1',
          'area_name': 'Circular Road',
          'allottee_name': 'Nadeem Ahmed',
          'outstanding_now': '260100.00',
          'fines_unpaid': ready ? 0 : 1,
          'fines_paid': ready ? 1 : 0,
          'ready_to_release': ready,
        });

    testWidgets('a settled seal is a job waiting, and says arrears do not gate it',
        (tester) async {
      await _pump(
        tester,
        FieldSealCard(seal: seal(ready: true), onRelease: () {}),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Ready to unseal'), findsOneWidget);
      expect(find.textContaining('do not hold the shutter closed'),
          findsOneWidget);
      // Shown, but explicitly not a gate.
      expect(find.textContaining('260,100.00'), findsOneWidget);
    });

    testWidgets('an unsettled seal is drawn as still sealed', (tester) async {
      await _pump(tester, FieldSealCard(seal: seal(ready: false)));
      expect(find.text('Still sealed'), findsOneWidget);
      expect(find.textContaining('1 fines unpaid'), findsOneWidget);
    });
  });
}
