import 'dart:io';

import 'package:dio/dio.dart' show FormData;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide FormData;
import 'package:mcq_app/config/routes/app_routes.dart';
import 'package:mcq_app/controllers/agreement_case_controller.dart';
import 'package:mcq_app/controllers/agreement_dashboard_controller.dart';
import 'package:mcq_app/controllers/agreement_decision_controller.dart';
import 'package:mcq_app/controllers/auth_controller.dart';
import 'package:mcq_app/core/capture/photo_capture.dart';
import 'package:mcq_app/core/network/api_config.dart';
import 'package:mcq_app/core/network/api_exception.dart';
import 'package:mcq_app/data/repositories/agreement_repository.dart';
import 'package:mcq_app/data/repositories/auth_repository.dart';
import 'package:mcq_app/models/models.dart';
import 'package:mcq_app/views/agreements/case/agreement_case_screen.dart';
import 'package:mcq_app/views/agreements/case/agreement_decision_screen.dart';

import 'support/agreement_fixtures.dart';
import 'support/api_stub.dart';

void main() {
  group('the session names the workspace', () {
    test('reads workspaces and capabilities off the mobile block', () {
      final DeviceSession session = DeviceSession.fromJson(
        sessionWith(token: 't')['data'] as Map<String, dynamic>,
      );
      expect(session.access.workspaces, <MobileWorkspace>[
        MobileWorkspace.agreements,
      ]);
      expect(session.access.can(AgreementCapability.endorse), isTrue);
      expect(session.access.can(AgreementCapability.decide), isFalse);
      expect(session.access.fromServer, isTrue);
    });

    test('a server with no mobile block is the magistrate app as before', () {
      final DeviceSession session = DeviceSession.fromJson(<String, dynamic>{
        'user': <String, dynamic>{'username': 'mag', 'name': 'M'},
      });
      expect(session.access.workspaces, <MobileWorkspace>[
        MobileWorkspace.field,
      ]);
      expect(AppRoutes.homeFor(session.access), AppRoutes.magistrateHome);
    });

    test('password_change_required on the block forces the change', () {
      final DeviceSession session = DeviceSession.fromJson(
        sessionWith(passwordChangeRequired: true)['data']
            as Map<String, dynamic>,
      );
      expect(session.mustChangePassword, isTrue);
    });

    test('roles are read into AppRole, and unknown ones are kept aside', () {
      final AuthUser user = AuthUser.fromJson(<String, dynamic>{
        'username': 'admin',
        'name': 'A',
        'roles': <String>[
          'MCQ_ADMINISTRATOR',
          'cmo',
          'TAXATION_SUPERINTENDENT',
        ],
      });
      expect(user.roles, <AppRole>[AppRole.mcqAdministrator, AppRole.cmo]);
      expect(user.hasRole(AppRole.mcqAdministrator), isTrue);
      expect(user.hasRole(AppRole.magistrate), isFalse);
      expect(user.otherRoles, <String>['TAXATION_SUPERINTENDENT']);
      expect(
        AppRole.fromCode('SYSTEM_ADMINISTRATOR'),
        AppRole.systemAdministrator,
      );
    });

    test('an unknown workspace is skipped, not guessed at', () {
      final MobileAccess access = MobileAccess.fromJson(<String, dynamic>{
        'workspaces': <String>['agreements', 'something_new'],
      });
      expect(access.workspaces, <MobileWorkspace>[MobileWorkspace.agreements]);
    });

    test('routes to one workspace straight, and to the switcher otherwise', () {
      MobileAccess of(List<String> w) =>
          MobileAccess.fromJson(<String, dynamic>{'workspaces': w});
      expect(
        AppRoutes.homeFor(of(<String>['agreements'])),
        AppRoutes.agreementsHome,
      );
      expect(
        AppRoutes.homeFor(of(<String>['field'])),
        AppRoutes.magistrateHome,
      );
      expect(
        AppRoutes.homeFor(of(<String>['field', 'agreements'])),
        AppRoutes.workspaces,
      );
      expect(AppRoutes.homeFor(of(<String>[])), AppRoutes.workspaces);
    });
  });

  group('a 403 in the agreement workspace', () {
    test(
      'keeps the session — it means "not yours", not "signed out"',
      () async {
        var ended = 0;
        final StubbedApi stubbed = StubbedApi(onUnauthorized: () => ended++);
        await stubbed.storage.saveSession(token: 'live');
        stubbed.stub.reply(<String, dynamic>{
          'message': 'This action is unauthorized.',
          'code': 'intake.own_case',
        }, statusCode: 403);

        await expectLater(
          ApiAgreementRepository(api: stubbed.service).caseDetail('41'),
          throwsA(
            isA<ApiException>()
                .having(
                  (ApiException e) => e.failure,
                  'failure',
                  ApiFailure.forbidden,
                )
                .having((ApiException e) => e.code, 'code', 'intake.own_case'),
          ),
        );
        expect(await stubbed.storage.readToken(), 'live');
        expect(ended, 0);
      },
    );

    test('a 401 still ends it', () async {
      var ended = 0;
      final StubbedApi stubbed = StubbedApi(onUnauthorized: () => ended++);
      await stubbed.storage.saveSession(token: 'dead');
      stubbed.stub.reply(<String, dynamic>{}, statusCode: 401);

      await expectLater(
        ApiAgreementRepository(api: stubbed.service).dashboard(),
        throwsA(isA<ApiException>()),
      );
      expect(await stubbed.storage.readToken(), isNull);
      expect(ended, 1);
    });

    test('a field call keeps treating 403 as a dead session', () async {
      var ended = 0;
      final StubbedApi stubbed = StubbedApi(onUnauthorized: () => ended++);
      await stubbed.storage.saveSession(token: 'dead');
      stubbed.stub.reply(<String, dynamic>{}, statusCode: 403);

      await expectLater(
        stubbed.service.get(ApiPaths.beat),
        throwsA(isA<ApiException>()),
      );
      expect(ended, 1);
    });

    test('a database_error carries its reference for MCQ IT', () async {
      final StubbedApi stubbed = StubbedApi();
      stubbed.stub.reply(<String, dynamic>{
        'message': 'Server error.',
        'code': 'database_error',
        'reference': 'AB12CD34',
      }, statusCode: 500);

      try {
        await ApiAgreementRepository(api: stubbed.service).dashboard();
        fail('should have thrown');
      } on ApiException catch (error) {
        expect(error.reference, 'AB12CD34');
      }
    });
  });

  group('what goes on the wire', () {
    late StubbedApi stubbed;
    late ApiAgreementRepository repo;

    setUp(() {
      stubbed = StubbedApi();
      repo = ApiAgreementRepository(api: stubbed.service);
    });

    test('the dashboard sends its days as yyyy-MM-dd', () async {
      stubbed.stub.reply(<String, dynamic>{'data': dashboardData()});
      await repo.dashboard(
        from: DateTime(2026, 11, 1),
        to: DateTime(2026, 11, 16),
      );
      expect(stubbed.stub.lastOptions!.path, ApiPaths.intakesDashboard);
      expect(stubbed.stub.lastOptions!.queryParameters, <String, dynamic>{
        'from': '2026-11-01',
        'to': '2026-11-16',
      });
    });

    test('the dashboard opens on all time, with no dates sent', () async {
      stubbed.stub.reply(<String, dynamic>{'data': dashboardData()});
      final AgreementDashboardController controller =
          AgreementDashboardController(
            agreementRepository: repo,
            authController: AuthController(
              authRepository: ApiAuthRepository(
                api: stubbed.service,
                storage: stubbed.storage,
              ),
            ),
          );
      expect(controller.period.value, IntakePeriod.allTime);
      await controller.load();
      expect(stubbed.stub.lastOptions!.path, ApiPaths.intakesDashboard);
      expect(stubbed.stub.lastOptions!.queryParameters, isEmpty);
    });

    test('a waiting queue is asked for without dates', () async {
      stubbed.stub.reply(casesPage());
      await repo.cases(
        IntakeListQuery(
          scope: 'review',
          label: 'To review',
          from: DateTime(2026, 11, 1),
          to: DateTime(2026, 11, 16),
        ),
        search: '  S-14 ',
      );
      final Map<String, dynamic> q = stubbed.stub.lastOptions!.queryParameters;
      expect(q['scope'], 'review');
      expect(q['q'], 'S-14');
      expect(q.containsKey('from'), isFalse);
    });

    test('an acted scope keeps the dates its tile counted with', () async {
      stubbed.stub.reply(casesPage());
      await repo.cases(
        IntakeListQuery(
          scope: 'acted:endorsed',
          label: 'Endorsed',
          from: DateTime(2026, 11, 1),
          to: DateTime(2026, 11, 16),
        ),
      );
      final Map<String, dynamic> q = stubbed.stub.lastOptions!.queryParameters;
      expect(q['scope'], 'acted:endorsed');
      expect(q['from'], '2026-11-01');
    });

    test(
      'an act posts to the server\'s path with uuid and lock_version',
      () async {
        final AgreementCase file = AgreementCase.fromJson(caseData());
        stubbed.stub.reply(<String, dynamic>{
          'data': caseData(status: 'pending_admin'),
        });
        final AgreementCase after = await repo.act(
          file.id,
          file.actOptions.first,
          const IntakeDecisionRequest(
            clientUuid: '0b9c0d6e-1f2a-4b3c-8d4e-5f6a7b8c9d0e',
            lockVersion: 3,
            remarks: 'Rent verified.',
          ),
        );
        expect(
          stubbed.stub.lastOptions!.path,
          '/api/v1/allotment/intakes/41/endorse',
        );
        expect(stubbed.stub.sentBody, <String, dynamic>{
          'client_uuid': '0b9c0d6e-1f2a-4b3c-8d4e-5f6a7b8c9d0e',
          'lock_version': 3,
          'remarks': 'Rent verified.',
        });
        expect(after.statusValue, 'pending_admin');
      },
    );

    test('attachments go up as multipart attachments[]', () async {
      final Directory dir = Directory.systemTemp.createTempSync('intake');
      addTearDown(() => dir.deleteSync(recursive: true));
      final File picture = File('${dir.path}/note.jpg')
        ..writeAsBytesSync(<int>[0xFF, 0xD8, 0xFF]);
      final AgreementCase file = AgreementCase.fromJson(caseData());
      stubbed.stub.reply(<String, dynamic>{'data': caseData()});

      await repo.act(
        file.id,
        file.actOptions[1],
        IntakeDecisionRequest(
          clientUuid: 'u-1',
          remarks: 'Shop number differs from the register.',
          destination: 'estate',
          attachments: <String>[picture.path],
        ),
      );
      final FormData form = stubbed.stub.lastOptions!.data as FormData;
      expect(form.files.single.key, 'attachments[]');
      expect(
        Map<String, String>.fromEntries(form.fields),
        containsPair('destination', 'estate'),
      );
    });

    test('a document url is fetched on our own host, never another', () async {
      stubbed.stub.reply(<String, dynamic>{});
      await repo.document(
        'https://elsewhere.example/api/v1/allotment/intakes/41/media/11',
      );
      expect(
        stubbed.stub.lastOptions!.uri.toString(),
        '${ApiConfig.baseUrl}/api/v1/allotment/intakes/41/media/11',
      );
    });
  });

  test('the same photo can be attached more than once', () async {
    // Android names a picked photo after its media id, so picking it again
    // returns the same path; it is still attached, and removed by position.
    final _PickPhotos photos = _PickPhotos(<List<String>>[
      <String>['/cache/scaled_25.png', '/cache/scaled_26.png'],
      <String>['/cache/scaled_26.png', '/cache/scaled_26.png'],
    ]);
    final AgreementCase file = AgreementCase.fromJson(caseData());
    final AgreementDecisionController c = AgreementDecisionController(
      caseFile: file,
      option: file.actOptions.first,
      agreementRepository: FakeAgreementRepository(),
      photoCapture: photos,
    );
    await c.attach(fromGallery: true);
    await c.attach(fromGallery: true);
    expect(c.attachments, <String>[
      '/cache/scaled_25.png',
      '/cache/scaled_26.png',
      '/cache/scaled_26.png',
      '/cache/scaled_26.png',
    ]);
    c.removeAttachment(2);
    expect(c.attachments.length, 3);
  });

  group('reading the payloads', () {
    test('the dashboard keeps each tile\'s own scope', () {
      final AgreementDashboard d = AgreementDashboard.fromJson(dashboardData());
      expect(d.waitingTotal, 7);
      expect(d.queues.map((IntakeTile t) => t.scope), <String>[
        'review',
        'queries',
        'dispatch',
      ]);
      expect(d.returnedByMe!.count, 2);
      final IntakeTile endorsed = d.myActions.first;
      expect(endorsed.count, 12, reason: 'cases, not acts');
      expect(endorsed.acts, 14);
      expect(endorsed.scope, 'acted:endorsed');
      expect(d.register!.agreementsLive, 19);
      final IntakeTile activated = d.register!.byStatus[2];
      expect(activated.status, 'activated');
      expect(activated.label, isNull, reason: 'a bare string has no label');
      expect(d.nothingWaiting, isFalse);
    });

    test('the legacy register row is checked field by field', () {
      final List<LegacyCheck> checks = AgreementCaseController.legacyChecks(
        AgreementCase.fromJson(caseData()),
      );
      final Map<String, LegacyCheck> by = <String, LegacyCheck>{
        for (final LegacyCheck c in checks) c.label: c,
      };
      // Case and spacing, and CNIC dashes, are not differences.
      expect(by['Name']!.match, LegacyMatch.same);
      expect(by['CNIC']!.match, LegacyMatch.same);
      expect(by['CNIC']!.legacyValue, '54400-1122334-5');
      expect(by['Father']!.match, LegacyMatch.differs);
      expect(by['Mobile']!.match, LegacyMatch.differs);
      expect(by['Monthly rent']!.legacyValue, 'Rs 10,248.70');
      expect(by['Arrears up to']!.match, LegacyMatch.differs);
    });

    test('equal figures written differently still match', () {
      final Map<String, dynamic> data = caseData();
      final Map<String, dynamic> entry =
          (data['legacy'] as Map<String, dynamic>)['entry']
              as Map<String, dynamic>;
      entry['monthly_rent'] = '12500.0';
      entry['mobile_no'] = '+92 300 1234567';
      entry['arrears_up_to'] = '2026-10-31';
      final Map<String, LegacyCheck> by = <String, LegacyCheck>{
        for (final LegacyCheck c in AgreementCaseController.legacyChecks(
          AgreementCase.fromJson(data),
        ))
          c.label: c,
      };
      expect(by['Monthly rent']!.match, LegacyMatch.same);
      expect(by['Mobile']!.match, LegacyMatch.same);
      expect(by['Arrears up to']!.match, LegacyMatch.same);
    });

    test('a shop with no legacy row has nothing to check', () {
      final Map<String, dynamic> data = caseData()
        ..['legacy'] = <String, dynamic>{'entry': null};
      final AgreementCase c = AgreementCase.fromJson(data);
      expect(c.legacy, isNotNull);
      expect(c.legacy!.entry, isNull);
      expect(AgreementCaseController.legacyChecks(c), isEmpty);
    });

    test('a case keeps ids as strings and money untouched', () {
      final AgreementCase c = AgreementCase.fromJson(caseData());
      expect(c.id, '41');
      expect(c.lockVersion, 3);
      expect(c.shop.market, 'Liaquat Bazaar');
      expect(c.amounts['verified_monthly_rent'], '12500.00');
      expect(c.amounts['instalment_offer.monthly'], '7500.00');
      expect(c.allowedActs.map((IntakeActOption o) => o.act), <String>[
        'endorse',
        'return',
      ]);
      expect(c.actOptions.first.signed, isTrue);
      expect(c.actOptions[1].destinations, <String>['estate', 'taxation']);
      expect(c.actions[1].attachments.single.isPdf, isTrue);
      expect(c.execution!.videoRestricted, isTrue);
      expect(c.execution!.video.single.canOpen, isFalse);
      expect(c.applicant!.recordMatches, isTrue);
    });

    test('an open query closes the onward act and opens respond', () {
      final AgreementCase c = AgreementCase.fromJson(caseData(queryOpen: true));
      expect(c.query!.by, 'Administrator');
      expect(c.actOptions.first.reason, IntakeRefusalReason.queryOpen);
      expect(
        c.allowedActs.map((IntakeActOption o) => o.act),
        contains('respond'),
      );
    });
  });

  group('screens', () {
    late _RecordingRepository repo;

    setUp(() {
      Get.reset();
      final StubbedApi api = StubbedApi();
      Get.put<AuthController>(
        AuthController(
          authRepository: ApiAuthRepository(
            api: api.service,
            storage: api.storage,
          ),
        ),
        permanent: true,
      );
      repo = _RecordingRepository();
      Get.put<AgreementRepository>(repo, permanent: true);
    });

    tearDown(Get.reset);

    testWidgets('the act bar draws only what act_options allow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AgreementCaseScreen(caseId: '41')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Endorse'), findsOneWidget);
      expect(find.text('Return or query'), findsOneWidget);
      expect(find.text('Answer query'), findsNothing);
    });

    testWidgets('an open query says so and offers the answer', (
      WidgetTester tester,
    ) async {
      repo.queryOpen = true;
      await tester.pumpWidget(
        const MaterialApp(home: AgreementCaseScreen(caseId: '41')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Endorse'), findsNothing);
      expect(find.text('Answer query'), findsOneWidget);
      expect(
        find.text('A query is open at your stage. Answer it first.'),
        findsOneWidget,
      );
    });

    testWidgets('a retry re-sends the same client_uuid', (
      WidgetTester tester,
    ) async {
      repo.failNext = const ApiException(
        message: 'No connection.',
        failure: ApiFailure.network,
      );
      await _openDecision(tester, 'endorse');

      await tester.tap(find.text('Endorse').last);
      await tester.pumpAndSettle();
      expect(find.text('Send it again'), findsOneWidget);

      await tester.tap(find.text('Send it again'));
      await tester.pumpAndSettle();

      expect(repo.sent, hasLength(2));
      expect(repo.sent[0].clientUuid, repo.sent[1].clientUuid);
      expect(repo.sent[0].lockVersion, 3);
      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-'
          r'[0-9a-f]{12}$',
        ).hasMatch(repo.sent[0].clientUuid),
        isTrue,
      );
      expect(_result, isNotNull);
      expect(_result!.file.statusValue, 'pending_admin');
      expect(
        Get.isRegistered<AgreementDecisionController>(),
        isFalse,
        reason:
            'a kept controller would carry its client_uuid into the next act',
      );
    });

    testWidgets('a return needs remarks and a destination before it sends', (
      WidgetTester tester,
    ) async {
      await _openDecision(tester, 'return');

      expect(
        find.text('Still needed: where it goes and your remarks.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Return or query').last);
      await tester.pumpAndSettle();
      expect(repo.sent, isEmpty);
    });

    testWidgets('someone acting first reloads the case and goes back to it', (
      WidgetTester tester,
    ) async {
      repo.failNext = const ApiException(
        message: 'Changed.',
        failure: ApiFailure.conflict,
        code: 'intake.changed_since_viewed',
      );
      await _openDecision(tester, 'endorse');

      await tester.tap(find.text('Endorse').last);
      await tester.pumpAndSettle();

      expect(repo.detailReads, 1);
      expect(_result, isNotNull);
      expect(_result!.notice, contains('Someone acted on this case first'));
    });
  });
}

DecisionResult? _result;

Future<void> _openDecision(WidgetTester tester, String act) async {
  _result = null;
  final AgreementCase file = AgreementCase.fromJson(caseData());
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () async {
            _result = await Navigator.of(context).push<DecisionResult>(
              MaterialPageRoute<DecisionResult>(
                builder: (_) =>
                    AgreementDecisionScreen(act: act, caseFile: file),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(find.byType(AgreementDecisionScreen), findsOneWidget);
  expect(find.text('Not open on this case'), findsNothing);
  expect(Get.isRegistered<AgreementDecisionController>(), isTrue);
}

class _RecordingRepository extends FakeAgreementRepository {
  final List<IntakeDecisionRequest> sent = <IntakeDecisionRequest>[];
  ApiException? failNext;
  bool queryOpen = false;
  int detailReads = 0;

  @override
  Future<AgreementCase> caseDetail(String id) async {
    detailReads++;
    return AgreementCase.fromJson(caseData(id: id, queryOpen: queryOpen));
  }

  @override
  Future<AgreementCase> act(
    String caseId,
    IntakeActOption option,
    IntakeDecisionRequest request,
  ) async {
    sent.add(request);
    final ApiException? failure = failNext;
    failNext = null;
    if (failure != null) throw failure;
    return super.act(caseId, option, request);
  }
}

class _PickPhotos implements PhotoCapture {
  _PickPhotos(this._picks);

  final List<List<String>> _picks;

  @override
  Future<List<String>> fromGalleryMany({required int limit}) async =>
      _picks.removeAt(0);

  @override
  Future<PhotoCaptureResult> fromCamera() async => PhotoCaptureResult.cancelled;

  @override
  Future<PhotoCaptureResult> fromGallery() => fromCamera();
}
