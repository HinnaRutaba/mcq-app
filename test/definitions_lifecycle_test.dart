import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:mcq_app/config/routes/app_routes.dart';
import 'package:mcq_app/controllers/auth_controller.dart';
import 'package:mcq_app/controllers/definitions_controller.dart';
import 'package:mcq_app/data/repositories/auth_repository.dart';
import 'package:mcq_app/data/repositories/definitions_repository.dart';
import 'package:mcq_app/models/models.dart';
import 'package:mcq_app/views/auth/change_password_screen.dart';
import 'package:mcq_app/views/auth/login_screen.dart';

import 'support/api_stub.dart';
import 'support/definitions_fixtures.dart';

/// When the enforcement module's drop-downs are fetched, and when they are
/// thrown away.
///
/// The rows live for the whole app lifecycle, but they are not fetched on the
/// app's start-up: a call before an officer is signed in carries no bearer
/// token, and its 401 clears the keychain out from under the splash screen. So
/// the controller follows the session, and these tests are about that.
void main() {
  late StubbedApi api;
  late ApiStub adapter;
  late AuthController auth;
  late ApiDefinitionsRepository repository;
  late DefinitionsController definitions;

  /// Every path the stub was asked for, so a test can say "nothing went out".
  late List<String> calls;

  setUp(() {
    Get.reset();
    api = StubbedApi();
    adapter = api.stub;

    calls = <String>[];
    adapter.onRequest = (dynamic options) => calls.add(options.path as String);

    auth = AuthController(
      authRepository: ApiAuthRepository(api: api.service, storage: api.storage),
    );
    Get.put<AuthController>(auth, permanent: true);

    repository = ApiDefinitionsRepository(api: api.service);
    definitions = DefinitionsController(
      definitionsRepository: repository,
      authController: auth,
    );
  });

  tearDown(Get.reset);

  /// Registers the controller the way `setupDependencies` does — permanently,
  /// which is what runs `onInit` and arms the session watcher.
  void register() =>
      Get.put<DefinitionsController>(definitions, permanent: true);

  /// Only the master-data calls, so a test can count them without counting the
  /// sign-in that went with them.
  List<String> definitionCalls() => calls
      .where((String path) => path.endsWith('/enforcement/definitions'))
      .toList();

  /// Answers each path with the payload that belongs to it, so a flow that
  /// makes several calls does not need them stubbed in order.
  void answerByPath({Map<String, dynamic>? definitionsReply}) {
    adapter.onRequest = (dynamic options) {
      final path = options.path as String;
      calls.add(path);
      if (path.endsWith('/auth/device/session')) {
        adapter.reply(sessionResponse());
      } else if (path.endsWith('/auth/device/login')) {
        adapter.reply(loginResponse());
      } else if (path.endsWith('/enforcement/definitions')) {
        adapter.reply(definitionsReply ?? definitionsResponse);
      } else {
        adapter.reply(<String, dynamic>{'data': <String, dynamic>{}});
      }
    };
  }

  /// The real auth screens, behind a router that has somewhere to land.
  Future<void> pumpAuthFlow(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: AppRoutes.login,
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.login,
              builder: (_, _) => const LoginScreen(),
            ),
            GoRoute(
              path: AppRoutes.changePassword,
              builder: (_, _) => const ChangePasswordScreen(),
            ),
            GoRoute(
              path: AppRoutes.magistrateHome,
              builder: (_, _) => const Scaffold(body: Text('DASHBOARD')),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Taps a button, scrolling it into view first — the change-password screen
  /// is taller than the test viewport, and a tap that lands outside it is a
  /// tap that quietly does nothing.
  Future<void> tapButton(WidgetTester tester, String label) async {
    final button = find.text(label);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  /// Signs in through the form, rather than by calling the controller: the
  /// controller gates on a mounted `Form`, and this is the path an officer
  /// actually takes.
  Future<void> signInThroughTheScreen(WidgetTester tester) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, 'magistrate');
    await tester.enterText(fields.last, 'password');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
  }

  /// Puts a live session in place the way the splash screen does, and waits for
  /// the rows the session triggers.
  Future<void> becomeSignedIn() async {
    api.keychain['mcq.auth.bearer_token'] = 'a-live-token';
    answerByPath();
    await auth.restoreSession();
    await definitions.ensureLoaded();
  }

  group('before anybody is signed in', () {
    test('registering it puts nothing on the wire', () {
      register();

      expect(
        definitionCalls(),
        isEmpty,
        reason: 'an unauthenticated call would 401 and clear the keychain',
      );
      expect(definitions.isReady, isFalse);
      expect(definitions.isLoading.value, isFalse);
      expect(definitions.definitions.value, isNull);
    });

    test('the pickers are empty rather than half-built', () {
      register();

      expect(definitions.fineTypes, isEmpty);
      expect(definitions.actionTypes, isEmpty);
      expect(definitions.recordableActionTypes, isEmpty);
      expect(definitions.caseStatuses, isEmpty);
      expect(definitions.casePriorities, isEmpty);
      expect(definitions.sealStatuses, isEmpty);
      expect(definitions.fineStatuses, isEmpty);

      // A form can tell "not loaded" from "the register is empty", and refuse
      // to draw a picker from either.
      expect(definitions.isReady, isFalse);
      expect(definitions.fineType('encroachment'), isNull);
      expect(definitions.fieldsFor('site_visit'), isNull);
    });
  });

  group('a stored session restored on launch', () {
    test('loads the rows as soon as the session is confirmed', () async {
      register();
      await becomeSignedIn();

      expect(definitionCalls(), hasLength(1));
      expect(definitions.isReady, isTrue);
      expect(definitions.fineTypes, hasLength(2));
    });

    test('the splash screen does not wait on them', () async {
      register();
      api.keychain['mcq.auth.bearer_token'] = 'a-live-token';
      answerByPath();

      // `restoreSession` is what the splash awaits. The rows are kicked off by
      // the session landing, not awaited by it — an officer must not be held on
      // the logo while a drop-down loads.
      final restored = await auth.restoreSession();

      expect(restored, isTrue);
      expect(definitions.isLoading.value, isTrue);

      await definitions.ensureLoaded();
      expect(definitions.isReady, isTrue);
    });

    test('a dead token leaves the rows alone', () async {
      register();
      api.keychain['mcq.auth.bearer_token'] = 'dead-token';
      adapter.reply(<String, dynamic>{
        'message': 'Unauthenticated.',
      }, statusCode: 401);

      final restored = await auth.restoreSession();

      expect(restored, isFalse);
      expect(definitionCalls(), isEmpty);
      expect(definitions.isReady, isFalse);
    });

    test('no stored token at all fetches nothing', () async {
      register();

      final restored = await auth.restoreSession();

      expect(restored, isFalse);
      expect(calls, isEmpty, reason: 'nothing should reach the socket');
    });

    test('a forced password change is not a session to fetch on', () async {
      register();
      api.keychain['mcq.auth.bearer_token'] = 'a-live-token';
      adapter.reply(sessionResponse(mustChangePassword: true));

      final restored = await auth.restoreSession();

      expect(restored, isFalse);
      expect(
        definitionCalls(),
        isEmpty,
        reason: 'the server refuses everything else until it is changed',
      );
      expect(definitions.isReady, isFalse);
    });
  });

  group('signing in', () {
    testWidgets('loads the rows once the token is in the keychain', (
      WidgetTester tester,
    ) async {
      register();
      answerByPath();

      await pumpAuthFlow(tester);
      await signInThroughTheScreen(tester);

      expect(find.text('DASHBOARD'), findsOneWidget);
      expect(definitionCalls(), hasLength(1));
      expect(definitions.isReady, isTrue);
      expect(definitions.fineTypes, hasLength(2));
    });

    testWidgets('a refused sign-in fetches nothing', (
      WidgetTester tester,
    ) async {
      register();
      adapter.onRequest = (dynamic options) {
        calls.add(options.path as String);
        adapter.reply(<String, dynamic>{
          'message': 'These credentials do not match our records.',
        }, statusCode: 422);
      };

      await pumpAuthFlow(tester);
      await signInThroughTheScreen(tester);

      expect(find.text('DASHBOARD'), findsNothing);
      expect(definitionCalls(), isEmpty);
      expect(definitions.isReady, isFalse);
    });
  });

  group('a forced password change', () {
    /// A magistrate's first session starts here: the server hands out a token,
    /// refuses everything else until the password is changed, and the change
    /// then revokes that token and signs them in again. If the rows are not
    /// fetched on *that* second sign-in, the pickers stay empty for the whole
    /// of their first shift.
    testWidgets('loads the rows on the re-sign-in it forces', (
      WidgetTester tester,
    ) async {
      register();

      var loginsAnswered = 0;
      adapter.onRequest = (dynamic options) {
        final path = options.path as String;
        calls.add(path);
        if (path.endsWith('/auth/device/login')) {
          loginsAnswered++;
          adapter.reply(
            // The first sign-in is the one that demands a change; the second
            // is the one the change performs for the officer.
            loginsAnswered == 1
                ? loginResponse(mustChangePassword: true)
                : loginResponse(),
          );
        } else if (path.endsWith('/auth/password')) {
          adapter.reply(<String, dynamic>{'message': 'Password changed.'});
        } else if (path.endsWith('/enforcement/definitions')) {
          adapter.reply(definitionsResponse);
        } else {
          adapter.reply(<String, dynamic>{'data': <String, dynamic>{}});
        }
      };

      await pumpAuthFlow(tester);
      await signInThroughTheScreen(tester);

      // Sent to the change screen, and nothing fetched: the token cannot be
      // used for anything else yet.
      expect(find.text('Set Password & Continue'), findsOneWidget);
      expect(definitionCalls(), isEmpty);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Quetta-Revenue-2026!');
      await tester.enterText(fields.at(1), 'Quetta-Revenue-2026!');
      await tapButton(tester, 'Set Password & Continue');

      expect(find.text('DASHBOARD'), findsOneWidget);
      expect(
        definitionCalls(),
        hasLength(1),
        reason: 'the second sign-in is a usable session, so the rows load',
      );
      expect(definitions.isReady, isTrue);
      expect(definitions.fineTypes, hasLength(2));
    });

    testWidgets('abandoning it fetches nothing', (WidgetTester tester) async {
      register();
      adapter.onRequest = (dynamic options) {
        calls.add(options.path as String);
        adapter.reply(loginResponse(mustChangePassword: true));
      };

      await pumpAuthFlow(tester);
      await signInThroughTheScreen(tester);
      await tapButton(tester, 'Back to Sign In');

      expect(definitionCalls(), isEmpty);
      expect(definitions.isReady, isFalse);
    });
  });

  group('signing out', () {
    test('throws the rows away for the next officer', () async {
      register();
      await becomeSignedIn();
      expect(definitions.isReady, isTrue);

      adapter.onRequest = (dynamic options) =>
          calls.add(options.path as String);
      adapter.reply(<String, dynamic>{'message': 'Signed out.'});
      await auth.signOut();

      expect(
        definitions.isReady,
        isFalse,
        reason: 'the next officer may be posted where the rows differ',
      );
      expect(definitions.fineTypes, isEmpty);
      expect(
        repository.cached,
        isNull,
        reason: 'the repository cache goes with it, or the next load is stale',
      );
    });

    test('the next officer gets their own copy, not the last one', () async {
      register();
      await becomeSignedIn();
      expect(definitionCalls(), hasLength(1));

      adapter.onRequest = (dynamic options) =>
          calls.add(options.path as String);
      adapter.reply(<String, dynamic>{'message': 'Signed out.'});
      await auth.signOut();

      await becomeSignedIn();

      expect(
        definitionCalls(),
        hasLength(2),
        reason: 'a fresh sign-in goes back to the server for the rows',
      );
      expect(definitions.isReady, isTrue);
    });
  });

  group('the rows, once they are in hand', () {
    setUp(() async {
      register();
      await becomeSignedIn();
    });

    test('every vocabulary is on the controller', () {
      expect(definitions.fineTypes, hasLength(2));
      expect(definitions.actionTypes, hasLength(3));
      expect(definitions.caseStatuses, hasLength(1));
      expect(definitions.casePriorities, hasLength(1));
      expect(definitions.sealStatuses, hasLength(1));
      expect(definitions.fineStatuses, hasLength(1));
      expect(definitions.isEmpty, isFalse);
    });

    test('the lookups answer without a call', () {
      final before = definitionCalls().length;

      expect(definitions.fineType('encroachment')!.suggestedAmount, '3000.00');
      expect(definitions.fineTypeById(4)!.code, 'encroachment');
      expect(definitions.actionType('payment_promised')!.id, 5);
      expect(definitions.actionTypeById(1)!.code, 'site_visit');
      expect(definitions.caseStatus('warned')!.label, 'Warned');
      expect(definitions.casePriority('critical')!.tone, 'danger');
      expect(definitions.sealStatus('sealed')!.label, 'Sealed');
      expect(definitions.fineStatus('paid')!.label, 'Paid');

      expect(definitionCalls(), hasLength(before));
    });

    test('a code the register no longer offers reads back as null', () {
      // A fine already on record can name an offence MCQ has since switched
      // off, so a screen reading one back has to cope rather than assert.
      expect(definitions.fineType('retired_offence'), isNull);
      expect(definitions.caseStatus('invented'), isNull);
    });

    test('the form spec comes from the server, not a switch', () {
      expect(definitions.fieldsFor('payment_promised')!.promiseDate, isTrue);
      expect(definitions.fieldsFor('site_visit')!.hasAny, isFalse);
      expect(definitions.fieldsFor('fine_imposed')!.amount, isTrue);
    });

    test('a picker of what an officer may record leaves out what the '
        'server writes itself', () {
      // `fine_imposed` is on a timeline but is raised by the fine endpoint.
      // Offering it would offer a button that fails at a shop counter.
      expect(
        definitions.recordableActionTypes.map(
          (ActionTypeDefinition t) => t.code,
        ),
        <String>['site_visit', 'payment_promised'],
      );
      expect(definitions.actionTypes, hasLength(3));
    });

    test('a second reader does not go back to the wire', () async {
      final before = definitionCalls().length;

      await definitions.ensureLoaded();
      await definitions.load();

      expect(definitionCalls(), hasLength(before));
    });

    test('a reload does, for a register MCQ edited mid-shift', () async {
      final before = definitionCalls().length;

      await definitions.reload();

      expect(definitionCalls(), hasLength(before + 1));
      expect(definitions.isReady, isTrue);
    });
  });

  group('when the bazaar has no signal', () {
    /// A live session, but the master-data call fails.
    Future<void> signInWithNoDefinitions() async {
      api.keychain['mcq.auth.bearer_token'] = 'a-live-token';
      adapter.onRequest = (dynamic options) {
        final path = options.path as String;
        calls.add(path);
        adapter.reply(
          path.endsWith('/enforcement/definitions')
              ? <String, dynamic>{
                  'message': 'The register could not be reached.',
                }
              : sessionResponse(),
          statusCode: path.endsWith('/enforcement/definitions') ? 500 : 200,
        );
      };
      await auth.restoreSession();
      await definitions.ensureLoaded();
    }

    test('the app stays usable and the failure is reportable', () async {
      register();
      await signInWithNoDefinitions();

      expect(
        auth.isSignedIn,
        isTrue,
        reason: 'the drop-downs failing must not cost the officer their shift',
      );
      expect(definitions.isReady, isFalse);
      expect(definitions.hasError, isTrue);
      expect(definitions.errorMessage.value, isNotNull);
      expect(definitions.isLoading.value, isFalse);
    });

    test(
      'ensureLoaded retries after a failure, and clears the error',
      () async {
        register();
        await signInWithNoDefinitions();
        expect(definitions.hasError, isTrue);

        // The signal comes back.
        answerByPath();
        await definitions.ensureLoaded();

        expect(definitions.isReady, isTrue);
        expect(definitions.hasError, isFalse);
        expect(definitions.fineTypes, hasLength(2));
      },
    );
  });

  group('the whole app lifecycle', () {
    test('it is permanent, so the rows survive a tab being disposed', () async {
      register();
      await becomeSignedIn();

      // What a screen leaving the tree does. A permanent controller is not
      // disposed by it, so the rows are still there for the next screen.
      Get.delete<DefinitionsController>();

      final found = Get.find<DefinitionsController>();
      expect(identical(found, definitions), isTrue);
      expect(found.isReady, isTrue);
      expect(found.fineTypes, hasLength(2));
      expect(definitionCalls(), hasLength(1));
    });
  });
}

// --- Captured payloads, trimmed to what these tests read -----------------

Map<String, dynamic> sessionResponse({bool mustChangePassword = false}) =>
    <String, dynamic>{
      'data': <String, dynamic>{
        'user': <String, dynamic>{
          'id': '5',
          'username': 'magistrate',
          'name': 'Habibullah Tareen',
          'designation': 'Municipal Magistrate',
          'must_change_password': mustChangePassword,
          'is_active': true,
          'roles': <String>['MAGISTRATE'],
        },
        'token_expires_at': null,
      },
    };

Map<String, dynamic> loginResponse({bool mustChangePassword = false}) =>
    <String, dynamic>{
      'data': <String, dynamic>{
        'token': 'a-live-token',
        'token_expires_at': null,
        'user': <String, dynamic>{
          'id': '5',
          'username': 'magistrate',
          'name': 'Habibullah Tareen',
          'designation': 'Municipal Magistrate',
          'must_change_password': mustChangePassword,
          'is_active': true,
          'roles': <String>['MAGISTRATE'],
        },
      },
    };
