import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/api/field_write_controller.dart';
import '../../../controllers/api/record_action_controller.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/enforcement/field_evidence.dart';
import '../../../widgets/widgets.dart';
import 'case_write_args.dart';
import 'widgets/evidence_capture_card.dart';
import 'widgets/server_field_error.dart';

/// Recording a visit, a warning, a **promise to pay** or a **revisit**.
///
/// When the officer arrived here from the action sheet the type is already
/// chosen, and the form drops the dropdown entirely: a promise is then two
/// taps — pick the date the shopkeeper named, submit. That is the
/// difference between a feature used at a shop front and one that is not.
///
/// The pattern here is reused by every other write: no optimistic UI, a
/// spinner on the button, 422 bound to the fields, 409 in a dialog with the
/// server's sentence, and a lost signal queueing the record with its
/// `client_action_uuid` instead of losing it.
class RecordActionScreen extends StatefulWidget {
  const RecordActionScreen({super.key, required this.caseId, this.args});

  final int caseId;
  final CaseWriteArgs? args;

  @override
  State<RecordActionScreen> createState() => _RecordActionScreenState();
}

class _RecordActionScreenState extends State<RecordActionScreen> {
  late Future<CaseWriteArgs> _argsFuture =
      widget.args != null
          ? Future.value(widget.args)
          : CaseWriteArgs.forCase(widget.caseId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.titleLarge(
          (widget.args?.actionType ?? '').isEmpty
              ? t('action.title')
              : tEnum('actionType', widget.args!.actionType!),
        ),
      ),
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
                    _argsFuture = CaseWriteArgs.forCase(widget.caseId);
                  }),
                ),
              ),
            );
          }
          return _RecordActionForm(args: snapshot.data!, caseId: widget.caseId);
        },
      ),
    );
  }
}

class _RecordActionForm extends StatefulWidget {
  const _RecordActionForm({required this.args, required this.caseId});

  final CaseWriteArgs args;
  final int caseId;

  @override
  State<_RecordActionForm> createState() => _RecordActionFormState();
}

class _RecordActionFormState extends State<_RecordActionForm> {
  late final String _tag = 'action-${widget.caseId}';
  late final RecordActionController _controller = Get.put(
    RecordActionController.resolve(
      caseId: widget.caseId,
      shopLabel: widget.args.shopLabel,
      allotteeName: widget.args.allotteeName,
    ),
    tag: _tag,
  );

  /// True when the officer picked the action from the sheet. The dropdown
  /// is then a question he has already answered.
  bool get _preset => (widget.args.actionType ?? '').isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_preset) _controller.actionType.value = widget.args.actionType!;
  }

  @override
  void dispose() {
    Get.delete<RecordActionController>(tag: _tag);
    super.dispose();
  }

  Future<void> _submit() async {
    final result = await _controller.submit();
    if (!mounted) return;
    switch (result) {
      case FieldWriteResult.sent:
      case FieldWriteResult.replayed:
      case FieldWriteResult.queued:
        Navigator.of(context).pop(true);
      case FieldWriteResult.refused:
      case FieldWriteResult.invalid:
      case FieldWriteResult.failed:
        // Stay on the form: the officer has something to read or fix.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    '${widget.args.shopLabel} — ${widget.args.allotteeName}',
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (!_preset)
            Obx(
              () => AppDropdown<String>(
                label: t('action.type'),
                items: FieldWriteEnums.actionTypes,
                itemLabel: (value) => tEnum('actionType', value),
                value: _controller.actionType.value.isEmpty
                    ? null
                    : _controller.actionType.value,
                onChanged: (value) =>
                    _controller.actionType.value = value ?? '',
              ),
            ),
          ServerFieldError(
            errors: _controller.fieldErrors,
            field: 'action_type',
          ),
          if (!_preset) const SizedBox(height: 24),

          // The date a promise or a revisit hangs on. Asked for with the
          // words a shopkeeper actually uses — "in one week", "end of the
          // month" — because he does not say "the fourteenth".
          Obx(() {
            if (!_controller.needsPromiseDate && !_controller.needsVisitDate) {
              return const SizedBox.shrink();
            }
            final promise = _controller.needsPromiseDate;
            final chosen = promise
                ? _controller.promisedPaymentDate.value
                : _controller.nextVisitDate.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DateRow(
                  label: promise
                      ? t('action.promisedDate')
                      : t('action.revisitDate'),
                  value: chosen,
                  onPick: () async {
                    final picked = await AppDateChoiceSheet.ask(
                      context,
                      title: promise
                          ? t('action.promisedDate')
                          : t('action.revisitDate'),
                      subtitle: promise
                          ? t('action.promisedDateHelp')
                          : t('action.revisitDateHelp'),
                    );
                    if (picked == null) return;
                    if (promise) {
                      _controller.promisedPaymentDate.value = picked;
                    } else {
                      _controller.nextVisitDate.value = picked;
                    }
                  },
                ),
                ServerFieldError(
                  errors: _controller.fieldErrors,
                  field: promise ? 'promised_payment_date' : 'next_visit_date',
                ),
                const SizedBox(height: 24),
              ],
            );
          }),

          EvidenceCaptureCard(controller: _controller),
          const SizedBox(height: 28),

          Obx(
            () => AppButton(
              label: t('common.submit'),
              isLoading: _controller.isSubmitting.value,
              onPressed: _controller.isValid ? _submit : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// The chosen date, or an invitation to choose one.
class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chosen = value != null;
    return AppCard(
      onTap: onPick,
      tone: chosen ? AppTone.warning : null,
      rail: chosen,
      child: Row(
        children: [
          Icon(
            chosen ? Icons.event_available_rounded : Icons.event_rounded,
            color: chosen
                ? AppTone.warning.on(context)
                : theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodySmall(
                  label,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 2),
                AppText.titleMedium(
                  chosen ? Formatters.date(value!) : t('action.chooseDate'),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: theme.dividerColor),
        ],
      ),
    );
  }
}
