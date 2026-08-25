import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/payment_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/get_helpers.dart';
import '../../../models/chalaan.dart';
import '../../../models/payment_method.dart';
import '../../../widgets/widgets.dart';

/// Bottom sheet for settling a chalaan: pick a method, then either a
/// simulated instant payment (Bank/Easypaisa/JazzCash) or a manual bank
/// transfer reference submitted for verification.
class PaymentMethodSheet extends StatefulWidget {
  const PaymentMethodSheet({super.key, required this.chalaan, required this.onSettled});

  final Chalaan chalaan;
  final ValueChanged<Chalaan> onSettled;

  static Future<void> show(
    BuildContext context, {
    required Chalaan chalaan,
    required ValueChanged<Chalaan> onSettled,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentMethodSheet(chalaan: chalaan, onSettled: onSettled),
    );
  }

  @override
  State<PaymentMethodSheet> createState() => _PaymentMethodSheetState();
}

class _PaymentMethodSheetState extends State<PaymentMethodSheet> {
  late final PaymentController controller = getOrPut(() => PaymentController());

  @override
  void initState() {
    super.initState();
    controller.reset();
  }

  Future<void> _confirmOnline() async {
    final result = await controller.payOnline(widget.chalaan.id);
    if (result != null && mounted) {
      Navigator.pop(context);
      widget.onSettled(result);
    }
  }

  Future<void> _submitManual() async {
    final result = await controller.submitManualPayment(widget.chalaan.id);
    if (result != null && mounted) {
      Navigator.pop(context);
      widget.onSettled(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Obx(() {
            final method = controller.selectedMethod.value;
            final isProcessing = controller.isProcessing.value;
            final isManual = method == PaymentMethod.manual;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.headlineSmall('Pay ${Formatters.currency(widget.chalaan.amount)}'),
                const SizedBox(height: 4),
                AppText.body(widget.chalaan.propertyName),
                const SizedBox(height: 20),
                for (final m in PaymentMethod.values.where((m) => m != PaymentMethod.cash))
                  _MethodOption(
                    method: m,
                    selected: method == m,
                    onTap: () => controller.selectMethod(m),
                  ),
                if (isManual) ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Bank transaction reference number',
                    hint: 'e.g. TXN-88213374',
                    controller: controller.referenceController,
                    prefixIcon: Icons.numbers_rounded,
                  ),
                  const SizedBox(height: 8),
                  AppText.caption(
                    'We\'ll mark this chalaan as pending until a magistrate verifies the '
                    'transfer against bank records.',
                  ),
                ],
                const SizedBox(height: 24),
                AppButton(
                  label: isManual ? 'Submit for Verification' : 'Confirm Payment',
                  isLoading: isProcessing,
                  onPressed: method == null || isProcessing
                      ? null
                      : (isManual ? _submitManual : _confirmOnline),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _MethodOption extends StatelessWidget {
  const _MethodOption({required this.method, required this.selected, required this.onTap});

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = selected ? scheme.primary : Theme.of(context).dividerColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
            color: selected ? scheme.primary.withValues(alpha: 0.06) : null,
          ),
          child: Row(
            children: [
              Icon(method.icon, color: selected ? scheme.primary : null),
              const SizedBox(width: 12),
              Expanded(child: AppText(method.label, variant: AppTextVariant.titleSmall)),
              Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: selected ? scheme.primary : null,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
