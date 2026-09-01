import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../controllers/api/field_write_controller.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/widgets.dart';

/// The evidence block every field write shares: a photograph, a GPS fix,
/// the date it happened, a witness — with their signature — and remarks.
///
/// The thumbnail matters. A photograph of a thumb is worse than no
/// photograph, and nobody finds out until somebody opens the file months
/// later — so the officer sees what they captured before they submit.
///
/// Both images upload **first**, separately, and the action then carries
/// their paths. On a weak signal that means a retry re-sends a few hundred
/// bytes rather than two megabytes, and a failed action never loses the
/// evidence or asks a witness to sign twice.
class EvidenceCaptureCard extends StatelessWidget {
  const EvidenceCaptureCard({
    super.key,
    required this.controller,
    this.showWitness = true,
    this.showRemarks = true,
  });

  final FieldWriteController controller;
  final bool showWitness;
  final bool showRemarks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.titleMedium(t('action.photo')),
        const SizedBox(height: 4),
        AppText.caption(t('action.photoHelp')),
        const SizedBox(height: 12),
        Obx(() => _photoBlock(context)),
        const SizedBox(height: 20),

        AppText.titleMedium(t('action.location')),
        const SizedBox(height: 8),
        Obx(() => _locationBlock(context)),
        const SizedBox(height: 20),

        Obx(
          () => AppDateField(
            label: t('action.date'),
            value: controller.actionDate.value,
            // A past date is accepted; a future one is refused by the
            // server, so it is not offered here either.
            lastDate: DateTime.now(),
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
            onChanged: (picked) => controller.actionDate.value = picked,
          ),
        ),
        const SizedBox(height: 4),
        AppText.caption(t('action.dateHelp')),

        if (showWitness) ...[
          const SizedBox(height: 20),
          AppTextField(
            label: t('action.witness'),
            hint: t('common.optional'),
            onChanged: (value) => controller.witnessName.value = value,
          ),
          const SizedBox(height: 12),
          Obx(() => _signatureBlock(context)),
        ],

        if (showRemarks) ...[
          const SizedBox(height: 20),
          AppTextField(
            label: t('common.remarks'),
            hint: t('common.optional'),
            maxLines: 4,
            onChanged: (value) => controller.remarks.value = value,
          ),
        ],
      ],
    );
  }

  Widget _photoBlock(BuildContext context) {
    final photo = controller.photo.value;

    if (photo == null) {
      return AppButton(
        label: t('action.takePhoto'),
        icon: Icons.photo_camera_rounded,
        variant: AppButtonVariant.outline,
        isLoading: controller.isCapturing.value,
        onPressed: controller.capturePhoto,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            photo,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            // A handset that cannot decode its own capture must not take
            // the form down with it.
            errorBuilder: (context, error, stack) => Container(
              height: 180,
              alignment: Alignment.center,
              color: Theme.of(context).colorScheme.surface,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (controller.isUploading.value) ...[
              const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              AppText.caption(t('action.uploading')),
            ] else if (controller.uploadedPhotoPath.value.isNotEmpty)
              AppText.caption(t('action.uploaded')),
            const Spacer(),
            TextButton(
              onPressed: controller.capturePhoto,
              child: AppText.label(t('action.retakePhoto')),
            ),
            TextButton(
              onPressed: controller.removePhoto,
              child: AppText.label(t('action.removePhoto')),
            ),
          ],
        ),
      ],
    );
  }

  /// The witness's signature. Optional everywhere, and worth taking
  /// everywhere — a seal with one on the record is a much stronger
  /// document than a seal without.
  Widget _signatureBlock(BuildContext context) {
    final signature = controller.signature.value;

    if (signature == null) {
      return AppButton(
        label: t('action.signatureTake'),
        icon: Icons.draw_rounded,
        variant: AppButtonVariant.outline,
        onPressed: () async {
          final file = await AppSignaturePad.capture(context);
          if (file != null) controller.setSignature(file);
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 110,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.file(
            signature,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) =>
                const Icon(Icons.broken_image_outlined),
          ),
        ),
        Row(
          children: [
            if (controller.uploadedSignaturePath.value.isNotEmpty)
              AppText.caption(t('action.uploaded')),
            const Spacer(),
            TextButton(
              onPressed: () async {
                final file = await AppSignaturePad.capture(context);
                if (file != null) controller.setSignature(file);
              },
              child: AppText.label(t('action.signatureRedo')),
            ),
            TextButton(
              onPressed: controller.removeSignature,
              child: AppText.label(t('action.removePhoto')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _locationBlock(BuildContext context) {
    if (controller.isLocating.value) {
      return Row(
        children: [
          const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          AppText.body(t('action.locationFixing')),
        ],
      );
    }

    final fix = controller.fix.value;
    if (fix == null) {
      // Both coordinates or neither: with no fix the record carries none,
      // and the officer is told so rather than left to assume a pin.
      return Row(
        children: [
          Expanded(child: AppText.body(t('action.locationNone'))),
          const SizedBox(width: 8),
          AppButton(
            label: t('action.locationRetry'),
            variant: AppButtonVariant.ghost,
            fullWidth: false,
            height: 44,
            onPressed: controller.locate,
          ),
        ],
      );
    }

    return Row(
      children: [
        const Icon(Icons.place_rounded, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: AppText.body(
            t('action.locationFix',
                args: {'accuracy': fix.accuracyM.toStringAsFixed(0)}),
          ),
        ),
        IconButton(
          onPressed: controller.locate,
          icon: const Icon(Icons.refresh_rounded, size: 20),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
      ],
    );
  }
}
