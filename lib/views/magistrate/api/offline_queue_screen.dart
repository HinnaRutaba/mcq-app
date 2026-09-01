import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/theme/app_colors.dart';
import '../../../controllers/api/offline_queue_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/offline/queued_write.dart';
import '../../../widgets/widgets.dart';
import 'widgets/queued_write_tile.dart';

/// What has not synced yet.
///
/// A visible list with a retry, because an officer needs to know whether
/// the seal they recorded actually landed. **Nothing is ever dropped for
/// them**: a write the server refused sits here with the server's own
/// sentence until the officer decides what to do about it.
///
/// Two tabs, because they are two different jobs. The first is a queue that
/// will empty itself when the signal comes back and needs nothing from the
/// officer. The second is a pile of refusals that will never clear on their
/// own, and each one is a thing he recorded standing in front of a shop.
/// Mixing them lets the second hide inside the first.
class OfflineQueueScreen extends StatefulWidget {
  const OfflineQueueScreen({super.key});

  @override
  State<OfflineQueueScreen> createState() => _OfflineQueueScreenState();
}

class _OfflineQueueScreenState extends State<OfflineQueueScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OfflineQueueController>();

    return Scaffold(
      appBar: AppBar(
        title: AppText.titleLarge(t('queue.title')),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Obx(
              () => _QueueTab(
                label: t('queue.tabWaiting'),
                icon: Icons.cloud_upload_outlined,
                count: controller.pendingCount,
                tone: AppStatusTone.warning,
              ),
            ),
            Obx(
              () => _QueueTab(
                label: t('queue.tabAttention'),
                icon: Icons.report_gmailerrorred_rounded,
                count: controller.attentionCount,
                tone: AppStatusTone.danger,
              ),
            ),
          ],
        ),
      ),
      // Syncing is the one thing this screen is for, so it gets the
      // button rather than an icon in the bar.
      floatingActionButton: Obx(
        () => FloatingActionButton.extended(
          onPressed: controller.isSyncing.value || !controller.isOnline.value
              ? null
              : () {
                  AppHaptics.select();
                  controller.drain();
                },
          backgroundColor: controller.isSyncing.value || !controller.isOnline.value
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : null,
          foregroundColor: controller.isSyncing.value || !controller.isOnline.value
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : null,
          icon: controller.isSyncing.value
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              : const Icon(Icons.sync_rounded),
          label: Text(t('queue.syncNow')),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _QueueList(
            controller: controller,
            rowsOf: (c) => c.items.where((item) => !item.isBlocked).toList(),
            emptyIllustration: AppIllustrationKind.allSynced,
            emptyTitle: 'queue.empty',
            emptyMessage: 'queue.emptyHelp',
          ),
          _QueueList(
            controller: controller,
            rowsOf: (c) => c.needsAttention,
            emptyIllustration: AppIllustrationKind.allClear,
            emptyTitle: 'queue.empty',
            emptyMessage: 'queue.emptyHelp',
            noticeTone: AppStatusTone.danger,
            noticeTitle: 'queue.conflict',
            noticeMessage: 'queue.conflictHelp',
          ),
        ],
      ),
    );
  }
}

class _QueueTab extends StatelessWidget {
  const _QueueTab({
    required this.label,
    required this.icon,
    required this.count,
    required this.tone,
  });

  final String label;
  final IconData icon;
  final int count;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colour = tone.tone.on(context);
    return Tab(
      height: 54,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 7),
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 7),
          Badge.count(
            count: count,
            backgroundColor: colour,
            textColor: tone.tone.onFilled(context),
            isLabelVisible: count > 0,
          ),
        ],
      ),
    );
  }
}

class _QueueList extends StatelessWidget {
  const _QueueList({
    required this.controller,
    required this.rowsOf,
    required this.emptyIllustration,
    required this.emptyTitle,
    required this.emptyMessage,
    this.noticeTone,
    this.noticeTitle,
    this.noticeMessage,
  });

  final OfflineQueueController controller;
  final List<QueuedWrite> Function(OfflineQueueController) rowsOf;
  final AppIllustrationKind emptyIllustration;
  final String emptyTitle;
  final String emptyMessage;
  final AppStatusTone? noticeTone;
  final String? noticeTitle;
  final String? noticeMessage;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rows = rowsOf(controller);

      if (rows.isEmpty) {
        return AppEmptyState(
          illustration: emptyIllustration,
          title: t(emptyTitle),
          message: t(emptyMessage),
        );
      }

      return ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 110),
        children: [
          if (!controller.isOnline.value) ...[
            AppBanner(
              tone: AppStatusTone.warning,
              icon: Icons.wifi_off_rounded,
              message: t('common.offline'),
            ),
            const SizedBox(height: 16),
          ],
          if (noticeTone != null) ...[
            AppBanner(
              tone: noticeTone!,
              icon: Icons.report_gmailerrorred_rounded,
              title: t(noticeTitle!),
              message: t(noticeMessage!),
            ),
            const SizedBox(height: 16),
          ],
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 12),
              child: AppStaggerIn(
                index: i,
                child: QueuedWriteTile(
                  write: rows[i],
                  onRetry: () => controller.retry(rows[i].clientActionUuid),
                  onDiscard: () => _discard(context, rows[i]),
                ),
              ),
            ),
        ],
      );
    });
  }

  Future<void> _discard(BuildContext context, QueuedWrite write) async {
    // Discarding names the shop and the allottee: this is an officer's own
    // record of something they did, and it does not come back.
    final confirmed = await AppConfirmDialog.ask(
      context,
      title: t('queue.discard'),
      body: t('queue.discardConfirm', args: {
        'shop': write.shopLabel,
        'allottee': write.allotteeLabel,
      }),
      confirmLabel: t('queue.discard'),
    );
    if (confirmed) {
      await controller.discard(write.clientActionUuid);
    }
  }
}
