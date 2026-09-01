import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/api/field_write_controller.dart';
import '../../../controllers/api/seal_form_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/widgets.dart';
import 'case_write_args.dart';
import 'widgets/evidence_capture_card.dart';
import 'widgets/server_field_error.dart';

/// Sealing a shop, and releasing a seal.
///
/// Both confirm, and the confirmation names the shop and the allottee.
/// Sealing closes somebody's livelihood; releasing one that should not be
/// released loses MCQ its leverage. Neither is an undo-able tap.
class SealFormScreen extends StatefulWidget {
  const SealFormScreen({
    super.key,
    required this.mode,
    this.caseId,
    this.sealId,
    this.args,
  });

  final SealMode mode;
  final int? caseId;
  final int? sealId;
  final CaseWriteArgs? args;

  @override
  State<SealFormScreen> createState() => _SealFormScreenState();
}

class _SealFormScreenState extends State<SealFormScreen> {
  late Future<CaseWriteArgs> _argsFuture = _resolveArgs();

  Future<CaseWriteArgs> _resolveArgs() {
    if (widget.args != null) return Future.value(widget.args);
    return widget.mode == SealMode.seal
        ? CaseWriteArgs.forCase(widget.caseId!)
        : CaseWriteArgs.forSeal(widget.sealId!);
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.mode == SealMode.seal ? t('cases.sealShop') : t('cases.releaseSeal');

    return Scaffold(
      appBar: AppBar(title: AppText.titleLarge(title)),
      body: FutureBuilder<CaseWriteArgs>(
        future: _argsFuture,
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
                    _argsFuture = _resolveArgs();
                  }),
                ),
              ),
            );
          }
          return _SealForm(
            mode: widget.mode,
            caseId: widget.caseId,
            sealId: widget.sealId,
            args: snapshot.data!,
          );
        },
      ),
    );
  }
}

class _SealForm extends StatefulWidget {
  const _SealForm({
    required this.mode,
    required this.args,
    this.caseId,
    this.sealId,
  });

  final SealMode mode;
  final CaseWriteArgs args;
  final int? caseId;
  final int? sealId;

  @override
  State<_SealForm> createState() => _SealFormState();
}

class _SealFormState extends State<_SealForm> {
  late final String _tag =
      'seal-${widget.mode.name}-${widget.caseId ?? widget.sealId}';
  late final SealFormController _controller = Get.put(
    SealFormController.resolve(
      mode: widget.mode,
      shopLabel: widget.args.shopLabel,
      allotteeName: widget.args.allotteeName,
      caseId: widget.caseId,
      sealId: widget.sealId,
    ),
    tag: _tag,
  );

  bool get _isSeal => widget.mode == SealMode.seal;

  @override
  void dispose() {
    Get.delete<SealFormController>(tag: _tag);
    super.dispose();
  }

  Future<void> _submit() async {
    // The confirmation sits at the point of no return, after the officer
    // has taken the photograph and before anything is sent — and it names
    // the shop and the allottee.
    final confirmed = await AppConfirmDialog.ask(
      context,
      title: _isSeal ? t('seal.confirmSealTitle') : t('seal.confirmReleaseTitle'),
      body: t(
        _isSeal ? 'seal.confirmSealBody' : 'seal.confirmReleaseBody',
        args: {
          'shop': widget.args.shopLabel,
          'allottee': widget.args.allotteeName,
        },
      ),
      confirmLabel: _isSeal ? t('seal.confirmSeal') : t('seal.confirmRelease'),
    );
    if (!confirmed) return;

    final result = await _controller.submit();
    if (!mounted) return;
    if (result == FieldWriteResult.sent ||
        result == FieldWriteResult.replayed ||
        result == FieldWriteResult.queued) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppBanner(
            tone: AppStatusTone.warning,
            icon: _isSeal ? Icons.lock_rounded : Icons.lock_open_rounded,
            message: t(
              _isSeal ? 'seal.confirmSealBody' : 'seal.confirmReleaseBody',
              args: {
                'shop': widget.args.shopLabel,
                'allottee': widget.args.allotteeName,
              },
            ),
          ),
          const SizedBox(height: 20),

          // Required on both directions. A release with no reason is a
          // shutter that opened with no record of who decided it should.
          AppTextField(
            label: _isSeal ? t('seal.reason') : t('seal.unsealReason'),
            hint: _isSeal ? null : t('seal.unsealReasonHint'),
            maxLines: 3,
            onChanged: (value) => _controller.reason.value = value,
          ),
          ServerFieldError(
            errors: _controller.fieldErrors,
            field: _isSeal ? 'reason' : 'unseal_reason',
          ),
          const SizedBox(height: 24),

          EvidenceCaptureCard(controller: _controller),
          const SizedBox(height: 12),
          Obx(() {
            if (_controller.photo.value != null) return const SizedBox.shrink();
            return AppText.caption(t('action.photoRequired'));
          }),
          const SizedBox(height: 16),

          Obx(
            () => AppButton(
              label: _isSeal ? t('seal.confirmSeal') : t('seal.confirmRelease'),
              variant: _isSeal
                  ? AppButtonVariant.danger
                  // Releasing is the officer finishing a job. It should
                  // not be drawn in the same red as closing a shop.
                  : AppButtonVariant.primary,
              // Both are decisions, and both should feel like one.
              destructive: true,
              isLoading: _controller.isSubmitting.value,
              onPressed: _controller.isValid ? _submit : null,
            ),
          ),
        ],
      ),
    );
  }
}
