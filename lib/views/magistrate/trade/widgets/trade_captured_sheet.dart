import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/trade_application.dart';
import '../../../../widgets/widgets.dart';

/// What came back from capturing a shop: the application, the fee the server
/// quoted, the challan it raised and the number the shopkeeper reads out at a
/// payment counter.
///
/// One call did four things, and the shopkeeper standing there needs to be told
/// three of them — what it costs, that they have been texted a link, and what
/// to quote if the link does not work.
class TradeCapturedSheet extends StatelessWidget {
  const TradeCapturedSheet({super.key, required this.application});

  final TradeApplication application;

  static Future<void> show(
    BuildContext context, {
    required TradeApplication application,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (BuildContext context) =>
          TradeCapturedSheet(application: application),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final int? years = application.years;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppTone.success.container(context),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: AppTone.success.on(context),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const AppText.titleLarge('Shop captured'),
                    if (application.applicationNo != null) ...<Widget>[
                      const SizedBox(height: 2),
                      AppText.caption(application.applicationNo!, color: muted),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (application.businessName != null)
            _Line(label: 'Shop', value: application.businessName!),
          if (application.applicantName != null)
            _Line(label: 'Shopkeeper', value: application.applicantName!),
          if (application.trade != null)
            _Line(label: 'Trade', value: application.trade!),
          if (years != null)
            _Line(
              label: 'Term',
              value: '$years ${years == 1 ? 'year' : 'years'}',
            ),
          if (application.feeAmount != null)
            _Line(
              // The server's own figure. Nothing here multiplied anything.
              label: 'Fee quoted',
              value: Formatters.money(application.feeAmount) ?? '—',
            ),

          if (application.challanNo != null ||
              application.consumerNo != null) ...<Widget>[
            const SizedBox(height: 18),
            const AppText.titleMedium('The bill'),
            const SizedBox(height: 8),
            if (application.challanNo != null)
              _Line(label: 'Challan', value: application.challanNo!),
            if (application.consumerNo != null)
              _ConsumerNumber(consumerNo: application.consumerNo!),
            const SizedBox(height: 6),
            AppText.caption(
              application.hasLiveLink
                  ? 'A payment link has been texted to the shopkeeper.'
                  : 'No payment link is live on this bill yet — send them to a '
                        'counter with the consumer number.',
              color: muted,
            ),
          ],

          const SizedBox(height: 22),
          AppButton(
            label: 'Done',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 96, child: AppText.body(label, color: muted)),
          Expanded(child: AppText.body(value, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// The number a shopkeeper reads out at a counter, so it is the one thing here
/// worth being able to copy.
class _ConsumerNumber extends StatelessWidget {
  const _ConsumerNumber({required this.consumerNo});

  final String consumerNo;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          SizedBox(width: 96, child: AppText.body('Consumer no', color: muted)),
          Expanded(
            child: AppText.body(consumerNo, fontWeight: FontWeight.w600),
          ),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: consumerNo));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: AppText.body('Consumer number copied')),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            tooltip: 'Copy',
          ),
        ],
      ),
    );
  }
}
