import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/capture/photo_capture.dart';
import '../core/network/api_exception.dart';
import '../data/repositories/enforcement_case_repository.dart';
import '../data/repositories/evidence_repository.dart';
import '../models/enforcement_case.dart';
import '../models/field_seal.dart';
import '../models/seal_requests.dart';

/// What came of pressing "Seal the shop".
enum SealOutcome {
  /// Applied. [SealController.applied] holds what the server wrote.
  success,

  /// The form itself was not ready; the fields and the still-needed note
  /// already say why.
  invalidForm,

  /// The server refused it. See [SealController.errorMessage].
  failed,
}

/// Shutting a shop: `POST enforcement/cases/{case}/seal`.
///
/// A seal hangs off a case, so the form is in two halves — which case, and
/// why. The case is either one already open on the unit or one the officer
/// opens on the spot through `CreateCaseScreen`, which hands the new file back
/// here to be sealed.
class SealController extends GetxController {
  SealController({
    required this.propertyId,
    List<EnforcementCase>? knownCases,
    int? caseId,
    EnforcementCaseRepository? caseRepository,
    EvidenceRepository? evidenceRepository,
    PhotoCapture? photoCapture,
  }) : _cases = caseRepository ?? Get.find<EnforcementCaseRepository>(),
       _evidence = evidenceRepository ?? Get.find<EvidenceRepository>(),
       _photos = photoCapture ?? PhotoCapture(),
       cases = RxList<EnforcementCase>(knownCases ?? <EnforcementCase>[]),
       selectedCaseId = RxnInt(caseId),
       // An empty list is an answer: the caller looked and the shop has none.
       // Only a caller that never looked leaves this to be read here.
       _wasGivenCases = knownCases != null;

  final int propertyId;

  final EnforcementCaseRepository _cases;
  final EvidenceRepository _evidence;
  final PhotoCapture _photos;

  /// Whether the shop's profile handed its own list over. It has already read
  /// them, and re-reading four pages of cases at a shopfront is a call the
  /// officer waits on for nothing.
  final bool _wasGivenCases;

  /// The cases on this unit, newest of the officer's own first.
  final RxList<EnforcementCase> cases;

  final RxBool isLoadingCases = RxBool(false);
  final RxnString casesError = RxnString();

  /// The case the seal will be recorded against.
  final RxnInt selectedCaseId;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  /// Why the shop is being shut. The server keeps this as the record.
  final TextEditingController reasonController = TextEditingController();

  /// The day the seal went on. Today unless the officer says otherwise, and
  /// never a day that has not happened.
  final Rxn<DateTime> sealedOn = Rxn<DateTime>(DateTime.now());

  /// Who stood there and saw the shutter come down.
  ///
  /// The server takes this **or** a photograph and refuses a seal carrying
  /// neither: on one officer's word alone it is the first thing challenged.
  /// See [hasCorroboration].
  final TextEditingController witnessController = TextEditingController();

  /// The photograph of the sealed shutter. [photoLocalPath] is the file on the
  /// handset; [photoUploadedPath] is what the server gave back for it, and the
  /// only one that may go on the request — a seal must not claim evidence the
  /// server has never received.
  final RxnString photoLocalPath = RxnString();
  final RxnString photoUploadedPath = RxnString();
  final RxBool isUploadingPhoto = RxBool(false);

  final RxBool isSubmitting = RxBool(false);
  final RxnString errorMessage = RxnString();
  final Rxn<FieldSeal> applied = Rxn<FieldSeal>();

  /// Bumped on every edit, so the submit bar can re-read the text controller
  /// — which is not observable on its own.
  final RxInt revision = RxInt(0);

  /// The request that went out, kept for the retry.
  ///
  /// Re-sending *this* instance is what makes a resend on a bazaar's signal
  /// land as the same seal: its `client_action_uuid` was minted once. Building
  /// a fresh one would seal the shop twice.
  CaseSealRequest? _sent;

  String? _reasonServerError;
  String? _witnessServerError;

  @override
  void onInit() {
    super.onInit();
    if (!_wasGivenCases) loadCases();
  }

  @override
  void onClose() {
    reasonController.dispose();
    witnessController.dispose();
    super.onClose();
  }

  /// The case chosen, when one is.
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
      // Nothing chosen yet: the live case is the one a seal belongs on.
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
  /// the officer opened it in order to seal against it.
  void adopt(EnforcementCase file) {
    if (file.id == null) return;
    cases.removeWhere((EnforcementCase held) => held.id == file.id);
    cases.insert(0, file);
    selectedCaseId.value = file.id;
    _sent = null;
  }

  void setSealedOn(DateTime day) {
    sealedOn.value = day;
    _sent = null;
  }

  // --- What backs the seal up -------------------------------------------

  /// Takes the photograph and puts it up straight away, so the officer learns
  /// the upload failed while they are still standing at the shutter rather
  /// than at the moment they press the button.
  Future<PhotoOutcome> attachPhoto({bool fromGallery = false}) async {
    final PhotoCaptureResult result = fromGallery
        ? await _photos.fromGallery()
        : await _photos.fromCamera();
    if (result.outcome != PhotoOutcome.taken) return result.outcome;

    photoLocalPath.value = result.path;
    photoUploadedPath.value = null;
    markEdited();
    await _uploadPhoto();
    return PhotoOutcome.taken;
  }

  Future<void> _uploadPhoto() async {
    final String? path = photoLocalPath.value;
    if (path == null) return;
    isUploadingPhoto.value = true;
    try {
      final upload = await _evidence.upload(
        filePath: path,
        kind: EvidenceRepository.kindPhoto,
      );
      photoUploadedPath.value = upload.path;
      _witnessServerError = null;
      _sent = null;
    } on ApiException catch (error) {
      // The picture stays on the handset and the tile offers a retry. A
      // photograph that will not go up is not a reason to leave a shop open —
      // the officer can name a witness instead.
      errorMessage.value = error.message;
    } finally {
      isUploadingPhoto.value = false;
    }
  }

  Future<void> retryPhotoUpload() => _uploadPhoto();

  void removePhoto() {
    photoLocalPath.value = null;
    photoUploadedPath.value = null;
    markEdited();
  }

  /// Whether the seal carries what the server asks for behind it — a named
  /// witness or a photograph it actually holds.
  ///
  /// A photograph still on the handset does not count: the request would name
  /// a path the server cannot resolve.
  bool get hasCorroboration =>
      witnessController.text.trim().isNotEmpty ||
      photoUploadedPath.value != null;

  /// Anything the officer changed makes this a different seal from the one
  /// that was refused, so the kept request — and its idempotency key — goes
  /// with it. Pressing send again without editing resends the same one.
  void markEdited() {
    revision.value++;
    _sent = null;
  }

  // --- Whether it may be sent -------------------------------------------

  String? validateReason(String? value) {
    final String? fromServer = _reasonServerError;
    if (fromServer != null) return fromServer;

    final String reason = value?.trim() ?? '';
    if (reason.isEmpty) return 'Say why the shop is being sealed';
    if (reason.length < CaseSealRequest.reasonMinLength) {
      return 'At least ${CaseSealRequest.reasonMinLength} characters — this is '
          'the record of why a shop was shut';
    }
    if (reason.length > CaseSealRequest.reasonMaxLength) {
      return 'Keep it under ${CaseSealRequest.reasonMaxLength} characters';
    }
    return null;
  }

  /// The witness field's own message. A seal with neither witness nor
  /// photograph is refused by the server, so the form says so before it is
  /// sent rather than after.
  String? validateWitness(String? value) {
    final String? fromServer = _witnessServerError;
    if (fromServer != null) return fromServer;
    if (hasCorroboration) return null;
    return 'Name a witness, or photograph the sealed shutter';
  }

  /// What is still missing, in the order the form asks for it. Shown beside
  /// the disabled button — a button that will not press and will not say why
  /// is the thing officers give up on.
  List<String> get missing => <String>[
    if (selectedCaseId.value == null) 'the case to seal against',
    if (reasonController.text.trim().isEmpty) 'why it is being sealed',
    if (sealedOn.value == null) 'the day it went on',
    // One or the other, never both: the server takes a seal backed by either.
    if (!hasCorroboration) 'a witness’s name or a photograph',
  ];

  bool get isValid =>
      missing.isEmpty && validateReason(reasonController.text) == null;

  // --- The write --------------------------------------------------------

  Future<SealOutcome> apply() async {
    _reasonServerError = null;
    _witnessServerError = null;
    errorMessage.value = null;

    // The Form paints the messages; whether the seal may be sent is decided
    // here — the rules belong to the controller, not to whether a widget
    // happens to be mounted.
    formKey.currentState?.validate();
    if (!isValid) return SealOutcome.invalidForm;

    final int caseId = selectedCaseId.value!;

    isSubmitting.value = true;
    try {
      applied.value = await _cases.seal(caseId, _sent ??= _request());
      return SealOutcome.success;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      if (error.isValidation) {
        _reasonServerError = error.errorFor('seal_reason');
        // `witness_name` comes back blamed with no message under it when the
        // seal carried neither witness nor photograph; the sentence is on the
        // refusal itself.
        _witnessServerError = error.messageFor('witness_name');
        formKey.currentState?.validate();
      }
      return SealOutcome.failed;
    } finally {
      isSubmitting.value = false;
    }
  }

  CaseSealRequest _request() {
    final String witness = witnessController.text.trim();
    final String? photo = photoUploadedPath.value;

    return CaseSealRequest(
      sealReason: reasonController.text.trim(),
      sealedOn: sealedOn.value,
      // Both, as the endpoint documents them: `sealed_on` by example and
      // `action_date` in the parameter table, for the same day.
      actionDate: sealedOn.value,
      witnessName: witness.isEmpty ? null : witness,
      // The one photograph fills both fields the endpoint publishes for it:
      // `seal_photo_path` is the seal's own, `photo_path` the envelope every
      // field write carries. Sending it twice costs nothing and leaves no
      // question which of them the server's "witness or photograph" check
      // reads.
      sealPhotoPath: photo,
      photoPath: photo,
    );
  }
}
