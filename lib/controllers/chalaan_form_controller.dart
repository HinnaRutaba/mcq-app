import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/repositories/chalaan_repository.dart';
import '../data/repositories/property_repository.dart';
import '../models/chalaan.dart';
import '../models/property.dart';
import 'seal_controller.dart';

/// Drives the "Create Chalaan/Fine" screen (opened from the Magistrate
/// shell's center FAB).
///
/// A fine can optionally seal the property immediately on submit — that
/// creates a linked [SealController] seal record in the same action.
class ChalaanFormController extends GetxController {
  ChalaanFormController({
    ChalaanRepository? chalaanRepository,
    PropertyRepository? propertyRepository,
  })  : _chalaanRepository = chalaanRepository ?? Get.find<ChalaanRepository>(),
        _propertyRepository = propertyRepository ?? Get.find<PropertyRepository>();

  final ChalaanRepository _chalaanRepository;
  final PropertyRepository _propertyRepository;
  SealController get _sealController => Get.find<SealController>();

  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  final Rx<ChalaanType> type = ChalaanType.chalaan.obs;
  final Rx<Property?> property = Rx<Property?>(null);
  final Rx<DateTime?> dueDate = Rx<DateTime?>(null);
  final RxBool sealImmediately = false.obs;
  final RxBool isSubmitting = false.obs;

  List<Property> get properties => _propertyRepository.getAll();

  void setType(ChalaanType value) {
    type.value = value;
    if (value == ChalaanType.chalaan) sealImmediately.value = false;
  }

  void setProperty(Property? value) => property.value = value;

  void setDueDate(DateTime value) => dueDate.value = value;

  void setSealImmediately(bool? value) => sealImmediately.value = value ?? false;

  String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Amount is required';
    final amount = double.tryParse(value.trim());
    if (amount == null || amount <= 0) return 'Enter a valid amount';
    return null;
  }

  String? validateDescription(String? value) {
    if (type.value == ChalaanType.fine && (value == null || value.trim().isEmpty)) {
      return 'A reason is required for a fine';
    }
    return null;
  }

  /// Validates and submits. Returns the created [Chalaan], or `null` if the
  /// form was invalid / no property was picked / no due date was picked.
  Future<Chalaan?> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return null;
    final selectedProperty = property.value;
    final selectedDueDate = dueDate.value;
    if (selectedProperty == null || selectedDueDate == null) return null;

    isSubmitting.value = true;
    try {
      final chalaan = await _chalaanRepository.create(
        type: type.value,
        propertyId: selectedProperty.id,
        amount: double.parse(amountController.text.trim()),
        dueDate: selectedDueDate,
        description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
      );

      if (type.value == ChalaanType.fine && sealImmediately.value) {
        await _sealController.sealProperty(
          propertyId: selectedProperty.id,
          propertyName: selectedProperty.name,
          tenantName: selectedProperty.tenantName,
          reason: descriptionController.text.trim(),
          relatedChalaanId: chalaan.id,
        );
      }

      return chalaan;
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    amountController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
