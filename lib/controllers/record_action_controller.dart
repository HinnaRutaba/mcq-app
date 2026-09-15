import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/network/api_exception.dart';
import '../data/repositories/enforcement_case_repository.dart';
import '../models/enforcement_action.dart';
import '../models/enforcement_action_request.dart';
import '../models/enforcement_case.dart';
import '../models/enforcement_definitions.dart';
import 'definitions_controller.dart';

/// What came of pressing the button at the foot of the action form.
enum RecordActionOutcome {
  /// Written. [RecordActionController.recorded] holds what the server made of
  /// it.
  success,

  /// The form itself was not ready; the fields and the still-needed note
  /// already say why.
  invalidForm,

  /// The server refused it. See [RecordActionController.errorMessage].
  failed,
}

/// Recording one step against a case:
/// `POST enforcement/cases/{case}/actions`.
///
/// Which inputs the form asks for comes from the register rather than from a
/// switch on the code — `DefinitionsController.fieldsFor` is the server's own
/// answer to whether the step carries a promised payment date or a return
/// visit. So `payment_promised` asks for the day they will pay without this
/// controller knowing anything about that code, and a step MCQ publishes next
/// year gets the right form without an app release.
///
/// Like a seal, an action hangs off a case, so the form is in two halves:
/// which case, and the step itself. A shop with no case gets one opened on the
/// spot through `CreateCaseScreen`, which hands the new file back to [adopt].
class RecordActionController extends GetxController {
  RecordActionController({
    required this.propertyId,
    required this.actionCode,
    List<EnforcementCase>? knownCases,
    int? caseId,
    EnforcementCaseRepository? caseRepository,
    DefinitionsController? definitionsController,
  }) : _cases = caseRepository ?? Get.find<EnforcementCaseRepository>(),
       _definitions =
           definitionsController ?? Get.find<DefinitionsController>(),
       cases = RxList<EnforcementCase>(knownCases ?? <EnforcementCase>[]),
       selectedCaseId = RxnInt(caseId),
       // An empty list is an answer: the caller looked and the shop has none.
       // Only a caller that never looked leaves this to be read here.
       _wasGivenCases = knownCases != null;

  final int propertyId;

  /// The `ActionTypeDefinition.code` being recorded, e.g. `payment_promised`.
  /// What goes over the wire as `action_type`.
  final String actionCode;

  final EnforcementCaseRepository _cases;
  final DefinitionsController _definitions;

  /// Whether the shop's profile handed its own list over. It has already read
  /// them, and re-reading four pages of cases at a shopfront is a call the
  /// officer waits on for nothing.
  final bool _wasGivenCases;

  /// The cases on this unit, in the order they were handed over.
  final RxList<EnforcementCase> cases;

  final RxBool isLoadingCases = RxBool(false);
  final RxnString casesError = RxnString();

  /// The case the step will be recorded against.
  final RxnInt selectedCaseId;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  /// What was said at the shop. The only place the shopkeeper's own words
  /// land, and what somebody reading the timeline next month has to go on.
  final TextEditingController remarksController = TextEditingController();

  /// The day the officer called. Today unless they say otherwise, and never a
  /// day that has not happened.
  ///
  /// Date-only, like the bounds the form picks between: a value carrying this
  /// morning's clock time is after a `lastDate` of today and the picker
  /// asserts on it.
  final Rxn<DateTime> actionDate = Rxn<DateTime>(
    DateUtils.dateOnly(DateTime.now()),
  );

  /// The day they said they would pay. Today or later.
  final Rxn<DateTime> promisedPaymentDate = Rxn<DateTime>();

  /// The day the officer will come back.
  final Rxn<DateTime> nextVisitDate = Rxn<DateTime>();

  final RxBool isSubmitting = RxBool(false);
  final RxnString errorMessage = RxnString();
  final Rxn<EnforcementAction> recorded = Rxn<EnforcementAction>();

  /// Bumped on every edit, so the submit bar can re-read the text controller
  /// — which is not observable on its own.
  final RxInt revision = RxInt(0);

  /// The request that went out, kept for the retry.
  ///
  /// Re-sending *this* instance is what makes a resend on a bazaar's signal
  /// land as the same record: its `client_action_uuid` was minted once.
  /// Building a fresh one would put the visit on the timeline twice.
  EnforcementActionRequest? _sent;

  String? _remarksServerError;
  String? _promiseServerError;
  String? _visitServerError;

  @override
  void onInit() {
    super.onInit();
    // Normally already in hand — fetched at sign-in. This is for the officer
    // who signed in on a dead signal and is now standing in a bazaar.
    _definitions.ensureLoaded();
    if (!_wasGivenCases) loadCases();
  }

  @override
  void onClose() {
    remarksController.dispose();
    super.onClose();
  }

  // --- What the register says this step is ------------------------------

  /// The register's row for [actionCode] — its wording and its form spec.
  /// Read it inside an `Obx`: it is null until the definitions land.
  ActionTypeDefinition? get definition => _definitions.actionType(actionCode);

  /// Which inputs this step carries, as the server published them. Null while
  /// the rows are still coming, and on a step MCQ has since switched off —
  /// the form waits rather than guessing which date to ask for.
  ActionTypeFields? get fields => _definitions.fieldsFor(actionCode);

  bool get isLoadingDefinitions => _definitions.isLoading.value;

  String? get definitionsError => _definitions.errorMessage.value;

  Future<void> reloadDefinitions() => _definitions.reload();

  // --- The case it goes on ----------------------------------------------

  EnforcementCase? get selectedCase {
    final int? id = selectedCaseId.value;
    if (id == null) return null;
    for (final EnforcementCase file in cases) {
      if (file.id == id) return file;
    }
    return null;
  }

  /// Reads the unit's cases. Only for a cold link — see [_wasGivenCases].
  Future<void> loadCases() async {
    isLoadingCases.value = true;
    casesError.value = null;
    try {
      cases.value = await _cases.casesForProperty(propertyId);
      // Nothing chosen yet: the live case is the one a visit belongs on.
      selectedCaseId.value ??= _live()?.id;
    } on ApiException catch (error) {
      casesError.value = error.message;
    } finally {
      isLoadingCases.value = false;
    }
  }

  EnforcementCase? _live() {
    for (final EnforcementCase file in cases) {
      if (file.isLive) return file;
    }
    return null;
  }

  void chooseCase(int caseId) {
    selectedCaseId.value = caseId;
    _sent = null;
  }

  /// Takes on a case just opened through `CreateCaseScreen` and selects it —
  /// the officer opened it in order to record against it.
  void adopt(EnforcementCase file) {
    if (file.id == null) return;
    cases.removeWhere((EnforcementCase held) => held.id == file.id);
    cases.insert(0, file);
    selectedCaseId.value = file.id;
    _sent = null;
  }

  // --- The step itself ---------------------------------------------------

  void setActionDate(DateTime day) {
    actionDate.value = DateUtils.dateOnly(day);
    _sent = null;
  }

  void setPromisedPaymentDate(DateTime day) {
    promisedPaymentDate.value = DateUtils.dateOnly(day);
    _promiseServerError = null;
    _sent = null;
  }

  void setNextVisitDate(DateTime day) {
    nextVisitDate.value = DateUtils.dateOnly(day);
    _visitServerError = null;
    _sent = null;
  }

  /// Anything the officer changed makes this a different record from the one
  /// that was refused, so the kept request — and its idempotency key — goes
  /// with it. Pressing send again without editing resends the same one.
  void markEdited() {
    revision.value++;
    _sent = null;
  }

  // --- Whether it may be sent -------------------------------------------

  String? validateRemarks(String? value) {
    final String? fromServer = _remarksServerError;
    if (fromServer != null) return fromServer;

    final String remarks = value?.trim() ?? '';
    if (remarks.length > EnforcementActionRequest.remarksMaxLength) {
      return 'Keep it under ${EnforcementActionRequest.remarksMaxLength} '
          'characters';
    }
    return null;
  }

  /// Only what the server said about the date. Whether one has been picked at
  /// all is the still-needed note's job — a field turned red under a picker
  /// the officer has not opened yet is noise.
  String? validatePromisedDate(String? value) => _promiseServerError;

  String? validateVisitDate(String? value) => _visitServerError;

  /// What the form is still short of, in the order it asks for it.
  List<String> get missing {
    final ActionTypeFields? spec = fields;
    return <String>[
      if (spec == null) 'what MCQ says this step records',
      if (selectedCaseId.value == null) 'the case to record it against',
      if (actionDate.value == null) 'the day you called',
      if ((spec?.promiseDate ?? false) && promisedPaymentDate.value == null)
        'the day they promised to pay',
      if ((spec?.visitDate ?? false) && nextVisitDate.value == null)
        'the day you will come back',
    ];
  }

  bool get isValid =>
      missing.isEmpty && validateRemarks(remarksController.text) == null;

  // --- The write --------------------------------------------------------

  Future<RecordActionOutcome> record() async {
    _remarksServerError = null;
    _promiseServerError = null;
    _visitServerError = null;
    errorMessage.value = null;

    // The Form paints the messages; whether the record may be sent is decided
    // here — the rules belong to the controller, not to whether a widget
    // happens to be mounted.
    formKey.currentState?.validate();
    if (!isValid) return RecordActionOutcome.invalidForm;

    final int caseId = selectedCaseId.value!;

    isSubmitting.value = true;
    try {
      recorded.value = await _cases.recordAction(caseId, _sent ??= _request());
      return RecordActionOutcome.success;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      if (error.isValidation) {
        _remarksServerError = error.errorFor('remarks');
        _promiseServerError = error.errorFor('promised_payment_date');
        _visitServerError = error.errorFor('next_visit_date');
        formKey.currentState?.validate();
      }
      return RecordActionOutcome.failed;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Only the dates the register asked for go on the wire: a `site_visit`
  /// carrying a promised payment date is a record of something nobody said.
  EnforcementActionRequest _request() {
    final ActionTypeFields? spec = fields;
    final String remarks = remarksController.text.trim();

    return EnforcementActionRequest.ofCode(
      actionCode,
      actionDate: actionDate.value,
      promisedPaymentDate: (spec?.promiseDate ?? false)
          ? promisedPaymentDate.value
          : null,
      nextVisitDate: (spec?.visitDate ?? false) ? nextVisitDate.value : null,
      remarks: remarks.isEmpty ? null : remarks,
    );
  }
}
