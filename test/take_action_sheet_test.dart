import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:mcq_app/controllers/auth_controller.dart';
import 'package:mcq_app/controllers/definitions_controller.dart';
import 'package:mcq_app/core/network/api_exception.dart';
import 'package:mcq_app/data/repositories/auth_repository.dart';
import 'package:mcq_app/data/repositories/definitions_repository.dart';
import 'package:mcq_app/data/repositories/enforcement_case_repository.dart';
import 'package:mcq_app/data/repositories/reporting_repository.dart';
import 'package:mcq_app/models/enforcement_definitions.dart';
import 'package:mcq_app/views/magistrate/property/property_profile_screen.dart';
import 'package:mcq_app/views/magistrate/property/widgets/take_action_sheet.dart';
import 'package:mcq_app/widgets/widgets.dart';

import 'support/api_stub.dart';
import 'support/dashboard_fixtures.dart';
import 'support/definitions_fixtures.dart';
import 'support/property_profile_fixtures.dart';

/// The sheet behind the shop's Take Action button. Its whole point is that the
/// list is the register's — `GET enforcement/definitions`' own `action_types`,
/// in the server's order — so these tests are about what the register says.
void main() {
  late StubbedApi api;

  const ApiException offline = ApiException(
    message: 'No connection. Check your signal and try again.',
    failure: ApiFailure.network,
  );

  /// The published list, longer than the fixtures' three rows: the two the
  /// server writes itself are in `action_types` too, and the sheet shows the
  /// register as it stands rather than a list of its own.
  Map<String, dynamic> registerOf(List<Map<String, dynamic>> actions) {
    final Map<String, dynamic> data = definitionsData();
    data['action_types'] = actions;
    return data;
  }

  Map<String, dynamic> action(
    String code,
    String name, {
    bool promiseDate = false,
  }) => <String, dynamic>{
    'code': code,
    'name': name,
    'fields': <String, dynamic>{'promise_date': promiseDate},
  };

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

  /// Opens the sheet from a bare page, and keeps what it popped.
  Future<ActionTypeDefinition?> openSheet(WidgetTester tester) async {
    ActionTypeDefinition? picked;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => AppButton(
              label: 'Take Action',
              onPressed: () async =>
                  picked = await TakeActionSheet.show(context),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Take Action'));
    await tester.pumpAndSettle();

    return picked;
  }

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
        (double shown, FadeTransition fade) => shown * fade.opacity.value,
      );

  /// The names on screen, in the order they are laid out.
  List<String> shown(WidgetTester tester) => tester
      .widgetList<AppText>(find.byType(AppText))
      .map((AppText text) => text.text)
      .toList();

  setUp(() {
    Get.reset();
    api = StubbedApi();
  });

  tearDown(Get.reset);

  testWidgets('lists what the register publishes, in the server order', (
    WidgetTester tester,
  ) async {
    seedDefinitions(
      register: registerOf(<Map<String, dynamic>>[
        action('site_visit', 'Site visit'),
        action('payment_promised', 'Payment promised', promiseDate: true),
        action('fine_imposed', 'Fine imposed'),
        action('seal', 'Sealed'),
      ]),
    );

    await openSheet(tester);

    expect(
      shown(tester),
      containsAllInOrder(<String>[
        'Site visit',
        'Payment promised',
        'Fine imposed',
        'Sealed',
      ]),
    );
  });

  testWidgets('says what an action carries, off the register fields', (
    WidgetTester tester,
  ) async {
    seedDefinitions(
      register: registerOf(<Map<String, dynamic>>[
        action('site_visit', 'Site visit'),
        action('payment_promised', 'Payment promised', promiseDate: true),
      ]),
    );

    await openSheet(tester);

    expect(find.text('Needs a promised date'), findsOneWidget);
  });

  testWidgets('hands the chosen action back to the screen', (
    WidgetTester tester,
  ) async {
    seedDefinitions(
      register: registerOf(<Map<String, dynamic>>[
        action('site_visit', 'Site visit'),
        action('notice_served', 'Notice served'),
      ]),
    );

    ActionTypeDefinition? picked;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => AppButton(
              label: 'Take Action',
              onPressed: () async =>
                  picked = await TakeActionSheet.show(context),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Take Action'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Notice served'));
    await tester.pumpAndSettle();

    expect(picked?.code, 'notice_served');
    expect(find.text('Notice served'), findsNothing);
  });

  testWidgets('a register that would not load shows the failure and a retry', (
    WidgetTester tester,
  ) async {
    seedDefinitions(repository: _RefusingDefinitions(offline));

    await openSheet(tester);

    expect(find.byType(AppErrorRetry), findsOneWidget);
    expect(find.text(offline.message), findsOneWidget);
  });

  testWidgets('a register with no actions says so rather than looking empty', (
    WidgetTester tester,
  ) async {
    seedDefinitions(register: registerOf(<Map<String, dynamic>>[]));

    await openSheet(tester);

    expect(find.byType(AppEmptyState), findsOneWidget);
  });

  testWidgets('the rows arrive after the sheet, one after another', (
    WidgetTester tester,
  ) async {
    seedDefinitions(
      register: registerOf(<Map<String, dynamic>>[
        action('site_visit', 'Site visit'),
        action('verbal_warning', 'Verbal warning'),
        action('final_warning', 'Final warning'),
      ]),
    );

    ActionTypeDefinition? picked;
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
    expect(find.text('Site visit'), findsOneWidget);
    expect(visibility(tester, 'Site visit'), 0);

    // Part way through the stagger: the first row is ahead of the third, which
    // is what makes it a stagger rather than three rows fading as one.
    for (int elapsed = 0; elapsed < 480; elapsed += 16) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(visibility(tester, 'Site visit'), greaterThan(0));
    expect(
      visibility(tester, 'Site visit'),
      greaterThan(visibility(tester, 'Final warning')),
    );

    // And all the way in, so nothing is left half-faded.
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(visibility(tester, 'Final warning'), 1);
    expect(picked, isNull);
  });

  testWidgets('the shop profile opens it from the Take Action button', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(420, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    seedDefinitions(
      register: registerOf(<Map<String, dynamic>>[
        action('site_visit', 'Site visit'),
      ]),
    );
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

    expect(find.text('Take action'), findsOneWidget);
    expect(find.text('Site visit'), findsOneWidget);
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
