import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/dialer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/enforcement/fine.dart';
import '../../../../widgets/widgets.dart';

/// What happened when the fine was imposed — and it is a moment worth
/// designing.
///
/// In one transaction the server posted the receivable to the ledger,
/// raised a payable challan, issued a payment link and a Consumer Number,
/// and sent the violator an SMS. The magistrate has nothing else to do. So
/// this screen's job is to hand him the four things he needs before he
/// walks away from the shop:
///
/// * the **fine number**, for the file;
/// * the **challan number and amount**, for the argument;
/// * the **Consumer Number**, large and copyable, because that is what the
///   shopkeeper reads out at a bank counter;
/// * whether the **SMS actually went out**, and to which number — if it did
///   not, the officer needs to know before he leaves.
///
/// And one sentence that prevents the commonest argument at the counter:
/// **a fine is a separate debt from the rent.** Paying one settles nothing
/// of the other, and the two are never summed.
class FineResultView extends StatelessWidget {
  const FineResultView({
    super.key,
    required this.outcome,
    required this.shopLabel,
    required this.onClose,
  });

  final FineOutcome outcome;
  final String shopLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final challan = outcome.challan;

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SuccessMark(),
          const SizedBox(height: 18),
          AppText.headlineSmall(
            // 201 created; 200 is the server saying "you already sent
            // that". Never announce a fine twice.
            outcome.wasCreated ? t('fines.imposed') : t('action.savedAlready'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          UserText.body(
            shopLabel,
            maxLines: 2,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 24),

          AppMoneyPanel(
            label: t('fines.amountImposed'),
            amount: outcome.fine.amount,
            absentLabel: t('common.notRecorded'),
            tone: AppTone.warning,
            facts: [
              if (outcome.fine.fineNo.isNotEmpty)
                AppPill(
                  icon: Icons.tag_rounded,
                  tone: AppTone.warning,
                  label: outcome.fine.fineNo,
                ),
              if (!outcome.fine.fineType.isEmpty)
                AppPill(
                  icon: Icons.gavel_rounded,
                  tone: AppTone.warning,
                  // The server's own label, already translated.
                  label: outcome.fine.fineType.label,
                ),
            ],
            footnote: t('challan.separateDebt'),
          ),

          if (challan != null) ...[
            const SizedBox(height: 16),
            _Reference(
              label: t('fines.challanNo'),
              value: challan.challanNo,
              icon: Icons.receipt_long_rounded,
            ),
            if ((challan.consumerNo ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              // The one number the shopkeeper reads out at a counter.
              // Large, and copyable in one tap.
              _ConsumerNumber(consumerNo: challan.consumerNo!),
            ],
          ],

          const SizedBox(height: 16),
          AppBanner(
            tone: outcome.linkDispatched
                ? AppStatusTone.success
                : AppStatusTone.danger,
            icon: outcome.linkDispatched
                ? Icons.sms_rounded
                : Icons.sms_failed_rounded,
            message: outcome.linkDispatched
                ? t('fines.smsSent', args: {'mobile': outcome.smsSentTo ?? ''})
                : t('fines.smsNotSent'),
          ),

          if (outcome.fine.notYetEffective) ...[
            const SizedBox(height: 12),
            AppBanner(
              tone: AppStatusTone.warning,
              icon: Icons.hourglass_empty_rounded,
              message: t('fines.requiresApproval'),
            ),
          ],

          const SizedBox(height: 24),

          // Most recovery conversations in Pakistan happen on WhatsApp.
          // Handing the link over there is the fastest way to get paid.
          if ((challan?.payUrl ?? '').isNotEmpty) ...[
            AppButton(
              label: t('fines.sendOnWhatsApp'),
              icon: Icons.chat_rounded,
              variant: AppButtonVariant.accent,
              onPressed: () => Dialer.whatsApp(
                outcome.fine.payerMobile,
                message: _message(challan!.payUrl!, challan.consumerNo),
              ),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: t('fines.sharePaymentLink'),
              icon: Icons.share_rounded,
              variant: AppButtonVariant.outline,
              onPressed: () => SharePlus.instance.share(
                ShareParams(
                  text: _message(challan!.payUrl!, challan.consumerNo),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          AppButton(
            label: t('common.close'),
            variant: AppButtonVariant.ghost,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }

  /// A polite message with the amount, the Consumer Number and the link —
  /// the three things the shopkeeper needs and nothing he does not.
  String _message(String payUrl, String? consumerNo) => t(
        'fines.shareMessage',
        args: {
          'amount': outcome.fine.amount.withSymbol(),
          'consumer': consumerNo ?? '—',
          'link': payUrl,
        },
      );
}

/// A tick that draws itself. Small, quick, and only on this screen —
/// a fine is the one write in the app that ends in a document.
class _SuccessMark extends StatefulWidget {
  const _SuccessMark();

  @override
  State<_SuccessMark> createState() => _SuccessMarkState();
}

class _SuccessMarkState extends State<_SuccessMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..forward();

  @override
  void initState() {
    super.initState();
    AppHaptics.success();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colour = AppTone.success.on(context);
    return Center(
      child: ScaleTransition(
        scale: CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutBack,
        ),
        child: Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: colour.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(color: colour.withValues(alpha: 0.4), width: 2),
          ),
          child: Icon(Icons.check_rounded, size: 40, color: colour),
        ),
      ),
    );
  }
}

/// A reference number, in a monospaced-feeling row with a copy button.
class _Reference extends StatelessWidget {
  const _Reference({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: value));
        AppFeedback.toast(t('profile.copied'));
      },
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodySmall(
                  label,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: AppText.titleMedium(value),
                ),
              ],
            ),
          ),
          Icon(Icons.copy_rounded, size: 18, color: theme.dividerColor),
        ],
      ),
    );
  }
}

/// The Consumer Number, large, with a copy button — exactly as the brief
/// asks, because it is read out loud at a bank counter by somebody who is
/// already annoyed.
class _ConsumerNumber extends StatelessWidget {
  const _ConsumerNumber({required this.consumerNo});

  final String consumerNo;

  @override
  Widget build(BuildContext context) {
    final colour = AppTone.info.on(context);
    return AppCard(
      tone: AppTone.info,
      rail: true,
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: consumerNo));
        AppHaptics.select();
        AppFeedback.toast(t('profile.copied'));
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.label(t('fines.consumerNo'), color: colour),
                const SizedBox(height: 4),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: AppText(
                    consumerNo,
                    variant: AppTextVariant.headlineMedium,
                    color: colour,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colour.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.copy_rounded, color: colour, size: 21),
          ),
        ],
      ),
    );
  }
}
