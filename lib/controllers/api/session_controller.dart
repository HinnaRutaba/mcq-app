import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/device_info_service.dart';
import '../../core/storage/read_cache.dart';
import '../../core/utils/app_feedback.dart';
import '../../data/api/repositories/auth_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/auth/session_user.dart';
import 'locale_controller.dart';

/// Where the officer is in the sign-in lifecycle. The router reads this.
enum SessionStage {
  /// Checking the stored token against the server. Nothing is rendered yet.
  starting,

  /// No usable token — show login.
  signedOut,

  /// Signed in, but the server says the password must be changed before
  /// anything else.
  mustChangePassword,

  /// Signed in and usable.
  ready,
}

/// The session: the token, the officer, and their permissions.
///
/// Permissions are never cached past a session — they are rows resolved per
/// request, and a transferred officer's authority changes without them
/// signing in again. The *user* record is cached only so that launching in
/// a basement shows the app rather than a locked door, and it is refreshed
/// the moment there is signal.
class SessionController extends GetxController {
  SessionController({
    required AuthRepository auth,
    required ApiClient client,
    required LocaleController locale,
    required DeviceInfoService devices,
    required ReadCache cache,
  })  : _auth = auth,
        _client = client,
        _locale = locale,
        _devices = devices,
        _cache = cache;

  final AuthRepository _auth;
  final ApiClient _client;
  final LocaleController _locale;
  final DeviceInfoService _devices;
  final ReadCache _cache;

  final Rx<SessionStage> stage = SessionStage.starting.obs;
  final Rx<SessionUser?> user = Rx<SessionUser?>(null);
  final RxBool isSubmitting = false.obs;

  /// The 422 the server returns for every login failure — wrong password,
  /// unknown username, deactivated or locked account. Shown as given: the
  /// message is deliberately the same for all four so the client cannot be
  /// used to test which usernames exist.
  final RxString signInError = ''.obs;

  /// True when the officer we are showing came from the cache because the
  /// session check could not reach the server.
  final RxBool sessionUnverified = false.obs;

  /// Where the officer was when the token died, so they return to it.
  String? returnTo;

  /// go_router listens to this to re-run its redirect.
  final RouterRefreshNotifier routerRefresh = RouterRefreshNotifier();

  @override
  void onInit() {
    super.onInit();
    _client.onUnauthenticated = (error) => expire(message: error.message);
    // A 403 is a refusal of one action: show the server's sentence and do
    // not navigate, do not clear anything.
    _client.onForbidden = (error) => AppFeedback.toast(error.message, isError: true);
  }

  bool can(String permission) => user.value?.can(permission) ?? false;
  bool canAny(List<String> permissions) => user.value?.canAny(permissions) ?? false;

  /// Called before anything is rendered.
  ///
  /// Do not skip the session check and discover the token is dead three
  /// screens in.
  Future<void> bootstrap() async {
    stage.value = SessionStage.starting;
    if (!await _auth.hasToken()) {
      _toSignedOut();
      return;
    }
    await refreshSession();
  }

  Future<void> refreshSession() async {
    try {
      final officer = await _auth.session();
      _adopt(officer);
    } on ApiException catch (error) {
      if (error.isUnauthenticated) {
        _toSignedOut();
        return;
      }
      if (error.isNetwork) {
        // No signal at launch. Fall back to the officer we last saw so the
        // app opens on cached lists instead of a dead end, and say so.
        final cached = _cache.readMap(ReadCache.session);
        if (cached != null) {
          sessionUnverified.value = true;
          _adopt(SessionUser.fromJson(cached.value), verified: false);
          return;
        }
      }
      _toSignedOut();
      AppFeedback.toast(error.message, isError: true);
    }
  }

  void _adopt(SessionUser officer, {bool verified = true}) {
    user.value = officer;
    if (verified) {
      sessionUnverified.value = false;
      // Cached for an offline launch only. Permissions on it are never
      // trusted for a *write* — the server checks every request.
      _cache.write(ReadCache.session, _userJson(officer));
    }
    _locale.followUserPreference(officer.localeCode);

    if (officer.isBlocked) {
      // A locked or inactive account must not get past the launch screen
      // even if the token still works.
      _toSignedOut();
      AppFeedback.toast(t('error.sessionExpired'), isError: true);
      return;
    }
    stage.value = officer.mustChangePassword
        ? SessionStage.mustChangePassword
        : SessionStage.ready;
    routerRefresh.ping();
  }

  Map<String, dynamic> _userJson(SessionUser officer) => {
        'id': officer.id,
        'username': officer.username,
        'name': officer.name,
        'employee_no': officer.employeeNo,
        'designation': officer.designation,
        'mobile_no': officer.mobileNo,
        'email': officer.email,
        'locale': officer.localeCode,
        'must_change_password': officer.mustChangePassword,
        'is_active': officer.isActive,
        'is_locked': officer.isLocked,
        'permissions': officer.permissions,
        'roles': [
          for (final role in officer.roles)
            {'role_code': role.code, 'name': role.name},
        ],
      };

  void _toSignedOut() {
    user.value = null;
    stage.value = SessionStage.signedOut;
    routerRefresh.ping();
  }

  Future<String> suggestedDeviceName() => _devices.suggestedDeviceName();

  /// One error message for every failure, and no retry loop: five failures
  /// locks the account for 15 minutes.
  Future<bool> signIn({
    required String username,
    required String password,
    required String deviceName,
  }) async {
    isSubmitting.value = true;
    signInError.value = '';
    try {
      final result = await _auth.signIn(
        username: username,
        password: password,
        deviceName: deviceName,
      );
      await _devices.remember(deviceName);
      _client.resetExpiryLatch();
      _adopt(result.user);
      return true;
    } on ApiException catch (error) {
      // Show the server's sentence when it sent one; otherwise our own
      // single message. Never guess which of the four cases it was.
      signInError.value = error.isValidation && !error.fromServer
          ? t('auth.failed')
          : (error.fromServer ? error.message : t('auth.failed'));
      if (error.isNetwork) signInError.value = error.message;
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> signOut() async {
    isSubmitting.value = true;
    try {
      await _auth.signOut();
    } on ApiException {
      // The local token is cleared by the repository regardless.
    } finally {
      isSubmitting.value = false;
      await _cache.clear(ReadCache.session);
      _client.resetExpiryLatch();
      _toSignedOut();
    }
  }

  /// A 401 at any moment: the token was revoked (a password change, an
  /// administrator reset, a deactivation) or it expired. Clear the
  /// keychain, remember where they were, and send them to login **once**,
  /// with an explanation. Queued work is not touched.
  Future<void> expire({String? message}) async {
    returnTo = Get.currentRoute;
    await _auth.forgetToken();
    await _cache.clear(ReadCache.session);
    _toSignedOut();
    AppFeedback.toast(message ?? t('error.sessionExpired'), isError: true);
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    isSubmitting.value = true;
    try {
      final message = await _auth.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmation: confirmation,
      );
      // Every token is revoked on a password change — by design. Back to
      // login with the new one.
      _toSignedOut();
      return message ?? t('password.changed');
    } finally {
      isSubmitting.value = false;
    }
  }
}

/// A [Listenable] go_router can watch, so the redirect re-runs the moment
/// the session stage changes — a 401 mid-tap sends the officer to login
/// without any screen having to know about it.
class RouterRefreshNotifier extends ChangeNotifier {
  void ping() => notifyListeners();
}
