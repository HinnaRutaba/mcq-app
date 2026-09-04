import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

import 'package:mcq_app/controllers/auth_controller.dart';
import 'package:mcq_app/controllers/dashboard_controller.dart';
import 'package:mcq_app/controllers/definitions_controller.dart';
import 'package:mcq_app/controllers/fine_controller.dart';
import 'package:mcq_app/controllers/trade_capture_controller.dart';
import 'package:mcq_app/core/network/api_exception.dart';
import 'package:mcq_app/data/repositories/auth_repository.dart';
import 'package:mcq_app/data/repositories/definitions_repository.dart';
import 'package:mcq_app/data/repositories/evidence_repository.dart';
import 'package:mcq_app/data/repositories/fine_repository.dart';
import 'package:mcq_app/data/repositories/person_repository.dart';
import 'package:mcq_app/data/repositories/reporting_repository.dart';
import 'package:mcq_app/data/repositories/trade_repository.dart';
import 'package:mcq_app/models/evidence_upload.dart';
import 'package:mcq_app/models/fine.dart';
import 'package:mcq_app/models/fine_request.dart';
import 'package:mcq_app/views/magistrate/shared/create_fine_screen.dart';
import 'package:mcq_app/views/magistrate/shared/widgets/amount_field.dart';
import 'package:mcq_app/views/magistrate/shared/widgets/area_search_field.dart';
import 'package:mcq_app/views/magistrate/trade/trade_capture_screen.dart';
import 'package:mcq_app/widgets/widgets.dart';

import 'support/api_stub.dart';
import 'support/dashboard_fixtures.dart';
import 'support/definitions_fixtures.dart';
import 'support/person_fixtures.dart';
import 'support/property_profile_fixtures.dart';
import 'support/trade_fixtures.dart';

/// A refused write, on a handset rather than in a controller.
///
/// The officer presses Send from the bottom bar, so that is where the server's
/// answer has to land. A message at the top of a form they have already
/// scrolled past is a message nobody reads. These are about the officer being
/// told, without having to go looking.
void main() {
  const String refusal =
      'A fine for breaking a seal has to be filed against the case the seal '
      'belongs to.';

  late _RefusingFineRepository fines;

  setUp(() async {
    Get.reset();
    final StubbedApi api = StubbedApi();
    api.stub.reply(definitionsResponse);

    final AuthController auth = AuthController(
      authRepository: ApiAuthRepository(api: api.service, storage: api.storage),
    );
    Get.put<AuthController>(auth, permanent: true);

    final DefinitionsController definitions = DefinitionsController(
      definitionsRepository: ApiDefinitionsRepository(api: api.service),
      authController: auth,
    );
    await definitions.load();
    Get.put<DefinitionsController>(definitions, permanent: true);

    final DashboardController dashboard = DashboardController(
      dashboardRepository: FakeDashboardRepository(),
      defaultersRepository: FakeDefaultersRepository(),
      authController: auth,
    );
    dashboard.beat.value = beatFixture;
    Get.put<DashboardController>(dashboard, permanent: true);

    fines = _RefusingFineRepository(refusal);
    Get.put<FineRepository>(fines, permanent: true);
    Get.put<EvidenceRepository>(_FakeEvidenceRepository(), permanent: true);
    Get.put<PersonRepository>(FakePersonRepository(), permanent: true);
    Get.put<ReportingRepository>(FakeReportingRepository(), permanent: true);
  });

  tearDown(Get.reset);

  /// A phone, not a test bench two screens tall: the whole point is that the
  /// form is longer than the glass.
  Future<FineController> pumpForm(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: CreateFineScreen()));
    await tester.pumpAndSettle();

    final FineController controller = Get.find<FineController>();
    controller.setArea(1);
    controller.chooseFineType(controller.fineTypes[1]);
    controller.amountController.text = '4500';
    controller.offenderNameController.text = 'Noor Ahmed';
    controller.offenderFatherController.text = 'Gul Khan';
    controller.offenderMobileController.text = '03001234567';
    controller.offenderCnicController.text = '5440011223344';
    await tester.pumpAndSettle();
    return controller;
  }

  /// The form's own list. `.first` is the outermost — the search box and the
  /// text fields bring scrollables of their own.
  ScrollableState scrollable(WidgetTester tester) =>
      tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(Form),
              matching: find.byType(Scrollable),
            )
            .first,
      );

  testWidgets(
    'a refusal lands at the button, whatever the form is scrolled to',
    (WidgetTester tester) async {
      final FineController controller = await pumpForm(tester);

      // Where the officer actually is when they press Send: at the foot of the
      // form, with the top of it well out of sight.
      final ScrollableState list = scrollable(tester);
      list.position.jumpTo(list.position.maxScrollExtent);
      await tester.pumpAndSettle();
      final double scrolled = list.position.pixels;
      expect(scrolled, greaterThan(0));

      final Finder button = find.widgetWithText(AppButton, 'Impose a fine');
      await tester.tap(button);
      await tester.pumpAndSettle();

      // The server's own sentence, verbatim, and nowhere else.
      expect(controller.errorMessage.value, refusal);
      final Finder alert = find.byType(AppAlert);
      expect(alert, findsOneWidget);
      expect(find.textContaining('has to be filed against'), findsOneWidget);

      // Directly above the button that was just pressed — not at the top of the
      // form, and without yanking the form anywhere.
      final Rect message = tester.getRect(alert);
      final Rect pressed = tester.getRect(button);
      expect(message.bottom, lessThanOrEqualTo(pressed.top));
      expect(pressed.top - message.bottom, lessThan(20));
      expect(list.position.pixels, scrolled);

      // On the glass, not merely built.
      final Size screen = tester.view.physicalSize;
      expect(message.top, greaterThanOrEqualTo(0));
      expect(message.bottom, lessThanOrEqualTo(screen.height));
    },
  );

  testWidgets('nothing is left at the top of the form to go looking for', (
    WidgetTester tester,
  ) async {
    await pumpForm(tester);

    // Pressed from the top of the form, where nothing has been scrolled past.
    final ScrollableState list = scrollable(tester);
    expect(list.position.pixels, 0);

    await tester.tap(find.widgetWithText(AppButton, 'Impose a fine'));
    await tester.pumpAndSettle();

    // One message, in the bar. The form itself carries no copy of it.
    expect(find.byType(AppAlert), findsOneWidget);
    expect(
      find.descendant(of: find.byType(Form), matching: find.byType(AppAlert)),
      findsNothing,
    );
  });

  testWidgets('a refusal about a field carries the form up to that field', (
    WidgetTester tester,
  ) async {
    final FineController controller = await pumpForm(tester);
    // A refusal about the amount, which has a field of its own further up.
    fines.fieldErrors = const <String, List<String>>{
      'fine_amount': <String>['The fine amount is below the minimum.'],
    };

    final ScrollableState list = scrollable(tester);
    list.position.jumpTo(list.position.maxScrollExtent);
    await tester.pumpAndSettle();
    final double scrolled = list.position.pixels;

    await tester.tap(find.widgetWithText(AppButton, 'Impose a fine'));
    await tester.pumpAndSettle();

    // The message is under the field it names…
    expect(
      controller.validateAmount(controller.amountController.text),
      'The fine amount is below the minimum.',
    );
    expect(find.text('The fine amount is below the minimum.'), findsOneWidget);

    // …and the form went up to it rather than leaving the officer at the foot
    // of a form with a red field somewhere above them.
    expect(list.position.pixels, lessThan(scrolled));
    final Rect field = tester.getRect(find.byType(AmountField));
    expect(field.top, greaterThanOrEqualTo(0));
    expect(field.bottom, lessThanOrEqualTo(tester.view.physicalSize.height));

    // The bar still says the whole of what the server said: a sentence it sent
    // is never silently dropped.
    expect(controller.errorMessage.value, isNotNull);
    expect(find.text(refusal), findsOneWidget);
  });

  testWidgets('a refusal naming the area is shown on the area box', (
    WidgetTester tester,
  ) async {
    final FineController controller = await pumpForm(tester);
    // The area is chosen on a search box, not a `FormField` — nothing repaints
    // it when the form is validated, so this is the one that goes stale.
    fines.fieldErrors = const <String, List<String>>{
      'area_id': <String>['That area is not on your beat.'],
    };

    final ScrollableState list = scrollable(tester);
    list.position.jumpTo(list.position.maxScrollExtent);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppButton, 'Impose a fine'));
    await tester.pumpAndSettle();

    expect(controller.areaServerError.value, 'That area is not on your beat.');
    // Under the box that chose it, not only in the bar at the bottom.
    expect(find.text('That area is not on your beat.'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AreaSearchField),
        matching: find.text('That area is not on your beat.'),
      ),
      findsOneWidget,
    );
  });

  group('capturing a shop', () {
    late FakeTradeRepository trade;

    Future<TradeCaptureController> pumpCapture(
      WidgetTester tester, {
      required Map<String, List<String>> errors,
      String message = 'That shop cannot be captured here.',
    }) async {
      trade = FakeTradeRepository(
        captureFailure: ApiException(
          message: message,
          failure: ApiFailure.validation,
          code: 'validation_failed',
          statusCode: 422,
          errors: errors,
        ),
      );
      Get.put<TradeRepository>(trade, permanent: true);

      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: TradeCaptureScreen(areaId: 1)),
      );
      await tester.pumpAndSettle();

      final TradeCaptureController capture = Get.find<TradeCaptureController>();
      capture
        ..cnicController.text = '5440112233445'
        ..applicantController.text = 'Abdul Karim'
        ..fatherController.text = 'Muhammad Yousaf'
        ..mobileController.text = '03001234567'
        ..businessController.text = 'Al Madina Naan Shop'
        ..addressController.text = 'Shop 14, Circular Road, Quetta';
      capture.chooseCategory(tradeTariffFixture.category(40)!);
      await tester.pumpAndSettle();
      return capture;
    }

    testWidgets('the refusal lands at the button and the form goes to the '
        'field', (WidgetTester tester) async {
      final TradeCaptureController capture = await pumpCapture(
        tester,
        errors: <String, List<String>>{
          'cnic': <String>['That CNIC is already on the register.'],
        },
      );

      final ScrollableState list = scrollable(tester);
      list.position.jumpTo(list.position.maxScrollExtent);
      await tester.pumpAndSettle();
      final double scrolled = list.position.pixels;
      expect(scrolled, greaterThan(0));

      final Finder button = find.widgetWithText(AppButton, 'Capture this shop');
      await tester.tap(button);
      await tester.pumpAndSettle();

      // The sentence is beside the button that was just pressed…
      expect(capture.errorMessage.value, 'That shop cannot be captured here.');
      final Finder alert = find.byType(AppAlert);
      expect(alert, findsOneWidget);
      final Rect pressed = tester.getRect(button);
      expect(tester.getRect(alert).bottom, lessThanOrEqualTo(pressed.top));

      // …and the form went up to the field it named.
      expect(list.position.pixels, lessThan(scrolled));
      expect(
        find.text('That CNIC is already on the register.'),
        findsOneWidget,
      );
    });

    testWidgets('a refusal naming the bazaar is shown on the bazaar box', (
      WidgetTester tester,
    ) async {
      await pumpCapture(
        tester,
        errors: <String, List<String>>{
          'area_id': <String>['That bazaar is not on your beat.'],
        },
      );

      final ScrollableState list = scrollable(tester);
      list.position.jumpTo(list.position.maxScrollExtent);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AppButton, 'Capture this shop'));
      await tester.pumpAndSettle();

      // The bazaar is a search box rather than a `FormField`, so nothing
      // repaints it when the form is validated — this is the one that went
      // missing entirely before.
      expect(
        find.descendant(
          of: find.byType(AreaSearchField),
          matching: find.text('That bazaar is not on your beat.'),
        ),
        findsOneWidget,
      );
    });
  });
}

class _RefusingFineRepository implements FineRepository {
  _RefusingFineRepository(this.message);

  final String message;
  Map<String, List<String>> fieldErrors = const <String, List<String>>{
    'enforcement_case_id': <String>[],
  };

  ApiException get _refusal => ApiException(
    message: message,
    failure: ApiFailure.validation,
    code: 'validation_failed',
    statusCode: 422,
    errors: fieldErrors,
  );

  @override
  Future<Fine> impose({
    required int propertyId,
    required FineRequest request,
  }) async => throw _refusal;

  @override
  Future<Fine> imposeInArea({required FineRequest request}) async =>
      throw _refusal;
}

class _FakeEvidenceRepository implements EvidenceRepository {
  @override
  Future<EvidenceUpload> upload({
    required String filePath,
    String kind = EvidenceRepository.kindPhoto,
    String? mimeType,
    ProgressCallback? onProgress,
  }) async => EvidenceUpload.fromJson(<String, dynamic>{'path': 'evidence/1'});
}
