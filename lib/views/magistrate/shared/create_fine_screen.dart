import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../config/theme/app_colors.dart';
import '../../../controllers/fine_controller.dart';
import '../../../core/capture/location_capture.dart';
import '../../../core/capture/photo_capture.dart';
import '../../../models/unit_card.dart';
import '../../../widgets/widgets.dart';
import 'widgets/evidence_tile.dart';
import 'widgets/fine_imposed_sheet.dart';
import 'widgets/signature_sheet.dart';
import '../../../config/theme/app_radius.dart';

/// Imposing a fine.
///
/// The form is four numbered blocks on one scroll — the shop, the offence, who
/// pays, the evidence — under a bar that stays on screen carrying the amount
/// and the button. It is one pass, not a wizard: an officer standing in front
/// of a shopkeeper should be able to see everything the fine will say without
/// tapping "next", and should never have to scroll to find out why the button
/// will not press.
///
/// The three pieces of evidence sit side by side rather than stacked, because
/// stacked they pushed the submit button a screen and a half below the fold.
///
/// One call posts the lot: the receivable, the challan, the payment link and
/// the text message to the person fined. What comes back is shown in
/// [FineImposedSheet], including the case where the amount exceeded the
/// officer's own field limit and a senior has to approve it — a shopkeeper
/// should never be told a fine is final when it is not.
class CreateFineScreen extends StatefulWidget {
  const CreateFineScreen({super.key, this.unit, this.propertyId});

  /// The shop, when the officer came from its profile.
  final UnitCard? unit;

  /// Its id, when only that was carried on the route.
  final int? propertyId;

  @override
  State<CreateFineScreen> createState() => _CreateFineScreenState();
}

class _CreateFineScreenState extends State<CreateFineScreen> {
  late final FineController controller = Get.put(
    FineController(unit: widget.unit, propertyId: widget.propertyId),
  );

  @override
  void dispose() {
    Get.delete<FineController>();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final outcome = await controller.impose();
    if (!mounted) return;

    if (outcome == ImposeOutcome.success) {
      final fine = controller.imposed.value;
      if (fine == null) return;
      await FineImposedSheet.show(context, fine: fine);
      if (mounted) Navigator.of(context).pop(fine);
    }
    // A refusal is already on the form: the banner carries the server's own
    // sentence and the per-field messages are back under their fields.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Obx(() {
            final unit = controller.selectedUnit.value;
            return AppHeroHeader(
              title: 'Impose a fine',
              subtitle: unit == null
                  ? 'Choose the shop first'
                  : _unitLine(unit),
              leading: AppCircleIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            );
          }),
          Expanded(
            child: Form(
              key: controller.formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                children: <Widget>[
                  Obx(() {
                    final message = controller.errorMessage.value;
                    if (message == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      // The server's own sentence, verbatim. It knows why it
                      // refused and the handset does not.
                      child: AppAlert(message: message),
                    );
                  }),
                  _ShopSection(controller: controller),
                  const SizedBox(height: 20),
                  _OffenceSection(controller: controller),
                  const SizedBox(height: 20),
                  _PayerSection(controller: controller),
                  const SizedBox(height: 20),
                  _EvidenceSection(controller: controller),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _SubmitBar(
        controller: controller,
        onSubmit: _submit,
      ),
    );
  }
}

String _unitLine(UnitCard unit) {
  final parts = <String>[
    if (unit.shopNo != null) unit.shopNo!,
    if (unit.marketName != null) unit.marketName!,
  ];
  if (parts.isEmpty) return unit.propertyCode ?? 'Selected shop';
  return parts.join(' · ');
}

// ---------------------------------------------------------------------------
// Sections
// ---------------------------------------------------------------------------

/// A numbered block. The number is the point: it tells the officer how much
/// form is left, which a flat run of labels never does.
class _Section extends StatelessWidget {
  const _Section({
    required this.step,
    required this.title,
    required this.child,
    this.note,
  });

  final String step;
  final String title;
  final String? note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              height: 24,
              width: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: AppText.caption(
                step,
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: AppText.titleLarge(title)),
          ],
        ),
        if (note != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 34),
            child: AppText.body(note!, color: muted),
          ),
        ],
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _ShopSection extends StatelessWidget {
  const _ShopSection({required this.controller});

  final FineController controller;

  @override
  Widget build(BuildContext context) {
    return _Section(
      step: '1',
      title: 'The shop',
      child: Obx(() {
        final unit = controller.selectedUnit.value;
        if (unit != null)
          return _ChosenShop(unit: unit, controller: controller);
        if (controller.propertyId != null) {
          return const AppCard(
            child: AppText.body('This fine is against the unit you opened.'),
          );
        }
        return _ShopSearch(controller: controller);
      }),
    );
  }
}

class _ChosenShop extends StatelessWidget {
  const _ChosenShop({required this.unit, required this.controller});

  final UnitCard unit;
  final FineController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return AppCard(
      child: Row(
        children: <Widget>[
          Icon(
            Icons.storefront_rounded,
            color: theme.colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppText.titleMedium(_unitLine(unit)),
                const SizedBox(height: 2),
                AppText.caption(
                  // "Vacant" is not the same fact as "owes nothing", so the
                  // two never share a line.
                  unit.isVacant
                      ? 'Vacant — nobody holds this unit'
                      : (unit.allotteeName ?? 'Held, allottee not named'),
                  color: muted,
                ),
              ],
            ),
          ),
          if (controller.propertyId == null)
            TextButton(
              onPressed: controller.clearUnit,
              child: const AppText.label('Change'),
            ),
        ],
      ),
    );
  }
}

class _ShopSearch extends StatelessWidget {
  const _ShopSearch({required this.controller});

  final FineController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppSearchField(
          controller: controller.searchController,
          hint: 'Shop number, code, allottee or CNIC',
          onChanged: controller.search,
        ),
        const SizedBox(height: 10),
        Obx(() {
          if (controller.isSearching.value) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: AppText.caption('Searching…'),
            );
          }
          final results = controller.searchResults;
          if (results.isEmpty) return const SizedBox.shrink();
          return Column(
            children: <Widget>[
              for (final UnitCard unit in results)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    onTap: () => controller.chooseUnit(unit),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(child: AppText.body(_unitLine(unit))),
                        if (unit.isSealed)
                          const AppStatusBadge(
                            label: 'Sealed',
                            tone: AppTone.warning,
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}

class _OffenceSection extends StatelessWidget {
  const _OffenceSection({required this.controller});

  final FineController controller;

  @override
  Widget build(BuildContext context) {
    return _Section(
      step: '2',
      title: 'The offence',
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Obx(
              () => AppDropdown<FineType>(
                label: 'What happened',
                hint: 'Choose an offence',
                items: FineType.all,
                itemLabel: (FineType type) => type.label,
                value: controller.fineType.value,
                validator: controller.validateFineType,
                onChanged: (FineType? type) {
                  controller.fineType.value = type;
                  controller.markEdited();
                },
              ),
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Fine amount',
              hint: 'e.g. 4500',
              controller: controller.amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              // Digits and one dot. The figure is never turned into a number
              // on the handset — it is sent as typed.
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              prefixIcon: Icons.payments_outlined,
              validator: controller.validateAmount,
              onChanged: (_) => controller.markEdited(),
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Provision of law',
              hint: 'e.g. Section 96, Balochistan LG Act 2010',
              controller: controller.provisionController,
              validator: controller.validateProvision,
              onChanged: (_) => controller.markEdited(),
            ),
            const SizedBox(height: 18),
            Obx(
              () => AppDateField(
                label: 'When it happened',
                value: controller.imposedOn.value,
                // A past date is accepted; a future one is refused by the
                // server, so the picker never offers one.
                lastDate: DateTime.now(),
                onChanged: (DateTime picked) {
                  controller.imposedOn.value = picked;
                  controller.markEdited();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayerSection extends StatelessWidget {
  const _PayerSection({required this.controller});

  final FineController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // The server's own answer, read and not recomputed: whether there is
      // anybody on the register to bill is its judgement, not the handset's.
      final needsOffender = controller.needsOffenderDetails;
      final unit = controller.selectedUnit.value;

      return _Section(
        step: '3',
        title: 'Who pays',
        note: needsOffender
            ? 'Nobody on the register holds this unit, so the fine has to name '
                  'the person. All three are required together.'
            : null,
        child: needsOffender
            ? AppCard(
                child: Column(
                  children: <Widget>[
                    AppTextField(
                      label: "Offender's name",
                      controller: controller.offenderNameController,
                      validator: controller.validateOffenderName,
                      onChanged: (_) => controller.markEdited(),
                    ),
                    const SizedBox(height: 18),
                    AppTextField(
                      label: "Father's name",
                      controller: controller.offenderFatherController,
                      validator: controller.validateOffenderFather,
                      onChanged: (_) => controller.markEdited(),
                    ),
                    const SizedBox(height: 18),
                    AppTextField(
                      label: 'Mobile number',
                      controller: controller.offenderMobileController,
                      keyboardType: TextInputType.phone,
                      validator: controller.validateOffenderMobile,
                      onChanged: (_) => controller.markEdited(),
                    ),
                  ],
                ),
              )
            : AppAlert(
                tone: AppTone.info,
                icon: Icons.person_outline_rounded,
                message: unit?.allotteeName == null
                    ? 'The allottee holding this unit will be billed and sent '
                          'the payment link.'
                    : '${unit!.allotteeName} will be billed and sent the '
                          'payment link.',
              ),
      );
    });
  }
}

class _EvidenceSection extends StatelessWidget {
  const _EvidenceSection({required this.controller});

  final FineController controller;

  Future<void> _photo(BuildContext context) async {
    final outcome = await controller.attachPhoto();
    if (!context.mounted) return;
    if (outcome == PhotoOutcome.needsSettings) {
      _say(context, 'Allow the camera in Settings to attach a photograph.');
    }
  }

  Future<void> _location(BuildContext context) async {
    final outcome = await controller.attachLocation();
    if (!context.mounted) return;
    switch (outcome) {
      case LocationOutcome.fixed:
        break;
      case LocationOutcome.serviceOff:
        _say(context, 'Turn location on to record where the fine was issued.');
      case LocationOutcome.needsSettings:
        _say(context, 'Allow location in Settings to record where you stood.');
      case LocationOutcome.refused:
      case LocationOutcome.unavailable:
        _say(
          context,
          'No fix here. The fine can still be recorded without one.',
        );
    }
  }

  Future<void> _signature(BuildContext context) async {
    final path = await SignatureSheet.show(
      context,
      witnessName: controller.witnessController.text,
    );
    if (path != null) await controller.attachSignature(path);
  }

  static void _say(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: AppText.body(message)));
  }

  @override
  Widget build(BuildContext context) {
    return _Section(
      step: '4',
      title: 'The evidence',
      note:
          'None of this is required, and all of it makes the fine harder to '
          'argue with.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Obx(
            () => IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: EvidenceTile(
                      icon: Icons.photo_camera_outlined,
                      label: 'Photo',
                      busy: controller.isUploadingPhoto.value,
                      state: _photoState,
                      detail: _photoDetail,
                      onTap: controller.photoUploadedPath.value != null
                          ? controller.removePhoto
                          : (controller.photoLocalPath.value != null
                                ? controller.retryPhotoUpload
                                : () => _photo(context)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: EvidenceTile(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      busy: controller.isFixingLocation.value,
                      state: _locationState,
                      detail: _locationDetail,
                      onTap: () => _location(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: EvidenceTile(
                      icon: Icons.draw_outlined,
                      label: 'Signature',
                      state: _signatureState,
                      onTap: controller.signatureLocalPath.value == null
                          ? () => _signature(context)
                          : controller.removeSignature,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Obx(() {
            final path = controller.photoLocalPath.value;
            if (path == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Image.file(
                  File(path),
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  // A thumbnail that will not decode must not take the form
                  // down with it.
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            );
          }),
          const SizedBox(height: 18),
          AppTextField(
            label: 'Witness name',
            hint: 'Optional',
            controller: controller.witnessController,
            onChanged: (_) => controller.markEdited(),
          ),
          const SizedBox(height: 18),
          AppTextField(
            label: 'Remarks',
            hint: 'Optional',
            controller: controller.remarksController,
            maxLines: 4,
            validator: controller.validateRemarks,
            onChanged: (_) => controller.markEdited(),
          ),
        ],
      ),
    );
  }

  EvidenceState get _photoState {
    if (controller.photoUploadedPath.value != null) {
      return EvidenceState.attached;
    }
    if (controller.photoLocalPath.value != null) return EvidenceState.pending;
    return EvidenceState.empty;
  }

  String? get _photoDetail {
    if (controller.isUploadingPhoto.value) return 'Sending';
    if (controller.photoUploadedPath.value != null) return 'Attached';
    if (controller.photoLocalPath.value != null) return 'Retry';
    return null;
  }

  EvidenceState get _locationState {
    if (controller.locationFix.value != null) return EvidenceState.attached;
    return switch (controller.locationOutcome.value) {
      LocationOutcome.refused ||
      LocationOutcome.needsSettings ||
      LocationOutcome.serviceOff => EvidenceState.unavailable,
      _ => EvidenceState.empty,
    };
  }

  String? get _locationDetail {
    final fix = controller.locationFix.value;
    // The accuracy is the evidence. "Fixed" alone could mean 800 metres, which
    // does not put anybody in front of a shop.
    if (fix != null) return '${fix.accuracyM.round()} m';
    return null;
  }

  EvidenceState get _signatureState {
    if (controller.signatureUploadedPath.value != null) {
      return EvidenceState.attached;
    }
    if (controller.signatureLocalPath.value != null) {
      return EvidenceState.pending;
    }
    return EvidenceState.empty;
  }
}

/// The bar that stays on screen: the amount as typed, what is still missing,
/// and the button.
class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.controller, required this.onSubmit});

  final FineController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Obx(() {
            // Re-read the text controllers whenever anything was edited.
            controller.revision.value;
            final amount = controller.amountController.text.trim();
            final missing = controller.missing;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          AppText.caption('Fine amount', color: muted),
                          const SizedBox(height: 2),
                          // Printed exactly as typed. Never parsed, never
                          // rounded, never added to anything.
                          AppText.titleLarge(
                            amount.isEmpty ? '—' : 'Rs $amount',
                          ),
                        ],
                      ),
                    ),
                    if (missing.isNotEmpty)
                      Flexible(
                        child: AppText.caption(
                          'Still needed: ${missing.take(2).join(', ')}'
                          '${missing.length > 2 ? '…' : ''}',
                          color: muted,
                          textAlign: TextAlign.end,
                          maxLines: 2,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Impose a fine',
                  icon: Icons.gavel_rounded,
                  isLoading: controller.isSubmitting.value,
                  onPressed: missing.isEmpty ? onSubmit : null,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
