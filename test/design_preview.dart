import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:mcq_app/app/dependency_injection.dart';
import 'package:mcq_app/config/theme/app_radius.dart';
import 'package:mcq_app/config/theme/app_theme.dart';
import 'package:mcq_app/controllers/auth_controller.dart';
import 'package:mcq_app/controllers/challans_controller.dart';
import 'package:mcq_app/config/theme/app_brand.dart';
import 'package:mcq_app/controllers/dashboard_controller.dart';
import 'package:mcq_app/controllers/definitions_controller.dart';
import 'package:mcq_app/controllers/fine_controller.dart';
import 'package:mcq_app/controllers/defaulters_controller.dart';
import 'package:mcq_app/controllers/property_profile_controller.dart';
import 'package:mcq_app/controllers/theme_controller.dart';
import 'package:mcq_app/controllers/trade_capture_controller.dart';
import 'package:mcq_app/controllers/trade_licences_controller.dart';
import 'package:mcq_app/core/network/api_exception.dart';
import 'package:mcq_app/data/repositories/challan_repository.dart';
import 'package:mcq_app/data/repositories/dashboard_repository.dart';
import 'package:mcq_app/data/repositories/defaulters_repository.dart';
import 'package:mcq_app/data/repositories/person_repository.dart';
import 'package:mcq_app/data/repositories/definitions_repository.dart';
import 'package:mcq_app/data/repositories/enforcement_case_repository.dart';
import 'package:mcq_app/data/repositories/reporting_repository.dart';
import 'package:mcq_app/data/repositories/trade_repository.dart';
import 'package:mcq_app/views/auth/change_password_screen.dart';
import 'package:mcq_app/views/auth/login_screen.dart';
import 'package:mcq_app/models/challan.dart';
import 'package:mcq_app/models/property_profile.dart';
import 'package:mcq_app/models/defaulter_card.dart';
import 'package:mcq_app/models/unit_card.dart';
import 'package:mcq_app/views/magistrate/defaulters/defaulters_screen.dart';
import 'package:mcq_app/views/magistrate/home/home_screen.dart';
import 'package:mcq_app/views/magistrate/magistrate_shell.dart';
import 'package:mcq_app/views/magistrate/more/more_screen.dart';
import 'package:mcq_app/views/magistrate/more/profile_screen.dart';
import 'package:mcq_app/views/magistrate/more/sealed_screen.dart';
import 'package:mcq_app/views/magistrate/round/round_screen.dart';
import 'package:mcq_app/views/magistrate/trade/trade_capture_screen.dart';
import 'package:mcq_app/views/magistrate/trade/trade_licences_screen.dart';
import 'package:mcq_app/views/magistrate/challans/challans_screen.dart';
import 'package:mcq_app/views/magistrate/property/property_profile_screen.dart';
import 'package:mcq_app/views/magistrate/shared/create_fine_screen.dart';
import 'package:mcq_app/views/magistrate/shared/widgets/challan_sheet.dart';
import 'package:mcq_app/views/magistrate/shared/widgets/create_fine_button.dart';
import 'package:mcq_app/widgets/widgets.dart';

import 'support/api_stub.dart';
import 'support/challan_fixtures.dart';
import 'support/dashboard_fixtures.dart';
import 'support/definitions_fixtures.dart';
import 'support/person_fixtures.dart';
import 'support/property_profile_fixtures.dart';
import 'support/trade_fixtures.dart';

/// Renders every screen to a PNG under `test/preview/` so a change can be
/// looked at, not merely analysed. Run it deliberately:
///
///     flutter test test/design_preview.dart --update-goldens
///
/// The filename has no `_test` suffix on purpose: `flutter test` collects only
/// `*_test.dart`, so these stay out of the ordinary suite. They are previews to
/// review, not assertions — a deliberate redesign should never surface as a
/// failing build.
const UnitCard _finedUnit = UnitCard(
  propertyId: 77,
  propertyCode: 'PR-LQ-077',
  shopNo: 'F-3',
  areaId: 2,
  areaName: 'Prince Road',
  marketName: 'Liaquat Bazaar',
  allotmentId: 12,
  allotteeName: 'Abdul Samad',
  mobileNo: '03007654321',
  cnic: '5440099887766',
  outstanding: '4500.00',
);

/// The row the officer tapped to get to the profile. Passed to one entry so
/// the header is previewed the way it actually arrives — with the beat's next
/// visit on it, which none of the profile's own three calls returns.
final DefaulterCard _tappedRow = DefaulterCard(
  propertyId: fixturePropertyId,
  shopNo: 'S-22',
  marketName: 'Liaquat Bazaar',
  allotteeName: 'Muhammad Iqbal',
  outstanding: '187450.00',
  monthsBehind: 14,
  neverPaid: true,
  nextVisitDate: DateTime(2026, 9, 12),
);

void main() {
  setUpAll(() async {
    Get.reset();
    installInMemoryKeychain();
    setupDependencies();
    await _loadRealFonts();
  });

  tearDownAll(Get.reset);

  // Builders rather than widgets, so an entry can set up the state it means to
  // show — the sign-in screen is worth seeing with a failure on it, since that
  // is the state an officer meets at a counter when the password is wrong.
  final screens = <String, Widget Function()>{
    'login': () {
      Get.find<AuthController>().errorMessage.value = null;
      return const LoginScreen();
    },
    'login_error': () {
      Get.find<AuthController>().errorMessage.value =
          'These credentials do not match our records.';
      return const LoginScreen();
    },
    'change_password': () {
      Get.find<AuthController>().errorMessage.value = null;
      return const ChangePasswordScreen();
    },
    'home': () {
      _seedDashboard();
      return const MagistrateHomeScreen();
    },
    // Caught part-way in: the last queue tiles still arriving, and the
    // share bar still drawing itself across.
    'home_arriving': () {
      _seedDashboard();
      return const MagistrateHomeScreen();
    },
    // The header once it has collapsed: the name pinned on a plain bar, with
    // the designation and the beat strip gone.
    'home_collapsed': () {
      _seedDashboard();
      return const MagistrateHomeScreen();
    },
    // The state a area with no signal produces, which the happy path never
    // shows and which is where a dashboard usually falls apart.
    'home_offline': () {
      _seedDashboard(
        failure: const ApiException(
          message: 'No connection. Check your signal and try again.',
          failure: ApiFailure.network,
        ),
      );
      return const MagistrateHomeScreen();
    },
    // One per tab on the bottom bar, so a restructure of the shell shows up
    // as a picture and not only as a passing test.
    // The bar on its own, at a small handset's width and in the real font:
    // whether four labels fit is a question about font metrics, which a
    // widget test cannot answer because it draws every glyph as a square.
    // The button is here because the notch is cut around it — a bar drawn
    // without one shows a gap and no curve.
    'nav_bar': () => Scaffold(
      body: const SizedBox.shrink(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const CreateFineButton(),
      bottomNavigationBar: AppBottomNavBar(
        entries: MagistrateShell.entries,
        currentIndex: 0,
        onTap: (_) {},
        centerGap: CreateFineButton.notchGap,
        centerGapRadius: CreateFineButton.notchRadius,
      ),
    ),
    'defaulters': () {
      _seedDefaulters();
      return const DefaultersScreen();
    },
    // The same list with a state chip on it, which is the only filter that
    // does not go to the server.
    'defaulters_never_paid': () {
      _seedDefaulters().showState(DefaulterState.neverPaid);
      return const DefaultersScreen();
    },
    // The header once the list has been scrolled: the title alone on a pinned
    // bar, with the search box and the chips gone under it.
    'defaulters_collapsed': () {
      _seedDefaulters();
      return const DefaultersScreen();
    },
    'round': () => const RoundScreen(),
    // The licence round: three queues over the officer's own areas, and the
    // doorway lookup that takes the screen over when anything is typed.
    'trade_licences': () {
      _seedTrade();
      return const TradeLicencesScreen();
    },
    'trade_licences_lapsed': () {
      _seedTrade().showQueue(TradeQueue.lapsed);
      return const TradeLicencesScreen();
    },
    // The officer's own captures, which do carry money — and one whose
    // payment link has died, so the consumer number is all the shopkeeper has.
    'trade_licences_captures': () {
      _seedTrade().showQueue(TradeQueue.captures);
      return const TradeLicencesScreen();
    },
    // The doorway answer for a shop that may trade.
    'trade_licences_lookup': () {
      _seedTrade(query: '03304100000');
      return const TradeLicencesScreen();
    },
    // And the one that becomes a field capture. Found-and-lapsed and
    // never-licensed are different conversations, so both are worth seeing.
    'trade_licences_unlicensed': () {
      _seedTrade(query: '03309999999');
      return const TradeLicencesScreen();
    },
    'trade_licences_renewal': () {
      _seedTrade(query: '5440112233445');
      return const TradeLicencesScreen();
    },
    // The capture form, reached from that answer with the number already in
    // it. Nothing here prices the licence — the fee is the tariff's.
    'trade_capture': () {
      _seedTradeCapture();
      return const TradeCaptureScreen(searched: '03309999999', areaId: 1);
    },
    'trade_capture_filled': () {
      _seedTradeCapture();
      return const TradeCaptureScreen(searched: '03001234567', areaId: 1);
    },
    // The bottom of the same form: the shop, and the GPS fix that is what puts
    // somebody at this shopfront if the capture is ever argued with.
    'trade_capture_shop': () {
      _seedTradeCapture();
      return const TradeCaptureScreen(areaId: 1);
    },
    // The billing list: rent bills and penalties in one place, kept apart and
    // never totalled.
    'challans': () {
      _seedChallans();
      return const ChallansScreen();
    },
    'challans_collapsed': () {
      _seedChallans(challans: challanRun(30));
      return const ChallansScreen();
    },
    'challans_fines': () {
      _seedChallans().showFilter(ChallanFilter.fines);
      return const ChallansScreen();
    },
    // A list longer than a page: the plate leads with what the area owes in
    // total, and says underneath how far the scroll has got.
    'challans_paged': () {
      _seedChallans(challans: challanRun(30));
      return const ChallansScreen();
    },
    // One bill read end to end, the sheet a bill row on the Owed tab opens.
    // A rent bill breaks down; a fine is one charge under one label, which is
    // why both are here.
    // A row off the live wire, so the still is of real keys rather than the
    // spec's — a combined demand on a rent tenancy, with no link and no
    // consumer number yet.
    'challan_sheet': () => _sheet(
      // As the Challans list opens it, so the way through to the shop is in
      // the still too.
      ChallanSheet(challan: challanOffTheWire, onOpenShop: () {}),
    ),
    'challan_sheet_fine': () =>
        _sheet(ChallanSheet(challan: challansFixture[2])),
    'more': () => const MoreScreen(),
    'sealed': () => const SealedScreen(),
    'profile': () {
      Get.find<AuthController>().officer.value = officerFixture;
      Get.find<ThemeController>().setColorScheme(
        AppColorScheme.balochistanGreen,
      );
      return const MagistrateProfileScreen();
    },
    // Proof the choice reaches the whole interface and not just the picker:
    // the header, the chips, the tick and the button all follow.
    'profile_indigo': () {
      Get.find<AuthController>().officer.value = officerFixture;
      Get.find<ThemeController>().setColorScheme(AppColorScheme.indigo);
      return const MagistrateProfileScreen();
    },
    // The property profile: the shop the first row of the defaulter list
    // opens, read from all three of its endpoints. One entry per tab, since
    // the header and the actions on it ride above all four.
    'property_profile': () {
      _seedPropertyProfile();
      return PropertyProfileScreen(
        propertyId: fixturePropertyId,
        card: _tappedRow,
      );
    },
    // The header once the page has been scrolled: the figure owed on a bar,
    // with the actions small under it.
    'property_profile_collapsed': () {
      _seedPropertyProfile();
      return PropertyProfileScreen(
        propertyId: fixturePropertyId,
        card: _tappedRow,
      );
    },
    // And caught half way down, which is where a page with little to scroll
    // comes to rest: one block at a middle size, not two over each other.
    'property_profile_half': () {
      _seedPropertyProfile();
      return PropertyProfileScreen(
        propertyId: fixturePropertyId,
        card: _tappedRow,
      );
    },
    'property_profile_owed': () {
      _seedPropertyProfile();
      return const PropertyProfileScreen(propertyId: fixturePropertyId);
    },
    'property_profile_cases': () {
      _seedPropertyProfile();
      return const PropertyProfileScreen(propertyId: fixturePropertyId);
    },
    'property_profile_history': () {
      _seedPropertyProfile();
      return const PropertyProfileScreen(propertyId: fixturePropertyId);
    },
    // The same screen for a property nobody holds — no holder, no tenancy,
    // nobody to call, and rent that may still be owed.
    'property_profile_vacant': () {
      _seedPropertyProfile(profile: vacantPropertyProfileFixture);
      return const PropertyProfileScreen(propertyId: fixturePropertyId);
    },
    'fine': () {
      // Reset the scheme: an earlier entry deliberately switches to indigo and
      // the controller is a permanent singleton, so without this the fine form
      // is previewed in somebody else's brand.
      Get.find<ThemeController>().setColorScheme(
        AppColorScheme.balochistanGreen,
      );
      _seedDefinitions();
      // The areas are the beat's, held by the controller the home
      // screen builds — which a preview of this screen alone stands in for.
      _seedDashboard();
      return const CreateFineScreen();
    },
    // The same form with a shop already chosen, which is how it is reached
    // from a unit's profile.
    'fine_with_shop': () {
      Get.find<ThemeController>().setColorScheme(
        AppColorScheme.balochistanGreen,
      );
      _seedDefinitions();
      return const CreateFineScreen(unit: _finedUnit);
    },
    // The lower half of the same form: who pays, and the evidence strip.
    'fine_evidence': () {
      Get.find<ThemeController>().setColorScheme(
        AppColorScheme.balochistanGreen,
      );
      _seedDefinitions();
      return const CreateFineScreen(unit: _finedUnit);
    },
    // The same form against a area rather than a shop — a hawker, a
    // handcart. The areas come off the officer's beat.
    'fine_in_area': () {
      Get.find<ThemeController>().setColorScheme(
        AppColorScheme.balochistanGreen,
      );
      _seedDefinitions();
      // The areas are the beat's, held by the controller the home
      // screen builds — which a preview of this screen alone stands in for.
      _seedDashboard();
      return const CreateFineScreen();
    },
    // The route carried a property id and nothing else, so the shop's card
    // and the person to bill are fetched before either can be shown.
    'fine_from_property': () {
      _seedDefinitions();
      _seedPropertyProfile();
      return const CreateFineScreen(propertyId: fixturePropertyId);
    },
    // The same block on a shop: filled in from the register, and the area
    // taken off the unit rather than asked for.
    'fine_shop_payer': () {
      Get.find<ThemeController>().setColorScheme(
        AppColorScheme.balochistanGreen,
      );
      _seedDefinitions();
      return const CreateFineScreen(unit: _finedUnit);
    },
    // Its "who pays" block, which an area fine always has to fill in.
    // The CNIC search under "who pays": thirteen digits, and whoever the
    // registers hold offered under the field.
    'fine_person_lookup': () {
      Get.find<ThemeController>().setColorScheme(
        AppColorScheme.balochistanGreen,
      );
      _seedDefinitions();
      _seedDashboard();
      Get.delete<PersonRepository>(force: true);
      Get.put<PersonRepository>(
        FakePersonRepository(fineCount: 2),
        permanent: true,
      );
      return const CreateFineScreen();
    },
    'fine_in_area_payer': () {
      Get.find<ThemeController>().setColorScheme(
        AppColorScheme.balochistanGreen,
      );
      _seedDefinitions();
      return const CreateFineScreen();
    },
  };

  // A dashboard is taller than a form. Rendering it at the default height
  // would crop the half worth reviewing — the activity figures — out of the
  // picture, which is how a layout problem goes unseen.
  const tall = <String, double>{
    'nav_bar': 400,
    'trade_licences': 2100,
    'trade_licences_lapsed': 1800,
    'trade_licences_captures': 1900,
    'trade_licences_lookup': 1500,
    'trade_licences_unlicensed': 1300,
    'trade_licences_renewal': 1500,
    'trade_capture': 3000,
    'trade_capture_filled': 3000,
    'trade_capture_shop': 2200,
    'challans': 2900,
    'challans_collapsed': 1400,
    'challans_fines': 1200,
    'challans_paged': 1800,
    'challan_sheet': 2500,
    'challan_sheet_fine': 2400,
    'fine': 2600,
    'fine_with_shop': 2600,
    'fine_evidence': 2600,
    'fine_from_property': 2600,
    'fine_person_lookup': 3000,
    'fine_shop_payer': 2800,
    'fine_in_area': 2800,
    'fine_in_area_payer': 2800,
    'home': 7000,
    'home_arriving': 2900,
    'home_collapsed': 1400,
    'home_offline': 2100,
    'property_profile': 2400,
    'property_profile_owed': 2900,
    'property_profile_collapsed': 1500,
    'property_profile_half': 1500,
    'property_profile_cases': 2600,
    'property_profile_history': 4400,
    'property_profile_vacant': 2200,
    'defaulters': 2900,
    'defaulters_never_paid': 2900,
    // Short on purpose: the list has to outrun the viewport to be scrolled.
    'defaulters_collapsed': 1400,
    'profile': 3900,
    'profile_indigo': 3900,
  };

  /// Entries to drag before capturing, and by how much.
  const scrolled = <String, double>{
    'home_collapsed': 420,
    'challans_collapsed': 420,
    'defaulters_collapsed': 420,
    'property_profile_collapsed': 420,
    // Enough to take the header to about the middle of its collapse.
    'property_profile_half': 60,
    'fine_evidence': 700,
    'fine_in_area_payer': 620,
    'fine_shop_payer': 700,
    'fine_person_lookup': 900,
    'trade_capture_shop': 1500,
  };

  /// Entries caught part-way through their entrance instead of at rest. A
  /// still of a settled page proves nothing about how it arrives.
  const midFlight = <String, int>{'home_arriving': 330};

  /// A nudge to give once the screen is up — a tab to open on a screen that
  /// registers its own controller, which a builder cannot reach before the
  /// widget it belongs to exists.
  final nudge = <String, void Function()>{
    'property_profile_owed': () =>
        Get.find<PropertyProfileController>().showTab(ProfileTab.owed),
    'property_profile_cases': () =>
        Get.find<PropertyProfileController>().showTab(ProfileTab.cases),
    'property_profile_history': () =>
        Get.find<PropertyProfileController>().showTab(ProfileTab.history),
    // The lookup is debounced, and `pumpAndSettle` does not advance a plain
    // `Timer` — so the answer is asked for straight out rather than waiting
    // 400ms that never pass. The call behind it is the real one.
    'trade_licences_lookup': () =>
        Get.find<TradeLicencesController>().retryLookup(),
    'trade_licences_unlicensed': () =>
        Get.find<TradeLicencesController>().retryLookup(),
    'trade_licences_renewal': () =>
        Get.find<TradeLicencesController>().retryLookup(),
    // The officer pressed the fine button with no shop in mind, so the fine is
    // against somebody in a area.
    'fine_in_area': () {
      final FineController fine = Get.find<FineController>()..setArea(2);
      // Encroachment on the fixture's register — the amount and the section of
      // law under it are the register's own, not typed.
      fine.chooseFineType(fine.fineTypes.last);
    },
    'fine_person_lookup': () {
      final FineController fine = Get.find<FineController>()..setArea(2);
      fine.chooseFineType(fine.fineTypes.last);
      fine.personLookup.cnicController.text = '5440010000000';
      fine.personLookup.search('5440010000000');
    },
    'fine_in_area_payer': () {
      final FineController fine = Get.find<FineController>()..setArea(2);
      fine.offenderNameController.text = 'Noor Ahmed';
      fine.offenderFatherController.text = 'Gul Khan';
      fine.offenderMobileController.text = '03001234567';
      fine.offenderCnicController.text = '5440011223344';
      fine.offenderAddressController.text = 'Handcart, Circular Road';
    },
    // The form as it looks once the officer has filled it in: a trade chosen
    // off the tariff, and the fee on the bar quoted per year rather than
    // multiplied by the term.
    'trade_capture_filled': () {
      final TradeCaptureController capture = Get.find<TradeCaptureController>();
      capture
        ..applicantController.text = 'Abdul Karim'
        ..fatherController.text = 'Muhammad Yousaf'
        ..businessController.text = 'Al Madina Naan Shop'
        ..addressController.text = 'Shop 14, Circular Road, Quetta'
        ..cnicController.text = '5440112233445';
      capture.chooseCategory(tradeTariffFixture.category(40)!);
      capture.setYears(3);
    },
  };

  for (final entry in screens.entries) {
    for (final mode in <String>['light', 'dark']) {
      testWidgets('${entry.key} ($mode)', (WidgetTester tester) async {
        tester.view
          ..physicalSize = Size(1080, tall[entry.key] ?? 2100)
          ..devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        // Built before the theme, because an entry may choose a colour scheme
        // and the whole point of that entry is that the theme follows it.
        final screen = entry.value();
        final scheme = Get.find<ThemeController>().colorScheme.value;

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _withRealFont(
              mode == 'dark' ? AppTheme.dark(scheme) : AppTheme.light(scheme),
            ),
            home: screen,
          ),
        );
        final catchAt = midFlight[entry.key];
        if (catchAt == null) {
          await tester.pumpAndSettle();
        } else {
          // Frame by frame, the way a handset actually runs it. A single big
          // jump fires the stagger's timers *during* the advance, so the
          // controllers they start have not rendered anything by the time the
          // frame is built — the first attempts at this captured a page far
          // emptier than a real device ever shows.
          await tester.pump();
          for (var elapsed = 0; elapsed < catchAt; elapsed += 16) {
            await tester.pump(const Duration(milliseconds: 16));
          }
        }

        final nudged = nudge[entry.key];
        if (nudged != null) {
          nudged();
          await tester.pumpAndSettle();
          await tester.pump(const Duration(milliseconds: 500));
          await tester.pumpAndSettle();
        }

        // A screen that wants to be seen mid-scroll says so, and the preview
        // drags it there — a collapsing header is a state, not a still.
        final scrollBy = scrolled[entry.key];
        if (scrollBy != null) {
          // Whichever scrollable the screen happens to use.
          final scrollable = find.byType(CustomScrollView).evaluate().isNotEmpty
              ? find.byType(CustomScrollView)
              : find.byType(ListView).first;
          await tester.drag(scrollable, Offset(0, -scrollBy));
          await tester.pumpAndSettle();
          // Sections that scrolled into view start their entrance on a plain
          // `Timer`, which `pumpAndSettle` does not advance — without this the
          // capture is of a half-faded page, and the run leaves it pending.
          await tester.pump(const Duration(milliseconds: 500));
          await tester.pumpAndSettle();
        }

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('preview/${entry.key}_$mode.png'),
        );

        // Let whatever was still moving finish, so the run ends with no timer
        // or animation left pending.
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
      });
    }
  }
}

/// Puts a signed-in officer and a dashboard over the fixtures in place of the
/// real ones, so home renders the payload the staging server actually returns
/// instead of reaching for the network.
void _seedDashboard({Object? failure}) {
  Get.find<AuthController>().officer.value = officerFixture;

  // Swap the repository, not the controller. `Get.put` is put-*if-absent*, so
  // putting a controller over the `lazyPut` registration made by
  // `setupDependencies` is silently a no-op and the screen rebuilds the real
  // one. Deleting the repository does remove it — it is not `fenix` — and the
  // controller, which is, drops its instance and keeps its factory, so the
  // screen's `Get.find` builds a fresh one over whatever is registered now.
  Get.delete<DashboardRepository>(force: true);
  Get.put<DashboardRepository>(
    FakeDashboardRepository(failure: failure),
    permanent: true,
  );
  Get.delete<DefaultersRepository>(force: true);
  Get.put<DefaultersRepository>(
    FakeDefaultersRepository(failure: failure),
    permanent: true,
  );
  Get.delete<DashboardController>(force: true);
}

/// Puts the offence register over the fixture and rebuilds the controller that
/// holds it, so the fine form's picker is drawn from rows rather than from a
/// call the preview cannot make.
void _seedDefinitions() {
  Get.find<AuthController>().officer.value = officerFixture;
  Get.delete<DefinitionsRepository>(force: true);
  Get.put<DefinitionsRepository>(FakeDefinitionsRepository(), permanent: true);
  // Permanent, which is what runs `onInit` — and with an officer already set,
  // that loads the rows.
  Get.delete<DefinitionsController>(force: true);
  Get.put<DefinitionsController>(DefinitionsController(), permanent: true);
}

/// Puts the defaulter list and the officer's areas over the fixtures, and
/// drops the controller so it is rebuilt over them. Returns it, so an entry
/// can set the filter it means to show.
DefaultersController _seedDefaulters() {
  Get.delete<DashboardRepository>(force: true);
  Get.put<DashboardRepository>(FakeDashboardRepository(), permanent: true);
  Get.delete<DefaultersRepository>(force: true);
  Get.put<DefaultersRepository>(FakeDefaultersRepository(), permanent: true);
  // `fenix`, so the find below builds a fresh one over the fakes just put.
  Get.delete<DefaultersController>(force: true);
  return Get.find<DefaultersController>();
}

/// Puts the licence queues, the captures and the lookup over the fixtures, and
/// drops the controller so it is rebuilt over them. Returns it, so an entry can
/// choose the queue it means to show.
///
/// [query] is typed into the search box as well as set on the controller: the
/// box is what an officer sees, and a preview of an answer with an empty box
/// above it is a picture of a state the app never reaches.
TradeLicencesController _seedTrade({Object? failure, String? query}) {
  Get.delete<TradeRepository>(force: true);
  Get.put<TradeRepository>(
    FakeTradeRepository(failure: failure),
    permanent: true,
  );
  // `fenix`, so the find below builds a fresh one over the fake just put.
  Get.delete<TradeLicencesController>(force: true);
  final TradeLicencesController controller =
      Get.find<TradeLicencesController>();
  if (query != null) {
    controller.searchController.text = query;
    controller.query.value = query;
  }
  return controller;
}

/// A sheet as `showModalBottomSheet` draws it — the surface, the lip and the
/// bottom edge — so a still of one is a still of what the officer sees.
Widget _sheet(Widget child) => Builder(
  builder: (BuildContext context) => Scaffold(
    backgroundColor: Colors.black54,
    body: Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    ),
  ),
);

/// Puts the billing list over the fixtures and drops the controller so it is
/// rebuilt over them. Returns it, so an entry can choose the filter it means to
/// show.
ChallansController _seedChallans({List<Challan>? challans}) {
  Get.delete<ChallanRepository>(force: true);
  Get.put<ChallanRepository>(
    FakeChallanRepository(challans: challans),
    permanent: true,
  );
  // `fenix`, so the find below builds a fresh one over the fake just put.
  Get.delete<ChallansController>(force: true);
  return Get.find<ChallansController>();
}

/// The capture form registers its own controller, so only the repository under
/// it is swapped — and the controller is dropped, because `Get.put` is
/// put-*if-absent* and the form would otherwise adopt the last entry's.
void _seedTradeCapture() {
  Get.delete<TradeRepository>(force: true);
  Get.put<TradeRepository>(FakeTradeRepository(), permanent: true);
  Get.delete<TradeCaptureController>(force: true);
}

/// Puts one property's profile, cases and timeline over the fixtures.
///
/// The screen registers its own controller, so only the repositories under it
/// are swapped.
void _seedPropertyProfile({PropertyProfile? profile}) {
  // An earlier entry deliberately switches to indigo and the theme controller
  // is a permanent singleton, so without this the profile is previewed in
  // somebody else's brand.
  Get.find<ThemeController>().setColorScheme(AppColorScheme.balochistanGreen);
  // `Get.put` is put-*if-absent*, so the screen would adopt the controller the
  // previous entry left registered and never read these repositories.
  Get.delete<PropertyProfileController>(force: true);
  Get.delete<ReportingRepository>(force: true);
  Get.put<ReportingRepository>(
    FakeReportingRepository(profile: profile),
    permanent: true,
  );
  Get.delete<EnforcementCaseRepository>(force: true);
  Get.put<EnforcementCaseRepository>(
    FakeEnforcementCaseRepository(),
    permanent: true,
  );
}

/// The app's theme asks `google_fonts` for Inter, which cannot be fetched in a
/// test — so every label falls back to the placeholder font and renders as a
/// black box. Repointing the theme at the Roboto loaded by [_loadRealFonts]
/// makes the preview legible. Sizes, weights and spacing are untouched, so what
/// is being reviewed is still the real layout.
ThemeData _withRealFont(ThemeData theme) => theme.copyWith(
  textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
  primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Roboto'),
  // `apply` does not reach the styles hanging off component themes, and each
  // one that is missed shows up as a row of black rectangles — form hints and
  // validation messages especially, which is most of what there is to review on
  // a screen like the fine form.
  appBarTheme: theme.appBarTheme.copyWith(
    titleTextStyle: _real(theme.appBarTheme.titleTextStyle),
  ),
  inputDecorationTheme: theme.inputDecorationTheme.copyWith(
    hintStyle: _real(theme.inputDecorationTheme.hintStyle),
    labelStyle: _real(theme.inputDecorationTheme.labelStyle),
    floatingLabelStyle: _real(theme.inputDecorationTheme.floatingLabelStyle),
    errorStyle: _real(theme.inputDecorationTheme.errorStyle),
    helperStyle: _real(theme.inputDecorationTheme.helperStyle),
    prefixStyle: _real(theme.inputDecorationTheme.prefixStyle),
    suffixStyle: _real(theme.inputDecorationTheme.suffixStyle),
    counterStyle: _real(theme.inputDecorationTheme.counterStyle),
  ),
);

TextStyle? _real(TextStyle? style) => style?.copyWith(fontFamily: 'Roboto');

/// Loads a real font out of the Flutter SDK, plus the Material icon font.
///
/// Asserts the directory is there rather than skipping quietly: a missing font
/// does not fail the render, it just draws every label as a black rectangle,
/// and a preview nobody can read is worse than no preview.
Future<void> _loadRealFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  expect(
    flutterRoot,
    isNotNull,
    reason: 'FLUTTER_ROOT is set by `flutter test`; run the previews with it',
  );

  final fontsDir = Directory('$flutterRoot/bin/cache/artifacts/material_fonts');
  expect(
    fontsDir.existsSync(),
    isTrue,
    reason: 'no font at ${fontsDir.path} — the preview would be unreadable',
  );

  final fonts = <String, List<String>>{
    'Roboto': <String>[
      'Roboto-Regular.ttf',
      'Roboto-Medium.ttf',
      'Roboto-Bold.ttf',
    ],
    'MaterialIcons': <String>['MaterialIcons-Regular.otf'],
  };

  for (final family in fonts.entries) {
    final loader = FontLoader(family.key);
    for (final name in family.value) {
      final file = File('${fontsDir.path}/$name');
      expect(file.existsSync(), isTrue, reason: 'missing font ${file.path}');
      loader.addFont(
        file.readAsBytes().then(
          (List<int> bytes) => ByteData.sublistView(Uint8List.fromList(bytes)),
        ),
      );
    }
    await loader.load();
  }
}
