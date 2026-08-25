import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/repositories/chalaan_repository.dart';
import '../models/chalaan.dart';
import '../models/payment_method.dart';

/// Drives the tenant's payment-method bottom sheet: pick a method, then
/// either simulate an instant online payment or submit a manual bank
/// transfer reference for verification.
class PaymentController extends GetxController {
  PaymentController({ChalaanRepository? chalaanRepository})
      : _chalaanRepository = chalaanRepository ?? Get.find<ChalaanRepository>();

  final ChalaanRepository _chalaanRepository;

  final Rx<PaymentMethod?> selectedMethod = Rx<PaymentMethod?>(null);
  final RxBool isProcessing = false.obs;
  final TextEditingController referenceController = TextEditingController();

  void selectMethod(PaymentMethod method) => selectedMethod.value = method;

  Future<Chalaan?> payOnline(String chalaanId) async {
    final method = selectedMethod.value;
    if (method == null || !method.isInstant) return null;

    isProcessing.value = true;
    try {
      return await _chalaanRepository.payOnline(chalaanId, method);
    } finally {
      isProcessing.value = false;
    }
  }

  Future<Chalaan?> submitManualPayment(String chalaanId) async {
    final reference = referenceController.text.trim();
    if (reference.isEmpty) return null;

    isProcessing.value = true;
    try {
      return await _chalaanRepository.submitManualPayment(chalaanId, reference);
    } finally {
      isProcessing.value = false;
    }
  }

  void reset() {
    selectedMethod.value = null;
    referenceController.clear();
  }

  @override
  void onClose() {
    referenceController.dispose();
    super.onClose();
  }
}
