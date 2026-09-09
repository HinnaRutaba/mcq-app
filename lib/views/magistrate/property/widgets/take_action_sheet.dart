import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_brand.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../controllers/definitions_controller.dart';
import '../../../../models/enforcement_definitions.dart';
import '../../../../models/shop_action.dart';
import '../../../../widgets/widgets.dart';

/// The steps an officer can take on one shop.
///
/// The rows are [ShopAction] — the app's own list, worded as the choice being
/// made and ordered roughly as enforcement escalates. What each row *posts* is
/// still the register's: the matching `ActionTypeDefinition` is looked up by
/// code and handed back with the choice, so an action MCQ renames or reprices
/// arrives here without an app release. A step the register has switched off
/// is shown and refused rather than quietly dropped — an officer who cannot
/// find "Give a warning" will assume the app is broken.
class TakeActionSheet extends StatefulWidget {
  const TakeActionSheet({
    super.key,
    this.sealed = false,
    this.hasOpenCase = false,
    this.definitions,
  });

  /// Whether the shop stands sealed — the row is a release rather than a seal.
  final bool sealed;

  /// Whether there is a case to record against. Without one, the steps that
  /// need a case say that they will open it.
  final bool hasOpenCase;

  /// Injected by a test or a preview. Null resolves the app's own singleton.
  final DefinitionsController? definitions;

  /// The step the officer picked, or null if they closed the sheet.
  ///
  /// [from] is the control that opened it — the sheet grows out of that
  /// button's own rectangle rather than sliding up from nowhere.
  static Future<ShopActionChoice?> show(
    BuildContext context, {
    GlobalKey? from,
    bool sealed = false,
    bool hasOpenCase = false,
  }) {
    return AppContainerSheet.show<ShopActionChoice>(
      context,
      from: from,
      fromColor: context.brand.accent,
      builder: (BuildContext context) =>
          TakeActionSheet(sealed: sealed, hasOpenCase: hasOpenCase),
    );
  }

  @override
  State<TakeActionSheet> createState() => _TakeActionSheetState();
}

/// When the rows start arriving — as the growing surface finishes, so they
/// land on a sheet rather than inside a moving hole.
const Duration _staggerAfter = Duration(milliseconds: 240);

class _TakeActionSheetState extends State<TakeActionSheet> {
  late final DefinitionsController _definitions =
      widget.definitions ?? Get.find<DefinitionsController>();

  @override
  void initState() {
    super.initState();
    // Normally already in hand — the rows are fetched at sign-in. This is for
    // the officer who signed in on a dead signal and is now in a bazaar.
    _definitions.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return ConstrainedBox(
      // As tall as the list needs, and no taller. Eight steps is more than
      // three quarters of a handset, and the last of them — the seal — is the
      // one an officer must not have to go looking for.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // Stretched, or the header shrinks to its own text and is centred
        // over rows that run the full width.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Expanded(child: AppText.titleLarge('Take action')),
                    const SizedBox(width: 8),
                    // The library's round button rather than a bare icon: it
                    // carries a 36pt tap target and a ripple, and a glyph on
                    // its own is neither.
                    AppCircleIconButton(
                      icon: Icons.close_rounded,
                      size: 36,
                      background: AppTone.neutral.container(context),
                      iconColor: AppTone.neutral.on(context),
                      onTap: () => context.pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                AppText.caption(
                  'Roughly in the order they escalate.',
                  color: muted,
                ),
              ],
            ),
          ),
          // Read here, in the builder: the register lands after the sheet is
          // up on the one round a signal cost, and a read in a child's build
          // would register with nothing.
          Flexible(
            child: Obx(() {
              final bool ready = _definitions.isReady;
              final String? error = _definitions.errorMessage.value;
              final bool loading = _definitions.isLoading.value;
              final List<ActionTypeDefinition> types = _definitions.actionTypes;

              if (!ready && loading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                );
              }
              if (!ready && error != null) {
                return AppErrorRetry(
                  title: 'Could not load the actions',
                  message: error,
                  onRetry: _definitions.reload,
                );
              }
              // Loaded and empty is a misconfigured register, not a shop with
              // nothing to do about it — every row would be refused.
              if (types.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.rule_folder_outlined,
                  title: 'No actions published',
                  message:
                      'MCQ has not published anything that can go on a case '
                      'yet.',
                );
              }

              return _steps(context, types);
            }),
          ),
        ],
      ),
    );
  }

  Widget _steps(BuildContext context, List<ActionTypeDefinition> types) {
    final List<ShopAction> steps = ShopAction.forShop(sealed: widget.sealed);

    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        // Clear of the home indicator: this sheet paints to the bottom edge
        // rather than being inset from it.
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: <Widget>[
        for (final (int at, ShopAction step) in steps.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            // Held back until the sheet has grown, then one after another — a
            // list already sitting there when the surface arrives reads as a
            // screenshot.
            child: AppEntrance(
              index: at,
              delay: _staggerAfter,
              child: _StepRow(
                step: step,
                definition: _rowFor(step),
                note: _noteFor(step),
                onTap: _offers(step)
                    ? () => context.pop(
                        ShopActionChoice(step, definition: _rowFor(step)),
                      )
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  /// The register's row for a step, or null where the step is not an action
  /// type at all — a new case is its own endpoint.
  ActionTypeDefinition? _rowFor(ShopAction step) {
    final String? code = step.code;
    return code == null ? null : _definitions.actionType(code);
  }

  /// Whether the step can be taken. A step MCQ has switched off cannot be
  /// posted, so the row is refused rather than failing at a shop counter.
  bool _offers(ShopAction step) => step.code == null || _rowFor(step) != null;

  /// A pill under the description, for what this shop's state changes about
  /// the step, or why it cannot be taken at all.
  ///
  /// Not what the form will ask for: the register's `fields` block says a
  /// promise needs a date, and so does the step's own description — the same
  /// fact twice on one row.
  String? _noteFor(ShopAction step) {
    if (!_offers(step)) return 'MCQ has switched this off';
    if (step.needsCase && !widget.hasOpenCase) return 'Opens a case first';
    if (step == ShopAction.openCase && widget.hasOpenCase) {
      return 'One case is already open';
    }
    return null;
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.definition,
    required this.note,
    required this.onTap,
  });

  final ShopAction step;

  /// The register's row behind this step, where it has one.
  final ActionTypeDefinition? definition;

  final String? note;

  /// Null where the step cannot be taken.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final bool offered = onTap != null;
    final AppTone tone = _toneFor(step);

    return Opacity(
      // Dimmed rather than hidden: the list is the same length whatever MCQ
      // has switched off, so an officer can see what is missing.
      opacity: offered ? 1 : 0.5,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: <Widget>[
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: tone.container(context),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(_iconFor(step), color: tone.on(context)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppText.body(
                    step.label,
                    fontWeight: FontWeight.w700,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 2),
                  AppText.caption(step.description, color: muted, maxLines: 2),
                  if (note != null) ...<Widget>[
                    const SizedBox(height: 6),
                    AppStatusBadge(label: note!),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              offered ? Icons.chevron_right_rounded : Icons.block_rounded,
              size: 20,
              color: muted,
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(ShopAction step) => switch (step) {
  ShopAction.visit => Icons.storefront_outlined,
  ShopAction.warn => Icons.campaign_outlined,
  ShopAction.promise => Icons.handshake_outlined,
  ShopAction.remind => Icons.event_repeat_outlined,
  ShopAction.fine => Icons.gavel_rounded,
  ShopAction.openCase => Icons.create_new_folder_outlined,
  ShopAction.seal => Icons.lock_outline_rounded,
  ShopAction.unseal => Icons.lock_open_rounded,
};

/// How hard the step is on the shopkeeper: a visit is a visit, a fine and a
/// seal are not.
AppTone _toneFor(ShopAction step) => switch (step) {
  ShopAction.visit => AppTone.primary,
  ShopAction.warn => AppTone.warning,
  ShopAction.promise => AppTone.success,
  ShopAction.remind => AppTone.info,
  ShopAction.fine || ShopAction.seal => AppTone.danger,
  ShopAction.openCase => AppTone.warning,
  ShopAction.unseal => AppTone.success,
};
