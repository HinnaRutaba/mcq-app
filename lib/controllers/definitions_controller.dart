import 'package:get/get.dart';

import '../core/network/api_exception.dart';
import '../data/repositories/definitions_repository.dart';
import '../models/api_refs.dart';
import '../models/auth_user.dart';
import '../models/enforcement_action_request.dart';
import '../models/enforcement_definitions.dart';
import 'auth_controller.dart';

/// Holds the enforcement module's master data for the life of the app.
///
/// Every drop-down in the module is drawn from this: the offences a fine can be
/// raised for, the actions that can be recorded against a case, and the four
/// status vocabularies. They are rows MCQ can rename, reorder and switch off,
/// so a screen must read them from here rather than carry a copy — a hardcoded
/// picker is a list that silently stops matching the register.
///
/// **It follows the session rather than the app's start-up.** Registered
/// permanently before `runApp`, it fetches nothing until an officer is actually
/// signed in: a call on the wire before that has no bearer token, and its 401
/// would clear the keychain out from under the splash screen. Instead it
/// watches [AuthController.officer] and loads when a usable session appears —
/// whether that is a stored token restored on launch, a fresh sign-in, or the
/// re-sign-in that follows a forced password change. On sign-out it throws the
/// rows away, because the next officer on this handset may be posted somewhere
/// with a different set.
///
/// Reading it in a view: the getters below read [definitions] when they are
/// called, so call them **inside** the `Obx` builder. A getter read in a child
/// widget's build or in a callback registers with nothing and the screen will
/// not rebuild when the rows arrive.
class DefinitionsController extends GetxController {
  DefinitionsController({
    DefinitionsRepository? definitionsRepository,
    AuthController? authController,
  }) : _repository = definitionsRepository ?? Get.find<DefinitionsRepository>(),
       _auth = authController ?? Get.find<AuthController>();

  final DefinitionsRepository _repository;
  final AuthController _auth;

  /// The master data, once an officer is signed in and the call has landed.
  /// Null before that — which a form can tell apart from "empty" and refuse to
  /// draw a picker from.
  final Rxn<EnforcementDefinitions> definitions = Rxn<EnforcementDefinitions>();

  final RxBool isLoading = RxBool(false);

  /// Why the last attempt failed. A bazaar with no signal at sign-in leaves the
  /// app usable and the pickers empty, so a screen that needs them shows this
  /// with a retry rather than an empty drop-down.
  final RxnString errorMessage = RxnString();

  /// The load in flight, so two screens asking at once wait on one call rather
  /// than flickering [isLoading] twice.
  Future<void>? _inFlight;

  /// Whether the rows are in hand. The one thing to gate a picker on.
  bool get isReady => definitions.value != null;

  /// Loaded, but the server sent no fine or action types at all — a
  /// misconfigured register rather than a failed call.
  bool get isEmpty => definitions.value?.isEmpty ?? false;

  bool get hasError => errorMessage.value != null;

  // --- The vocabularies -------------------------------------------------

  /// The offences a fine can be raised for, each with the provision to quote
  /// and an amount to start the officer off.
  List<FineTypeDefinition> get fineTypes =>
      definitions.value?.fineTypes ?? const <FineTypeDefinition>[];

  /// Everything that can appear on a case timeline — including the entries the
  /// server writes itself. For a picker of what an officer may *record*, use
  /// [recordableActionTypes].
  List<ActionTypeDefinition> get actionTypes =>
      definitions.value?.actionTypes ?? const <ActionTypeDefinition>[];

  /// The action types the action endpoint will accept, in the server's own
  /// order and with its own wording.
  ///
  /// This is the list to build a "record a visit" picker from. It leaves out
  /// the rows the server writes itself — a fine, a seal, a release, a closure —
  /// which appear in [actionTypes] because they appear on a timeline, not
  /// because an officer can post them. Offering one of those would be offering
  /// a button that fails at a shop counter.
  List<ActionTypeDefinition> get recordableActionTypes => actionTypes
      .where(
        (ActionTypeDefinition type) =>
            EnforcementActionType.fromCode(type.code) != null,
      )
      .toList();

  List<LabelledValue> get caseStatuses =>
      definitions.value?.caseStatuses ?? const <LabelledValue>[];

  List<LabelledValue> get casePriorities =>
      definitions.value?.casePriorities ?? const <LabelledValue>[];

  List<LabelledValue> get sealStatuses =>
      definitions.value?.sealStatuses ?? const <LabelledValue>[];

  List<LabelledValue> get fineStatuses =>
      definitions.value?.fineStatuses ?? const <LabelledValue>[];

  // --- Lookups ----------------------------------------------------------

  /// The offence with this code, e.g. `encroachment`. Null when the rows are
  /// not loaded, or when MCQ has switched it off since — a fine already on
  /// record can name a code the register no longer offers, so a screen reading
  /// one back has to cope with null rather than assert.
  FineTypeDefinition? fineType(String code) =>
      definitions.value?.fineType(code);

  FineTypeDefinition? fineTypeById(int id) =>
      definitions.value?.fineTypeById(id);

  ActionTypeDefinition? actionType(String code) =>
      definitions.value?.actionType(code);

  ActionTypeDefinition? actionTypeById(int id) =>
      definitions.value?.actionTypeById(id);

  /// The labelled entry for a stored value, so a screen holding a bare
  /// `"part_recovered"` can print "Some money recovered" and tone it the way
  /// the server tones the record itself.
  LabelledValue? caseStatus(String value) =>
      definitions.value?.caseStatus(value);

  LabelledValue? casePriority(String value) =>
      definitions.value?.casePriority(value);

  LabelledValue? sealStatus(String value) =>
      definitions.value?.sealStatus(value);

  LabelledValue? fineStatus(String value) =>
      definitions.value?.fineStatus(value);

  /// What to draw a form for [code] from — the server's own answer to which of
  /// the four optional inputs the action wants. Null when the rows are not
  /// loaded; do not fall back to a `switch` on the code.
  ActionTypeFields? fieldsFor(String code) => actionType(code)?.fields;

  // --- Loading ----------------------------------------------------------

  @override
  void onInit() {
    super.onInit();

    // The session is the trigger, not this controller's own construction. A
    // fetch here would go out unauthenticated: `setupDependencies` runs before
    // the splash screen has looked at the keychain.
    ever<AuthUser?>(_auth.officer, _onSessionChanged);

    // `ever` fires on change only. An officer already signed in by the time
    // this is built — a lazily created controller, a test — would otherwise
    // wait for a sign-out and back in.
    _onSessionChanged(_auth.officer.value);
  }

  /// Fetches the rows. Safe to call again; the repository caches, so this only
  /// reaches the wire once unless [refresh] is set.
  Future<void> load({bool refresh = false}) {
    final running = _inFlight;
    if (running != null && !refresh) return running;
    return _inFlight = _load(refresh: refresh);
  }

  /// The rows, fetching them if they are not in hand — including after a
  /// failed attempt.
  ///
  /// This is what a screen that cannot work without them should await: a fine
  /// form opened in a bazaar where sign-in happened on a dead signal has no
  /// offences to offer, and the officer would rather wait for a call than be
  /// shown an empty picker.
  Future<EnforcementDefinitions?> ensureLoaded() async {
    if (isReady) return definitions.value;
    await load();
    return definitions.value;
  }

  /// Goes back to the server for a fresh copy — the retry behind an error
  /// state, and what to call if MCQ has edited the register mid-shift.
  Future<void> reload() => load(refresh: true);

  Future<void> _load({required bool refresh}) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      definitions.value = await _repository.definitions(refresh: refresh);
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    } finally {
      isLoading.value = false;
      _inFlight = null;
    }
  }

  void _onSessionChanged(AuthUser? officer) {
    // A session that cannot be used is not a session to fetch on. The server
    // refuses everything else while `must_change_password` stands, so loading
    // here would spend a call to be told so.
    if (officer == null || officer.mustChangePassword) {
      if (isReady || hasError) clear();
      return;
    }
    load();
  }

  /// Throws the rows away. Called on sign-out: the next officer on this handset
  /// may be posted somewhere with a different set of rows, and showing them the
  /// last officer's pickers would be showing them the wrong register.
  void clear() {
    _repository.forget();
    _inFlight = null;
    definitions.value = null;
    errorMessage.value = null;
    isLoading.value = false;
  }
}
