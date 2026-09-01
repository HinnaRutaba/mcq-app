import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/api/inspection_form_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/widgets.dart';

/// Recording an inspection.
///
/// One step: the photograph goes on the request itself. Not queued offline
/// either — an inspection carries no idempotency key, so a blind retry
/// could record it twice. This write needs signal, and says so if it fails.
class RecordInspectionScreen extends StatefulWidget {
  const RecordInspectionScreen({super.key, required this.propertyId});

  final int propertyId;

  @override
  State<RecordInspectionScreen> createState() => _RecordInspectionScreenState();
}

class _RecordInspectionScreenState extends State<RecordInspectionScreen> {
  static const List<String> _types = ['routine', 'complaint', 'enforcement'];

  late final String _tag = 'inspection-${widget.propertyId}';
  late final InspectionFormController _controller = Get.put(
    InspectionFormController.resolve(widget.propertyId),
    tag: _tag,
  );

  @override
  void dispose() {
    Get.delete<InspectionFormController>(tag: _tag);
    super.dispose();
  }

  Future<void> _submit() async {
    final saved = await _controller.submit();
    if (saved && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: AppText.titleLarge(t('inspection.title'))),
      body: Obx(
        () => SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppDropdown<String>(
                label: t('inspection.type'),
                items: _types,
                itemLabel: (value) => t('inspectionType.$value'),
                value: _controller.inspectionType.value.isEmpty
                    ? null
                    : _controller.inspectionType.value,
                onChanged: (value) =>
                    _controller.inspectionType.value = value ?? '',
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: t('inspection.findings'),
                maxLines: 5,
                onChanged: (value) => _controller.findings.value = value,
                validator: (_) => _controller.errorFor('findings'),
              ),
              const SizedBox(height: 20),
              AppText.titleMedium(t('action.photo')),
              const SizedBox(height: 4),
              AppText.caption(t('action.photoHelp')),
              const SizedBox(height: 12),
              if (_controller.photo.value == null)
                AppButton(
                  label: t('action.takePhoto'),
                  icon: Icons.photo_camera_rounded,
                  variant: AppButtonVariant.outline,
                  isLoading: _controller.isCapturing.value,
                  onPressed: _controller.capturePhoto,
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _controller.photo.value!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(
                          onPressed: _controller.capturePhoto,
                          child: AppText.label(t('action.retakePhoto')),
                        ),
                        TextButton(
                          onPressed: _controller.removePhoto,
                          child: AppText.label(t('action.removePhoto')),
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 28),
              AppButton(
                label: t('common.submit'),
                isLoading: _controller.isSubmitting.value,
                onPressed: _controller.isValid ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
