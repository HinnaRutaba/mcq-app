import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import 'package:mcq_app/controllers/auth_controller.dart';
import 'package:mcq_app/controllers/definitions_controller.dart';
import 'package:mcq_app/core/network/api_exception.dart';
import 'package:mcq_app/data/repositories/auth_repository.dart';
import 'package:mcq_app/data/repositories/definitions_repository.dart';
import 'package:mcq_app/data/repositories/enforcement_case_repository.dart';
import 'package:mcq_app/data/repositories/reporting_repository.dart';
import 'package:mcq_app/models/enforcement_definitions.dart';
import 'package:mcq_app/models/shop_action.dart';
import 'package:mcq_app/views/magistrate/property/property_profile_screen.dart';
import 'package:mcq_app/views/magistrate/property/widgets/take_action_sheet.dart';
import 'package:mcq_app/widgets/widgets.dart';

import 'support/api_stub.dart';
import 'support/dashboard_fixtures.dart';
import 'support/definitions_fixtures.dart';
import 'support/property_profile_fixtures.dart';

/// The sheet behind the shop's Take Action button.
///
/// The rows are the app's own list, worded as the choice an officer is making
/// — so these are about that list being offered whole, in order, with the
/// register's row attached to each and the seal reading the shop's state.
void main() {
  late StubbedApi api;

  const ApiException offline = ApiException(
    message: 'No connection. Check your signal and try again.',
    failure: ApiFailure.network,
  );

  Map<String, dynamic> registerOf(List<Map<String, dynamic>> actions) {
    final Map<String, dynamic> data = definitionsData();
    data['action_types'] = actions;
    return data;
  }

  Map<String, dynamic> action(
    String code,
    String name, {
    bool promiseDate = false,
    bool visitDate = false,
    bool amount = false,
  }) => <String, dynamic>{
    'code': code,
    'name': name,
    'fields': <String, dynamic>{
      'promise_date': promiseDate,
      'visit_date': visitDate,
      'amount': amount,
    },
  };

  /// A register carrying a row for every step the app offers.
  Map<String, dynamic> wholeRegister() => registerOf(<Map<String, dynamic>>[
    action('site_visit', 'Site visit'),
    action('verbal_warning', 'Verbal warning'),
    action('payment_promised', 'Payment promised', promiseDate: true),
    action('reminder_visit_set', 'Reminder visit set', visitDate: true),
    action('fine_imposed', 'Fine imposed', amount: true),
    action('seal', 'Sealed'),
    action('unseal', 'Seal released'),
  ]);

  /// Registers the master data the way `setupDependencies` does — permanently,
  /// with an officer already signed in, which is what makes it fetch.
  void seedDefinitions({
    Map<String, dynamic>? register,
    DefinitionsRepository? repository,
  }) {
    final AuthController auth = AuthController(
      authRepository: ApiAuthRepository(api: api.service, storage: api.storage),
    );
    Get.put<AuthController>(auth, permanent: true);
    auth.officer.value = officerFixture;

    Get.delete<DefinitionsController>(force: true);
    Get.put<DefinitionsController>(
      DefinitionsController(
        definitionsRepository:
            repository ?? FakeDefinitionsRepository(data: register),
        authController: auth,
      ),
      permanent: true,
    );
  }

  ShopActionChoice? picked;

  /// Opens the sheet from a bare page, and keeps what it popped.
  ///
  /// Tall, because the list is lazy: at the default 600pt the last row is
  /// never built and a test for it would be a test of the viewport.
  Future<void> openSheet(
    WidgetTester tester, {
    bool sealed = false,
    bool hasOpenCase = true,
  }) async {
    tester.view
      ..physicalSize = const Size(420, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // A real router over it: the sheet pops through `context.pop`, which needs
    // one — the app is never without it, and a test that faked it would not be
    // testing the way the row actually closes the sheet.
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          routes: <RouteBase>[
            GoRoute(
              path: '/',
              builder: (BuildContext context, GoRouterState state) => Scaffold(
                body: AppButton(
                  label: 'Take Action',
                  onPressed: () async => picked = await TakeActionSheet.show(
                    context,
                    sealed: sealed,
                    hasOpenCase: hasOpenCase,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Take Action'));
    await tester.pumpAndSettle();
    // The rows are held back before they stagger, on a plain `Timer`.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  /// The names on screen, in the order they are laid out.
  List<String> shown(WidgetTester tester) => tester
      .widgetList<AppText>(find.byType(AppText))
      .map((AppText text) => text.text)
      .toList();

  /// How visible a row is, all the fades over it multiplied together — the
  /// sheet's own contents fading in, and the row's place in the stagger.
  double visibility(WidgetTester tester, String label) => tester
      .widgetList<FadeTransition>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(FadeTransition),
        ),
      )
      .fold<double>(
        1,
        (double so, FadeTransition fade) => so * fade.opacity.value,
      );

  setUp(() {
    Get.reset();
    api = StubbedApi();
    picked = null;
  });

  tearDown(Get.reset);

  testWidgets('offers every step, in the order they escalate', (
    WidgetTester tester,
  ) async {
    seedDefinitions(register: wholeRegister());

    await openSheet(tester);

    expect(
      shown(tester),
      containsAllInOrder(<String>[
        'Record a visit',
        'Give a warning',
        'Take promise to pay',
        'Set reminder to visit',
        'Impose a fine',
        'Create new case',
        'Seal the shop',
      ]),
    );
    // The seal and the release are one row in two states, never both.
    expect(find.text('Unseal the shop'), findsNothing);
  });

  testWidgets('a shop already sealed is offered the release instead', (
    WidgetTester tester,
  ) async {
    seedDefinitions(register: wholeRegister());

    await openSheet(tester, sealed: true);

    expect(find.text('Unseal the shop'), findsOneWidget);
    expect(find.text('Seal the shop'), findsNothing);
  });

  testWidgets('hands back the step with the register row behind it', (
    WidgetTester tester,
  ) async {
    seedDefinitions(register: wholeRegister());

    await openSheet(tester);
    await tester.tap(find.text('Take promise to pay'));
    await tester.pumpAndSettle();

    expect(picked?.action, ShopAction.promise);
    // The row is the register's, so what is eventually posted is MCQ's own
    // action type and not this list's wording.
    expect(picked?.definition?.code, 'payment_promised');
    expect(picked?.definition?.name, 'Payment promised');
    expect(picked?.definition?.fields.promiseDate, isTrue);
  });

  testWidgets('a new case comes back with no register row, having none', (
    WidgetTester tester,
  ) async {
    seedDefinitions(register: wholeRegister());

    await openSheet(tester);
    await tester.tap(find.text('Create new case'));
    await tester.pumpAndSettle();

    expect(picked?.action, ShopAction.openCase);
    expect(picked?.definition, isNull);
  });

  testWidgets('a step MCQ has switched off is shown, and refused', (
    WidgetTester tester,
  ) async {
    seedDefinitions(
      register: registerOf(<Map<String, dynamic>>[
        action('site_visit', 'Site visit'),
      ]),
    );

    await openSheet(tester);

    // Still on the list: an officer who cannot find "Give a warning" will
    // assume the app is broken rather than that MCQ withdrew it.
    expect(find.text('Give a warning'), findsOneWidget);
    expect(find.text('MCQ has switched this off'), findsWidgets);

    await tester.tap(find.text('Give a warning'));
    await tester.pumpAndSettle();

    expect(picked, isNull);
    expect(find.text('Give a warning'), findsOneWidget);
  });

  testWidgets('says in a line what every step does', (
    WidgetTester tester,
  ) async {
    seedDefinitions(register: wholeRegister());

    await openSheet(tester);

    // "Take promise to pay" on its own is a phrase, not an instruction.
    for (final ShopAction step in ShopAction.forShop(sealed: false)) {
      expect(
        find.text(step.description),
        findsOneWidget,
        reason: 'no description shown for ${step.label}',
      );
    }
  });

  testWidgets('a shop with no case is told the step will open one', (
    WidgetTester tester,
  ) async {
    seedDefinitions(register: wholeRegister());

    await openSheet(tester, hasOpenCase: false);

    expect(find.text('Opens a case first'), findsOneWidget);
    expect(find.text('One case is already open'), findsNothing);
  });

  testWidgets('a shop that already has one is told so before a second', (
    WidgetTester tester,
  ) async {
    seedDefinitions(register: wholeRegister());

    await openSheet(tester);

    expect(find.text('One case is already open'), findsOneWidget);
  });

  testWidgets('a register that would not load shows the failure and a retry', (
    WidgetTester tester,
  ) async {
    seedDefinitions(repository: _RefusingDefinitions(offline));

    await openSheet(tester);

    expect(find.byType(AppErrorRetry), findsOneWidget);
    expect(find.text(offline.message), findsOneWidget);
  });

  testWidgets('a register with no actions says so rather than refusing eight', (
    WidgetTester tester,
  ) async {
    seedDefinitions(register: registerOf(<Map<String, dynamic>>[]));

    await openSheet(tester);

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text('Record a visit'), findsNothing);
  });

  testWidgets('the rows arrive after the sheet, one after another', (
    WidgetTester tester,
  ) async {
    seedDefinitions(register: wholeRegister());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => AppButton(
              label: 'Open',
              onPressed: () async =>
                  picked = await TakeActionSheet.show(context),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    // The surface is still growing: the rows are laid out — the sheet's height
    // is settled from the first frame — but none of them are showing yet.
    expect(find.text('Record a visit'), findsOneWidget);
    expect(visibility(tester, 'Record a visit'), 0);

    // Part way through the stagger: the first row is ahead of the fourth,
    // which is what makes it a stagger rather than a list fading as one.
    for (int elapsed = 0; elapsed < 480; elapsed += 16) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(visibility(tester, 'Record a visit'), greaterThan(0));
    expect(
      visibility(tester, 'Record a visit'),
      greaterThan(visibility(tester, 'Set reminder to visit')),
    );

    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(visibility(tester, 'Set reminder to visit'), 1);
    expect(picked, isNull);
  });

  testWidgets('the shop profile opens it from the Take Action button', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(420, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    seedDefinitions(register: wholeRegister());
    Get.delete<ReportingRepository>(force: true);
    Get.put<ReportingRepository>(FakeReportingRepository(), permanent: true);
    Get.delete<EnforcementCaseRepository>(force: true);
    Get.put<EnforcementCaseRepository>(
      FakeEnforcementCaseRepository(),
      permanent: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: PropertyProfileScreen(propertyId: fixturePropertyId),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppExtendedFab), findsOneWidget);

    await tester.tap(find.text('Take Action'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Take action'), findsOneWidget);
    expect(find.text('Record a visit'), findsOneWidget);
  });
}

/// A register the handset cannot reach — the bazaar with no signal.
class _RefusingDefinitions implements DefinitionsRepository {
  _RefusingDefinitions(this.failure);

  final ApiException failure;

  @override
  EnforcementDefinitions? get cached => null;

  @override
  Future<EnforcementDefinitions> definitions({bool refresh = false}) async =>
      throw failure;

  @override
  void forget() {}
}
