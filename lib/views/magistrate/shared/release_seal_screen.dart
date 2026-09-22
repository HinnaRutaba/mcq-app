import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_radius.dart';
import '../../../controllers/defaulters_controller.dart';
import '../../../controllers/release_seal_controller.dart';
import '../../../controllers/seals_controller.dart';
import '../../../core/capture/photo_capture.dart';
import '../../../core/utils/form_scroll.dart';
import '../../../models/field_seal.dart';
import '../../../widgets/widgets.dart';
import 'widgets/evidence_tile.dart';
import 'widgets/seal_released_sheet.dart';
import 'widgets/seal_tile.dart';
import 'widgets/still_needed_note.dart';

/// Taking a seal off a shop: which seal, and why.
///
/// A release hangs off the seal rather than the unit, and a shop's profile
/// carries a seal number but no id to post against — so this form reads the
/// officer's own sealed list and keeps the rows naming the unit. Where MCQ has
/// not cleared the seal, the form asks for the justification the server
/// insists on before it will open a shop that still owes money.
class ReleaseSealScreen extends StatefulWidget {
  const ReleaseSealScreen({super.key, required this.propertyId, this.sealId});

  final int propertyId;

  /// A seal to start on, when the caller knows which.
  final int? sealId;

  /// Opens the form, and tells the caller what came back.
  ///
  /// A release changes the shop's own record, the sealed list and the
  /// defaulter rows that carry the seal badge, so all three are put right.
  /// Null back means the officer walked away, which costs nothing.
  static Future<FieldSeal?> open(
    BuildContext context, {
    required int propertyId,
    int? sealId,
    Future<void> Function()? onReleased,
  }) async {
    final FieldSeal? seal = await context.push<FieldSeal>(
      AppRoutes.releaseSealPath(propertyId: propertyId, sealId: sealId),
    );
    if (seal == null) return null;
    await SealsController.reloadIfOpened();
    await DefaultersController.reloadIfOpened();
    if (!context.mounted) return seal;
    await onReleased?.call();
    return seal;
  }

  @override
  State<ReleaseSealScreen> createState() => _ReleaseSealScreenState();
}

class _ReleaseSealScreenState extends State<ReleaseSealScreen> {
  late final ReleaseSealController controller = Get.put(
    ReleaseSealController(
      propertyId: widget.propertyId,
      sealId: widget.sealId,
    ),
  );

  @override
  void dispose() {
    Get.delete<ReleaseSealController>();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final ReleaseOutcome outcome = await controller.release();
    if (!mounted) return;

    if (outcome == ReleaseOutcome.success) {
      final FieldSeal? seal = controller.released.value;
      if (seal == null) return;
      await SealReleasedSheet.show(context, seal: seal);
      if (mounted) Navigator.of(context).pop(seal);
      return;
    }

    // The server's own sentence is in the submit bar, under the thumb that
    // just pressed the button. Anything it blamed a field for is under that
    // field, so the form goes to it.
    scrollToFirstError(controller.formKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          AppHeroHeader(
            title: 'Unseal the shop',
            subtitle: 'Lets them trade again, with the reason on record',
            leading: AppCircleIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => context.pop(),
            ),
          ),
          Expanded(
            child: Form(
              key: controller.formKey,
              // A column, not a list: a lazy list only builds the visible
              // sections, so `validate()` would paint messages on half the
              // form and pass the rest.
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _SealSection(controller: controller),
                    const SizedBox(height: 20),
                    _ReasonSection(controller: controller),
                    const SizedBox(height: 20),
                    _WitnessSection(controller: controller),
                  ],
                ),
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

/// Which seal comes off.
class _SealSection extends StatelessWidget {
  const _SealSection({required this.controller});

  final ReleaseSealController controller;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppText.titleMedium('Which seal'),
        const SizedBox(height: 3),
        AppText.caption(
          'The seal on this unit, as MCQ holds it.',
          color: muted,
          maxLines: 2,
        ),
        const SizedBox(height: 10),
        Obx(() {
          if (controller.isLoadingSeals.value && controller.seals.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final String? error = controller.sealsError.value;
          if (error != null && controller.seals.isEmpty) {
            return AppErrorRetry(
              title: 'Could not read this shop’s seals',
              message: error,
              onRetry: controller.loadSeals,
            );
          }

          final List<FieldSeal> rows = controller.seals.toList();
          if (rows.isEmpty) {
            return const AppCard(
              padding: EdgeInsets.fromLTRB(12, 16, 12, 16),
              child: AppDetailRow(
                icon: Icons.lock_open_outlined,
                // Nothing to take off. The shop may have been released
                // already, or sealed by an officer whose list this is not.
                value:
                    'MCQ holds no seal on this shop against your name. '
                    'Nothing to release.',
                maxLines: 3,
              ),
            );
          }

          final int? chosen = controller.selectedSealId.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final FieldSeal seal in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Opacity(
                    // Dimmed rather than hidden: a seal already off is worth
                    // seeing, and is not the row to press.
                    opacity: seal.isSealed ? 1 : 0.55,
                    child: SealTile(
                      seal: seal,
                      readyToRelease: controller.isReady(seal),
                      onTap: seal.id == null
                          ? null
                          : () => controller.chooseSeal(seal.id!),
                    ),
                  ),
                ),
              if (chosen != null && controller.needsOverride) ...<Widget>[
                const SizedBox(height: 2),
                const AppAlert(
                  tone: AppTone.warning,
                  icon: Icons.info_outline_rounded,
                  message:
                      'MCQ has not cleared this seal — the money behind it is '
                      'not settled. You can still open the shop, but you must '
                      'say why.',
                ),
              ],
            ],
          );
        }),
      ],
    );
  }
}

/// Why it is coming off, the day, and — where MCQ has not cleared it — the
/// justification for opening a shop that still owes money.
class _ReasonSection extends StatelessWidget {
  const _ReasonSection({required this.controller});

  final ReleaseSealController controller;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final DateTime today = DateUtils.dateOnly(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppText.titleMedium('Why it is coming off'),
        const SizedBox(height: 3),
        AppText.caption(
          'Kept as the record of why a shop was opened again, so name the '
          'receipt or the order behind it.',
          color: muted,
          maxLines: 2,
        ),
        const SizedBox(height: 10),
        AppTextField(
          controller: controller.reasonController,
          hint: 'e.g. Fine paid in full, receipt MCQ-RC-2627-00123.',
          maxLines: 3,
          validator: controller.validateReason,
          onChanged: (String _) => controller.markEdited(),
        ),
        Obx(() {
          // Read in the builder so the block appears the moment a seal MCQ has
          // not cleared is the one chosen.
          if (!controller.needsOverride) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: AppTextField(
              controller: controller.overrideController,
              label: 'Why open it before MCQ has cleared it',
              hint:
                  'e.g. Deputy Commissioner’s order of 12 Sep 2026 to reopen '
                  'pending appeal.',
              maxLines: 3,
              validator: controller.validateOverride,
              onChanged: (String _) => controller.markEdited(),
            ),
          );
        }),
        const SizedBox(height: 16),
        Obx(
          () => AppDateField(
            label: 'The day the seal came off',
            hint: 'Today',
            value: controller.unsealedOn.value,
            // Never a day that has not happened; a seal cut last week can
            // still be written up today.
            firstDate: today.subtract(const Duration(days: 30)),
            lastDate: today,
            onChanged: controller.setUnsealedOn,
          ),
        ),
      ],
    );
  }
}

/// Who saw the shutter go up. Optional, unlike on the seal itself.
class _WitnessSection extends StatelessWidget {
  const _WitnessSection({required this.controller});

  final ReleaseSealController controller;

  Future<void> _photo(BuildContext context) async {
    final PhotoOutcome outcome = await controller.attachPhoto();
    if (!context.mounted) return;
    if (outcome == PhotoOutcome.needsSettings) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText.body(
            'Allow the camera in Settings to photograph the shutter.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppText.titleMedium('Who saw it'),
        const SizedBox(height: 3),
        AppText.caption(
          'Optional, and worth having: an opened shop is questioned as often '
          'as a shut one.',
          color: muted,
          maxLines: 2,
        ),
        const SizedBox(height: 10),
        Obx(() {
          controller.revision.value;
          return AppTextField(
            controller: controller.witnessController,
            label: 'The witness',
            hint: 'e.g. Abdul Samad, the shopkeeper next door',
            optional: true,
            validator: controller.validateWitness,
            onChanged: (String _) => controller.markEdited(),
          );
        }),
        const SizedBox(height: 16),
        Obx(
          () => Row(
            children: <Widget>[
              Expanded(
                child: EvidenceTile(
                  icon: Icons.photo_camera_outlined,
                  label: 'Shutter',
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
              const Spacer(flex: 2),
            ],
          ),
        ),
        Obx(() {
          final String? path = controller.photoLocalPath.value;
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
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          );
        }),
      ],
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
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.controller, required this.onSubmit});

  final ReleaseSealController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

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
            final List<String> missing = controller.missing;
            final String? error = controller.errorMessage.value;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (missing.isNotEmpty) ...<Widget>[
                  StillNeededNote(missing: missing),
                  const SizedBox(height: 10),
                ],
                if (error != null) ...<Widget>[
                  AppAlert(message: error, compact: true),
                  const SizedBox(height: 10),
                ],
                AppButton(
                  // Nothing was written if the send failed, and the same
                  // request goes out again — see `ReleaseSealController`.
                  label: error == null ? 'Unseal the shop' : 'Send it again',
                  icon: Icons.lock_open_rounded,
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
