import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../config/routes/queue_destination.dart';
import '../../../controllers/field/queue_list_controller.dart';
import '../../../core/utils/dialer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/widgets.dart';
import 'widgets/field_card_tile.dart';
import 'widgets/field_list_view.dart';

/// The list behind a beat tile the app has no designed screen for.
///
/// MCQ was explicit that no number on the dashboard may be a dead end, and
/// the server sends each queue's own `endpoint` so the app does not have to
/// hard-code paths. This screen is what makes that promise true for a queue
/// added after this release: it fetches the server's route and renders
/// whatever cards come back, using the same card widget as everything else.
class QueueListScreen extends StatefulWidget {
  const QueueListScreen({super.key, required this.args});

  final QueueListArgs args;

  @override
  State<QueueListScreen> createState() => _QueueListScreenState();
}

class _QueueListScreenState extends State<QueueListScreen> {
  late final String _tag = 'queue-${widget.args.endpoint}';
  late final QueueListController _controller = Get.put(
    QueueListController.resolve(widget.args.endpoint),
    tag: _tag,
  );

  @override
  void dispose() {
    Get.delete<QueueListController>(tag: _tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: AppText.titleLarge(widget.args.title)),
      body: Obx(() {
        final rows = _controller.rows;

        return FieldListView(
          isLoading: _controller.isLoading.value,
          isEmpty: rows.isEmpty && !_controller.isLoading.value,
          failureMessage: _controller.failure.value?.message,
          onRefresh: () => _controller.reload(refreshing: true),
          emptyState: AppEmptyState(
            illustration: AppIllustrationKind.allClear,
            title: t('list.nothingHere'),
          ),
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              AppStaggerIn(
                index: i,
                enabled: _controller.isFirstLoad.value,
                child: FieldCardTile(
                  card: rows[i],
                  heroPrefix: 'queue',
                  onTap: () => context.push(
                    AppRoutes.propertyProfilePath(rows[i].propertyId, from: 'queue'),
                    extra: rows[i],
                  ),
                  onCall: rows[i].isCallable
                      ? () => Dialer.call(rows[i].mobileNo)
                      : null,
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}
