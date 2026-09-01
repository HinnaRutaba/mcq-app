import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/api/fine_form_controller.dart';
import '../../../data/api/repositories/property_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/enforcement/field_evidence.dart';
import '../../../models/common/money.dart';
import '../../../models/property/property_summary.dart';
import '../../../widgets/widgets.dart';
import '../field/widgets/field_actions.dart';
import '../field/widgets/fine_result_view.dart';
import 'widgets/evidence_capture_card.dart';
import 'widgets/server_field_error.dart';

/// Imposing a fine.
///
/// A fine produces a payable challan with its own payment link, and the
/// person fined gets an SMS with that link — so the screen ends by telling
/// the officer the challan number and whether the link went out, which is
/// what lets them say "check your phone".
class FineFormScreen extends StatefulWidget {
  const FineFormScreen({
    super.key,
    required this.propertyId,
    this.property,
    this.target,
  });

  final int propertyId;
  final PropertySummary? property;

  /// Carried when the officer came from a field card. Its
  /// `needs_offender_details` is the **server's** answer to "is there
  /// anybody to bill", and it beats anything the handset works out.
  final ActionTarget? target;

  @override
  State<FineFormScreen> createState() => _FineFormScreenState();
}

class _FineFormScreenState extends State<FineFormScreen> {
  late Future<PropertySummary> _propertyFuture = widget.property != null
      ? Future.value(widget.property)
      : Get.find<PropertyApiRepository>().byId(widget.propertyId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: AppText.titleLarge(t('fines.impose'))),
      body: FutureBuilder<PropertySummary>(
        future: _propertyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            // The shape of the page, not a spinner in the middle of it.
            return const Padding(
              padding: EdgeInsets.all(18),
              child: AppSkeletonList(count: 3),
            );
          }
          if (!snapshot.hasData) {
            return Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
              child: AppBanner(
                tone: AppStatusTone.danger,
                icon: Icons.cloud_off_rounded,
                message: t('error.network'),
                action: AppButton(
                  label: t('common.retry'),
                  variant: AppButtonVariant.outline,
                  fullWidth: false,
                  height: 44,
                  onPressed: () => setState(() {
                    _propertyFuture = Get.find<PropertyApiRepository>()
                        .byId(widget.propertyId);
                  }),
                ),
              ),
            );
          }
          return _FineForm(property: snapshot.data!, target: widget.target);
        },
      ),
    );
  }
}

class _FineForm extends StatefulWidget {
  const _FineForm({required this.property, this.target});

  final PropertySummary property;
  final ActionTarget? target;

  @override
  State<_FineForm> createState() => _FineFormState();
}

class _FineFormState extends State<_FineForm> {
  late final String _tag = 'fine-${widget.property.id}';
  late final FineFormController _controller = Get.put(
    FineFormController.resolve(
      widget.property,
      needsOffenderOverride: widget.target?.needsOffenderDetails,
    ),
    tag: _tag,
  );

  @override
  void dispose() {
    Get.delete<FineFormController>(tag: _tag);
    super.dispose();
  }

  Future<void> _submit() async {
    final payer = _controller.needsOffenderDetails
        ? _controller.offenderName.value.trim()
        : widget.property.allottee.name;

    final confirmed = await AppConfirmDialog.ask(
      context,
      title: t('fines.confirmTitle'),
      body: t('fines.confirmBody', args: {
        'shop': widget.property.label,
        'payer': payer,
        'amount': Money(_controller.amount.value.trim()).withSymbol(),
      }),
      confirmLabel: t('fines.impose'),
      note: t('fines.legalProvisionHelp'),
    );
    if (!confirmed) return;
    await _controller.submit();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final outcome = _controller.outcome.value;
      if (outcome != null) {
        return FineResultView(
          outcome: outcome,
          shopLabel: widget.target?.describe ??
              '${widget.property.label} · ${widget.property.areaName}',
          onClose: () => Navigator.of(context).pop(true),
        );
      }

      return SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
              child: Row(
                children: [
                  const Icon(Icons.storefront_outlined, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: UserText.body(
                      '${widget.property.label} · ${widget.property.areaName}',
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            AppDropdown<String>(
              label: t('fines.type'),
              items: FieldWriteEnums.fineTypes,
              itemLabel: (value) => t('fineType.$value'),
              value: _controller.fineType.value.isEmpty
                  ? null
                  : _controller.fineType.value,
              onChanged: (value) => _controller.fineType.value = value ?? '',
            ),
            ServerFieldError(errors: _controller.fieldErrors, field: 'fine_type'),
            const SizedBox(height: 20),

            AppTextField(
              label: t('fines.amount'),
              hint: '4500.00',
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) => _controller.amount.value = value,
            ),
            ServerFieldError(errors: _controller.fieldErrors, field: 'fine_amount'),
            const SizedBox(height: 20),

            // Required, with a hint that explains why — not a placeholder.
            AppTextField(
              label: t('fines.legalProvision'),
              hint: t('fines.legalProvisionHint'),
              onChanged: (value) => _controller.legalProvision.value = value,
            ),
            const SizedBox(height: 6),
            AppText.caption(t('fines.legalProvisionHelp')),
            ServerFieldError(errors: _controller.fieldErrors, field: 'legal_provision'),
            const SizedBox(height: 24),

            if (_controller.needsOffenderDetails) ...[
              AppText.titleMedium(t('fines.offenderSection')),
              const SizedBox(height: 8),
              // The officer is told why the form is asking, or they will
              // think it is broken.
              AppBanner(
                tone: AppStatusTone.info,
                icon: Icons.info_outline_rounded,
                message: t('fines.offenderWhy'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: t('fines.offenderName'),
                onChanged: (value) => _controller.offenderName.value = value,
              ),
              ServerFieldError(errors: _controller.fieldErrors, field: 'offender_name'),
              const SizedBox(height: 20),
              AppTextField(
                label: t('fines.offenderCnic'),
                hint: '54400-1234567-1',
                onChanged: (value) => _controller.offenderCnic.value = value,
              ),
              const SizedBox(height: 6),
              AppText.caption(t('common.optional')),
              ServerFieldError(
                  errors: _controller.fieldErrors, field: 'offender_cnic'),
              const SizedBox(height: 20),
              AppTextField(
                label: t('fines.offenderMobile'),
                hint: '03009876543',
                keyboardType: TextInputType.phone,
                onChanged: (value) => _controller.offenderMobile.value = value,
              ),
              const SizedBox(height: 6),
              AppText.caption(t('fines.offenderMobileRequired')),
              Obx(() {
                final localError =
                    _controller.validateMobile(_controller.offenderMobile.value);
                if (localError == null ||
                    _controller.offenderMobile.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 6, 0, 0),
                  child: AppText.caption(t(localError), color: Colors.red),
                );
              }),
              ServerFieldError(errors: _controller.fieldErrors, field: 'offender_mobile_no'),
              const SizedBox(height: 24),
            ] else ...[
              AppBanner(
                tone: AppStatusTone.info,
                icon: Icons.person_outline_rounded,
                message: t('fines.billedToAllottee'),
              ),
              const SizedBox(height: 24),
            ],

            EvidenceCaptureCard(controller: _controller),
            const SizedBox(height: 28),

            AppButton(
              label: t('fines.impose'),
              icon: Icons.gavel_rounded,
              isLoading: _controller.isSubmitting.value,
              onPressed: _controller.isValid ? _submit : null,
            ),
          ],
        ),
      );
    });
  }
}
