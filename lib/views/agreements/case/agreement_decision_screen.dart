import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_radius.dart';
import '../../../controllers/agreement_decision_controller.dart';
import '../../../core/utils/form_scroll.dart';
import '../../../models/agreement_case.dart';
import '../../../models/agreement_requests.dart';
import '../../../widgets/widgets.dart';
import '../shared/intake_labels.dart';
import 'widgets/intake_decision_summary.dart';

/// What the case screen gets back: the case as it now stands, and a line to
/// tell the officer.
/// [done] is false when someone acted first and the case was reloaded.
typedef DecisionResult = ({AgreementCase file, String? notice, bool done});

/// Taking one act on a case — whichever `act_options` offered.
class AgreementDecisionScreen extends StatefulWidget {
  const AgreementDecisionScreen({super.key, required this.act, this.caseFile});

  final String act;

  /// The case that was on screen. Its `lock_version` is what the act is
  /// checked against, so a cold link with none cannot decide anything.
  final AgreementCase? caseFile;

  @override
  State<AgreementDecisionScreen> createState() =>
      _AgreementDecisionScreenState();
}

class _AgreementDecisionScreenState extends State<AgreementDecisionScreen> {
  AgreementDecisionController? controller;

  @override
  void initState() {
    super.initState();
    final AgreementCase? file = widget.caseFile;
    final IntakeActOption? option = file?.actOptions
        .where((IntakeActOption o) => o.act == widget.act && o.allowed)
        .firstOrNull;
    if (file != null && option != null) {
      controller = Get.put<AgreementDecisionController>(
        AgreementDecisionController(caseFile: file, option: option),
      );
    }
  }

  @override
  void dispose() {
    if (controller != null) Get.delete<AgreementDecisionController>();
    super.dispose();
  }

  Future<void> _submit() async {
    final AgreementDecisionController c = controller!;
    FocusScope.of(context).unfocus();
    final DecisionOutcome outcome = await c.submit();
    if (!mounted) return;

    switch (outcome) {
      case DecisionOutcome.success:
        final AgreementCase updated = c.result.value!;
        final String? now = updated.statusValue;
        Navigator.of(context).pop<DecisionResult>((
          file: updated,
          done: true,
          notice:
              '${IntakeLabels.actDone(c.option.act)}.'
              '${now == null ? '' : ' Now ${IntakeLabels.status(now).toLowerCase()}.'}',
        ));
      case DecisionOutcome.stale:
        final AgreementCase? reloaded = c.result.value;
        if (reloaded != null) {
          Navigator.of(context).pop<DecisionResult>((
            file: reloaded,
            notice: c.errorMessage.value,
            done: false,
          ));
        }
      case DecisionOutcome.invalidForm:
      case DecisionOutcome.failed:
        scrollToFirstError(c.formKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AgreementDecisionController? c = controller;
    final String title = IntakeLabels.act(widget.act);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Column(
          children: <Widget>[
            AppHeroHeader(
              title: title,
              subtitle: widget.caseFile?.intakeNo,
              leading: AppCircleIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => context.pop(),
              ),
            ),
            Expanded(
              child: c == null
                  ? const Center(
                      child: AppEmptyState(
                        icon: Icons.block_rounded,
                        title: 'Not open on this case',
                        message: 'Go back to the case and choose again.',
                      ),
                    )
                  : Form(
                      key: c.formKey,
                      // A column, not a list, so validate() reaches every field.
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            AppEntrance(
                              child: IntakeDecisionSummary(file: c.caseFile),
                            ),
                            ..._notes(c),
                            if (c.needsDestination) ...<Widget>[
                              const SizedBox(height: 16),
                              AppEntrance(
                                index: 2,
                                child: AppFormSection(
                                  step: '1',
                                  title: 'Where it goes',
                                  required: true,
                                  child: Obx(
                                    () => AppOptionDropdown<String>(
                                      items: c.option.destinations,
                                      itemTitle: _destination,
                                      itemDescription: _destinationNote,
                                      itemIcon: _destinationIcon,
                                      value: c.destination.value,
                                      hint: 'Choose where it goes',
                                      onChanged: c.chooseDestination,
                                      validator: c.validateDestination,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            AppEntrance(
                              index: 3,
                              child: AppFormSection(
                                step: c.needsDestination ? '2' : '1',
                                title: 'Remarks',
                                optional: !c.remarksRequired,
                                required: c.remarksRequired,
                                note: c.isReject
                                    ? '${IntakeDecisionRequest.remarksMin} to '
                                          '${IntakeDecisionRequest.remarksMax} '
                                          'characters.'
                                    : null,
                                child: AppTextField(
                                  hint: 'What the next officer should know',
                                  controller: c.remarksController,
                                  maxLines: 5,
                                  optional: !c.remarksRequired,
                                  validator: c.validateRemarks,
                                  onChanged: (_) => c.markEdited(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            AppEntrance(
                              index: 4,
                              child: AppFormSection(
                                step: c.needsDestination ? '3' : '2',
                                title: 'Attachments',
                                optional: true,
                                trailing: Obx(() {
                                  final int added = c.attachments.length;
                                  const int max =
                                      IntakeDecisionRequest.maxAttachments;
                                  return AppStatusBadge(
                                    label: '$added/$max added',
                                    icon: Icons.photo_library_outlined,
                                    tone: added == max
                                        ? AppTone.success
                                        : AppTone.primary,
                                  );
                                }),
                                child: _Attachments(controller: c),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
        bottomNavigationBar: c == null
            ? null
            : _SubmitBar(controller: c, label: title, onSubmit: _submit),
      ),
    );
  }

  static String _destination(String value) => switch (value) {
    'estate' => 'Estate',
    'taxation' => 'Taxation',
    'cmo' => 'The CMO',
    _ => IntakeLabels.branch(value),
  };

  static String? _destinationNote(String value) => switch (value) {
    'estate' => 'Return the case for corrections',
    'taxation' => 'Ask Taxation a query',
    'cmo' => 'Ask the CMO a query',
    _ => null,
  };

  static IconData _destinationIcon(String value) => switch (value) {
    'estate' => Icons.undo_rounded,
    'taxation' => Icons.receipt_long_outlined,
    'cmo' => Icons.account_balance_outlined,
    _ => Icons.apartment_outlined,
  };

  /// What this act means, said before it is taken.
  static List<Widget> _notes(AgreementDecisionController c) {
    final String? text = switch (c.option.act) {
      'endorse' =>
        'Endorsing recommends the case to the Administrator. It is not '
            'approval.',
      'approve' =>
        'Approval does not create the agreement — Estate activates it. The '
            'case goes back to the CMO for dispatch.',
      'reject' => 'Rejecting ends this case. It cannot be undone here.',
      'dispatch' => 'Sends the approved case on to Taxation.',
      'respond' => 'Answers the query open at your stage.',
      _ => null,
    };
    return <Widget>[
      if (text != null) ...<Widget>[
        const SizedBox(height: 14),
        AppEntrance(
          index: 1,
          child: AppAlert(
            tone: c.isReject ? AppTone.danger : AppTone.accent,
            icon: c.isReject
                ? Icons.warning_amber_rounded
                : Icons.info_outline_rounded,
            message: text,
          ),
        ),
      ],
    ];
  }
}

class _Attachments extends StatelessWidget {
  const _Attachments({required this.controller});

  final AgreementDecisionController controller;

  static const double _gap = 8;

  /// Four to a row on a phone; never larger than this on a tablet.
  static const int _across = 4;
  static const double _maxSide = 104;

  Future<void> _fromGallery(BuildContext context) async {
    final int room = controller.attachmentsLeft;
    await controller.attach(fromGallery: true);
    final int skipped = controller.lastSkipped;
    if (skipped == 0 || !context.mounted) return;
    AppSnackBar.show(
      context,
      'Only $room more ${room == 1 ? 'picture fits' : 'pictures fit'} — '
      '$skipped left out.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<String> files = controller.attachments.toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (files.isNotEmpty) ...<Widget>[
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints box) {
                final double side = math.min(
                  (box.maxWidth - _gap * (_across - 1)) / _across,
                  _maxSide,
                );
                return Wrap(
                  spacing: _gap,
                  runSpacing: _gap,
                  children: <Widget>[
                    // Unkeyed: the same picture may be attached twice.
                    for (int i = 0; i < files.length; i++)
                      _PhotoTile(
                        path: files[i],
                        side: side,
                        onRemove: () => controller.removeAttachment(i),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
          ],
          if (controller.canAttachMore)
            Row(
              children: <Widget>[
                Expanded(
                  child: AppButton(
                    label: 'Camera',
                    icon: Icons.photo_camera_outlined,
                    variant: AppButtonVariant.outline,
                    height: 44,
                    onPressed: () => controller.attach(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: 'Gallery',
                    icon: Icons.photo_library_outlined,
                    variant: AppButtonVariant.outline,
                    height: 44,
                    onPressed: () => _fromGallery(context),
                  ),
                ),
              ],
            ),
        ],
      );
    });
  }
}

/// A picked picture as a square tile, with a cross to take it back out.
class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.path,
    required this.side,
    required this.onRemove,
  });

  final String path;
  final double side;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SizedBox.square(
      dimension: side,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                child: Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  // Decoded at tile size, not the photo's full 1600px.
                  cacheWidth: (side * MediaQuery.devicePixelRatioOf(context))
                      .round(),
                  errorBuilder: (_, _, _) => Icon(
                    Icons.broken_image_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          // A small mark on a small tile, but a 28px target around it.
          Positioned(
            top: 0,
            right: 0,
            child: Semantics(
              button: true,
              label: 'Remove picture',
              child: AppPress(
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    height: 22,
                    width: 22,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.85),
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.controller,
    required this.label,
    required this.onSubmit,
  });

  final AgreementDecisionController controller;
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
            controller.revision.value;
            final List<String> missing = controller.missing;
            final String? error = controller.errorMessage.value;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (missing.isNotEmpty) ...<Widget>[
                  AppAlert(
                    message: 'Still needed: ${missing.join(' and ')}.',
                    tone: AppTone.warning,
                    icon: Icons.edit_note_rounded,
                    compact: true,
                  ),
                  const SizedBox(height: 10),
                ],
                if (error != null) ...<Widget>[
                  AppAlert(message: error, compact: true),
                  const SizedBox(height: 10),
                ],
                // Beside the button it describes: pressing it signs.
                if (controller.option.signed) ...<Widget>[
                  const AppAlert(
                    tone: AppTone.info,
                    icon: Icons.draw_outlined,
                    message:
                        'This act is signed with the signature on your '
                        'profile.',
                    compact: true,
                  ),
                  const SizedBox(height: 10),
                ],
                AppButton(
                  // A resend carries the same client_uuid: it lands once.
                  label: error == null ? label : 'Send it again',
                  variant: controller.isReject
                      ? AppButtonVariant.danger
                      : AppButtonVariant.primary,
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
