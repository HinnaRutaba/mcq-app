import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../controllers/api/session_controller.dart';
import '../../../controllers/field/field_seals_controller.dart';
import '../../../core/utils/dialer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/auth/permissions.dart';
import '../../../models/field/field_seal.dart';
import '../../../widgets/widgets.dart';
import '../api/case_write_args.dart';
import 'widgets/field_list_view.dart';
import 'widgets/field_seal_card.dart';

/// Seals — and the unseal queue.
///
/// **One list, two readings**, which is deliberate. MCQ asked both for
/// "what have I sealed" and "what now needs unsealing", and splitting them
/// into two screens would let them drift and leave a seal in neither. So
/// this is one request, split into two tabs of the same rows: everything
/// sealed, and the ones the server says are ready to release.
///
/// The tabs carry their counts, because the count on the second one is the
/// whole reason to look at this screen — a seal that is ready and left
/// standing is MCQ holding a shop closed after the reason has gone.
class FieldSealsScreen extends StatefulWidget {
  const FieldSealsScreen({super.key, this.readyOnly = false});

  /// True when the officer arrived from the home screen's "Ready to
  /// unseal" tile — that tab opens selected.
  final bool readyOnly;

  @override
  State<FieldSealsScreen> createState() => _FieldSealsScreenState();
}

class _FieldSealsScreenState extends State<FieldSealsScreen>
    with SingleTickerProviderStateMixin {
  // Tagged by which reading it opened on — "everything I have sealed" and
  // "ready to unseal" are the same list, but not the same question.
  late final String _tag = 'seals-${widget.readyOnly ? 'ready' : 'all'}';
  late final FieldSealsController _controller = Get.put(
    FieldSealsController.resolve(readyFirst: widget.readyOnly),
    tag: _tag,
  );
  late final TabController _tabs = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.readyOnly ? 1 : 0,
  );

  @override
  void initState() {
    super.initState();
    // The controller's own reading follows the tab, so anything that reads
    // `onlyReady` (the empty state's wording, chiefly) stays honest.
    _tabs.addListener(() => _controller.showOnlyReady(_tabs.index == 1));
  }

  @override
  void dispose() {
    _tabs.dispose();
    Get.delete<FieldSealsController>(tag: _tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    final canRelease = session.can(Permissions.sealRelease);

    return Scaffold(
      appBar: AppBar(
        title: AppText.titleLarge(t('seals.title')),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Obx(
              () => _CountedTab(
                label: t('seals.tabAll'),
                icon: Icons.lock_rounded,
                count: _controller.rows.length,
              ),
            ),
            Obx(
              () => _CountedTab(
                label: t('seals.tabReady'),
                icon: Icons.lock_open_rounded,
                count: _controller.readyCount,
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _SealList(
            controller: _controller,
            rowsOf: (c) => c.ordered,
            canRelease: canRelease,
            onRelease: _release,
            emptyTitle: 'seals.none',
            emptyMessage: 'seals.noneHelp',
          ),
          _SealList(
            controller: _controller,
            rowsOf: (c) => c.ready,
            canRelease: canRelease,
            onRelease: _release,
            emptyTitle: 'seals.noneReady',
            emptyMessage: 'seals.noneReadyHelp',
          ),
        ],
      ),
    );
  }

  void _release(FieldSeal seal) {
    context
        .push(
          AppRoutes.releaseSealPath(seal.sealId),
          extra: CaseWriteArgs(
            shopLabel: seal.unitLabel,
            allotteeName: seal.allotteeName,
            caseId: seal.caseId,
            sealId: seal.sealId,
            propertyId: seal.propertyId,
          ),
        )
        .then((_) => _controller.reload(refreshing: true));
  }
}

/// One tab: a glyph, a word and the count. The count is not decoration —
/// it is what tells the officer whether the other tab is worth opening.
class _CountedTab extends StatelessWidget {
  const _CountedTab({
    required this.label,
    required this.icon,
    required this.count,
  });

  final String label;
  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 54,
      icon: null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 7),
          Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 7),
          Badge.count(
            count: count,
            backgroundColor: Theme.of(context).colorScheme.primary,
            textColor: Theme.of(context).colorScheme.onPrimary,
            isLabelVisible: count > 0,
          ),
        ],
      ),
    );
  }
}

/// One tab's list. Both tabs are the same rows read two ways, so both go
/// through [FieldListView] and neither can empty itself on a failure.
class _SealList extends StatelessWidget {
  const _SealList({
    required this.controller,
    required this.rowsOf,
    required this.canRelease,
    required this.onRelease,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final FieldSealsController controller;
  final List<FieldSeal> Function(FieldSealsController) rowsOf;
  final bool canRelease;
  final void Function(FieldSeal) onRelease;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rows = rowsOf(controller);

      return FieldListView(
        isLoading: controller.isLoading.value,
        isEmpty: rows.isEmpty && !controller.isLoading.value,
        isStale: controller.isStale.value,
        fetchedAt: controller.fetchedAt.value,
        failureMessage: controller.failure.value?.message,
        onRefresh: () => controller.reload(refreshing: true),
        skeletonCount: 3,
        emptyState: AppEmptyState(
          illustration: AppIllustrationKind.shopSealed,
          title: t(emptyTitle),
          message: t(emptyMessage),
        ),
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            AppStaggerIn(
              index: i,
              enabled: controller.isFirstLoad.value,
              child: FieldSealCard(
                seal: rows[i],
                onTap: () => context.push(
                  AppRoutes.propertyProfilePath(rows[i].propertyId),
                ),
                onCall: rows[i].isCallable
                    ? () => Dialer.call(rows[i].mobileNo)
                    : null,
                onRelease: canRelease ? () => onRelease(rows[i]) : null,
              ),
            ),
          ],
        ],
      );
    });
  }
}
