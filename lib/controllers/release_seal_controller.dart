import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/capture/photo_capture.dart';
import '../core/network/api_exception.dart';
import '../data/repositories/evidence_repository.dart';
import '../data/repositories/field_seal_repository.dart';
import '../models/field_seal.dart';
import '../models/seal_requests.dart';

/// What came of pressing "Unseal the shop".
enum ReleaseOutcome {
  /// Taken off. [ReleaseSealController.released] holds what the server wrote.
  success,

  /// The form itself was not ready; the fields and the still-needed note
  /// already say why.
  invalidForm,

  /// The server refused it. See [ReleaseSealController.errorMessage].
  failed,
}

/// Taking a seal off: `POST enforcement/field/seals/{seal}/release`.
///
/// The release hangs off the **seal**, not the case or the unit, and a shop's
/// profile does not carry a seal id — its enforcement block has the seal
/// number and nothing to post against. So the form finds the unit's seal by
/// reading the officer's own sealed list and keeping the row that names this
/// property.
///
/// The server decides whether a seal is clear to come off. One it has not
/// cleared can still be released, but only with an override reason — that is
/// the record of why a shop that still owes money was opened, and it is held
/// to a longer minimum than the ordinary one.
class ReleaseSealController extends GetxController {
  ReleaseSealController({
    required this.propertyId,
    int? sealId,
    FieldSealRepository? sealRepository,
    EvidenceRepository? evidenceRepository,
    PhotoCapture? photoCapture,
  }) : _seals = sealRepository ?? Get.find<FieldSealRepository>(),
       _evidence = evidenceRepository ?? Get.find<EvidenceRepository>(),
       _photos = photoCapture ?? PhotoCapture(),
       selectedSealId = RxnInt(sealId);

  final int propertyId;

  final FieldSealRepository _seals;
  final EvidenceRepository _evidence;
  final PhotoCapture _photos;

  /// The seals on this unit, the standing one first.
  final RxList<FieldSeal> seals = RxList<FieldSeal>();

  final RxBool isLoadingSeals = RxBool(false);
  final RxnString sealsError = RxnString();

  /// The seal being taken off.
  final RxnInt selectedSealId;

  /// The ids the unseal queue came back with — the server's own answer to
  /// which seals are clear. Held apart from the rows because a row's
  /// `ready_to_release` may simply be absent, where membership of the queue
  /// cannot be.
  final RxSet<int> readyIds = RxSet<int>(<int>{});

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  /// Why the seal is coming off, e.g. "Fine paid in full, receipt
  /// MCQ-RC-2627-00123.".
  final TextEditingController reasonController = TextEditingController();

  /// Why a shop that the server has **not** cleared is being opened anyway.
  /// Required only then, and held to a longer minimum — see
  /// [SealReleaseRequest.overrideReasonMinLength].
  final TextEditingController overrideController = TextEditingController();

  /// The day the seal came off. Today unless the officer says otherwise, and
  /// never a day that has not happened.
  final Rxn<DateTime> unsealedOn = Rxn<DateTime>(
    DateUtils.dateOnly(DateTime.now()),
  );

  /// Who stood there, and the photograph of the opened shutter. Optional here:
  /// the release endpoint does not publish the "witness or photograph" rule
  /// the seal endpoint enforces, so the form offers both and blocks on
  /// neither — and if the server does blame one, its own words land on the
  /// field.
  final TextEditingController witnessController = TextEditingController();

  final RxnString photoLocalPath = RxnString();
  final RxnString photoUploadedPath = RxnString();
  final RxBool isUploadingPhoto = RxBool(false);

  final RxBool isSubmitting = RxBool(false);
  final RxnString errorMessage = RxnString();
  final Rxn<FieldSeal> released = Rxn<FieldSeal>();

  /// Bumped on every edit, so the submit bar can re-read the text controllers
  /// — which are not observable on their own.
  final RxInt revision = RxInt(0);

  /// The request that went out, kept for the retry. Re-sending *this* instance
  /// is what makes a resend on a bazaar's signal land as the same release.
  SealReleaseRequest? _sent;

  String? _reasonServerError;
  String? _overrideServerError;
  String? _witnessServerError;

  @override
  void onInit() {
    super.onInit();
    loadSeals();
  }

  @override
  void onClose() {
    reasonController.dispose();
    overrideController.dispose();
    witnessController.dispose();
    super.onClose();
  }

  // --- Which seal --------------------------------------------------------

  FieldSeal? get selectedSeal {
    final int? id = selectedSealId.value;
    if (id == null) return null;
    for (final FieldSeal seal in seals) {
      if (seal.id == id) return seal;
    }
    return null;
  }

  /// Whether the seal may come off without an override. The server's own
  /// judgement and nothing else — never recomputed from what is owed.
  bool isReady(FieldSeal seal) =>
      seal.readyToRelease || (seal.id != null && readyIds.contains(seal.id));

  /// Whether the officer has to justify opening a shop the server has not
  /// cleared. False while no seal is chosen — there is nothing to override.
  bool get needsOverride {
    final FieldSeal? seal = selectedSeal;
    return seal != null && !isReady(seal);
  }

  /// The unit's seals, and the queue that says which are clear.
  ///
  /// `seals` publishes no property filter, so this reads the officer's own
  /// list and keeps the rows naming this unit.
  Future<void> loadSeals() async {
    isLoadingSeals.value = true;
    sealsError.value = null;
    try {
      final List<List<FieldSeal>> both = await Future.wait(
        <Future<List<FieldSeal>>>[
          _seals.seals(),
          _seals.seals(readyOnly: true),
        ],
      );

      final List<FieldSeal> mine = both.first
          .where((FieldSeal seal) => seal.propertyId == propertyId)
          .toList();
      // The standing seal first: a unit released and sealed again carries both
      // rows, and it is the live one an officer at the shutter means.
      mine.sort((FieldSeal a, FieldSeal b) {
        if (a.isSealed == b.isSealed) return 0;
        return a.isSealed ? -1 : 1;
      });

      seals.value = mine;
      readyIds
        ..clear()
        ..addAll(both.last.map((FieldSeal seal) => seal.id).whereType<int>());
      selectedSealId.value ??=
          _standing()?.id ?? (mine.isEmpty ? null : mine.first.id);
    } on ApiException catch (error) {
      sealsError.value = error.message;
    } finally {
      isLoadingSeals.value = false;
    }
  }

  FieldSeal? _standing() {
    for (final FieldSeal seal in seals) {
      if (seal.isSealed) return seal;
    }
    return null;
  }

  void chooseSeal(int sealId) {
    selectedSealId.value = sealId;
    _sent = null;
  }

  void setUnsealedOn(DateTime day) {
    unsealedOn.value = DateUtils.dateOnly(day);
    _sent = null;
  }

  /// Anything the officer changed makes this a different release from the one
  /// that was refused, so the kept request — and its idempotency key — goes
  /// with it.
  void markEdited() {
    revision.value++;
    _sent = null;
  }

  // --- What backs it up ---------------------------------------------------

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
      _sent = null;
    } on ApiException catch (error) {
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

  // --- Whether it may be sent --------------------------------------------

  String? validateReason(String? value) {
    final String? fromServer = _reasonServerError;
    if (fromServer != null) return fromServer;

    final String reason = value?.trim() ?? '';
    if (reason.isEmpty) return 'Say why the seal is coming off';
    if (reason.length < SealReleaseRequest.reasonMinLength) {
      return 'At least ${SealReleaseRequest.reasonMinLength} characters — this '
          'is the record of why a shop was opened again';
    }
    if (reason.length > SealReleaseRequest.reasonMaxLength) {
      return 'Keep it under ${SealReleaseRequest.reasonMaxLength} characters';
    }
    return null;
  }

  String? validateOverride(String? value) {
    final String? fromServer = _overrideServerError;
    if (fromServer != null) return fromServer;
    if (!needsOverride) return null;

    final String reason = value?.trim() ?? '';
    if (reason.isEmpty) {
      return 'MCQ has not cleared this seal. Say why it is coming off anyway';
    }
    if (reason.length < SealReleaseRequest.overrideReasonMinLength) {
      return 'At least ${SealReleaseRequest.overrideReasonMinLength} '
          'characters — this is the justification for opening a shop that '
          'still owes money';
    }
    if (reason.length > SealReleaseRequest.reasonMaxLength) {
      return 'Keep it under ${SealReleaseRequest.reasonMaxLength} characters';
    }
    return null;
  }

  String? validateWitness(String? value) => _witnessServerError;

  /// What the form is still short of, in the order it asks for it.
  List<String> get missing => <String>[
    if (selectedSealId.value == null) 'the seal to take off',
    if (reasonController.text.trim().isEmpty) 'why it is coming off',
    if (needsOverride && overrideController.text.trim().isEmpty)
      'why it is coming off before MCQ cleared it',
    if (unsealedOn.value == null) 'the day it came off',
  ];

  bool get isValid =>
      missing.isEmpty &&
      validateReason(reasonController.text) == null &&
      validateOverride(overrideController.text) == null;

  // --- The write ----------------------------------------------------------

  Future<ReleaseOutcome> release() async {
    _reasonServerError = null;
    _overrideServerError = null;
    _witnessServerError = null;
    errorMessage.value = null;

    formKey.currentState?.validate();
    if (!isValid) return ReleaseOutcome.invalidForm;

    final int sealId = selectedSealId.value!;

    isSubmitting.value = true;
    try {
      released.value = await _seals.release(sealId, _sent ??= _request());
      return ReleaseOutcome.success;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      if (error.isValidation) {
        _reasonServerError = error.errorFor('unseal_reason');
        _overrideServerError = error.messageFor('override_reason');
        _witnessServerError = error.messageFor('witness_name');
        formKey.currentState?.validate();
      }
      return ReleaseOutcome.failed;
    } finally {
      isSubmitting.value = false;
    }
  }

  SealReleaseRequest _request() {
    final String override = overrideController.text.trim();
    final String witness = witnessController.text.trim();
    final String? photo = photoUploadedPath.value;

    return SealReleaseRequest(
      unsealReason: reasonController.text.trim(),
      // Sent only where the server asked for it: an override on a seal it has
      // already cleared is a justification for nothing.
      overrideReason: needsOverride && override.isNotEmpty ? override : null,
      unsealedOn: unsealedOn.value,
      // Both, as the endpoint documents them: `unsealed_on` by example and
      // `action_date` in the parameter table, for the same day.
      actionDate: unsealedOn.value,
      witnessName: witness.isEmpty ? null : witness,
      photoPath: photo,
    );
  }
}
