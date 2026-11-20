import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../controllers/agreement_case_controller.dart';
import '../../../models/agreement_case.dart';
import '../../../models/intake_attachments.dart';
import '../../../widgets/widgets.dart';
import 'agreement_decision_screen.dart';
import 'widgets/intake_act_bar.dart';
import 'widgets/intake_agreement_preview.dart';
import 'widgets/intake_attachments_drawer.dart';
import 'widgets/intake_documents.dart';
import 'widgets/intake_overview.dart';
import 'widgets/intake_timeline.dart';

/// One counter agreement case, read end to end, with the acts this reader may
/// take on it along the bottom.
class AgreementCaseScreen extends StatefulWidget {
  const AgreementCaseScreen({super.key, required this.caseId, this.row});

  final String caseId;

  /// The list row tapped. Draws the header before the detail lands.
  final AgreementCase? row;

  @override
  State<AgreementCaseScreen> createState() => _AgreementCaseScreenState();
}

class _AgreementCaseScreenState extends State<AgreementCaseScreen> {
  late final AgreementCaseController controller = Get.put(
    AgreementCaseController(caseId: widget.caseId, row: widget.row),
  );

  late final Worker _forbidden;

  @override
  void initState() {
    super.initState();
    // 403: not this officer's case — back to the list it came from.
    _forbidden = ever<bool>(controller.forbidden, (bool closed) {
      if (!closed || !mounted) return;
      _say('This case is not yours to open.');
      Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _forbidden.dispose();
    Get.delete<AgreementCaseController>();
    super.dispose();
  }

  void _say(String message) {
    AppSnackBar.show(context, message);
  }

  Future<void> _act(IntakeActOption option) async {
    final AgreementCase? file = controller.file.value;
    if (file == null) return;
    final DecisionResult? result = await context.push<DecisionResult>(
      AppRoutes.agreementDecisionPath(file.id, option.act),
      extra: file,
    );
    if (result == null || !mounted) return;
    controller.adopt(result.file);
    final String? notice = result.notice;
    if (notice == null) return;
    AppToast.show(
      context,
      notice,
      tone: result.done ? AppTone.success : AppTone.warning,
    );
  }

  Future<void> _open(IntakeDocument document) async {
    final result = await controller.openDocument(document);
    if (!mounted) return;
    if (result.download != null) {
      await IntakeDocumentSheet.show(
        context,
        title: document.name,
        download: result.download!,
      );
    } else if (result.error != null) {
      _say(result.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget page = Scaffold(
      bottomNavigationBar: Obx(() {
        final AgreementCase? file = controller.file.value;
        if (file == null || !controller.isDetailLoaded.value) {
          return const SizedBox.shrink();
        }
        return IntakeActBar(options: file.actOptions, onAct: _act);
      }),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: Obx(() {
          final AgreementCase? file = controller.file.value;
          final String? caseNo = file?.intakeNo;
          final String? name = file?.applicant?.name;
          final String? address = file?.shop.addressLine;
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              // Case number on top, the applicant, then where the shop is.
              AppSliverHeroHeader(
                title: name ?? caseNo ?? 'Case',
                subtitle: name == null ? null : caseNo,
                expandedHeight: address == null ? 80 : 96,
                leading: AppHeaderBackButton(
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                bottom: address == null ? null : _HeaderAddress(address),
                bottomSpacing: address == null ? null : 2,
              ),
              AppPinnedBar(
                height: _tabsHeight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
                  child: AppChipTabs<AgreementCaseTab>(
                    items: AgreementCaseTab.values,
                    itemLabel: (AgreementCaseTab tab) => tab.label,
                    selected: controller.tab.value,
                    onChanged: controller.showTab,
                    compact: true,
                  ),
                ),
              ),
              ..._slivers(file),
            ],
          );
        }),
      ),
    );

    return Obx(() {
      final AgreementCase? file = controller.file.value;
      return IntakeAttachmentsDrawer(
        open: controller.attachmentsOpen.value,
        onChanged: controller.showAttachments,
        groups: file == null
            ? const <IntakeAttachmentGroup>[]
            : controller.attachmentGroups(file),
        onOpen: _open,
        openingUrl: controller.openingUrl.value,
        child: page,
      );
    });
  }

  List<Widget> _slivers(AgreementCase? file) {
    final String? error = controller.errorMessage.value;
    if (file == null) {
      if (controller.isLoading.value) {
        return const <Widget>[
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      }
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: controller.notAvailable.value
              ? const AppEmptyState(
                  icon: Icons.folder_off_outlined,
                  title: 'This case is not available',
                )
              : AppErrorRetry(
                  title: 'Could not load the case',
                  message: error ?? 'Nothing came back.',
                  onRetry: controller.load,
                ),
        ),
      ];
    }

    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        sliver: SliverList.list(
          children: <Widget>[
            if (error != null) ...<Widget>[
              AppAlert(
                message: error,
                tone: AppTone.warning,
                icon: Icons.wifi_off_rounded,
              ),
              const SizedBox(height: 10),
            ],
            // The row only draws the header: cards built from it would animate
            // in, then animate again when the detail replaces them.
            if (controller.isLoading.value && !controller.isDetailLoaded.value)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: LinearProgressIndicator(minHeight: 2),
              )
            else ...<Widget>[
              // Keyed, so a row appearing above doesn't rebuild these.
              IntakeNotices(key: const ValueKey<String>('notices'), file: file),
              KeyedSubtree(
                key: ValueKey<AgreementCaseTab>(controller.tab.value),
                child: _tab(file),
              ),
            ],
          ],
        ),
      ),
    ];
  }

  Widget _tab(AgreementCase file) => switch (controller.tab.value) {
    AgreementCaseTab.overview => IntakeOverview(
      file: file,
      legacyChecks: AgreementCaseController.legacyChecks(file),
      showLegacyMatches: controller.legacyMatchesOpen.value,
      onShowLegacyMatches: controller.showLegacyMatches,
    ),
    AgreementCaseTab.money => IntakeMoney(amounts: file.amounts),
    AgreementCaseTab.workflow => IntakeTimeline(
      actions: file.actions,
      onOpen: _open,
      openingUrl: controller.openingUrl.value,
    ),
    AgreementCaseTab.preview => IntakeAgreementPreview(
      file: file,
      bytes: controller.agreementPdf.value,
      loading: controller.isPdfLoading.value,
      error: controller.pdfError.value,
      onRetry: () => controller.loadAgreementPdf(force: true),
    ),
  };
}

/// 10 over a compact chip row, and 2 under it.
const double _tabsHeight = 44;

/// The shop's address under the applicant's name, in line with the name.
class _HeaderAddress extends StatelessWidget {
  const _HeaderAddress(this.address);

  final String address;

  @override
  Widget build(BuildContext context) {
    final Color ink = Colors.white.withValues(alpha: 0.8);
    return Padding(
      padding: const EdgeInsets.only(left: 38),
      child: Row(
        children: <Widget>[
          Icon(Icons.place_outlined, size: 15, color: ink),
          const SizedBox(width: 4),
          Expanded(child: AppText.body(address, color: ink, maxLines: 1)),
        ],
      ),
    );
  }
}
