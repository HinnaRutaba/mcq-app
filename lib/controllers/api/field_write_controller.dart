import 'dart:io';

import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_exception.dart';
import '../../core/services/location_service.dart';
import '../../core/services/photo_service.dart';
import '../../core/utils/app_feedback.dart';
import '../../data/api/repositories/enforcement_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enforcement/field_evidence.dart';
import '../../models/offline/queued_write.dart';
import 'offline_queue_controller.dart';

/// What happened to a field write, from the officer's point of view.
enum FieldWriteResult {
  /// The server created it (201).
  sent,

  /// The server had it already (200) — a replay of the same
  /// `client_action_uuid`. Do not announce it twice.
  replayed,

  /// No signal. Stored on the handset with its UUID; it will sync itself.
  queued,

  /// The server refused it — a 409 domain refusal. Its sentence has been
  /// shown in a dialog.
  refused,

  /// 422. Errors are bound onto the form fields.
  invalid,

  /// Anything else, including a 403 (already toasted by the interceptor).
  failed,
}

/// Everything the four field writes have in common: a photograph, a GPS
/// fix, a date, a witness, remarks, an idempotency key, and the decision
/// between sending now and queueing.
///
/// Every field write takes a photograph, and the photograph is a separate,
/// prior call: upload once, get a path, then send the path with the action.
/// On a weak signal that means the action can be retried as often as the
/// handset likes without re-sending two megabytes, and a failed action does
/// not lose the evidence.
abstract class FieldWriteController extends GetxController {
  FieldWriteController({
    required EnforcementRepository enforcement,
    required PhotoService photos,
    required LocationService location,
    required OfflineQueueController queue,
  })  : enforcementRepository = enforcement,
        photoService = photos,
        locationService = location,
        offlineQueue = queue;

  final EnforcementRepository enforcementRepository;
  final PhotoService photoService;
  final LocationService locationService;
  final OfflineQueueController offlineQueue;

  static const Uuid _uuid = Uuid();

  /// Generated once, when the form opens, and reused on every retry of this
  /// same record — including after the app is killed, because it is stored
  /// with the queued item. This is what stops a weak signal fining a
  /// shopkeeper twice for one offence.
  late final String clientActionUuid = _uuid.v4();

  final Rx<File?> photo = Rx<File?>(null);
  final RxString uploadedPhotoPath = ''.obs;
  final RxBool isCapturing = false.obs;
  final RxBool isUploading = false.obs;

  /// A witness's signature, drawn on the handset and uploaded exactly like
  /// the photograph — separately, first, so a failed action never loses it.
  ///
  /// Optional everywhere, and worth taking everywhere. Sealing a shop with
  /// a witness signature on the record is a much stronger document than
  /// sealing one without, and it costs the officer fifteen seconds at the
  /// shop front rather than an argument six months later.
  final Rx<File?> signature = Rx<File?>(null);
  final RxString uploadedSignaturePath = ''.obs;

  final Rx<GpsFix?> fix = Rx<GpsFix?>(null);
  final RxBool isLocating = false.obs;

  final Rx<DateTime> actionDate = DateTime.now().obs;
  final RxString witnessName = ''.obs;
  final RxString remarks = ''.obs;

  final RxBool isSubmitting = false.obs;

  /// 422 errors, keyed by field name, ready to show under the inputs.
  final RxMap<String, List<String>> fieldErrors = <String, List<String>>{}.obs;

  String? errorFor(String field) => fieldErrors[field]?.first;

  @override
  void onInit() {
    super.onInit();
    // Start looking for a fix while the officer fills the form in, so the
    // GPS is not the thing keeping them at the shop front.
    locate();
  }

  Future<void> capturePhoto() async {
    isCapturing.value = true;
    try {
      final shot = await photoService.capture();
      if (shot == null) return;
      photo.value = shot;
      // A new photograph invalidates the path of the old one.
      uploadedPhotoPath.value = '';
    } finally {
      isCapturing.value = false;
    }
  }

  void removePhoto() {
    photo.value = null;
    uploadedPhotoPath.value = '';
  }

  void setSignature(File? file) {
    signature.value = file;
    // A new signature invalidates the path of the old one.
    uploadedSignaturePath.value = '';
  }

  void removeSignature() => setSignature(null);

  Future<void> locate() async {
    isLocating.value = true;
    try {
      fix.value = await locationService.currentFix();
    } finally {
      isLocating.value = false;
    }
  }

  /// Uploads the photograph if there is one that has not been uploaded yet.
  ///
  /// Returns false only when the upload could not *reach* the server, in
  /// which case the caller queues the write with the local file and the
  /// queue uploads it later — the officer does not re-shoot the evidence.
  ///
  /// Any other failure (the server rejecting the file, a missing
  /// permission) is rethrown: queueing a photograph the server has already
  /// refused would retry it forever.
  Future<bool> ensurePhotoUploaded() async {
    final file = photo.value;
    if (file == null || uploadedPhotoPath.value.isNotEmpty) return true;
    isUploading.value = true;
    try {
      final upload = await enforcementRepository.uploadEvidence(file: file);
      uploadedPhotoPath.value = upload.path;
      return true;
    } on ApiException catch (error) {
      if (error.isNetwork) return false;
      rethrow;
    } finally {
      isUploading.value = false;
    }
  }

  /// The same two-step upload for the witness signature.
  Future<bool> ensureSignatureUploaded() async {
    final file = signature.value;
    if (file == null || uploadedSignaturePath.value.isNotEmpty) return true;
    isUploading.value = true;
    try {
      final upload = await enforcementRepository.uploadEvidence(
        file: file,
        kind: EvidenceUpload.kindSignature,
      );
      uploadedSignaturePath.value = upload.path;
      return true;
    } on ApiException catch (error) {
      if (error.isNetwork) return false;
      rethrow;
    } finally {
      isUploading.value = false;
    }
  }

  FieldEvidence buildEvidence({bool recordedOffline = false}) => FieldEvidence(
        clientActionUuid: clientActionUuid,
        actionDate: actionDate.value,
        deviceRecordedAt: DateTime.now(),
        photoPath:
            uploadedPhotoPath.value.isEmpty ? null : uploadedPhotoPath.value,
        signaturePath: uploadedSignaturePath.value.isEmpty
            ? null
            : uploadedSignaturePath.value,
        latitude: fix.value?.latitude,
        longitude: fix.value?.longitude,
        locationAccuracyM: fix.value?.accuracyM,
        witnessName: witnessName.value,
        remarks: remarks.value,
        recordedOffline: recordedOffline,
      );

  /// Runs a write, applying the same handling to every one of them: no
  /// optimistic UI, 422 binds to the fields, 409 opens a dialog with the
  /// server's sentence, a lost signal queues the record.
  Future<FieldWriteResult> runWrite({
    required Future<bool> Function() send,
    required QueuedWrite Function() queueItem,
    required String successKey,
  }) async {
    isSubmitting.value = true;
    fieldErrors.clear();
    try {
      final photoReady = await ensurePhotoUploaded();
      final signatureReady = await ensureSignatureUploaded();
      if ((!photoReady && photo.value != null) ||
          (!signatureReady && signature.value != null)) {
        // An image never made it. Queue the whole thing, images included —
        // the officer does not re-shoot evidence or ask a witness to sign
        // twice because the signal died.
        await offlineQueue.enqueue(queueItem());
        return FieldWriteResult.queued;
      }

      final created = await send();
      AppFeedback.toast(
        created ? t(successKey) : t('action.savedAlready'),
      );
      return created ? FieldWriteResult.sent : FieldWriteResult.replayed;
    } on ApiException catch (error) {
      switch (error.kind) {
        case ApiFailureKind.network:
          await offlineQueue.enqueue(queueItem());
          return FieldWriteResult.queued;
        case ApiFailureKind.conflict:
          await AppFeedback.serverRefusal(error.message);
          return FieldWriteResult.refused;
        case ApiFailureKind.validation:
          fieldErrors.assignAll(error.errors);
          if (error.errors.isEmpty) AppFeedback.toast(error.message, isError: true);
          return FieldWriteResult.invalid;
        case ApiFailureKind.forbidden:
          // Already toasted by the interceptor; do not navigate.
          return FieldWriteResult.failed;
        default:
          AppFeedback.toast(error.message, isError: true);
          return FieldWriteResult.failed;
      }
    } finally {
      isSubmitting.value = false;
    }
  }
}
