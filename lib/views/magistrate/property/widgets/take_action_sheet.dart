import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../config/theme/app_brand.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../controllers/definitions_controller.dart';
import '../../../../models/enforcement_definitions.dart';
import '../../../../widgets/widgets.dart';

class TakeActionSheet extends StatefulWidget {
  const TakeActionSheet({super.key, this.definitions});

  /// Injected by a test or a preview. Null resolves the app's own singleton.
  final DefinitionsController? definitions;

  static Future<ActionTypeDefinition?> show(
    BuildContext context, {
    GlobalKey? from,
  }) {
    return AppContainerSheet.show<ActionTypeDefinition>(
      context,
      from: from,
      fromColor: context.brand.accent,
      builder: (BuildContext context) => const TakeActionSheet(),
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
      // As tall as the register needs, and no taller than this: the sheet is a
      // choice, and the shop is still behind it. A register of three rows is a
      // sheet of three rows.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const AppText.titleLarge('Take action'),
                const SizedBox(height: 4),
                AppText.caption(
                  'What happened at the shop, as MCQ publishes it.',
                  color: muted,
                ),
              ],
            ),
          ),
          Flexible(
            child: Obx(() {
              final List<ActionTypeDefinition> types = _definitions.actionTypes;
              final bool ready = _definitions.isReady;
              final String? error = _definitions.errorMessage.value;
              final bool loading = _definitions.isLoading.value;

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
              if (types.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.rule_folder_outlined,
                  title: 'No actions published',
                  message:
                      'MCQ has not published anything that can go on a case '
                      'yet.',
                );
              }

              return ListView(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  // Clear of the home indicator: this sheet paints to the
                  // bottom edge rather than being inset from it.
                  24 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                children: <Widget>[
                  for (final (int at, ActionTypeDefinition type)
                      in types.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      // Held back until the sheet has grown, then one after
                      // another — a list that is already sitting there when
                      // the surface arrives reads as a screenshot.
                      child: AppEntrance(
                        index: at,
                        delay: _staggerAfter,
                        child: _ActionRow(
                          type: type,
                          onTap: () => Navigator.of(context).pop(type),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.type, required this.onTap});

  final ActionTypeDefinition type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final AppTone tone = _toneFor(type.code);
    final String? needs = _needs(type.fields);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: tone.container(context),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(_iconFor(type.code), color: tone.on(context)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: [
                    Expanded(
                      child: AppText.body(
                        type.name,
                        fontWeight: FontWeight.w700,
                        maxLines: 2,
                      ),
                    ),
                    if (type.nameUr != null) ...<Widget>[
                      const SizedBox(height: 2),
                      AppText.label(type.nameUr!, color: muted, maxLines: 1),
                    ],
                  ],
                ),

                if (type.description != null) ...<Widget>[
                  const SizedBox(height: 3),
                  AppText.caption(type.description!, color: muted, maxLines: 2),
                ],
                if (needs != null) ...<Widget>[
                  const SizedBox(height: 6),
                  AppStatusBadge(label: needs),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.chevron_right_rounded, size: 20, color: muted),
        ],
      ),
    );
  }
}

/// What the action carries beyond a date and a remark, read off the server's
/// own `fields` block — so the officer knows what the form will ask for
/// before they pick it.
String? _needs(ActionTypeFields fields) {
  final List<String> parts = <String>[
    if (fields.promiseDate) 'a promised date',
    if (fields.visitDate) 'a return date',
    if (fields.amount) 'an amount',
    if (fields.sealNo) 'a seal number',
  ];
  if (parts.isEmpty) return null;
  return 'Needs ${parts.join(' and ')}';
}

/// A glyph for the codes MCQ publishes today, and a neutral one for anything
/// added since — the list is the server's, so this cannot be exhaustive.
IconData _iconFor(String code) => switch (code) {
  'site_visit' => Icons.storefront_outlined,
  'verbal_warning' => Icons.campaign_outlined,
  'final_warning' => Icons.warning_amber_rounded,
  'notice_served' => Icons.description_outlined,
  'payment_promised' => Icons.handshake_outlined,
  'reminder_visit_set' => Icons.event_repeat_outlined,
  'fine_imposed' => Icons.gavel_rounded,
  'seal' => Icons.lock_outline_rounded,
  'unseal' => Icons.lock_open_rounded,
  'case_closed' => Icons.task_alt_rounded,
  _ => Icons.assignment_outlined,
};

/// How hard the step is on the shopkeeper: a visit is a visit, a final warning
/// and a seal are not.
AppTone _toneFor(String code) => switch (code) {
  'final_warning' || 'fine_imposed' || 'seal' => AppTone.danger,
  'notice_served' || 'verbal_warning' => AppTone.warning,
  'payment_promised' || 'case_closed' || 'unseal' => AppTone.success,
  _ => AppTone.primary,
};
