import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../controllers/case_controller.dart';
import '../../../controllers/defaulters_controller.dart';
import '../../../core/utils/form_scroll.dart';
import '../../../models/api_refs.dart';
import '../../../models/case_type_option.dart';
import '../../../models/enforcement_case.dart';
import '../../../models/unit_card.dart';
import '../../../widgets/widgets.dart';
import 'widgets/case_opened_sheet.dart';
import 'widgets/offender_fields.dart';
import 'widgets/still_needed_note.dart';
import 'widgets/unit_summary_card.dart';

class CreateCaseScreen extends StatefulWidget {
  const CreateCaseScreen({super.key, this.unit, this.propertyId});

  final UnitCard? unit;

  final int? propertyId;

  /// Pushes this form over the screen the officer is on and puts back what a
  /// new case left out of date: the defaulter rows carry its badge for every
  /// caller, and [onOpened] re-reads the screen it was pushed from. A form
  /// walked away from costs nothing.
  static Future<EnforcementCase?> open(
    BuildContext context, {
    required int? propertyId,
    Future<void> Function()? onOpened,
  }) async {
    final EnforcementCase? opened = await context.push<EnforcementCase>(
      AppRoutes.createCasePath(propertyId: propertyId),
    );
    if (opened == null) return null;
    await DefaultersController.reloadIfOpened();
    if (!context.mounted) return opened;
    await onOpened?.call();
    return opened;
  }

  @override
  State<CreateCaseScreen> createState() => _CreateCaseScreenState();
}

class _CreateCaseScreenState extends State<CreateCaseScreen> {
  late final CaseController controller = Get.put(
    CaseController(unit: widget.unit, propertyId: widget.propertyId),
  );

  @override
  void dispose() {
    Get.delete<CaseController>();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final OpenCaseOutcome outcome = await controller.open();
    if (!mounted) return;

    if (outcome == OpenCaseOutcome.success) {
      final EnforcementCase? file = controller.opened.value;
      if (file == null) return;
      await CaseOpenedSheet.show(context, file: file);
      if (mounted) Navigator.of(context).pop(file);
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
          Obx(() {
            // Watched, not merely read: behind a route that carried only an
            // id, the shop's name arrives long after this is first drawn.
            controller.profile.value;
            return AppHeroHeader(
              title: 'Open a case',
              subtitle: controller.hasUnitDetails
                  ? controller.unitTitle
                  : (controller.targetPropertyId != null
                        ? 'Reading the register…'
                        : 'No shop on this link'),
              leading: AppCircleIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => context.pop(),
              ),
            );
          }),
          Expanded(
            child: Form(
              key: controller.formKey,

              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _ShopSection(controller: controller),
                    const SizedBox(height: 20),
                    _KindSection(controller: controller),
                    const SizedBox(height: 20),
                    _ReasonSection(controller: controller),
                    const SizedBox(height: 20),
                    _OffenderSection(controller: controller),
                    const SizedBox(height: 20),
                    _PrioritySection(controller: controller),
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

// ---------------------------------------------------------------------------
// Sections
// ---------------------------------------------------------------------------

/// Step 1: the shop the case is opened on, which the officer never chooses
/// here — they arrived from it.
class _ShopSection extends StatelessWidget {
  const _ShopSection({required this.controller});

  final CaseController controller;

  @override
  Widget build(BuildContext context) {
    return AppFormSection(
      step: '1',
      title: 'The shop',
      child: Obx(() {
        // Watched together: a card the officer arrived with answers this
        // section outright, and a fetched profile lands in it later.
        controller.profile.value;

        if (controller.hasUnitDetails) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              UnitSummaryCard(
                title: controller.unitTitle,
                holder: controller.allotteeName,
                code: controller.unitCode,
                area: controller.unitArea,
                address: controller.unitAddress,
                outstanding: controller.unitOutstanding,
                isVacant: controller.unitIsVacant,
                isSealed: controller.unitIsSealed,
              ),
              // A second file on the same shop is somebody else's work
              // duplicated, so it is said before the case is opened rather
              // than found afterwards.
              if (controller.hasOpenCase) ...<Widget>[
                const SizedBox(height: 12),
                AppAlert(
                  tone: AppTone.warning,
                  icon: Icons.folder_open_outlined,
                  message:
                      'Case ${controller.openCaseLabel} is already open on '
                      'this shop. Record this against that case unless it is '
                      'about something else.',
                ),
              ],
            ],
          );
        }

        if (controller.isLoadingProfile.value) {
          return const AppCard(child: AppText.body('Reading the register…'));
        }

        final int? id = controller.targetPropertyId;
        final String? error = controller.profileError.value;
        if (error != null && id != null) {
          // The case only needs the unit's id, which the route carried — so a
          // profile that would not load costs the officer the card, not the
          // case.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppAlert(
                tone: AppTone.warning,
                message:
                    '$error The case can still be opened on shop #$id, '
                    'without its details.',
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Try again',
                icon: Icons.refresh_rounded,
                fullWidth: false,
                onPressed: controller.loadProfile,
              ),
            ],
          );
        }

        // Nothing to open a case on: the link carried no shop, and this form
        // does not pick one.
        return const AppAlert(
          message:
              'This link carries no shop, so a case cannot be opened. Open '
              'the shop and take the action from there.',
        );
      }),
    );
  }
}

/// Step 2: what the case is about — the `case_type` the server files it under.
class _KindSection extends StatelessWidget {
  const _KindSection({required this.controller});

  final CaseController controller;

  @override
  Widget build(BuildContext context) {
    return AppFormSection(
      step: '2',
      title: 'What it is about',
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          final List<CaseTypeOption> kinds = controller.caseTypes;

          if (kinds.isEmpty) {
            if (controller.isLoadingCaseTypes.value) {
              return const AppText.body('Loading the case kinds…');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppAlert(
                  message:
                      controller.caseTypesError.value ??
                      'The case kinds have not been loaded, so a case cannot '
                          'be opened yet.',
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Try again',
                  icon: Icons.refresh_rounded,
                  fullWidth: false,
                  onPressed: controller.loadCaseTypes,
                ),
              ],
            );
          }

          final CaseTypeOption? chosen = controller.caseType.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppDropdown<CaseTypeOption>(
                // The rows arrive after the first build, and one kind is
                // chosen for the officer — both need the field rebuilt on its
                // value.
                key: ValueKey<String?>(chosen?.code),
                label: 'The kind of case',
                hint: 'Choose what the case is about',
                items: kinds,
                itemLabel: (CaseTypeOption kind) => kind.name,
                value: chosen,
                validator: controller.validateCaseType,
                onChanged: controller.chooseCaseType,
              ),
              if (chosen != null) ...<Widget>[
                if (chosen.nameUr != null) ...<Widget>[
                  const SizedBox(height: 12),
                  // Right to left, and larger than a caption: this is the
                  // wording the officer says out loud at the counter.
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: AppText.titleMedium(chosen.nameUr!),
                  ),
                ],
                if (chosen.description != null) ...<Widget>[
                  const SizedBox(height: 12),
                  AppAlert(
                    tone: AppTone.info,
                    icon: Icons.help_outline_rounded,
                    message: chosen.description!,
                  ),
                ],
              ],
            ],
          );
        }),
      ),
    );
  }
}

/// Step 3: why, in the officer's own words. It is the substance of the file
/// somebody reads back weeks later, so the form insists on it.
class _ReasonSection extends StatelessWidget {
  const _ReasonSection({required this.controller});

  final CaseController controller;

  @override
  Widget build(BuildContext context) {
    return AppFormSection(
      step: '3',
      title: 'Why it is being opened',
      note:
          'What you saw at the shop. A clerk reading this case later has only '
          'these words.',
      child: AppCard(
        child: AppTextField(
          hint: 'e.g. Trading in goods the agreement does not permit',
          controller: controller.reasonController,
          maxLines: 4,
          validator: controller.validateReason,
          onChanged: (_) => controller.markEdited(),
        ),
      ),
    );
  }
}

/// Step 4: the person the case is against. Prefilled from the register where
/// it names somebody — retyping four fields off the card in step 1 is how a
/// wrong digit reaches a notice.
class _OffenderSection extends StatelessWidget {
  const _OffenderSection({required this.controller});

  final CaseController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Read in the builder: behind a route that carried only an id, the
      // person on the register arrives with the profile long after this is
      // first drawn.
      controller.profile.value;

      return AppFormSection(
        step: '4',
        title: 'Who it is against',
        note: controller.hasRegisteredPerson
            ? 'Filled in from the register. Correct it if the person in front '
                  'of you is somebody else.'
            : 'A notice is served on this person, so the name, their '
                  "father's name and a mobile number are required together.",
        child: OffenderFields(
          lookup: controller.personLookup,
          nameController: controller.offenderNameController,
          fatherController: controller.offenderFatherController,
          mobileController: controller.offenderMobileController,
          validateCnic: controller.validateOffenderCnic,
          validateName: controller.validateOffenderName,
          validateFather: controller.validateOffenderFather,
          validateMobile: controller.validateOffenderMobile,
          onTaken: controller.takePerson,
          onChanged: controller.markEdited,
        ),
      );
    });
  }
}

class _PrioritySection extends StatelessWidget {
  const _PrioritySection({required this.controller});

  final CaseController controller;

  @override
  Widget build(BuildContext context) {
    return AppFormSection(
      step: '5',
      title: 'How urgent',
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          final List<LabelledValue> priorities = controller.priorities;

          if (priorities.isEmpty) {
            return AppText.body(
              controller.isLoadingPriorities
                  ? 'Loading the priorities…'
                  : 'The register lists no priorities, so this case will open '
                        'at its own.',
            );
          }

          final LabelledValue? chosen = controller.priority.value;
          return AppDropdown<LabelledValue>(
            // The rows are fetched at sign-in and `normal` is picked off them,
            // so the field is rebuilt when either lands.
            key: ValueKey<String?>(chosen?.value),
            label: 'Priority',
            hint: 'Leave for the register to decide',
            items: priorities,
            itemLabel: (LabelledValue row) => row.label,
            value: chosen,
            validator: controller.validatePriority,
            onChanged: controller.choosePriority,
          );
        }),
      ),
    );
  }
}

/// The bar that stays on screen: what is being opened, what is still missing,
/// and the button.
class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.controller, required this.onSubmit});

  final CaseController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color? muted = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.6,
    );

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
            // Re-read the reason field whenever anything was edited: a text
            // controller is not observable.
            controller.revision.value;
            final CaseTypeOption? kind = controller.caseType.value;
            final LabelledValue? priority = controller.priority.value;
            final List<String> missing = controller.missing;

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
                          AppText.caption('New case', color: muted),
                          const SizedBox(height: 2),
                          AppText.titleMedium(kind?.name ?? '—', maxLines: 1),
                        ],
                      ),
                    ),
                    if (priority != null) ...<Widget>[
                      const SizedBox(width: 12),
                      AppStatusBadge(
                        label: priority.label,
                        tone: AppToneColors.fromApi(priority.tone),
                      ),
                    ],
                  ],
                ),
                // Every missing field named: the shortened version tells an
                // officer the button will not press without telling them what
                // to do about it.
                if (missing.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  StillNeededNote(missing: missing),
                ],
                // Why the last press did not go through, kept beside the
                // button that will be pressed again. The server's own
                // sentence, verbatim: it knows why it refused.
                if (controller.errorMessage.value != null) ...<Widget>[
                  const SizedBox(height: 10),
                  AppAlert(
                    message: controller.errorMessage.value!,
                    compact: true,
                  ),
                ],
                const SizedBox(height: 10),
                AppButton(
                  label: 'Open the case',
                  icon: Icons.create_new_folder_outlined,
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
