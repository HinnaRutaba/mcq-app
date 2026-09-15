import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../controllers/defaulters_controller.dart';
import '../../../controllers/follow_ups_controller.dart';
import '../../../controllers/record_action_controller.dart';
import '../../../core/utils/form_scroll.dart';
import '../../../models/enforcement_action.dart';
import '../../../models/enforcement_case.dart';
import '../../../models/enforcement_definitions.dart';
import '../../../models/shop_action.dart';
import '../../../widgets/widgets.dart';
import 'create_case_screen.dart';
import 'widgets/action_recorded_sheet.dart';
import 'widgets/case_card.dart';
import 'widgets/still_needed_note.dart';

/// Recording one step against a case — a visit, a warning, a promise to pay.
///
/// The step travels as its register code, and the form is drawn from what MCQ
/// publishes for it: `payment_promised` asks for the day they will pay because
/// the register says that step carries one, not because this screen knows the
/// code.
///
/// Like a seal, the record has to hang off a case, so the first half of the
/// form is that choice — one of the unit's own cases, or a new one opened on
/// the spot through [CreateCaseScreen], which hands the file straight back.
class RecordActionScreen extends StatefulWidget {
  const RecordActionScreen({
    super.key,
    required this.propertyId,
    required this.actionCode,
    this.cases,
    this.caseId,
  });

  final int propertyId;

  /// The `ActionTypeDefinition.code` to record, e.g. `payment_promised`.
  final String actionCode;

  /// The unit's cases, when the caller has already read them — the shop's
  /// profile has, and asking for four pages again at a shopfront is a wait
  /// for nothing. Null makes this screen read them itself.
  final List<EnforcementCase>? cases;

  /// A case to start on.
  final int? caseId;

  /// Opens the form, and tells the caller what came back.
  ///
  /// A promise puts the shop on the follow-up list and changes the commitment
  /// on its defaulter row, so both are re-read for everybody and the screen
  /// this was pushed from is re-read through [onRecorded]. Null back means the
  /// officer walked away, which costs nothing.
  static Future<EnforcementAction?> open(
    BuildContext context, {
    required int propertyId,
    required String actionCode,
    List<EnforcementCase>? cases,
    int? caseId,
    Future<void> Function()? onRecorded,
  }) async {
    final EnforcementAction? action = await context.push<EnforcementAction>(
      AppRoutes.recordActionPath(
        propertyId: propertyId,
        actionCode: actionCode,
        caseId: caseId,
      ),
      extra: cases,
    );
    if (action == null) return null;
    await FollowUpsController.reloadIfOpened();
    await DefaultersController.reloadIfOpened();
    if (!context.mounted) return action;
    await onRecorded?.call();
    return action;
  }

  @override
  State<RecordActionScreen> createState() => _RecordActionScreenState();
}

class _RecordActionScreenState extends State<RecordActionScreen> {
  late final RecordActionController controller = Get.put(
    RecordActionController(
      propertyId: widget.propertyId,
      actionCode: widget.actionCode,
      knownCases: widget.cases,
      caseId: widget.caseId,
    ),
  );

  /// The app's own row for this code, for the wording an officer chose from.
  /// Null on a step published since — the register's name is used instead.
  late final ShopAction? step = ShopAction.byCode(widget.actionCode);

  @override
  void dispose() {
    Get.delete<RecordActionController>();
    super.dispose();
  }

  /// Opens a case in order to record against it, and takes the new file on.
  Future<void> _openCase() async {
    final EnforcementCase? file = await CreateCaseScreen.open(
      context,
      propertyId: widget.propertyId,
    );
    if (file == null) return;
    controller.adopt(file);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final RecordActionOutcome outcome = await controller.record();
    if (!mounted) return;

    if (outcome == RecordActionOutcome.success) {
      final EnforcementAction? action = controller.recorded.value;
      if (action == null) return;
      await ActionRecordedSheet.show(context, action: action);
      if (mounted) Navigator.of(context).pop(action);
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
            // The register's name is the fallback, read once: the header is
            // not the place to flicker from "Record a step" to "Payment
            // promised" when the definitions land.
            title: step?.label ?? controller.definition?.name ?? 'Record a step',
            subtitle: step?.description ?? 'On the case, with what was said.',
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
                    _CaseSection(controller: controller, onOpenCase: _openCase),
                    const SizedBox(height: 20),
                    _StepSection(controller: controller),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _SubmitBar(
        controller: controller,
        label: step?.label ?? 'Record it',
        onSubmit: _submit,
      ),
    );
  }
}

/// Which case the step goes on.
class _CaseSection extends StatelessWidget {
  const _CaseSection({required this.controller, required this.onOpenCase});

  final RecordActionController controller;
  final VoidCallback onOpenCase;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppText.titleMedium('Which case'),
        const SizedBox(height: 3),
        AppText.caption(
          'This goes on a case. Open one if the shop has none.',
          color: muted,
          maxLines: 2,
        ),
        const SizedBox(height: 10),
        Obx(() {
          if (controller.isLoadingCases.value && controller.cases.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final String? error = controller.casesError.value;
          if (error != null && controller.cases.isEmpty) {
            return AppErrorRetry(
              title: 'Could not read this shop’s cases',
              message: error,
              onRetry: controller.loadCases,
            );
          }

          final List<EnforcementCase> files = controller.cases.toList();
          final int? chosen = controller.selectedCaseId.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (files.isEmpty)
                const AppCard(
                  padding: EdgeInsets.fromLTRB(12, 16, 12, 16),
                  child: AppDetailRow(
                    icon: Icons.folder_off_outlined,
                    value: 'No case has been opened on this shop yet',
                    maxLines: 2,
                  ),
                )
              else
                for (final EnforcementCase file in files)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CaseCard(
                      file: file,
                      selected: file.id == chosen,
                      // The picker's own wording: a tap here hangs the record
                      // on the case, it does not open its history.
                      hint: file.id == chosen
                          ? 'this is where it goes'
                          : 'tap to record on this case',
                      onTap: file.id == null
                          ? null
                          : () => controller.chooseCase(file.id!),
                    ),
                  ),
              AppButton(
                label: 'Open a new case',
                icon: Icons.create_new_folder_outlined,
                variant: AppButtonVariant.outline,
                onPressed: onOpenCase,
              ),
            ],
          );
        }),
      ],
    );
  }
}

/// The step itself: when it happened, whatever date the register says it
/// carries, and what was said.
class _StepSection extends StatelessWidget {
  const _StepSection({required this.controller});

  final RecordActionController controller;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppText.titleMedium('What happened'),
        const SizedBox(height: 3),
        AppText.caption(
          'This goes on the case timeline as it stands, so write it for '
          'somebody reading it a month from now.',
          color: muted,
          maxLines: 2,
        ),
        const SizedBox(height: 10),
        Obx(() => _dates(context, controller)),
        const SizedBox(height: 16),
        AppTextField(
          label: 'What was said',
          hint: 'e.g. Said he would pay after the wedding season.',
          controller: controller.remarksController,
          maxLines: 3,
          optional: true,
          validator: controller.validateRemarks,
          onChanged: (String _) => controller.markEdited(),
        ),
      ],
    );
  }
}

/// The date fields this step carries, as the register published them.
///
/// Read inside an `Obx`: the spec arrives with the definitions, and the dates
/// themselves are observable.
Widget _dates(BuildContext context, RecordActionController controller) {
  final ActionTypeFields? spec = controller.fields;

  if (spec == null) {
    if (controller.isLoadingDefinitions) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return AppErrorRetry(
      title: 'Could not load this step',
      message:
          controller.definitionsError ??
          'MCQ is not publishing this step at the moment.',
      onRetry: controller.reloadDefinitions,
    );
  }

  final DateTime today = DateUtils.dateOnly(DateTime.now());

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      AppDateField(
        label: 'The day you called',
        hint: 'Today',
        value: controller.actionDate.value,
        // Never a day that has not happened; a visit made last week can still
        // be written up today.
        firstDate: today.subtract(const Duration(days: 30)),
        lastDate: today,
        onChanged: controller.setActionDate,
      ),
      if (spec.promiseDate) ...<Widget>[
        const SizedBox(height: 16),
        AppDateField(
          label: 'The day they will pay',
          hint: 'Pick the day they named',
          value: controller.promisedPaymentDate.value,
          // Today or later: a promise to have paid last week is not a promise,
          // and this date is what puts the shop back on the follow-up list.
          firstDate: today,
          lastDate: DateTime(today.year + 1, today.month, today.day),
          validator: controller.validatePromisedDate,
          onChanged: controller.setPromisedPaymentDate,
        ),
      ],
      if (spec.visitDate) ...<Widget>[
        const SizedBox(height: 16),
        AppDateField(
          label: 'The day you will return',
          hint: 'Pick the day',
          value: controller.nextVisitDate.value,
          firstDate: today,
          lastDate: DateTime(today.year + 1, today.month, today.day),
          validator: controller.validateVisitDate,
          onChanged: controller.setNextVisitDate,
        ),
      ],
    ],
  );
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.controller,
    required this.label,
    required this.onSubmit,
  });

  final RecordActionController controller;

  /// The step, worded as the officer chose it off the Take Action sheet.
  final String label;

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
            // Re-read the text controller whenever anything was edited.
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
                  // request goes out again — see `RecordActionController`.
                  label: error == null ? label : 'Send it again',
                  icon: Icons.check_rounded,
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
