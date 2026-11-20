import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/capture/photo_capture.dart';
import '../core/network/api_exception.dart';
import '../core/utils/client_action_uuid.dart';
import '../data/repositories/agreement_repository.dart';
import '../models/agreement_case.dart';
import '../models/agreement_requests.dart';
import 'agreement_case_controller.dart';
import 'agreement_cases_controller.dart';
import 'agreement_dashboard_controller.dart';

enum DecisionOutcome {
  /// Recorded. [AgreementDecisionController.result] is the updated case.
  success,

  /// The form is not ready; the fields say why.
  invalidForm,

  /// Someone acted first or the case moved on: [AgreementDecisionController
  /// .result] holds the reloaded case, and the officer decides again.
  stale,

  /// Refused. See [AgreementDecisionController.errorMessage].
  failed,
}

/// Taking one review act on a case: endorse, approve, reject, return, respond
/// or dispatch — whichever `act_options` offered.
///
/// The request is built once per tap and kept: a retry re-sends the same
/// `client_uuid`, which the server records once. Any edit makes it a
/// different request.
class AgreementDecisionController extends GetxController {
  AgreementDecisionController({
    required this.caseFile,
    required this.option,
    AgreementRepository? agreementRepository,
    PhotoCapture? photoCapture,
  }) : _agreements = agreementRepository ?? Get.find<AgreementRepository>(),
       _photos = photoCapture ?? PhotoCapture(),
       destination = RxnString(
         option.destinations.length == 1 ? option.destinations.first : null,
       );

  final AgreementCase caseFile;
  final IntakeActOption option;

  final AgreementRepository _agreements;
  final PhotoCapture _photos;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController remarksController = TextEditingController();

  /// Return only: `estate`, `taxation` or `cmo`.
  final RxnString destination;

  /// Local paths of the pictures attached to the act.
  final RxList<String> attachments = RxList<String>();

  final RxBool isSubmitting = RxBool(false);
  final RxnString errorMessage = RxnString();
  final Rxn<AgreementCase> result = Rxn<AgreementCase>();

  /// Bumped per edit, so the submit bar re-reads the text field.
  final RxInt revision = RxInt(0);

  IntakeDecisionRequest? _sent;
  String? _remarksServerError;
  String? _destinationServerError;

  @override
  void onClose() {
    remarksController.dispose();
    super.onClose();
  }

  bool get isReturn => option.act == 'return';
  bool get isReject => option.act == 'reject';

  /// The server says when; reject and return always need them.
  bool get remarksRequired => option.remarksRequired || isReject || isReturn;

  bool get needsDestination => isReturn && option.destinations.isNotEmpty;

  bool get canAttachMore =>
      attachments.length < IntakeDecisionRequest.maxAttachments;

  void markEdited() {
    revision.value++;
    _sent = null;
    _remarksServerError = null;
  }

  void chooseDestination(String? value) {
    destination.value = value;
    _destinationServerError = null;
    markEdited();
  }

  /// Pictures the last gallery pick brought past the cap and left out — an
  /// old Android chooser cannot be told the limit.
  int lastSkipped = 0;

  /// Pictures still allowed before the cap.
  int get attachmentsLeft =>
      IntakeDecisionRequest.maxAttachments - attachments.length;

  Future<PhotoOutcome> attach({bool fromGallery = false}) async {
    if (!canAttachMore) return PhotoOutcome.cancelled;
    lastSkipped = 0;
    if (fromGallery) {
      final int room = attachmentsLeft;
      final List<String> paths = await _photos.fromGalleryMany(limit: room);
      if (paths.isEmpty) return PhotoOutcome.cancelled;
      attachments.addAll(paths.take(room));
      lastSkipped = paths.length > room ? paths.length - room : 0;
      markEdited();
      return PhotoOutcome.taken;
    }
    final PhotoCaptureResult picked = await _photos.fromCamera();
    if (picked.outcome == PhotoOutcome.taken && picked.path != null) {
      attachments.add(picked.path!);
      markEdited();
    }
    return picked.outcome;
  }

  /// By position: the same picture may be attached more than once.
  void removeAttachment(int index) {
    attachments.removeAt(index);
    markEdited();
  }

  String? validateRemarks(String? value) {
    if (_remarksServerError != null) return _remarksServerError;
    final String text = value?.trim() ?? '';
    if (text.isEmpty) {
      return remarksRequired ? 'Say why — this goes on the case record' : null;
    }
    if (isReject && text.length < IntakeDecisionRequest.remarksMin) {
      return 'At least ${IntakeDecisionRequest.remarksMin} characters';
    }
    if (text.length > IntakeDecisionRequest.remarksMax) {
      return 'Keep it under ${IntakeDecisionRequest.remarksMax} characters';
    }
    return null;
  }

  String? validateDestination(String? value) {
    if (_destinationServerError != null) return _destinationServerError;
    if (needsDestination && value == null) return 'Choose where it goes';
    return null;
  }

  List<String> get missing => <String>[
    if (needsDestination && destination.value == null) 'where it goes',
    if (remarksRequired && remarksController.text.trim().isEmpty)
      'your remarks',
  ];

  Future<DecisionOutcome> submit() async {
    errorMessage.value = null;
    _remarksServerError = null;
    _destinationServerError = null;
    if (!(formKey.currentState?.validate() ?? false) || missing.isNotEmpty) {
      return DecisionOutcome.invalidForm;
    }

    isSubmitting.value = true;
    try {
      result.value = await _agreements.act(
        caseFile.id,
        option,
        _sent ??= _request(),
      );
      await _refreshLists();
      return DecisionOutcome.success;
    } on ApiException catch (error) {
      errorMessage.value = explainIntakeFailure(error);
      if (error.failure == ApiFailure.conflict ||
          error.failure == ApiFailure.forbidden) {
        // The case on screen is out of date: reload it and let the officer
        // decide again on what it says now.
        _sent = null;
        await _reload();
        return DecisionOutcome.stale;
      }
      if (error.isValidation) {
        _remarksServerError = error.messageFor('remarks');
        _destinationServerError = error.messageFor('destination');
        final String? files = _attachmentError(error);
        if (files != null) errorMessage.value = files;
        formKey.currentState?.validate();
      }
      return DecisionOutcome.failed;
    } finally {
      isSubmitting.value = false;
    }
  }

  IntakeDecisionRequest _request() {
    final String remarks = remarksController.text.trim();
    return IntakeDecisionRequest(
      clientUuid: ClientActionUuid.v4(),
      lockVersion: caseFile.lockVersion,
      remarks: remarks.isEmpty ? null : remarks,
      destination: isReturn ? destination.value : null,
      attachments: attachments.toList(),
    );
  }

  Future<void> _reload() async {
    try {
      result.value = await _agreements.caseDetail(caseFile.id);
    } on ApiException catch (_) {
      result.value = null;
    }
  }

  Future<void> _refreshLists() async {
    await Future.wait(<Future<void>>[
      AgreementDashboardController.reloadIfOpened(),
      AgreementCasesController.reloadIfOpened(),
    ]);
  }

  /// A refused file is named under `attachments.N`.
  static String? _attachmentError(ApiException error) {
    for (final MapEntry<String, List<String>> entry in error.errors.entries) {
      if (entry.key.startsWith('attachments') && entry.value.isNotEmpty) {
        return entry.value.first;
      }
    }
    return null;
  }
}
