import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/capture/location_capture.dart';
import '../core/capture/photo_capture.dart';
import '../core/network/api_exception.dart';
import '../data/repositories/evidence_repository.dart';
import '../data/repositories/fine_repository.dart';
import '../data/repositories/units_repository.dart';
import '../models/fine.dart';
import '../models/fine_request.dart';
import '../models/unit_card.dart';

/// What came of pressing "Impose a fine".
enum ImposeOutcome {
  /// Posted. [FineController.imposed] holds the fine, its challan and its
  /// payment link.
  success,

  /// The form itself was not valid; the fields already say why.
  invalidForm,

  /// The server refused it. See [FineController.errorMessage] and the field
  /// validators.
  failed,
}

/// The offence types the published API documents by example, with the wording
/// to put in front of an officer.
///
/// The server's enum is the authority and its full set is not published, so
/// this is a list of what is known to be accepted rather than a mirror of it.
/// The labels are written here because the server sends none on the way *in* —
/// it labels the type only on the fine that comes back, and that label is shown
/// verbatim wherever it appears.
class FineType {
  const FineType(this.value, this.label);

  final String value;
  final String label;

  static const List<FineType> all = <FineType>[
    FineType('unauthorised_use', 'Unauthorised use'),
    FineType('encroachment', 'Encroachment'),
  ];
}

/// Imposing a fine: the form, the evidence attached to it, and the one call
/// that posts the lot.
///
/// Three rules this controller exists to hold in one place:
///
/// * **The request is built once.** [_pending] keeps the [FineRequest] that was
///   sent, so a retry after a dead signal re-sends the same `client_action_uuid`
///   and the server recognises it as the same fine arriving twice rather than a
///   second one. Editing any field throws it away, because that is a different
///   fine.
/// * **Evidence is uploaded before the write.** The photograph and the
///   signature go up through [EvidenceRepository] and only their returned paths
///   travel on the fine — so the image goes over a bazaar's uplink once, and the
///   fine behind it can be retried as many times as it takes.
/// * **The amount is a string from end to end.** It is typed as a string, held
///   as a string and sent as a string. Nothing here parses it into a number.
class FineController extends GetxController {
  FineController({
    this.unit,
    this.propertyId,
    FineRepository? fineRepository,
    EvidenceRepository? evidenceRepository,
    UnitsRepository? unitsRepository,
    PhotoCapture? photoCapture,
    LocationCapture? locationCapture,
  }) : _fines = fineRepository ?? Get.find<FineRepository>(),
       _evidence = evidenceRepository ?? Get.find<EvidenceRepository>(),
       _units = unitsRepository ?? Get.find<UnitsRepository>(),
       _photos = photoCapture ?? PhotoCapture(),
       _locations = locationCapture ?? const LocationCapture();

  /// The unit being fined, when the officer arrived from its profile. Null when
  /// they came from the "new fine" button with no shop in mind, in which case
  /// they pick one first.
  final UnitCard? unit;

  /// The unit's id, for the case where only the id was carried on the route.
  final int? propertyId;

  final FineRepository _fines;
  final EvidenceRepository _evidence;
  final UnitsRepository _units;
  final PhotoCapture _photos;
  final LocationCapture _locations;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // --- Which shop -------------------------------------------------------
  final Rxn<UnitCard> selectedUnit = Rxn<UnitCard>();
  final TextEditingController searchController = TextEditingController();
  final RxList<UnitCard> searchResults = <UnitCard>[].obs;
  final RxBool isSearching = false.obs;

  // --- The offence ------------------------------------------------------
  final Rxn<FineType> fineType = Rxn<FineType>();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController provisionController = TextEditingController();
  final Rx<DateTime> imposedOn = DateTime.now().obs;

  // --- Who pays, when nobody is on the register -------------------------
  final TextEditingController offenderNameController = TextEditingController();
  final TextEditingController offenderFatherController =
      TextEditingController();
  final TextEditingController offenderMobileController =
      TextEditingController();

  // --- The evidence -----------------------------------------------------
  final RxnString photoLocalPath = RxnString();
  final RxnString photoUploadedPath = RxnString();
  final RxBool isUploadingPhoto = false.obs;

  final Rxn<LocationFix> locationFix = Rxn<LocationFix>();
  final RxBool isFixingLocation = false.obs;
  final Rx<LocationOutcome> locationOutcome = LocationOutcome.unavailable.obs;

  final RxnString signatureLocalPath = RxnString();
  final RxnString signatureUploadedPath = RxnString();
  final TextEditingController witnessController = TextEditingController();

  final TextEditingController remarksController = TextEditingController();

  // --- Submission -------------------------------------------------------
  final RxBool isSubmitting = false.obs;
  final RxnString errorMessage = RxnString();
  final Rxn<Fine> imposed = Rxn<Fine>();

  /// The request that was sent, kept for a retry so the idempotency key
  /// survives it. Cleared whenever the officer edits the fine.
  FineRequest? _pending;

  String? _amountServerError;
  String? _provisionServerError;
  String? _fineTypeServerError;
  String? _offenderNameServerError;
  String? _offenderFatherServerError;
  String? _offenderMobileServerError;

  @override
  void onInit() {
    super.onInit();
    if (unit != null) selectedUnit.value = unit;
  }

  @override
  void onClose() {
    searchController.dispose();
    amountController.dispose();
    provisionController.dispose();
    offenderNameController.dispose();
    offenderFatherController.dispose();
    offenderMobileController.dispose();
    witnessController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  /// The unit the fine will be posted against, whichever way the officer got
  /// here.
  int? get targetPropertyId => selectedUnit.value?.propertyId ?? propertyId;

  /// The server's own answer to "does this form need to name somebody?" — read,
  /// never worked out from whether the unit looks vacant.
  bool get needsOffenderDetails =>
      selectedUnit.value?.needsOffenderDetails ?? false;

  /// Whether every required field is filled. Drives the submit button, so the
  /// officer can see the form is not ready before they reach the bottom of it.
  bool get isComplete =>
      targetPropertyId != null &&
      fineType.value != null &&
      amountController.text.trim().isNotEmpty &&
      provisionController.text.trim().isNotEmpty &&
      (!needsOffenderDetails ||
          (offenderNameController.text.trim().isNotEmpty &&
              offenderFatherController.text.trim().isNotEmpty &&
              offenderMobileController.text.trim().isNotEmpty));

  /// Whether every field the server insists on passes its own validator.
  ///
  /// Separate from [isComplete], which only asks whether the fields have
  /// something in them: this one is the full set of rules, and it is what
  /// decides whether a fine is sent.
  bool get isValid =>
      targetPropertyId != null &&
      validateFineType(fineType.value) == null &&
      validateAmount(amountController.text) == null &&
      validateProvision(provisionController.text) == null &&
      validateOffenderName(offenderNameController.text) == null &&
      validateOffenderFather(offenderFatherController.text) == null &&
      validateOffenderMobile(offenderMobileController.text) == null &&
      validateRemarks(remarksController.text) == null;

  /// What is still missing, in the order the form asks for it. Shown beside the
  /// disabled button — a button that will not press and will not say why is the
  /// thing officers give up on.
  List<String> get missing => <String>[
    if (targetPropertyId == null) 'the shop',
    if (fineType.value == null) 'the offence',
    if (amountController.text.trim().isEmpty) 'the amount',
    if (provisionController.text.trim().isEmpty) 'the provision of law',
    if (needsOffenderDetails && offenderNameController.text.trim().isEmpty)
      "the offender's name",
    if (needsOffenderDetails && offenderFatherController.text.trim().isEmpty)
      "their father's name",
    if (needsOffenderDetails && offenderMobileController.text.trim().isEmpty)
      'their mobile number',
  ];

  /// Bumped by [markEdited]. The completeness of the form is worked out from
  /// `TextEditingController.text`, which is not observable, so the submit bar
  /// watches this instead and re-reads them.
  final RxInt revision = 0.obs;

  /// Any edit makes this a different fine, so the request built for the last
  /// attempt — and the uuid on it — is no longer the right one to resend.
  void markEdited() {
    _pending = null;
    revision.value++;
  }

  // --- Which shop -------------------------------------------------------

  Future<void> search(String query) async {
    final term = query.trim();
    if (term.length < 2) {
      searchResults.clear();
      return;
    }
    isSearching.value = true;
    try {
      // Vacant units included: the shop somebody is trading out of without an
      // allotment is exactly the one being fined.
      searchResults.value = await _units.units(search: term, limit: 20);
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      searchResults.clear();
    } finally {
      isSearching.value = false;
    }
  }

  void chooseUnit(UnitCard chosen) {
    selectedUnit.value = chosen;
    searchResults.clear();
    searchController.clear();
    markEdited();
  }

  void clearUnit() {
    selectedUnit.value = null;
    markEdited();
  }

  // --- The evidence -----------------------------------------------------

  /// Takes the photograph and puts it up straight away, so the officer learns
  /// the upload failed while they are still standing there rather than at the
  /// moment they press submit.
  Future<PhotoOutcome> attachPhoto({bool fromGallery = false}) async {
    final result = fromGallery
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
    final path = photoLocalPath.value;
    if (path == null) return;
    isUploadingPhoto.value = true;
    try {
      final upload = await _evidence.upload(
        filePath: path,
        kind: EvidenceRepository.kindPhoto,
      );
      photoUploadedPath.value = upload.path;
    } on ApiException catch (error) {
      // The picture stays on the handset and the button offers a retry. The
      // fine is not blocked by it — a photograph that will not go up is not a
      // reason to let a shopkeeper walk away unfined.
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

  Future<LocationOutcome> attachLocation() async {
    isFixingLocation.value = true;
    try {
      final result = await _locations.fix();
      locationOutcome.value = result.outcome;
      // Both coordinates or neither: a failed attempt clears the last fix
      // rather than leaving a stale one attached to a new shop.
      locationFix.value = result.fix;
      markEdited();
      return result.outcome;
    } finally {
      isFixingLocation.value = false;
    }
  }

  /// The signature is drawn on the handset and handed here as a PNG on disk.
  Future<void> attachSignature(String localPath) async {
    signatureLocalPath.value = localPath;
    signatureUploadedPath.value = null;
    markEdited();
    try {
      final upload = await _evidence.upload(
        filePath: localPath,
        kind: EvidenceRepository.kindSignature,
      );
      signatureUploadedPath.value = upload.path;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    }
  }

  void removeSignature() {
    signatureLocalPath.value = null;
    signatureUploadedPath.value = null;
    markEdited();
  }

  // --- Validators -------------------------------------------------------

  String? validateAmount(String? value) {
    if (_amountServerError != null) return _amountServerError;
    final amount = value?.trim() ?? '';
    if (amount.isEmpty) return 'A fine amount is required';
    // Shape only. The figure itself is never parsed into a number here — it is
    // sent as typed and the server decides what it is worth.
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(amount)) {
      return 'Enter an amount like 4500 or 4500.00';
    }
    if (RegExp(r'^0+(\.0{1,2})?$').hasMatch(amount)) {
      return 'The amount must be at least 1';
    }
    return null;
  }

  String? validateProvision(String? value) {
    if (_provisionServerError != null) return _provisionServerError;
    if ((value?.trim() ?? '').isEmpty) {
      // Not a formality: this is the sentence a magistrate reads out if the
      // fine is challenged.
      return 'Name the section of law. A fine without one cannot be enforced.';
    }
    return null;
  }

  String? validateFineType(FineType? value) {
    if (_fineTypeServerError != null) return _fineTypeServerError;
    if (value == null) return 'Choose what the offence was';
    return null;
  }

  String? validateOffenderName(String? value) {
    if (_offenderNameServerError != null) return _offenderNameServerError;
    if (!needsOffenderDetails) return null;
    if ((value?.trim() ?? '').isEmpty) return "The offender's name is required";
    return null;
  }

  String? validateOffenderFather(String? value) {
    if (_offenderFatherServerError != null) return _offenderFatherServerError;
    if (!needsOffenderDetails) return null;
    if ((value?.trim() ?? '').isEmpty) return "Their father's name is required";
    return null;
  }

  String? validateOffenderMobile(String? value) {
    if (_offenderMobileServerError != null) return _offenderMobileServerError;
    if (!needsOffenderDetails) return null;
    if ((value?.trim() ?? '').isEmpty) return 'A mobile number is required';
    return null;
  }

  String? validateRemarks(String? value) {
    final remarks = value ?? '';
    if (remarks.length > FineRequest.remarksMaxLength) {
      return 'Keep remarks under ${FineRequest.remarksMaxLength} characters';
    }
    return null;
  }

  // --- Submission -------------------------------------------------------

  Future<ImposeOutcome> impose() async {
    _clearServerErrors();
    errorMessage.value = null;

    final propertyId = targetPropertyId;
    if (propertyId == null) {
      errorMessage.value = 'Choose the shop this fine is against.';
      return ImposeOutcome.invalidForm;
    }
    // The Form is asked to paint the messages; whether the fine may be sent is
    // decided here. The rules belong to the controller, not to whether a
    // widget happens to be mounted.
    formKey.currentState?.validate();
    if (!isValid) return ImposeOutcome.invalidForm;

    // Built once and kept. A second press after a timeout re-sends this same
    // object, uuid and all, and the server treats it as the same fine.
    final request = _pending ??= _buildRequest();

    isSubmitting.value = true;
    try {
      imposed.value = await _fines.impose(
        propertyId: propertyId,
        request: request,
      );
      _pending = null;
      return ImposeOutcome.success;
    } on ApiException catch (error) {
      _applyFailure(error);
      formKey.currentState?.validate();
      return ImposeOutcome.failed;
    } finally {
      isSubmitting.value = false;
    }
  }

  FineRequest _buildRequest() {
    final fix = locationFix.value;
    return FineRequest(
      fineType: fineType.value!.value,
      fineAmount: amountController.text.trim(),
      legalProvision: provisionController.text.trim(),
      imposedOn: imposedOn.value,
      allotmentId: selectedUnit.value?.allotmentId,
      enforcementCaseId: selectedUnit.value?.openCaseId,
      offender: needsOffenderDetails
          ? FineOffender(
              name: offenderNameController.text.trim(),
              fatherName: offenderFatherController.text.trim(),
              mobileNo: offenderMobileController.text.trim(),
            )
          : null,
      actionDate: imposedOn.value,
      latitude: fix?.latitude,
      longitude: fix?.longitude,
      locationAccuracyM: fix?.accuracyM,
      // The uploaded path, never the handset's own — the server has no idea
      // what `/data/user/0/…` means.
      photoPath: photoUploadedPath.value,
      signaturePath: signatureUploadedPath.value,
      witnessName: _trimmedOrNull(witnessController.text),
      remarks: _trimmedOrNull(remarksController.text),
    );
  }

  static String? _trimmedOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _applyFailure(ApiException error) {
    errorMessage.value = error.message;
    if (!error.isValidation) return;

    _fineTypeServerError = error.errorFor('fine_type');
    _amountServerError = error.errorFor('fine_amount');
    _provisionServerError = error.errorFor('legal_provision');
    _offenderNameServerError = error.errorFor('offender_name');
    _offenderFatherServerError = error.errorFor('offender_father_name');
    _offenderMobileServerError = error.errorFor('offender_mobile_no');
  }

  void _clearServerErrors() {
    _fineTypeServerError = null;
    _amountServerError = null;
    _provisionServerError = null;
    _offenderNameServerError = null;
    _offenderFatherServerError = null;
    _offenderMobileServerError = null;
  }
}
