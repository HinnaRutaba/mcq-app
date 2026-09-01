import 'dart:io';

import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/services/photo_service.dart';
import '../../core/utils/app_feedback.dart';
import '../../data/api/repositories/property_repository.dart';
import '../../l10n/app_localizations.dart';

/// Recording an inspection of a unit.
///
/// One step, not two: the image goes on the request itself as a `photo`
/// part. And deliberately **not** queued offline — an inspection carries no
/// `client_action_uuid`, so a blind retry could record it twice. This write
/// needs signal.
class InspectionFormController extends GetxController {
  InspectionFormController({
    required this.propertyId,
    required PropertyApiRepository properties,
    required PhotoService photos,
  })  : _properties = properties,
        _photos = photos;

  factory InspectionFormController.resolve(int propertyId) =>
      InspectionFormController(
        propertyId: propertyId,
        properties: Get.find(),
        photos: Get.find(),
      );

  final int propertyId;
  final PropertyApiRepository _properties;
  final PhotoService _photos;

  final RxString inspectionType = ''.obs;
  final RxString findings = ''.obs;
  final Rx<File?> photo = Rx<File?>(null);
  final RxBool isCapturing = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxMap<String, List<String>> fieldErrors = <String, List<String>>{}.obs;

  bool get isValid =>
      inspectionType.value.isNotEmpty && findings.value.trim().isNotEmpty;

  String? errorFor(String field) => fieldErrors[field]?.first;

  Future<void> capturePhoto() async {
    isCapturing.value = true;
    try {
      final shot = await _photos.capture();
      if (shot != null) photo.value = shot;
    } finally {
      isCapturing.value = false;
    }
  }

  void removePhoto() => photo.value = null;

  Future<bool> submit() async {
    isSubmitting.value = true;
    fieldErrors.clear();
    try {
      final outcome = await _properties.recordInspection(
        propertyId: propertyId,
        inspectionType: inspectionType.value,
        findings: findings.value.trim(),
        photo: photo.value,
      );
      AppFeedback.toast(outcome.message ?? t('inspection.saved'));
      return true;
    } on ApiException catch (error) {
      if (error.isValidation) {
        fieldErrors.assignAll(error.errors);
      } else if (error.isConflict) {
        await AppFeedback.serverRefusal(error.message);
      } else if (!error.isForbidden) {
        AppFeedback.toast(error.message, isError: true);
      }
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
