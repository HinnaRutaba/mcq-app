import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/dialer.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/trade_application.dart';
import '../../../../widgets/widgets.dart';

/// One field capture waiting to be paid — a shop this officer wrote up whose
/// challan is still open.
///
/// Unlike a licence this one does carry money, so the quoted fee sits on the
/// right where a figure belongs. The consumer number is the only thing here
/// worth copying: it is what the shopkeeper reads out at a payment counter.
class CaptureTile extends StatelessWidget {
  const CaptureTile({
    super.key,
    required this.capture,
    this.onTap,
    this.dialer = const Dialer(),
  });

  final TradeApplication capture;

  /// Opens the capture in full. Every row has one: the record behind the tile
  /// already carries the rest of it, so there is nothing to fetch.
  final VoidCallback? onTap;

  final Dialer dialer;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final String? fee = Formatters.money(capture.feeAmount);
    final String? note = _note();
    final String? consumerNo = capture.consumerNo;
    final String? mobileNo = capture.mobileNo;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: AppText.titleMedium(_name, maxLines: 1)),
              if (fee != null) ...<Widget>[
                const SizedBox(width: 12),
                AppText.titleMedium(fee, maxLines: 1),
              ],
            ],
          ),
          const SizedBox(height: 3),
          AppText.body(_applicant, maxLines: 1),
          if (note != null) ...<Widget>[
            const SizedBox(height: 4),
            AppText.caption(note, color: muted, maxLines: 1),
          ],
          const SizedBox(height: 10),
          if (capture.challanNo != null)
            AppDetailRow(
              icon: Icons.receipt_long_outlined,
              value: capture.challanNo!,
            ),
          if (consumerNo != null)
            AppDetailRow(
              icon: Icons.confirmation_number_outlined,
              value: consumerNo,
              trailing: IconButton(
                onPressed: () => _copy(context, consumerNo),
                icon: const Icon(Icons.copy_rounded, size: 18),
                visualDensity: VisualDensity.compact,
                tooltip: 'Copy',
              ),
            ),
          Row(
            children: <Widget>[
              Expanded(
                child: Wrap(spacing: 6, runSpacing: 6, children: _badges()),
              ),
              if (mobileNo != null) ...<Widget>[
                const SizedBox(width: 8),
                AppButton(
                  label: 'Call',
                  icon: Icons.phone_outlined,
                  variant: AppButtonVariant.outline,
                  fullWidth: false,
                  height: 34,
                  onPressed: () => dialer.call(mobileNo),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String get _name =>
      capture.businessName ?? capture.applicantName ?? 'Unnamed shop';

  String get _applicant {
    final List<String> parts = <String>[
      if (capture.businessName != null && capture.applicantName != null)
        capture.applicantName!,
      ?capture.trade,
    ];
    return parts.isEmpty ? 'Trade not recorded' : parts.join(' · ');
  }

  String? _note() {
    final int? years = capture.years;
    final DateTime? applied = capture.appliedOn;
    final List<String> parts = <String>[
      ?capture.applicationNo,
      ?capture.areaName,
      if (years != null) '$years ${years == 1 ? 'year' : 'years'}',
      if (applied != null) Formatters.date(applied.toLocal()),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// Kept to one line beside the call button. The challan and consumer
  /// numbers are rows above rather than pills: they are long, and a badge
  /// row that wraps three deep is not a glance.
  List<Widget> _badges() => <Widget>[
    // Whether the shopkeeper can still pay from the text they were sent. A
    // dead link means they have to be sent to a counter with the number above.
    AppStatusBadge(
      label: capture.hasLiveLink ? 'Link live' : 'No live link',
      tone: capture.hasLiveLink ? AppTone.info : AppTone.neutral,
      icon: capture.hasLiveLink ? Icons.link_rounded : Icons.link_off_rounded,
    ),
    // Everything in this queue is pending, so only a status that is *not*
    // says anything worth a pill.
    if (capture.status != null && capture.status != 'pending')
      AppStatusBadge(label: _humanise(capture.status!), tone: AppTone.warning),
  ];

  static void _copy(BuildContext context, String consumerNo) {
    Clipboard.setData(ClipboardData(text: consumerNo));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: AppText.body('Consumer number copied')),
    );
  }

  /// `pending` -> `Pending`. The server sends a bare string here rather than a
  /// labelled value, so there is nothing to render verbatim.
  static String _humanise(String status) {
    final String words = status.replaceAll('_', ' ').trim();
    if (words.isEmpty) return 'Pending';
    return words[0].toUpperCase() + words.substring(1);
  }
}
