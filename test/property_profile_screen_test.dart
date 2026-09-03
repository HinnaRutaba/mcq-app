import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:mcq_app/controllers/property_profile_controller.dart';
import 'package:mcq_app/core/network/api_exception.dart';
import 'package:mcq_app/data/repositories/enforcement_case_repository.dart';
import 'package:mcq_app/data/repositories/reporting_repository.dart';
import 'package:mcq_app/core/utils/dialer.dart';
import 'package:mcq_app/core/utils/map_launcher.dart';
import 'package:mcq_app/models/api_refs.dart';
import 'package:mcq_app/models/defaulter_card.dart';
import 'package:mcq_app/models/property_profile.dart';
import 'package:mcq_app/views/magistrate/property/property_profile_screen.dart';
import 'package:mcq_app/views/magistrate/property/widgets/case_card.dart';
import 'package:mcq_app/views/magistrate/property/widgets/holder_actions.dart';
import 'package:mcq_app/views/magistrate/property/widgets/profile_header.dart';
import 'package:mcq_app/widgets/widgets.dart';

import 'support/dashboard_fixtures.dart';
import 'support/property_profile_fixtures.dart';

/// The property profile, end to end over its three endpoints: the profile
/// itself, the case list read across pages, and one case's visit timeline.
void main() {
  late FakeReportingRepository reporting;
  late FakeEnforcementCaseRepository caseRepository;

  const ApiException offline = ApiException(
    message: 'No connection. Check your signal and try again.',
    failure: ApiFailure.network,
  );

  /// The row an officer taps to get here — the same shop as the fixtures.
  final DefaulterCard card = defaultersFixture.first;

  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  /// Moves the page to a tab, the way tapping its chip does.
  Future<void> openTab(WidgetTester tester, ProfileTab tab) async {
    Get.find<PropertyProfileController>().showTab(tab);
    await settle(tester);
  }

  Future<void> pumpProfile(
    WidgetTester tester, {
    DefaulterCard? from,
    double height = 6000,
  }) async {
    // Tall enough that the whole page is laid out: a sliver list does not
    // build what is below the fold, and the timeline is the bottom third.
    tester.view
      ..physicalSize = Size(420, height)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Deleted first: `Get.put` is put-*if-absent*, so a fake put over an
    // existing registration would be silently dropped and the test would run
    // against the one it meant to replace.
    Get.delete<ReportingRepository>(force: true);
    Get.put<ReportingRepository>(reporting, permanent: true);
    Get.delete<EnforcementCaseRepository>(force: true);
    Get.put<EnforcementCaseRepository>(caseRepository, permanent: true);

    await tester.pumpWidget(
      MaterialApp(
        home: PropertyProfileScreen(propertyId: fixturePropertyId, card: from),
      ),
    );
    await settle(tester);
  }

  setUp(() {
    Get.reset();
    reporting = FakeReportingRepository();
    caseRepository = FakeEnforcementCaseRepository();
  });

  tearDown(Get.reset);

  group('the shop', () {
    testWidgets('is read from the profile endpoint', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester);

      expect(reporting.lastPropertyId, fixturePropertyId);
      expect(
        find.text('Shop S-22, Liaquat Bazaar, Jinnah Road, Quetta'),
        findsOneWidget,
      );
      expect(find.text('MCQ-JR-000118'), findsOneWidget);
      expect(find.text('Register 949 · 949/JR/0118'), findsOneWidget);
      expect(find.text('Zone 1 - Zarghoon'), findsOneWidget);
      // Bare strings with no tone of their own, shown as stated.
      expect(find.text('Allotted'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('says where the money stands, on the server’s own total', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester);
      await openTab(tester, ProfileTab.owed);

      // The three parts of the debt, as bars against each other.
      expect(find.text('Rs 13,500'), findsOneWidget);
      expect(find.text('Rs 162,700'), findsOneWidget);
      expect(find.text('Rs 11,250'), findsOneWidget);
      expect(find.text('14 months unpaid'), findsOneWidget);
      // Not the three above added up here — the total the server sent.
      expect(find.text('Total outstanding'), findsOneWidget);
      expect(find.text('Never'), findsOneWidget);
    });

    testWidgets('the tabs are how the rest of it is reached', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester);

      // The unit, on the tab the screen opens on.
      expect(find.text('Register 949 · 949/JR/0118'), findsOneWidget);
      expect(find.text('Total outstanding'), findsNothing);

      await tester.tap(find.text('Owed'));
      await settle(tester);

      expect(find.text('Total outstanding'), findsOneWidget);
      expect(find.text('Register 949 · 949/JR/0118'), findsNothing);
    });
  });

  group('the holder', () {
    testWidgets('is named, with a way to call them', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester);

      // Once on the header, once on the card.
      expect(find.text('Muhammad Iqbal'), findsNWidgets(2));
      expect(find.text('5440012345671'), findsOneWidget);
      expect(find.text('ALT-2019-041'), findsOneWidget);
    });

    testWidgets('can be reached from the header, and the shop found', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester);

      // Gathered on the header rather than one per card, and there whichever
      // tab is open — the officer is standing in front of the shop.
      expect(find.widgetWithText(AppHeroAction, 'Call'), findsOneWidget);
      expect(find.widgetWithText(AppHeroAction, 'Message'), findsOneWidget);
      expect(find.widgetWithText(AppHeroAction, 'Directions'), findsOneWidget);

      await openTab(tester, ProfileTab.history);

      expect(find.widgetWithText(AppHeroAction, 'Call'), findsOneWidget);
    });

    testWidgets('what the shop owes leads the header', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester);

      expect(find.text('Owes right now'), findsOneWidget);
      // The server's rent total, and never a fine folded into it.
      expect(find.text('Rs 187,450'), findsWidgets);
      expect(find.text('14 months behind'), findsOneWidget);
      expect(find.text('Never paid'), findsOneWidget);
    });

    testWidgets('the next visit rides on the owed block', (
      WidgetTester tester,
    ) async {
      await pumpProfile(
        tester,
        from: DefaulterCard(
          propertyId: fixturePropertyId,
          outstanding: '187450.00',
          nextVisitDate: DateTime(2026, 9, 12),
        ),
      );

      expect(find.text('Visit 12 Sep 2026'), findsOneWidget);
    });

    testWidgets('a promise names the day it comes due, as the list does', (
      WidgetTester tester,
    ) async {
      await pumpProfile(
        tester,
        from: DefaulterCard(
          propertyId: fixturePropertyId,
          outstanding: '187450.00',
          nextVisitDate: DateTime(2026, 9, 12),
          commitment: const <String, dynamic>{'promised_on': '2026-09-12'},
        ),
      );

      // The same day, worded the way the defaulters list words it — one fact
      // across both screens, not two.
      expect(find.text('Promised · 12 Sep 2026'), findsOneWidget);
      expect(find.text('Visit 12 Sep 2026'), findsNothing);
    });

    testWidgets('a profile that reports no months keeps the row’s own', (
      WidgetTester tester,
    ) async {
      // The payload omits `unpaid_months` for some shops, which parses to 0.
      // That is not "not behind", and it must not erase what the list knew.
      reporting = FakeReportingRepository(
        profile: PropertyProfile.fromJson(<String, dynamic>{
          ...propertyProfileJson,
          'position': <String, dynamic>{
            ...propertyProfileJson['position']! as Map<String, dynamic>,
            'unpaid_months': null,
          },
        }),
      );
      await pumpProfile(
        tester,
        from: DefaulterCard(
          propertyId: fixturePropertyId,
          outstanding: '187450.00',
          monthsBehind: 14,
        ),
      );

      expect(find.text('14 months behind'), findsOneWidget);
    });

    testWidgets('a shop nobody holds says so', (WidgetTester tester) async {
      reporting = FakeReportingRepository(
        profile: vacantPropertyProfileFixture,
      );
      await pumpProfile(tester);

      expect(find.text('Vacant unit'), findsOneWidget);
      expect(
        find.text('Nobody holds this shop on the register'),
        findsOneWidget,
      );
      // Nobody to call, but the shop is still somewhere.
      expect(find.widgetWithText(AppHeroAction, 'Call'), findsNothing);
      expect(find.widgetWithText(AppHeroAction, 'Directions'), findsOneWidget);

      await openTab(tester, ProfileTab.owed);

      // A vacant shop can still owe rent, so the figures stay.
      expect(find.text('Total outstanding'), findsOneWidget);
    });
  });

  group('the header collapsing', () {
    /// The sliver itself is not a box; measure the block it paints.
    Finder headerBox() => find
        .descendant(
          of: find.byType(ProfileHeader),
          matching: find.byType(ClipRRect),
        )
        .first;

    double headerHeight(WidgetTester tester) =>
        tester.getSize(headerBox()).height;

    double headerBottom(WidgetTester tester) =>
        tester.getRect(headerBox()).bottom;

    /// What the header names, so the same four things can be asked for at
    /// both ends of the collapse.
    Finder inHeader(WidgetTester tester, Finder matching) =>
        find.descendant(of: find.byType(ProfileHeader), matching: matching);

    testWidgets('keeps the shop, the figure and the actions, smaller', (
      WidgetTester tester,
    ) async {
      // A real handset's worth of screen, so there is something to scroll.
      await pumpProfile(tester, height: 800);

      final double expanded = headerHeight(tester);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await settle(tester);

      final double collapsed = headerHeight(tester);
      expect(collapsed, lessThan(expanded));

      // What survives, in the order the bar reads: which shop and who holds
      // it, the figure on its plate, then the actions.
      expect(inHeader(tester, find.text('S-22 · Liaquat Bazaar')), findsOne);
      expect(inHeader(tester, find.text('Muhammad Iqbal')), findsOne);
      expect(inHeader(tester, find.text('Rs 187,450')), findsOne);
      expect(inHeader(tester, find.byType(AppHeroAction)), findsNWidgets(3));

      // What goes: the pills under the figure, and the note beside them.
      expect(find.text('14 months behind'), findsNothing);
      expect(
        find.text('Rent arrears only — a fine is a separate debt'),
        findsNothing,
      );
    });

    testWidgets('declares the height its own block came out at', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester, height: 800);

      /// The block the header paints, which is laid out to its own height
      /// whatever the header declares.
      Finder block() => inHeader(tester, find.byType(Column)).first;

      /// Stated extents that had drifted from the block showed up here: dead
      /// space under the action chips at one end, a clipped chip at the other.
      void expectNoSlack(WidgetTester tester) {
        expect(
          tester.getRect(block()).bottom,
          closeTo(headerBottom(tester), 0.5),
        );
        expect(
          headerBottom(tester) -
              tester
                  .getRect(inHeader(tester, find.byType(HolderActions)))
                  .bottom,
          lessThan(30),
        );
      }

      expectNoSlack(tester);

      // And at the other end, where the block is a different height.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await settle(tester);

      expectNoSlack(tester);
    });

    testWidgets('leaves the tabs pinned under it, and working', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester, height: 800);

      final Finder tabs = find.byType(AppChipTabs<ProfileTab>);
      final double before = tester.getTopLeft(tabs).dy;

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await settle(tester);

      // Riding up with the header, but stopping under the collapsed bar.
      final double after = tester.getTopLeft(tabs).dy;
      expect(after, lessThan(before));
      expect(after, greaterThanOrEqualTo(kToolbarHeight));

      // And still the switch, not a picture of one.
      await tester.tap(find.text('Cases'));
      await settle(tester);
      expect(find.byType(CaseCard), findsWidgets);
    });
  });

  group('the cases', () {
    testWidgets('are this property’s, found by reading pages', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester);
      await openTab(tester, ProfileTab.cases);

      // `enforcement/cases` publishes no property filter, so the profile
      // reads pages and keeps the rows naming its own property.
      expect(caseRepository.pagesRequested, <int>[1, 2]);
      expect(find.byType(CaseCard), findsNWidgets(2));
      expect(find.text('MCQ-EC-2627-00204'), findsOneWidget);
      expect(find.text('MCQ-EC-2526-00187'), findsOneWidget);
      // Another shop's case shared page one and must not be here.
      expect(find.text('MCQ-EC-2627-00900'), findsNothing);
    });

    testWidgets('a case says what the debt has done since it opened', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester);
      await openTab(tester, ProfileTab.cases);

      expect(
        find.text('Rs 187,450 owed · Rs 150,200 when it opened'),
        findsOneWidget,
      );
      expect(find.text('Debt grown'), findsNWidgets(2));
      expect(find.text('Visit overdue'), findsOneWidget);
    });
  });

  group('the timeline', () {
    testWidgets('opens on the case the card named', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester, from: card);
      await openTab(tester, ProfileTab.history);

      expect(caseRepository.timelinesRequested, contains(fixtureLiveCaseId));
      // Every entry, in the order the server sent them.
      expect(find.text('Visited the shop'), findsOneWidget);
      expect(find.text('Warned in person'), findsOneWidget);
      expect(find.text('Notice handed over'), findsOneWidget);
      expect(find.text('Fine imposed'), findsOneWidget);
    });

    testWidgets('carries what was recorded on the day', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester);
      await openTab(tester, ProfileTab.history);

      // The figure quoted to the shopkeeper at the visit, and the fine — two
      // debts, so two rows, never one total.
      expect(find.text('Rs 150,200 owed on the day'), findsOneWidget);
      expect(find.text('Rs 187,450 owed on the day'), findsOneWidget);
      expect(find.text('Rs 5,000 fine'), findsOneWidget);
      expect(find.text('Witness Ghulam Rasool'), findsOneWidget);
      expect(find.text('Promised 20 Jul 2026'), findsOneWidget);
      // The audit trail on an entry written with no signal.
      expect(find.text('Offline · synced 2h later'), findsOneWidget);
    });

    testWidgets('reading another case swaps it', (WidgetTester tester) async {
      await pumpProfile(tester, from: card);
      await openTab(tester, ProfileTab.cases);

      await tester.tap(find.text('MCQ-EC-2526-00187'));
      await settle(tester);

      expect(caseRepository.timelinesRequested.last, fixtureClosedCaseId);
      // Choosing a case is asking for its history, so the page goes there.
      expect(
        Get.find<PropertyProfileController>().tab.value,
        ProfileTab.history,
      );
      expect(find.text('Second notice served.'), findsOneWidget);
      expect(find.text('Fine imposed'), findsNothing);
    });

    testWidgets('a timeline that will not load is one hole, not a wall', (
      WidgetTester tester,
    ) async {
      caseRepository = FakeEnforcementCaseRepository(timelineFailure: offline);
      await pumpProfile(tester);
      await openTab(tester, ProfileTab.history);

      expect(find.byType(AppAlert), findsOneWidget);
      // The rest of the shop is still reachable.
      await openTab(tester, ProfileTab.overview);
      expect(find.text('MCQ-JR-000118'), findsOneWidget);
      await openTab(tester, ProfileTab.cases);
      expect(find.byType(CaseCard), findsNWidgets(2));
    });
  });

  group('when the bazaar has no signal', () {
    testWidgets('the header still names the shop the officer tapped', (
      WidgetTester tester,
    ) async {
      reporting = FakeReportingRepository(failure: offline);
      caseRepository = FakeEnforcementCaseRepository(failure: offline);
      await pumpProfile(tester, from: card);

      // Drawn from the row that opened the screen, so a failed call does not
      // leave an officer looking at a blank page to find out which shop it is.
      expect(find.text('Muhammad Iqbal'), findsOneWidget);
      expect(find.text('S-22 · Liaquat Bazaar'), findsOneWidget);
      expect(find.text('Rs 187,450'), findsOneWidget);

      expect(find.text('Could not load this shop'), findsOneWidget);

      // Signal back, and the same button loads what failed.
      reporting.failure = null;
      caseRepository.failure = null;
      await tester.tap(find.text('Try again'));
      await settle(tester);

      expect(find.text('Register 949 · 949/JR/0118'), findsOneWidget);

      await openTab(tester, ProfileTab.cases);
      expect(find.byType(CaseCard), findsNWidgets(2));
    });
  });

  group('the controller', () {
    test('falls back to the card until the profile lands', () {
      final PropertyProfileController controller = PropertyProfileController(
        propertyId: fixturePropertyId,
        card: defaultersFixture.first,
        reportingRepository: FakeReportingRepository(failure: offline),
        caseRepository: FakeEnforcementCaseRepository(failure: offline),
      );

      expect(controller.holder, 'Muhammad Iqbal');
      expect(controller.propertyLine, 'S-22 · Liaquat Bazaar');
      expect(controller.tab.value, ProfileTab.overview);
      // The row's own number and pin, so the header can act before the
      // profile lands.
      expect(controller.mobileNo, '03001234511');
      expect(controller.canOpenMap, isTrue);
      expect(controller.outstanding, '187450.00');
      expect(controller.unpaidMonths, 14);
      // The case the row named, before any list has been read.
      expect(controller.selectedCaseId.value, isNull);
    });

    test('opens on the case the row named', () async {
      final PropertyProfileController controller = Get.put(
        PropertyProfileController(
          propertyId: fixturePropertyId,
          card: defaultersFixture.first,
          reportingRepository: reporting,
          caseRepository: caseRepository,
        ),
      );
      await controller.load();

      expect(controller.selectedCaseId.value, fixtureLiveCaseId);
      expect(controller.cases.length, 2);
      expect(controller.actions.length, liveCaseActionsJson.length);
    });
  });

  group('the header actions', () {
    testWidgets('hand the number to the dialler and to the messaging app', (
      WidgetTester tester,
    ) async {
      final _FakeDialer dialer = _FakeDialer();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HolderActions(mobileNo: '0300 123-4511', dialer: dialer),
          ),
        ),
      );

      await tester.tap(find.text('Call'));
      await tester.tap(find.text('Message'));
      await tester.pumpAndSettle();

      expect(dialer.dialled, <String>['0300 123-4511']);
      expect(dialer.messaged, <String>['0300 123-4511']);
      // Nothing to point a map at, so nothing offered.
      expect(find.text('Directions'), findsNothing);
    });

    testWidgets('open the shop on a map', (WidgetTester tester) async {
      final _FakeMaps maps = _FakeMaps();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HolderActions(
              point: const GeoPoint(
                latitude: '30.1889120',
                longitude: '66.9987450',
              ),
              address: 'Shop S-22, Liaquat Bazaar',
              maps: maps,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Directions'));
      await tester.pumpAndSettle();

      expect(maps.opened, hasLength(1));
      expect(maps.opened.single.point?.latitude, '30.1889120');
    });

    test('a fix beats an address, and neither means no map', () {
      const GeoPoint fix = GeoPoint(
        latitude: '30.1889120',
        longitude: '66.9987450',
      );

      expect(
        MapLauncher.targetFor(point: fix, address: 'Liaquat Bazaar').toString(),
        'https://www.google.com/maps/search/?api=1&query=30.188912%2C66.998745',
      );
      expect(
        MapLauncher.targetFor(address: 'Shop S-22, Liaquat Bazaar').toString(),
        'https://www.google.com/maps/search/'
        '?api=1&query=Shop+S-22%2C+Liaquat+Bazaar',
      );
      // A point the register holds no numbers for is not a point.
      expect(MapLauncher.targetFor(point: const GeoPoint()), isNull);
      expect(MapLauncher.targetFor(address: '  '), isNull);
    });
  });
}

/// A dialler and a map a test can press, since the platform has neither.
class _FakeDialer extends Dialer {
  final List<String> dialled = <String>[];
  final List<String> messaged = <String>[];

  @override
  Future<bool> call(String mobileNo) async {
    dialled.add(mobileNo);
    return true;
  }

  @override
  Future<bool> message(String mobileNo) async {
    messaged.add(mobileNo);
    return true;
  }
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
