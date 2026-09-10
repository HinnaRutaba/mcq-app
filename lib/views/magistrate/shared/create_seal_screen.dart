import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../controllers/defaulters_controller.dart';
import '../../../controllers/seal_controller.dart';
import '../../../core/utils/form_scroll.dart';
import '../../../models/enforcement_case.dart';
import '../../../models/field_seal.dart';
import '../../../widgets/widgets.dart';
import 'widgets/case_card.dart';
import 'create_case_screen.dart';
import 'widgets/seal_applied_sheet.dart';
import 'widgets/still_needed_note.dart';

/// Shutting a shop: which case the seal is recorded against, and why.
///
/// A seal has to hang off a case, so the first half of this form is that
/// choice — one of the unit's own cases, or a new one opened on the spot
/// through [CreateCaseScreen], which hands the file straight back here.
class CreateSealScreen extends StatefulWidget {
  const CreateSealScreen({
    super.key,
    required this.propertyId,
    this.cases,
    this.caseId,
  });

  final int propertyId;

  /// The unit's cases, when the caller has already read them — the shop's
  /// profile has, and asking for four pages again at a shopfront is a wait
  /// for nothing. Null makes this screen read them itself.
  final List<EnforcementCase>? cases;

  /// A case to start on.
  final int? caseId;

  /// Opens the form, and tells the caller what came back.
  ///
  /// A seal changes the shop's own record and the sealed list, so the shop is
  /// re-read through [onSealed] and the defaulter list refreshed for
  /// everybody. Null back means the officer walked away, which costs nothing.
  static Future<FieldSeal?> open(
    BuildContext context, {
    required int propertyId,
    List<EnforcementCase>? cases,
    int? caseId,
    Future<void> Function()? onSealed,
  }) async {
    final FieldSeal? seal = await context.push<FieldSeal>(
      AppRoutes.createSealPath(propertyId: propertyId, caseId: caseId),
      extra: cases,
    );
    if (seal == null) return null;
    await DefaultersController.reloadIfOpened();
    if (!context.mounted) return seal;
    await onSealed?.call();
    return seal;
  }

  @override
  State<CreateSealScreen> createState() => _CreateSealScreenState();
}

class _CreateSealScreenState extends State<CreateSealScreen> {
  late final SealController controller = Get.put(
    SealController(
      propertyId: widget.propertyId,
      knownCases: widget.cases,
      caseId: widget.caseId,
    ),
  );

  @override
  void dispose() {
    Get.delete<SealController>();
    super.dispose();
  }

  /// Opens a case in order to seal against it, and takes the new file on.
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
    final SealOutcome outcome = await controller.apply();
    if (!mounted) return;

    if (outcome == SealOutcome.success) {
      final FieldSeal? seal = controller.applied.value;
      if (seal == null) return;
      await SealAppliedSheet.show(context, seal: seal);
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
            title: 'Seal the shop',
            subtitle: 'Against a case, with the reason on record',
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
                    _ReasonSection(controller: controller),
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

/// Which case the seal goes on.
class _CaseSection extends StatelessWidget {
  const _CaseSection({required this.controller, required this.onOpenCase});

  final SealController controller;
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
          'A seal is recorded against a case. Open one if the shop has none.',
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
                      // The picker's own wording: a tap here hangs the seal on
                      // the case, it does not open its history.
                      hint: file.id == chosen
                          ? 'the seal goes on this case'
                          : 'tap to seal on this case',
                      onTap: file.id == null
                          ? null
                          : () => controller.chooseCase(file.id!),
                    ),
                  ),
              // Shown whatever the shop already has: a seal for something the
              // open case is not about belongs on a case of its own.
              AppButton(
                label: 'Open a new case',
                icon: Icons.create_new_folder_outlined,
                variant: AppButtonVariant.outline,
                onPressed: onOpenCase,
              ),
              // The server's own precondition, said rather than enforced: a
              // case opened a minute ago comes back with nothing on this flag,
              // and refusing to seal against it would strand the officer.
              if (controller.selectedCase?.canSeal == false) ...<Widget>[
                const SizedBox(height: 10),
                const AppAlert(
                  tone: AppTone.warning,
                  icon: Icons.info_outline_rounded,
                  message:
                      'MCQ has not cleared this case for sealing. You can '
                      'still send it — the server has the last word.',
                ),
              ],
            ],
          );
        }),
      ],
    );
  }
}

/// Why the shop is being shut, and the day the seal went on.
class _ReasonSection extends StatelessWidget {
  const _ReasonSection({required this.controller});

  final SealController controller;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final DateTime today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppText.titleMedium('Why it is being sealed'),
        const SizedBox(height: 3),
        AppText.caption(
          'Kept as the record of why a shop was shut, so write it for '
          'somebody reading it a year from now.',
          color: muted,
          maxLines: 2,
        ),
        const SizedBox(height: 10),
        AppTextField(
          controller: controller.reasonController,
          hint: 'e.g. Arrears unpaid after final notice.',
          maxLines: 3,
          validator: controller.validateReason,
          onChanged: (String _) => controller.markEdited(),
        ),
        const SizedBox(height: 16),
        Obx(
          () => AppDateField(
            label: 'The day the seal went on',
            hint: 'Today',
            value: controller.sealedOn.value,
            // Never a day that has not happened; a seal put on last week can
            // still be written up today.
            firstDate: today.subtract(const Duration(days: 30)),
            lastDate: today,
            onChanged: controller.setSealedOn,
          ),
        ),
      ],
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.controller, required this.onSubmit});

  final SealController controller;
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
                  // request goes out again — see `SealController`.
                  label: error == null ? 'Seal the shop' : 'Send it again',
                  icon: Icons.lock_outline_rounded,
                  variant: AppButtonVariant.danger,
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
