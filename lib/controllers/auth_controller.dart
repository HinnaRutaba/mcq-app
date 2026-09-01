import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/network/api_exception.dart';
import '../core/utils/device_name.dart';
import '../data/repositories/auth_repository.dart';
import '../models/auth_user.dart';

enum SignInOutcome {
  success,

  /// The form itself was not valid; the fields already say why.
  invalidForm,

  /// Credentials were right, but the server will refuse everything else until
  /// the password is changed.
  mustChangePassword,

  /// The server refused it. See [AuthController.errorMessage] and the field
  /// validators.
  failed,
}

/// What came of a forced password change.
enum PasswordChangeOutcome {
  /// Changed, and a fresh token is already in the keychain — the officer can go
  /// straight on to the dashboard.
  success,

  /// The form itself was not valid; the fields already say why.
  invalidForm,

  /// The password was changed, but a new session could not be established. The
  /// old token is dead either way, so the officer has to sign in again — with
  /// the new password.
  signInRequired,

  /// The server refused the change. See [AuthController.errorMessage] and the
  /// field validators.
  failed,
}

/// Owns the officer's session: the sign-in form, the forced password change,
/// who is signed in, and signing out.
///
/// All talking to the server goes through [AuthRepository], which is also what
/// puts the bearer token in the keychain and takes it out again — this
/// controller never handles the token itself. Navigation is the view's job; the
/// controller only reports what happened.
class AuthController extends GetxController {
  AuthController({AuthRepository? authRepository})
    : _authRepository = authRepository ?? Get.find<AuthRepository>();

  final AuthRepository _authRepository;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  /// The forced password-change form. Separate from the sign-in form because
  /// both can be alive at once — the officer signs in, then is sent here.
  final GlobalKey<FormState> changePasswordFormKey = GlobalKey<FormState>();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final RxBool obscurePassword = true.obs;
  final RxBool isLoading = false.obs;

  final RxnString errorMessage = RxnString();

  final Rxn<AuthUser> officer = Rxn<AuthUser>();

  String? _usernameServerError;
  String? _passwordServerError;
  String? _newPasswordServerError;

  /// The password the officer just signed in with, kept only while a forced
  /// change is in flight — the API needs it as `current_password`, and making
  /// them retype what they typed ten seconds ago is friction at a shop counter.
  /// Cleared the moment the change lands, or the flow is abandoned.
  String? _pendingCurrentPassword;

  bool get isSignedIn => officer.value != null;

  /// Whether the officer is mid-way through a change they cannot skip. False
  /// after a restart, because the current password is not persisted anywhere —
  /// they sign in again first.
  bool get hasPendingPasswordChange => _pendingCurrentPassword != null;

  @override
  void onInit() {
    super.onInit();
    _prefillUsername();
  }

  void toggleObscurePassword() =>
      obscurePassword.value = !obscurePassword.value;

  String? validateUsername(String? value) {
    if (_usernameServerError != null) return _usernameServerError;

    final username = value?.trim() ?? '';
    if (username.isEmpty) return 'Username is required';
    if (username.length < 3) return 'Username must be at least 3 characters';
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(username)) {
      return 'Use letters, numbers, dot, underscore or hyphen only';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (_passwordServerError != null) return _passwordServerError;
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  String? validateNewPassword(String? value) {
    // The server owns the real policy — its rule set is not published, so the
    // checks here only catch the obvious and its message wins when it speaks.
    if (_newPasswordServerError != null) return _newPasswordServerError;

    final password = value ?? '';
    if (password.isEmpty) return 'A new password is required';
    if (password.length < minPasswordLength) {
      return 'Use at least $minPasswordLength characters';
    }
    if (password == _pendingCurrentPassword) {
      return 'Choose a password you have not used before';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Please type the new password again';
    if (value != newPasswordController.text) {
      return 'The passwords do not match';
    }
    return null;
  }

  /// A floor, not the policy. The server's `Password` rule decides.
  static const int minPasswordLength = 8;

  Future<SignInOutcome> signIn() async {
    _clearErrors();

    if (!(formKey.currentState?.validate() ?? false)) {
      return SignInOutcome.invalidForm;
    }

    isLoading.value = true;
    try {
      final session = await _authRepository.signIn(
        username: usernameController.text.trim(),
        password: passwordController.text,
        deviceName: await _deviceName(),
      );

      officer.value = session.user;

      if (session.mustChangePassword) {
        _pendingCurrentPassword = passwordController.text;
        passwordController.clear();
        return SignInOutcome.mustChangePassword;
      }

      passwordController.clear();
      return SignInOutcome.success;
    } on ApiException catch (error) {
      _applyFailure(error);
      // Re-run the validators so any per-field message appears under its field.
      formKey.currentState?.validate();
      return SignInOutcome.failed;
    } finally {
      isLoading.value = false;
    }
  }

  /// Changes the password an officer was forced to change, then puts them back
  /// on a live session.
  ///
  /// The change revokes **every** token that officer holds, including the one
  /// this handset just received — so a successful change is immediately
  /// followed by a fresh sign-in with the new password. That second call is why
  /// this can return [PasswordChangeOutcome.signInRequired]: the password did
  /// change, but the new session did not stick, and the officer has to sign in
  /// themselves.
  Future<PasswordChangeOutcome> changePassword() async {
    final currentPassword = _pendingCurrentPassword;
    if (currentPassword == null) {
      // Nothing to change against — a restart, or this screen reached directly.
      errorMessage.value = 'Please sign in again to change your password.';
      return PasswordChangeOutcome.signInRequired;
    }

    _clearErrors();
    if (!(changePasswordFormKey.currentState?.validate() ?? false)) {
      return PasswordChangeOutcome.invalidForm;
    }

    final newPassword = newPasswordController.text;
    final username = officer.value?.username ?? usernameController.text.trim();

    isLoading.value = true;
    try {
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPasswordController.text,
      );
    } on ApiException catch (error) {
      _newPasswordServerError = error.errorFor('password');
      final currentPasswordError = error.errorFor('current_password');
      errorMessage.value = _newPasswordServerError == null
          ? (currentPasswordError ?? error.message)
          : null;
      changePasswordFormKey.currentState?.validate();
      isLoading.value = false;
      return PasswordChangeOutcome.failed;
    }

    // Past this point the password *has* changed and the old token is dead.
    _pendingCurrentPassword = null;
    try {
      final session = await _authRepository.signIn(
        username: username,
        password: newPassword,
        deviceName: await _deviceName(),
      );
      officer.value = session.user;
      _clearPasswordFields();
      return PasswordChangeOutcome.success;
    } catch (_) {
      // Do not report this as a failed change — it succeeded. The officer just
      // has to sign in with the password they have only just set.
      _clearPasswordFields();
      officer.value = null;
      errorMessage.value =
          'Your password was changed. Please sign in with your new password.';
      return PasswordChangeOutcome.signInRequired;
    } finally {
      isLoading.value = false;
    }
  }

  /// Leaves a forced change without doing it. The officer goes back to signing
  /// in; the server will send them here again next time.
  void abandonPasswordChange() {
    _pendingCurrentPassword = null;
    _clearPasswordFields();
    _clearErrors();
  }

  /// Checks a stored token on launch, before anything is rendered.
  ///
  /// Returns true only when the server confirmed the session and there is
  /// nothing standing in the officer's way. A 401 has already cleared the
  /// keychain by the time this returns; any other failure leaves the token
  /// alone, because a bazaar with no signal is not proof of a dead session —
  /// but it cannot be verified either, so the officer signs in again.
  Future<bool> restoreSession() async {
    if (!await _authRepository.hasStoredSession()) return false;

    isLoading.value = true;
    try {
      final session = await _authRepository.currentSession();
      officer.value = session.user;
      if (session.mustChangePassword) {
        errorMessage.value = _mustChangePasswordMessage;
        return false;
      }
      return true;
    } on ApiException catch (error) {
      officer.value = null;
      // A dead token needs no explanation; a connection problem does.
      errorMessage.value = error.isUnauthorized ? null : error.message;
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Revokes this device's token. Other devices stay signed in.
  ///
  /// The keychain is cleared even if the call fails, so this never leaves a
  /// live token on a handset the officer has finished with.
  Future<void> signOut() async {
    isLoading.value = true;
    try {
      await _authRepository.signOut();
    } on ApiException catch (_) {
      // Already cleared locally by the repository — nothing to recover from.
    } finally {
      officer.value = null;
      reset();
      isLoading.value = false;
    }
  }

  void reset() {
    _pendingCurrentPassword = null;
    _clearPasswordFields();
    obscurePassword.value = true;
    _clearErrors();
  }

  void _clearPasswordFields() {
    passwordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
  }

  static const String _mustChangePasswordMessage =
      'Your password must be changed before you can carry on. '
      'Please change it, then sign in again.';

  void _clearErrors() {
    errorMessage.value = null;
    _usernameServerError = null;
    _passwordServerError = null;
    _newPasswordServerError = null;
  }

  void _applyFailure(ApiException error) {
    _usernameServerError = error.errorFor('username');
    _passwordServerError = error.errorFor('password');

    // Only show the block when the server did not already pin the problem to a
    // field, so the officer is not told the same thing twice.
    final pinnedToField =
        _usernameServerError != null || _passwordServerError != null;
    errorMessage.value = pinnedToField ? null : error.message;
  }

  /// Reuses the name this handset signed in under before, so the officer's
  /// device list does not grow an entry per sign-in.
  Future<String> _deviceName() async =>
      await _authRepository.rememberedDeviceName() ?? DeviceName.resolve();

  Future<void> _prefillUsername() async {
    if (usernameController.text.isNotEmpty) return;
    final remembered = await _authRepository.rememberedUsername();
    if (remembered != null && usernameController.text.isEmpty) {
      usernameController.text = remembered;
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
