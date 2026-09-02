import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import 'package:mcq_app/config/routes/app_routes.dart';
import 'package:mcq_app/controllers/auth_controller.dart';
import 'package:mcq_app/data/repositories/auth_repository.dart';
import 'package:mcq_app/views/auth/change_password_screen.dart';
import 'package:mcq_app/views/auth/login_screen.dart';

import 'support/api_stub.dart';

/// Signing in, end to end: the screen calls the controller, the controller
/// calls the repository, the repository puts the token in the keychain — and
/// only then does the officer reach the dashboard.
///
/// Everything is real except the socket and the platform keychain.
void main() {
  late StubbedApi api;
  late AuthController controller;

  setUp(() {
    Get.reset();
    api = StubbedApi();
    controller = AuthController(
      authRepository: ApiAuthRepository(api: api.service, storage: api.storage),
    );
    Get.put<AuthController>(controller, permanent: true);
  });

  tearDown(Get.reset);

  /// The login screen behind a router that has somewhere to land.
  Future<void> pumpLogin(WidgetTester tester) async {
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

  Future<void> signIn(
    WidgetTester tester, {
    String username = 'magistrate',
    String password = 'password',
  }) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, username);
    await tester.enterText(fields.last, password);
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
  }

  group('signing in from the screen', () {
    testWidgets(
      'a good password lands on the dashboard, token in the keychain',
      (WidgetTester tester) async {
        api.stub.reply(_loginResponse);

        await pumpLogin(tester);
        expect(find.text('DASHBOARD'), findsNothing);

        await signIn(tester);

        expect(find.text('DASHBOARD'), findsOneWidget);
        expect(await api.storage.readToken(), 'live-token');
        expect(controller.isSignedIn, isTrue);
        expect(controller.officer.value!.name, 'Habibullah Tareen');

        // Signed in with the username, not the email, and the handset named
        // itself so the officer can recognise the device server-side.
        expect(api.stub.sentBody['username'], 'magistrate');
        expect(api.stub.sentBody['password'], 'password');
        expect(api.stub.sentBody['device_name'], isNotEmpty);
        expect(api.stub.lastOptions!.path, '/api/v1/auth/device/login');
      },
    );

    testWidgets('the sign-in call carries no bearer token', (
      WidgetTester tester,
    ) async {
      api.stub.reply(_loginResponse);
      await pumpLogin(tester);
      await signIn(tester);

      expect(
        api.stub.lastOptions!.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    testWidgets('a wrong password stays put and says so', (
      WidgetTester tester,
    ) async {
      api.stub.reply(<String, dynamic>{
        'message': 'These credentials do not match our records.',
      }, statusCode: 401);

      await pumpLogin(tester);
      await signIn(tester, password: 'wrong-password');

      expect(find.text('DASHBOARD'), findsNothing);
      expect(
        find.text('These credentials do not match our records.'),
        findsOneWidget,
      );
      expect(await api.storage.readToken(), isNull);
      expect(controller.isSignedIn, isFalse);
    });

    testWidgets('a 422 puts the message under the field it names', (
      WidgetTester tester,
    ) async {
      api.stub.reply(<String, dynamic>{
        'message': 'The given data was invalid.',
        'errors': <String, dynamic>{
          'username': <String>['This account is locked.'],
        },
      }, statusCode: 422);

      await pumpLogin(tester);
      await signIn(tester);

      expect(find.text('This account is locked.'), findsOneWidget);
      // Not repeated as a banner — the server already pinned it to a field.
      expect(find.text('The given data was invalid.'), findsNothing);
      expect(find.text('DASHBOARD'), findsNothing);
    });

    testWidgets('an officer who must change their password is held back', (
      WidgetTester tester,
    ) async {
      api.stub.reply(<String, dynamic>{
        'data': <String, dynamic>{
          'token': 'live-token',
          'user': <String, dynamic>{..._user, 'must_change_password': true},
        },
      });

      await pumpLogin(tester);
      await signIn(tester);

      expect(
        find.text('DASHBOARD'),
        findsNothing,
        reason: 'the server refuses everything else until the password changes',
      );
      expect(find.textContaining('password must be changed'), findsOneWidget);
    });

    testWidgets('an empty form never reaches the server', (
      WidgetTester tester,
    ) async {
      await pumpLogin(tester);
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(api.stub.lastOptions, isNull);
      expect(find.text('Username is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('no connection is reported as such, not as a bad password', (
      WidgetTester tester,
    ) async {
      api.stub.fail(DioExceptionType.connectionError);

      await pumpLogin(tester);
      await signIn(tester);

      expect(find.textContaining('No connection'), findsOneWidget);
      expect(find.text('DASHBOARD'), findsNothing);
    });
  });

  group('a password that must be changed', () {
    /// Signs in as an officer the server wants a new password from, landing on
    /// the change screen.
    Future<void> reachChangeScreen(WidgetTester tester) async {
      api.stub.reply(<String, dynamic>{
        'data': <String, dynamic>{
          'token': 'first-token',
          'user': <String, dynamic>{..._user, 'must_change_password': true},
        },
      });

      await pumpLogin(tester);
      await signIn(tester);
    }

    Future<void> setNewPassword(
      WidgetTester tester, {
      String password = 'Quetta-Revenue-2026!',
      String? confirmation,
    }) async {
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, password);
      await tester.enterText(fields.last, confirmation ?? password);
      await tester.tap(await _reveal(tester, 'Set Password & Continue'));
      await tester.pumpAndSettle();
    }

    testWidgets('sign-in leads to the change screen, not the dashboard', (
      WidgetTester tester,
    ) async {
      await reachChangeScreen(tester);

      expect(find.text('Set a new password'), findsOneWidget);
      expect(
        find.text('DASHBOARD'),
        findsNothing,
        reason: 'the server refuses everything else until this is done',
      );
      expect(controller.hasPendingPasswordChange, isTrue);
    });

    testWidgets('setting a password changes it, re-signs in, and lands on the '
        'dashboard', (WidgetTester tester) async {
      await reachChangeScreen(tester);

      final calls = <String>[];
      api.stub.onRequest = (RequestOptions options) {
        calls.add('${options.method} ${options.path}');
        if (options.path.endsWith('/auth/password')) {
          // The change went through; every token the officer held is now dead.
          api.stub.reply(<String, dynamic>{'message': 'Password updated.'});
        } else {
          api.stub.reply(<String, dynamic>{
            'data': <String, dynamic>{'token': 'second-token', 'user': _user},
          });
        }
      };

      await setNewPassword(tester);

      expect(calls, <String>[
        'PUT /api/v1/auth/password',
        'POST /api/v1/auth/device/login',
      ]);
      expect(find.text('DASHBOARD'), findsOneWidget);

      // The officer holds a live session again, on a token issued after the
      // change — not the one the change revoked.
      expect(await api.storage.readToken(), 'second-token');
      expect(controller.isSignedIn, isTrue);
      expect(controller.hasPendingPasswordChange, isFalse);
    });

    testWidgets('the change sends the password the officer signed in with', (
      WidgetTester tester,
    ) async {
      await reachChangeScreen(tester);

      final bodies = <Map<String, dynamic>>[];
      api.stub.onRequest = (RequestOptions options) {
        bodies.add(Map<String, dynamic>.from(options.data as Map));
        api.stub.reply(
          options.path.endsWith('/auth/password')
              ? <String, dynamic>{'message': 'Password updated.'}
              : <String, dynamic>{
                  'data': <String, dynamic>{
                    'token': 'second-token',
                    'user': _user,
                  },
                },
        );
      };

      await setNewPassword(tester, password: 'Quetta-Revenue-2026!');

      expect(bodies.first['current_password'], 'password');
      expect(bodies.first['password'], 'Quetta-Revenue-2026!');
      expect(bodies.first['password_confirmation'], 'Quetta-Revenue-2026!');
      // And the re-sign-in uses the new one, not the old.
      expect(bodies.last['password'], 'Quetta-Revenue-2026!');
    });

    testWidgets('a mismatched confirmation never reaches the server', (
      WidgetTester tester,
    ) async {
      await reachChangeScreen(tester);
      final callsBefore = api.stub.lastOptions;

      await setNewPassword(
        tester,
        password: 'Quetta-Revenue-2026!',
        confirmation: 'Quetta-Revenue-2027!',
      );

      expect(find.text('The passwords do not match'), findsOneWidget);
      expect(api.stub.lastOptions, same(callsBefore));
      expect(find.text('DASHBOARD'), findsNothing);
    });

    testWidgets('a password the server rejects is shown against the field', (
      WidgetTester tester,
    ) async {
      await reachChangeScreen(tester);

      api.stub.reply(<String, dynamic>{
        'message': 'The given data was invalid.',
        'errors': <String, dynamic>{
          'password': <String>['The password has already been used.'],
        },
      }, statusCode: 422);

      await setNewPassword(tester);

      expect(find.text('The password has already been used.'), findsOneWidget);
      expect(find.text('Set a new password'), findsOneWidget);
      expect(
        controller.hasPendingPasswordChange,
        isTrue,
        reason: 'nothing changed, so the officer can try another password',
      );
    });

    testWidgets('a change that lands but cannot re-sign-in goes to sign-in', (
      WidgetTester tester,
    ) async {
      await reachChangeScreen(tester);

      api.stub.onRequest = (RequestOptions options) {
        if (options.path.endsWith('/auth/password')) {
          api.stub.reply(<String, dynamic>{'message': 'Password updated.'});
        } else {
          api.stub.fail(DioExceptionType.connectionError);
        }
      };

      await setNewPassword(tester);

      expect(find.text('Welcome back'), findsOneWidget);
      expect(
        find.textContaining('password was changed'),
        findsOneWidget,
        reason: 'the change succeeded — do not report it as a failure',
      );
      expect(controller.hasPendingPasswordChange, isFalse);
    });

    testWidgets('backing out returns to sign-in and drops the pending change', (
      WidgetTester tester,
    ) async {
      await reachChangeScreen(tester);

      await tester.tap(await _reveal(tester, 'Back to Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(controller.hasPendingPasswordChange, isFalse);
    });
  });

  group('coming back to the app', () {
    test('no stored token means signing in again', () async {
      expect(await controller.restoreSession(), isFalse);
      expect(
        api.stub.lastOptions,
        isNull,
        reason: 'nothing to verify, so nothing to ask the server',
      );
    });

    test('a live token goes straight through', () async {
      await api.storage.saveSession(token: 'live-token');
      api.stub.reply(<String, dynamic>{
        'data': <String, dynamic>{'user': _user, 'token_expires_at': null},
      });

      expect(await controller.restoreSession(), isTrue);
      expect(api.stub.lastOptions!.path, '/api/v1/auth/device/session');
      expect(
        api.stub.lastOptions!.headers['Authorization'],
        'Bearer live-token',
      );
      expect(controller.officer.value!.username, 'magistrate');
    });

    test(
      'a dead token is cleared and reported without a scary message',
      () async {
        await api.storage.saveSession(token: 'dead-token');
        api.stub.reply(<String, dynamic>{
          'message': 'Unauthenticated.',
        }, statusCode: 401);

        expect(await controller.restoreSession(), isFalse);
        expect(await api.storage.readToken(), isNull);
        expect(
          controller.errorMessage.value,
          isNull,
          reason: 'an expired session is routine; do not alarm the officer',
        );
      },
    );

    test('no signal keeps the token but still asks them to sign in', () async {
      await api.storage.saveSession(token: 'live-token');
      api.stub.fail(DioExceptionType.connectionError);

      expect(await controller.restoreSession(), isFalse);
      expect(
        await api.storage.readToken(),
        'live-token',
        reason: 'a bazaar with no signal is not proof of a dead session',
      );
      expect(controller.errorMessage.value, contains('No connection'));
    });
  });

  group('signing out', () {
    test('revokes the device token and empties the keychain', () async {
      await api.storage.saveSession(
        token: 'live-token',
        username: 'magistrate',
      );
      api.stub.reply(<String, dynamic>{'message': 'Signed out.'});

      await controller.signOut();

      expect(api.stub.lastOptions!.path, '/api/v1/auth/device/logout');
      expect(await api.storage.readToken(), isNull);
      expect(controller.isSignedIn, isFalse);
      expect(
        await api.storage.readUsername(),
        'magistrate',
        reason: 'the username is kept to pre-fill the form; the token is not',
      );
    });

    test('clears the session even when the call fails', () async {
      await api.storage.saveSession(token: 'live-token');
      api.stub.fail(DioExceptionType.connectionError);

      await controller.signOut();

      expect(await api.storage.readToken(), isNull);
      expect(controller.isSignedIn, isFalse);
    });
  });

  /// A handset whose keystore has been invalidated, or a build the plugin is
  /// missing from. The officer still has to be able to work.
  group('a keychain that will not take a write', () {
    setUp(() {
      installUnwritableKeychain(api.keychain);
    });

    testWidgets('sign-in still lands on the dashboard', (
      WidgetTester tester,
    ) async {
      api.stub.reply(_loginResponse);

      await pumpLogin(tester);
      await signIn(tester);

      expect(find.text('DASHBOARD'), findsOneWidget);
      expect(controller.isSignedIn, isTrue);
      expect(controller.errorMessage.value, isNull);
    });

    test(
      'the token nothing could store still authenticates later calls',
      () async {
        await api.storage.saveSession(
          token: 'live-token',
          username: 'magistrate',
        );

        expect(
          api.keychain,
          isEmpty,
          reason:
              'the write was refused, so nothing reached the platform store',
        );
        expect(api.storage.isPersistent, isFalse);
        expect(await api.storage.readToken(), 'live-token');

        api.stub.reply(<String, dynamic>{'data': <String, dynamic>{}});
        await api.service.get('/api/v1/auth/session');

        expect(
          api.stub.lastOptions!.headers['Authorization'],
          'Bearer live-token',
        );
      },
    );

    test('signing out still drops the token', () async {
      await api.storage.saveSession(token: 'live-token');
      api.stub.reply(<String, dynamic>{'message': 'Signed out.'});

      await controller.signOut();

      expect(await api.storage.readToken(), isNull);
      expect(controller.isSignedIn, isFalse);
    });
  });
}

/// Scrolls a control into view before tapping it. The change-password form is
/// taller than the default test surface, and a tap that lands off-screen is a
/// test artefact, not a finding.
Future<Finder> _reveal(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  return finder;
}

const Map<String, dynamic> _user = <String, dynamic>{
  'id': '5',
  'username': 'magistrate',
  'name': 'Habibullah Tareen',
  'designation': 'Municipal Magistrate',
  'mobile_no': '03001234504',
  'email': 'magistrate@mcq.test',
  'locale': 'ur',
  'must_change_password': false,
  'is_active': true,
  'is_locked': false,
  'permissions': <String>['enforcement.fine.impose', 'property.view'],
  'roles': <String>['MAGISTRATE'],
  'created_at': '2026-08-26T08:40:34+00:00',
};

const Map<String, dynamic> _loginResponse = <String, dynamic>{
  'data': <String, dynamic>{
    'token': 'live-token',
    'token_expires_at': null,
    'user': _user,
  },
};
