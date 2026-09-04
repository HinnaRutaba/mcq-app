import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../core/utils/dialer.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/map_launcher.dart';
import '../../../../models/trade_application.dart';
import '../../../../widgets/widgets.dart';

/// One field capture read end to end: the shop, the applicant, the fee the
/// server quoted, the challan it raised and the number the shopkeeper reads
/// out at a payment counter.
///
/// Two ways in, one body. [confirm] is what comes back from capturing a shop —
/// one call did four things, and the shopkeeper standing there needs to be
/// told three of them. [show] is the same record reopened later from the
/// captures queue, where the officer is chasing a bill rather than raising it.
class CaptureSheet extends StatelessWidget {
  const CaptureSheet({
    super.key,
    required this.application,
    this.justCaptured = false,
    this.dialer = const Dialer(),
    this.maps = const MapLauncher(),
  });

  final TradeApplication application;

  /// Whether this is the receipt for a capture just made, rather than a row
  /// on the queue opened again.
  final bool justCaptured;

  /// Injected so a test can press these: the platform has no dialler and no
  /// map app.
  final Dialer dialer;
  final MapLauncher maps;

  /// A capture opened from the queue.
  static Future<void> show(
    BuildContext context, {
    required TradeApplication application,
  }) => _open(context, application: application, justCaptured: false);

  /// The receipt for a capture just made. Not dismissible: the consumer number
  /// on it is the shopkeeper's way to pay if the texted link fails, and a
  /// stray tap outside is not a reason to lose it.
  static Future<void> confirm(
    BuildContext context, {
    required TradeApplication application,
  }) => _open(context, application: application, justCaptured: true);

  static Future<void> _open(
    BuildContext context, {
    required TradeApplication application,
    required bool justCaptured,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: !justCaptured,
      enableDrag: !justCaptured,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (BuildContext context) =>
          CaptureSheet(application: application, justCaptured: justCaptured),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final String? mobileNo = application.mobileNo;
    final String? consumerNo = application.consumerNo;
    final String? fee = Formatters.money(application.feeAmount);
    final String? term = _term;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _head(context, muted),
          const SizedBox(height: 14),

          Wrap(spacing: 6, runSpacing: 6, children: _badges()),
          const SizedBox(height: 8),

          if (fee != null) ...<Widget>[
            _Fee(amount: fee),
            const SizedBox(height: 18),
          ] else
            const SizedBox(height: 10),

          const AppText.titleMedium('The application'),
          const SizedBox(height: 8),
          if (application.applicationNo != null)
            AppDetailRow(
              icon: Icons.description_outlined,
              value: application.applicationNo!,
            ),
          if (term != null)
            AppDetailRow(icon: Icons.event_available_outlined, value: term),
          if (application.appliedOn != null)
            AppDetailRow(
              icon: Icons.event_note_outlined,
              value:
                  'Applied '
                  '${Formatters.date(application.appliedOn!.toLocal())}',
            ),

          const SizedBox(height: 18),
          const AppText.titleMedium('The shopkeeper'),
          const SizedBox(height: 8),
          AppDetailRow(
            icon: Icons.person_outline_rounded,
            value: application.applicantName ?? 'Not recorded',
            maxLines: 2,
          ),
          if (application.fatherName != null)
            AppDetailRow(
              icon: Icons.people_outline_rounded,
              value: "Father's name: ${application.fatherName!}",
              maxLines: 2,
            ),
          if (application.cnic != null)
            AppDetailRow(
              icon: Icons.credit_card_outlined,
              value: application.cnic!,
            ),
          if (mobileNo != null)
            AppDetailRow(
              icon: Icons.phone_outlined,
              value: mobileNo,
              trailing: AppButton(
                label: 'Call',
                icon: Icons.phone_outlined,
                variant: AppButtonVariant.outline,
                fullWidth: false,
                height: 34,
                onPressed: () => dialer.call(mobileNo),
              ),
            ),

          const SizedBox(height: 18),
          const AppText.titleMedium('The shop'),
          const SizedBox(height: 8),
          if (application.trade != null)
            AppDetailRow(
              icon: Icons.storefront_outlined,
              value: application.trade!,
              maxLines: 2,
            ),
          if (application.shopAddress != null)
            AppDetailRow(
              icon: Icons.place_outlined,
              value: application.shopAddress!,
              maxLines: 3,
              trailing: _directions(context),
            ),
          if (application.areaName != null)
            AppDetailRow(
              icon: Icons.map_outlined,
              value: application.areaName!,
              maxLines: 2,
              // On the shop where there is one, on the bazaar otherwise — the
              // action belongs on the most exact place named.
              trailing: application.shopAddress == null
                  ? _directions(context)
                  : null,
            ),

          if (application.challanNo != null || consumerNo != null) ...<Widget>[
            const SizedBox(height: 18),
            const AppText.titleMedium('The bill'),
            const SizedBox(height: 8),
            if (application.challanNo != null)
              AppDetailRow(
                icon: Icons.receipt_long_outlined,
                value: application.challanNo!,
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
            AppText.caption(
              application.hasLiveLink
                  ? 'A payment link has been texted to the shopkeeper.'
                  : 'No payment link is live on this bill yet — send them to a '
                        'counter with the consumer number.',
              color: muted,
              maxLines: 3,
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

  /// The receipt leads with what just happened; the queue row leads with the
  /// shop, which is what the officer opened it looking for.
  Widget _head(BuildContext context, Color? muted) {
    final bool receipt = justCaptured;
    final AppTone tone = receipt ? AppTone.success : AppTone.warning;

    return Row(
      children: <Widget>[
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: tone.container(context),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            receipt ? Icons.check_rounded : Icons.storefront_outlined,
            color: tone.on(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppText.titleLarge(
                receipt ? 'Shop captured' : _name,
                maxLines: 2,
              ),
              if (_subtitle(receipt) != null) ...<Widget>[
                const SizedBox(height: 2),
                AppText.caption(
                  _subtitle(receipt)!,
                  color: muted,
                  maxLines: 2,
                ),
              ],
            ],
          ),
        ),
        if (!receipt)
          IconButton(
            // The sheet is a modal route on the navigator, not a page on the
            // router: `context.pop()` would take the screen underneath it
            // instead of closing this.
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close',
          ),
      ],
    );
  }

  String get _name =>
      application.businessName ?? application.applicantName ?? 'Unnamed shop';

  String? _subtitle(bool receipt) {
    if (receipt) return application.applicationNo;
    final List<String> parts = <String>[
      if (application.businessName != null && application.applicantName != null)
        application.applicantName!,
      ?application.trade,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  String? get _term {
    final int? years = application.years;
    return years == null ? null : '$years ${years == 1 ? 'year' : 'years'}';
  }

  List<Widget> _badges() => <Widget>[
    AppStatusBadge(
      label: _humanise(application.status ?? 'pending'),
      tone: AppTone.warning,
    ),
    // Whether the shopkeeper can still pay from the text they were sent. A
    // dead link means they have to be sent to a counter with the number below.
    AppStatusBadge(
      label: application.hasLiveLink ? 'Link live' : 'No live link',
      tone: application.hasLiveLink ? AppTone.info : AppTone.neutral,
      icon: application.hasLiveLink
          ? Icons.link_rounded
          : Icons.link_off_rounded,
    ),
  ];

  /// Null where the capture carries no address — a capture has no map pin.
  Widget? _directions(BuildContext context) {
    final Uri? target = MapLauncher.targetFor(
      address: application.shopAddress ?? application.areaName,
    );
    if (target == null) return null;

    return AppButton(
      label: 'Directions',
      icon: Icons.directions_outlined,
      variant: AppButtonVariant.outline,
      fullWidth: false,
      height: 34,
      onPressed: () =>
          maps.open(address: application.shopAddress ?? application.areaName),
    );
  }

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

/// The server's own quote for this licence. Nothing here multiplied anything.
class _Fee extends StatelessWidget {
  const _Fee({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return AppCard(
      color: AppTone.primary.container(context),
      borderColor: AppTone.primary.container(context),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppText.caption('Fee quoted', color: muted),
          const SizedBox(height: 2),
          AppText.headlineSmall(
            amount,
            color: AppTone.primary.on(context),
            fontWeight: FontWeight.w700,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
