import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../core/utils/dialer.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/map_launcher.dart';
import '../../../../models/api_refs.dart';
import '../../../../models/challan.dart';
import '../../../../widgets/widgets.dart';

class ChallanSheet extends StatelessWidget {
  const ChallanSheet({
    super.key,
    required this.challan,
    this.onOpenShop,
    this.dialer = const Dialer(),
    this.mapLauncher = const MapLauncher(),
  });

  final Challan challan;

  final VoidCallback? onOpenShop;

  final Dialer dialer;

  final MapLauncher mapLauncher;

  static Future<void> show(
    BuildContext context, {
    required Challan challan,
    VoidCallback? onOpenShop,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (BuildContext context) =>
          ChallanSheet(challan: challan, onOpenShop: onOpenShop),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final AppTone tone = AppToneColors.fromApi(challan.status?.tone);
    final String? mobileNo =
        challan.allottee?.mobileNo ?? challan.payerMobileNo;

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
                  color: tone.container(context),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  challan.isFine
                      ? Icons.gavel_rounded
                      : Icons.receipt_long_rounded,
                  color: tone.on(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppText.titleLarge(
                      challan.challanNo ?? 'Bill #${challan.id ?? '—'}',
                      maxLines: 1,
                    ),
                    if (_period != null) ...<Widget>[
                      const SizedBox(height: 2),
                      AppText.caption(_period!, color: muted, maxLines: 1),
                    ],
                  ],
                ),
              ),
              IconButton(
                // The sheet is a modal route on the navigator, not a page on
                // the router: `context.pop()` would take the screen underneath
                // it instead of closing this.
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 16),

          Wrap(spacing: 6, runSpacing: 6, children: _badges()),
          const SizedBox(height: 8),

          // The one figure an officer says out loud. Never a sum of this bill
          // and another — a fine and a month's rent are separate debts.
          _PayableNow(
            amount:
                Formatters.money(challan.amounts.payableNow) ??
                Formatters.money(challan.amounts.balanceAmount),
            overdue: challan.isOverdue,
          ),
          const SizedBox(height: 18),

          const AppText.titleMedium('The charge'),
          const SizedBox(height: 8),
          ..._charges(),

          const SizedBox(height: 12),
          const AppText.titleMedium('The bill'),
          const SizedBox(height: 8),
          ..._facts(),

          if (mobileNo != null || _payer != null) ...<Widget>[
            const SizedBox(height: 18),
            const AppText.titleMedium('Who pays it'),
            const SizedBox(height: 8),
            if (_payer != null)
              AppDetailRow(icon: Icons.person_outline_rounded, value: _payer!),
            if (_tenancy != null)
              AppDetailRow(icon: Icons.assignment_outlined, value: _tenancy!),
            if (_shop != null)
              AppDetailRow(
                icon: Icons.storefront_outlined,
                value: _shop!,
                maxLines: 2,
                // On the shop where there is one, on the bazaar otherwise —
                // the action belongs on the most exact place named.
                trailing: _directions(context),
              ),
            if (challan.area?.name != null)
              AppDetailRow(
                icon: Icons.place_outlined,
                value: challan.area!.name!,
                trailing: _shop == null ? _directions(context) : null,
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
          ],

          const SizedBox(height: 18),
          const AppText.titleMedium('Paying it'),
          const SizedBox(height: 8),
          if (challan.consumerNumber != null)
            _ConsumerNumber(consumerNumber: challan.consumerNumber!),
          if (challan.linkShortCode != null)
            _Line(label: 'Link code', value: challan.linkShortCode!),
          if (challan.linkExpiresAt != null)
            _Line(
              label: 'Link expires',
              value: Formatters.dateTime(challan.linkExpiresAt!.toLocal()),
            ),
          const SizedBox(height: 6),
          AppText.caption(_linkNote, color: muted, maxLines: 3),
          if (challan.canDefer) ...<Widget>[
            const SizedBox(height: 4),
            AppText.caption(
              'Part of this bill may be deferred.',
              color: muted,
              maxLines: 2,
            ),
          ],

          ..._notes(context),

          const SizedBox(height: 22),
          if (onOpenShop != null) ...<Widget>[
            AppButton(
              label: 'Open the shop',
              icon: Icons.storefront_outlined,
              variant: AppButtonVariant.outline,
              // Closed first, so coming back from the profile lands on the
              // list rather than on a sheet about a bill already read.
              onPressed: () {
                Navigator.of(context).pop();
                onOpenShop!();
              },
            ),
            const SizedBox(height: 10),
          ],
          AppButton(
            label: 'Done',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // --- What it is -------------------------------------------------------

  String? get _period {
    final List<String> parts = <String>[
      ?challan.challanType?.label,
      ?challan.billingPeriod?.periodCode,
      ?challan.billingPeriod?.fiscalYear,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  List<Widget> _badges() => <Widget>[
    if (challan.status != null)
      AppStatusBadge(
        // The server owns this wording; new statuses arrive without a release.
        label: challan.status!.label,
        tone: AppToneColors.fromApi(challan.status!.tone),
      ),
    if (challan.isOverdue && challan.daysOverdue > 0)
      AppStatusBadge(
        label:
            '${challan.daysOverdue} '
            '${challan.daysOverdue == 1 ? 'day' : 'days'} overdue',
        tone: AppTone.danger,
        icon: Icons.schedule_rounded,
      ),
    if (challan.isSettled)
      const AppStatusBadge(
        label: 'Settled',
        tone: AppTone.success,
        icon: Icons.task_alt_rounded,
      ),
    if (challan.hasLiveLink)
      const AppStatusBadge(
        label: 'Link live',
        tone: AppTone.info,
        icon: Icons.link_rounded,
      ),
  ];

  // --- What it is made of -----------------------------------------------

  /// A fine's single charge, or a rent bill's breakdown. Lines the server sent
  /// as zero are left out — a column of "Rs 0" reads as a bill with parts it
  /// does not have.
  List<Widget> _charges() {
    final ChallanAmounts money = challan.amounts;

    if (challan.isSingleCharge) {
      return <Widget>[
        _Line(
          label: 'Fine',
          value:
              Formatters.money(money.otherAmount) ??
              Formatters.money(money.totalAmount) ??
              '—',
        ),
        ..._settlement(money),
      ];
    }

    return <Widget?>[
      _line('This month', money.currentAmount),
      _line('Arrears', money.arrearsAmount),
      _line('Surcharge', money.surchargeAmount),
      _line('Other', money.otherAmount),
      _line('Brought forward', money.previousBalance),
      _line('Adjustment', money.adjustmentAmount),
      _line('Total', money.totalAmount),
      ..._settlement(money),
    ].nonNulls.toList();
  }

  List<Widget> _settlement(ChallanAmounts money) => <Widget?>[
    _line('Paid', money.paidAmount),
    _line('Deferred', money.deferredAmount),
    _line('Balance', money.balanceAmount),
  ].nonNulls.toList();

  /// Null where the server sent nothing, or sent a zero.
  ///
  /// The parse is a display decision — whether to draw the row at all — and
  /// never arithmetic: the figure itself is printed from the server's string.
  Widget? _line(String label, String? amount) {
    final String? shown = Formatters.money(amount);
    if (shown == null) return null;
    if (num.tryParse(amount!.trim()) == 0) return null;
    return _Line(label: label, value: shown);
  }

  // --- The rest of the record -------------------------------------------

  List<Widget> _facts() => <Widget>[
    if (challan.issueDate != null)
      _Line(
        label: 'Issued',
        value: Formatters.date(challan.issueDate!.toLocal()),
      ),
    if (challan.dueDate != null)
      _Line(label: 'Due', value: Formatters.date(challan.dueDate!.toLocal())),
    if (challan.dispatchedAt != null)
      _Line(
        label: 'Sent out',
        value: Formatters.date(challan.dispatchedAt!.toLocal()),
      ),
    if (challan.firstPaidAt != null)
      _Line(
        label: 'First paid',
        value: Formatters.date(challan.firstPaidAt!.toLocal()),
      ),
    if (challan.settledAt != null)
      _Line(
        label: 'Settled',
        value: Formatters.date(challan.settledAt!.toLocal()),
      ),
  ];

  /// The holder and their register code — the code is what a clerk looks the
  /// person up by, and the name alone is not unique in a bazaar.
  String? get _payer {
    final String? name = challan.allottee?.fullName ?? challan.payerName;
    if (name == null) return null;
    final String? code = challan.allottee?.allotteeCode;
    return code == null ? name : '$name · $code';
  }

  /// The tenancy the bill is raised under, and the terms it is held on — rent
  /// or lease, which `allotment_type` is the only field to say.
  String? get _tenancy {
    final AllotmentRef? allotment = challan.allotment;
    if (allotment == null) return null;
    final List<String> parts = <String>[
      ?allotment.allotmentNo,
      ?allotment.allotmentType?.label,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  String? get _shop => challan.property?.displayName;

  /// The fix the register holds for the unit, when it holds one. Null on every
  /// challan the billing endpoint sends today — it publishes no coordinates —
  /// and the search below is what stands in until it does.
  GeoPoint? get _fix => challan.property?.location;

  /// What to search a map for without a fix: the shop as the server named it,
  /// then the bazaar. Gets the officer to the right row of shops and leaves
  /// the last few yards to them.
  String? get _mapQuery {
    final List<String> parts = <String>[
      ?challan.property?.displayName,
      ?challan.area?.name,
    ];
    return parts.isEmpty ? null : parts.join(', ');
  }

  /// The map button, or null when there is nothing to point one at. A fix
  /// beats an address, and neither means no map.
  Widget? _directions(BuildContext context) {
    if (MapLauncher.targetFor(point: _fix, address: _mapQuery) == null) {
      return null;
    }
    return AppButton(
      label: _fix == null ? 'Find' : 'Directions',
      icon: Icons.map_outlined,
      variant: AppButtonVariant.outline,
      fullWidth: false,
      height: 34,
      onPressed: () => mapLauncher.open(point: _fix, address: _mapQuery),
    );
  }

  /// Whether the link still works is the whole point of saying anything about
  /// it — an expired link shared at a doorstep is worse than none.
  String get _linkNote => challan.hasLiveLink
      ? 'A payment link is live on this bill.'
      : 'No payment link is live on this bill. The consumer number is what '
            'the shopkeeper quotes at a counter.';

  /// The server's own asides about the bill, and the flags that change what it
  /// is safe to tell a shopkeeper.
  List<Widget> _notes(BuildContext context) {
    final List<Widget> notes = <Widget>[
      if (challan.supersededByChallanId != null)
        const AppAlert(
          tone: AppTone.warning,
          icon: Icons.change_circle_outlined,
          message:
              'This bill was replaced by a corrected one. Do not collect '
              'against it.',
        ),
      if (challan.isProrated)
        AppAlert(
          tone: AppTone.info,
          icon: Icons.pie_chart_outline_rounded,
          message: challan.prorationDays == null
              ? 'Part of a month, not a whole one.'
              : 'Part of a month — ${challan.prorationDays} days, not a '
                    'whole one.',
        ),
      if (challan.surchargeExempt)
        AppAlert(
          tone: AppTone.info,
          icon: Icons.remove_circle_outline_rounded,
          message: challan.surchargeExemptReason == null
              ? 'Surcharge waived on this bill.'
              : 'Surcharge waived: ${challan.surchargeExemptReason}',
        ),
      if (challan.isEdited)
        const AppAlert(
          tone: AppTone.neutral,
          icon: Icons.edit_note_rounded,
          message: 'This bill has been edited since it was raised.',
        ),
    ];

    if (challan.remarks == null && notes.isEmpty) return const <Widget>[];

    return <Widget>[
      const SizedBox(height: 18),
      const AppText.titleMedium('Worth knowing'),
      const SizedBox(height: 8),
      if (challan.remarks != null) ...<Widget>[
        AppText.body(challan.remarks!, maxLines: 4),
        if (notes.isNotEmpty) const SizedBox(height: 10),
      ],
      for (int i = 0; i < notes.length; i++) ...<Widget>[
        if (i > 0) const SizedBox(height: 8),
        notes[i],
      ],
    ];
  }
}

/// What is due today, in the size an officer reads across a counter.
class _PayableNow extends StatelessWidget {
  const _PayableNow({required this.amount, required this.overdue});

  final String? amount;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final AppTone tone = overdue ? AppTone.danger : AppTone.primary;
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return AppCard(
      color: tone.container(context),
      borderColor: tone.container(context),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        // Across the sheet, not hugging the figure: this is the line an
        // officer reads out, and a plate the width of its own text reads as
        // an aside. The children still draw left — stretch sizes them, and
        // `AppText` aligns to the start inside that width.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppText.caption('Payable now', color: muted),
          const SizedBox(height: 2),
          AppText.headlineSmall(
            amount ?? '—',
            color: tone.on(context),
            fontWeight: FontWeight.w700,
            maxLines: 1,
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
          SizedBox(width: 116, child: AppText.body(label, color: muted)),
          Expanded(child: AppText.body(value, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// The number a shopkeeper reads out at a counter, so it is the one thing here
/// worth being able to copy.
class _ConsumerNumber extends StatelessWidget {
  const _ConsumerNumber({required this.consumerNumber});

  final String consumerNumber;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Row(
      children: <Widget>[
        SizedBox(width: 116, child: AppText.body('Consumer no', color: muted)),
        Expanded(
          child: AppText.body(consumerNumber, fontWeight: FontWeight.w600),
        ),
        IconButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: consumerNumber));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: AppText.body('Consumer number copied')),
            );
          },
          icon: const Icon(Icons.copy_rounded, size: 18),
          tooltip: 'Copy',
        ),
      ],
    );
  }
}
