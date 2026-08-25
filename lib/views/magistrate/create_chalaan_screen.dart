import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/chalaan_form_controller.dart';
import '../../controllers/collections_controller.dart';
import '../../controllers/magistrate_home_controller.dart';
import '../../models/chalaan.dart';
import '../../models/property.dart';
import '../../widgets/widgets.dart';

/// Pushed from the Magistrate shell's center FAB: issue a new chalaan or
/// fine, with an option to seal the shop immediately for a fine.
class CreateChalaanScreen extends StatelessWidget {
  const CreateChalaanScreen({super.key});

  void _refreshRelatedScreens() {
    if (Get.isRegistered<MagistrateHomeController>()) {
      Get.find<MagistrateHomeController>().reload();
    }
    if (Get.isRegistered<CollectionsController>()) {
      Get.find<CollectionsController>().reload();
    }
  }

  Future<void> _submit(BuildContext context, ChalaanFormController controller) async {
    final chalaan = await controller.submit();
    if (!context.mounted) return;

    if (chalaan == null) {
      if (controller.property.value == null || controller.dueDate.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a property and a due date')),
        );
      }
      return;
    }

    _refreshRelatedScreens();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${chalaan.type.label} ${chalaan.id} created')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    // A fresh form every time this screen opens.
    Get.delete<ChalaanFormController>();
    final controller = Get.put(ChalaanFormController());

    return Scaffold(
      appBar: AppBar(title: const AppText.titleLarge('Create Chalaan/Fine')),
      body: SafeArea(
        top: false,
        child: Form(
          key: controller.formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Obx(
                () => AppChipTabs<ChalaanType>(
                  items: ChalaanType.values,
                  itemLabel: (t) => t.label,
                  selected: controller.type.value,
                  onChanged: controller.setType,
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => AppDropdown<Property>(
                  label: 'Property',
                  hint: 'Select a shop/unit',
                  items: controller.properties,
                  itemLabel: (p) => '${p.name} — ${p.tenantName}',
                  value: controller.property.value,
                  onChanged: controller.setProperty,
                  prefixIcon: Icons.storefront_outlined,
                ),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: 'Amount',
                hint: 'e.g. 15000',
                controller: controller.amountController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.currency_rupee_rounded,
                validator: controller.validateAmount,
              ),
              const SizedBox(height: 20),
              Obx(
                () => AppDateField(
                  label: 'Due Date',
                  value: controller.dueDate.value,
                  onChanged: controller.setDueDate,
                  firstDate: DateTime.now(),
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => AppTextField(
                  label: controller.type.value == ChalaanType.fine ? 'Reason' : 'Description (optional)',
                  hint: controller.type.value == ChalaanType.fine
                      ? 'e.g. Unauthorized encroachment'
                      : 'e.g. Monthly rent — September',
                  controller: controller.descriptionController,
                  maxLines: 3,
                  validator: controller.validateDescription,
                ),
              ),
              Obx(() {
                if (controller.type.value != ChalaanType.fine) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: AppCheckbox(
                    value: controller.sealImmediately.value,
                    onChanged: controller.setSealImmediately,
                    label: 'Seal shop immediately',
                  ),
                );
              }),
              const SizedBox(height: 28),
              Obx(
                () => AppButton(
                  label: 'Create',
                  isLoading: controller.isSubmitting.value,
                  onPressed: () => _submit(context, controller),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
