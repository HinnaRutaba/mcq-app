import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/tenant_payments_controller.dart';
import '../../core/utils/get_helpers.dart';
import '../../widgets/widgets.dart';
import 'widgets/chalaan_detail_sheet.dart';
import 'widgets/chalaan_tile.dart';
import 'widgets/payment_method_sheet.dart';

class TenantPaymentsScreen extends StatelessWidget {
  const TenantPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => TenantPaymentsController());

    return Scaffold(
      appBar: AppBar(title: const AppText.titleLarge('Payments')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            children: [
              AppSearchField(
                hint: 'Search chalaans, properties…',
                onChanged: controller.setQuery,
              ),
              const SizedBox(height: 12),
              Obx(
                () => AppChipTabs<TenantPaymentsFilter>(
                  items: TenantPaymentsFilter.values,
                  itemLabel: (f) => f.label,
                  selected: controller.filter.value,
                  onChanged: controller.setFilter,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Obx(() {
                  final chalaans = controller.filtered;
                  if (chalaans.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No chalaans found',
                      message: 'Try a different search or filter.',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => controller.reload(),
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: chalaans.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final chalaan = chalaans[index];
                        return ChalaanTile(
                          chalaan: chalaan,
                          onTap: () => ChalaanDetailSheet.show(
                            context,
                            chalaan,
                            onPay: () => PaymentMethodSheet.show(
                              context,
                              chalaan: chalaan,
                              onSettled: (_) => controller.reload(),
                            ),
                          ),
                          onPay: () => PaymentMethodSheet.show(
                            context,
                            chalaan: chalaan,
                            onSettled: (_) => controller.reload(),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
