import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../controllers/api/property_profile_controller.dart';
import '../../../core/utils/dialer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/property/property_summary.dart';
import '../../../widgets/widgets.dart';
import 'widgets/api_enum_badge.dart';
import 'widgets/challan_tile.dart';
import 'widgets/detail_row.dart';
import 'widgets/fine_tile.dart';

/// One unit in full — the richest single call, plus its two kinds of debt
/// kept apart.
class PropertyProfileScreen extends StatefulWidget {
  const PropertyProfileScreen({
    super.key,
    required this.propertyId,
    this.property,
  });

  final int propertyId;
  final PropertySummary? property;

  @override
  State<PropertyProfileScreen> createState() => _PropertyProfileScreenState();
}

class _PropertyProfileScreenState extends State<PropertyProfileScreen> {
  late final String _tag = 'property-${widget.propertyId}';
  late final PropertyProfileController _controller = Get.put(
    PropertyProfileController.resolve(widget.propertyId),
    tag: _tag,
  );

  @override
  void dispose() {
    Get.delete<PropertyProfileController>(tag: _tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: AppText.titleLarge(t('property.profile'))),
      body: Obx(() {
        final property = _controller.property.value ?? widget.property;

        if (property == null) {
          if (_controller.isLoading.value) {
            // The shape of the page, not a spinner in the middle of it.
            return const Padding(
              padding: EdgeInsets.all(18),
              child: AppSkeletonList(count: 3),
            );
          }
          return Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
            child: AppBanner(
              tone: AppStatusTone.danger,
              icon: Icons.cloud_off_rounded,
              message:
                  _controller.failure.value?.message ?? t('error.unexpected'),
              action: AppButton(
                label: t('common.retry'),
                variant: AppButtonVariant.outline,
                fullWidth: false,
                height: 44,
                onPressed: _controller.reload,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _controller.reload(refreshing: true),
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 40),
            children: [
              if (_controller.hasLiveStay) ...[
                AppBanner(
                  tone: AppStatusTone.danger,
                  icon: Icons.gavel_rounded,
                  message: t('cases.stayOrderWarning'),
                ),
                const SizedBox(height: 16),
              ],
              _identity(context, property),
              const SizedBox(height: 16),
              _balances(context),
              const SizedBox(height: 16),
              _actions(context, property),
              const SizedBox(height: 24),

              if (_controller.rentChallans.isNotEmpty) ...[
                AppText.titleMedium(t('property.challans')),
                const SizedBox(height: 12),
                for (final challan in _controller.rentChallans)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 10),
                    child: ChallanTile(challan: challan),
                  ),
                const SizedBox(height: 8),
              ],

              if (_controller.fineChallans.isNotEmpty ||
                  _controller.fines.isNotEmpty) ...[
                AppText.titleMedium(t('fines.title')),
                const SizedBox(height: 6),
                // A fine is a separate debt, not part of the rent: two
                // obligations, never one "amount due".
                AppText.caption(t('challan.separateDebt')),
                const SizedBox(height: 12),
                for (final challan in _controller.fineChallans)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 10),
                    child: ChallanTile(challan: challan),
                  ),
                for (final fine in _controller.fines)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 10),
                    child: FineTile(fine: fine),
                  ),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _identity(BuildContext context, PropertySummary property) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: AppText.headlineSmall(property.label)),
              ApiEnumBadge(property.category),
            ],
          ),
          const SizedBox(height: 4),
          AppText.caption(property.propertyCode),
          Divider(height: 24, color: Theme.of(context).dividerColor),
          DetailRow(label: t('property.area'), value: property.areaName),
          if ((property.marketName ?? '').isNotEmpty)
            DetailRow(label: t('property.market'), value: property.marketName),
          DetailRow(
            label: t('property.allottee'),
            valueWidget: UserText.body(
              property.allottee.exists
                  ? property.allottee.name
                  : t('property.noAllottee'),
              maxLines: 2,
            ),
          ),
          if (property.allottee.isCallable)
            DetailRow(
              label: t('property.mobile'),
              valueWidget: TextButton.icon(
                onPressed: () => Dialer.call(property.allottee.mobileNo),
                icon: const Icon(Icons.call_rounded, size: 18),
                label: AppText.label(property.allottee.mobileNo!),
              ),
            ),
          if ((property.allotment.allotmentNo ?? '').isNotEmpty)
            DetailRow(
              label: t('property.allotment'),
              value: property.allotment.allotmentNo,
            ),
          if (property.monthlyRent != null)
            DetailRow(
              label: t('property.monthlyRent'),
              valueWidget: MoneyText.small(
                property.monthlyRent!,
                withSymbol: true,
              ),
            ),
          if (property.isSealed)
            DetailRow(
              label: t('seal.title'),
              valueWidget: AppStatusBadge(
                label: t('seal.sealed'),
                tone: AppStatusTone.danger,
              ),
            ),
        ],
      ),
    );
  }

  Widget _balances(BuildContext context) {
    final balances = _controller.profile.value?.balances ?? const {};
    if (balances.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium(t('property.balance')),
          const SizedBox(height: 4),
          // Every figure the server put on the profile, under its own key.
          // None of them is combined with another here.
          for (final entry in balances.entries)
            DetailRow(
              label: entry.key.replaceAll('_', ' '),
              valueWidget: MoneyText.small(entry.value, withSymbol: true),
            ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, PropertySummary property) {
    final buttons = <Widget>[
      if (_controller.canImposeFine)
        AppButton(
          label: t('fines.impose'),
          icon: Icons.gavel_rounded,
          variant: AppButtonVariant.secondary,
          onPressed: () => context.push(
            AppRoutes.imposeFinePath(property.id),
            extra: property,
          ),
        ),
      if (_controller.canRecordInspection)
        AppButton(
          label: t('property.recordInspection'),
          icon: Icons.fact_check_outlined,
          variant: AppButtonVariant.outline,
          onPressed: () => context.push(
            AppRoutes.recordInspectionPath(property.id),
          ),
        ),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (final button in buttons)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 10),
            child: button,
          ),
      ],
    );
  }
}
