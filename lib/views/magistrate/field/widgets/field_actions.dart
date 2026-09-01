import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../controllers/api/session_controller.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../data/api/repositories/enforcement_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/auth/permissions.dart';
import '../../../../models/enforcement/field_evidence.dart';
import '../../../../models/field/field_card.dart';
import '../../../../widgets/widgets.dart';
import '../../api/case_write_args.dart';

/// Everything the action sheet needs to know about what it is acting on.
///
/// Built from a [FieldCard] wherever there is one, so opening the sheet
/// from a defaulter row, a follow-up or a round stop costs no round trip —
/// which matters, because the moment an officer needs it he is standing in
/// a bazaar on one bar of signal.
class ActionTarget {
  const ActionTarget({
    required this.propertyId,
    required this.shopLabel,
    required this.allotteeName,
    this.allotmentId,
    this.caseId,
    this.sealId,
    this.isSealed = false,
    this.canFineHolder = true,
    this.needsOffenderDetails = false,
    this.hasLiveStay = false,
    this.stayMessage,
  });

  final int propertyId;
  final String shopLabel;
  final String allotteeName;
  final int? allotmentId;
  final int? caseId;
  final int? sealId;
  final bool isSealed;

  /// False when there is no live agreement to bill. A vacant unit cannot be
  /// fined through its tenancy — the server returns 422 — so the fine
  /// action is hidden rather than offered and refused.
  final bool canFineHolder;

  final bool needsOffenderDetails;

  /// A court stay blocks the seal, the fine and the magistrate assignment.
  /// When the Law Branch has recorded one, those actions come off the sheet
  /// and the server's own sentence — which names the case — is shown in
  /// their place.
  final bool hasLiveStay;
  final String? stayMessage;

  factory ActionTarget.fromCard(FieldCard card) => ActionTarget(
        propertyId: card.propertyId,
        shopLabel: card.unitLabel,
        allotteeName: card.allotteeName ?? '',
        allotmentId: card.allotmentId,
        caseId: card.openCaseId,
        isSealed: card.isSealed,
        // A vacant unit has no holder to bill; the server says so and the
        // app trusts the flag rather than working it out itself.
        canFineHolder: card.canFineHolder && !card.isVacant,
        needsOffenderDetails: card.needsOffenderDetails || card.isVacant,
      );

  ActionTarget copyWith({
    int? caseId,
    int? sealId,
    bool? isSealed,
    bool? hasLiveStay,
    String? stayMessage,
  }) =>
      ActionTarget(
        propertyId: propertyId,
        shopLabel: shopLabel,
        allotteeName: allotteeName,
        allotmentId: allotmentId,
        caseId: caseId ?? this.caseId,
        sealId: sealId ?? this.sealId,
        isSealed: isSealed ?? this.isSealed,
        canFineHolder: canFineHolder,
        needsOffenderDetails: needsOffenderDetails,
        hasLiveStay: hasLiveStay ?? this.hasLiveStay,
        stayMessage: stayMessage ?? this.stayMessage,
      );

  CaseWriteArgs get writeArgs => CaseWriteArgs(
        shopLabel: shopLabel,
        allotteeName: allotteeName,
        caseId: caseId,
        sealId: sealId,
        propertyId: propertyId,
      );

  /// "Shop P-1 — Nadeem Ahmed". Named on every confirmation, because
  /// sealing the wrong shop is a real-world event with a real-world
  /// consequence for a real family's income.
  String get describe =>
      allotteeName.isEmpty ? shopLabel : '$shopLabel — $allotteeName';
}

/// The action sheet — the important part of the profile.
///
/// Two rules decide what appears on it, and both of them are about not
/// wasting an officer's five minutes:
///
/// * **Gate on the officer's own `permissions`.** An action his account
///   cannot perform is never offered. A button that will be refused is
///   worse than no button.
/// * **Hide, do not disable, what the domain forbids.** A vacant unit
///   cannot be fined through its tenancy; a shop with no case open cannot
///   be sealed; a shop under a court stay cannot be either. A greyed-out
///   row asks the officer to work out why, standing in a bazaar, and he
///   cannot.
class FieldActions {
  FieldActions._();

  static Future<void> show(
    BuildContext context, {
    required ActionTarget target,
    VoidCallback? onChanged,
  }) {
    final session = Get.find<SessionController>();
    final actions = <AppSheetAction>[];

    final canRecord = session.can(Permissions.actionRecord);
    final hasCase = target.caseId != null;

    // --- The four cheap wins, all one write on an open case -------------
    if (canRecord && hasCase) {
      actions.addAll([
        AppSheetAction(
          icon: Icons.assignment_turned_in_rounded,
          label: t('actions.recordVisit'),
          description: t('actions.recordVisitHelp'),
          onTap: () => _record(context, target, FieldWriteEnums.siteVisit,
              onChanged: onChanged),
        ),
        AppSheetAction(
          icon: Icons.campaign_rounded,
          label: t('actions.giveWarning'),
          description: t('actions.giveWarningHelp'),
          tone: AppTone.warning,
          onTap: () => _record(context, target, FieldWriteEnums.verbalWarning,
              onChanged: onChanged),
        ),
        AppSheetAction(
          icon: Icons.handshake_rounded,
          label: t('actions.takePromise'),
          description: t('actions.takePromiseHelp'),
          tone: AppTone.warning,
          onTap: () => _record(context, target, FieldWriteEnums.paymentPromised,
              onChanged: onChanged),
        ),
        AppSheetAction(
          icon: Icons.event_repeat_rounded,
          label: t('actions.setReminder'),
          description: t('actions.setReminderHelp'),
          tone: AppTone.info,
          onTap: () => _record(
              context, target, FieldWriteEnums.reminderVisitSet,
              onChanged: onChanged),
        ),
      ]);
    }

    // --- Opening the file ------------------------------------------------
    if (!hasCase &&
        target.allotmentId != null &&
        session.can(Permissions.caseManage)) {
      actions.add(
        AppSheetAction(
          icon: Icons.create_new_folder_rounded,
          label: t('actions.openCase'),
          description: t('actions.openCaseHelp'),
          onTap: () => _openCase(context, target, onChanged: onChanged),
        ),
      );
    }

    // --- The heavy end ---------------------------------------------------
    // A court stay takes all three off the sheet. The server would refuse
    // them anyway; refusing them here means the officer does not promise a
    // shopkeeper something that is about to be taken back.
    if (!target.hasLiveStay) {
      if (target.canFineHolder || target.needsOffenderDetails) {
        if (session.can(Permissions.fineImpose)) {
          actions.add(
            AppSheetAction(
              icon: Icons.gavel_rounded,
              label: t('actions.imposeFine'),
              description: target.needsOffenderDetails
                  ? t('actions.imposeFineOffenderHelp')
                  : t('actions.imposeFineHelp'),
              tone: AppTone.danger,
              onTap: () => context
                  .push(
                    AppRoutes.imposeFinePath(target.propertyId),
                    extra: target,
                  )
                  .then((_) => onChanged?.call()),
            ),
          );
        }
      }

      if (!target.isSealed &&
          hasCase &&
          session.can(Permissions.sealApply)) {
        actions.add(
          AppSheetAction(
            icon: Icons.lock_rounded,
            label: t('actions.sealShop'),
            description: t('actions.sealShopHelp'),
            destructive: true,
            onTap: () => context
                .push(
                  AppRoutes.sealCasePath(target.caseId!),
                  extra: target.writeArgs,
                )
                .then((_) => onChanged?.call()),
          ),
        );
      }
    }

    if (target.isSealed &&
        target.sealId != null &&
        session.can(Permissions.sealRelease)) {
      actions.add(
        AppSheetAction(
          icon: Icons.lock_open_rounded,
          label: t('actions.releaseSeal'),
          description: t('actions.releaseSealHelp'),
          tone: AppTone.success,
          onTap: () => context
              .push(
                AppRoutes.releaseSealPath(target.sealId!),
                extra: target.writeArgs,
              )
              .then((_) => onChanged?.call()),
        ),
      );
    }

    return AppActionSheet.show(
      context,
      title: t('actions.title'),
      subtitle: target.describe,
      actions: actions,
      // Hiding the seal and the fine is right; hiding them silently is
      // not. The officer is told why, in the server's own words where
      // there are any — they name the court case.
      notice: target.hasLiveStay
          ? AppBanner(
              tone: AppStatusTone.warning,
              icon: Icons.balance_rounded,
              title: t('actions.stayTitle'),
              message: target.stayMessage ?? t('actions.stayBlocks'),
            )
          : null,
      emptyMessage: target.hasLiveStay
          // The server's own sentence, which names the court case.
          ? (target.stayMessage ?? t('actions.stayBlocks'))
          : hasCase
              ? t('actions.nonePermitted')
              : t('actions.noCaseYet'),
    );
  }

  /// Opens the record-action form with the type already chosen.
  ///
  /// A promise or a revisit then needs only its date, which the form asks
  /// for with the quick options a shopkeeper actually uses — "in one week",
  /// "end of the month".
  static void _record(
    BuildContext context,
    ActionTarget target,
    String actionType, {
    VoidCallback? onChanged,
  }) {
    context
        .push(
          AppRoutes.recordActionPath(target.caseId!),
          extra: target.writeArgs.withActionType(actionType),
        )
        .then((_) => onChanged?.call());
  }

  /// Opening a case is not a field write — there is no evidence, no GPS and
  /// no photograph, only a decision to start a file. So it is a
  /// confirmation and one request, rather than a form.
  static Future<void> _openCase(
    BuildContext context,
    ActionTarget target, {
    VoidCallback? onChanged,
  }) async {
    final confirmed = await AppConfirmDialog.ask(
      context,
      title: t('actions.openCase'),
      body: t('actions.openCaseConfirm', args: {'shop': target.describe}),
      confirmLabel: t('actions.openCase'),
      destructive: false,
    );
    if (!confirmed) return;

    try {
      final outcome = await Get.find<EnforcementRepository>()
          .openCase(allotmentId: target.allotmentId!);
      AppHaptics.success();
      AppFeedback.toast(
        outcome.message ??
            // 201 created; 200 means the case already existed. Never
            // announce it twice.
            (outcome.wasCreated
                ? t('actions.caseOpened')
                : t('actions.caseAlreadyOpen')),
      );
      onChanged?.call();
    } on ApiException catch (error) {
      if (error.isConflict) {
        await AppFeedback.serverRefusal(error.message);
      } else if (!error.isForbidden) {
        AppFeedback.toast(error.message, isError: true);
      }
    }
  }
}
