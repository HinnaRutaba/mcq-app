import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../core/utils/dialer.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/map_launcher.dart';
import '../../../../models/trade_licence.dart';
import '../../../../widgets/widgets.dart';

/// One licence read end to end — the sheet a row on the round list opens.
///
/// The row is a glance: the shop, the holder and how long is left. Standing at
/// the shopfront the officer needs the rest of it — the number on the wall, the
/// code the shopkeeper shows, whose CNIC it is keyed on, and the number to ring
/// when the shop is shut. Everything here is already on the record behind the
/// row, so opening one fetches nothing.
class LicenceSheet extends StatelessWidget {
  const LicenceSheet({
    super.key,
    required this.licence,
    this.dialer = const Dialer(),
    this.maps = const MapLauncher(),
  });

  final TradeLicence licence;

  /// Injected so a test can press these: the platform has no dialler and no
  /// map app.
  final Dialer dialer;
  final MapLauncher maps;

  static Future<void> show(
    BuildContext context, {
    required TradeLicence licence,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (BuildContext context) => LicenceSheet(licence: licence),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final AppTone tone = licence.isValid ? AppTone.success : AppTone.danger;
    final String? mobileNo = licence.mobileNo;
    final String? term = _term;

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
                  licence.isValid
                      ? Icons.verified_outlined
                      : Icons.event_busy_outlined,
                  color: tone.on(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppText.titleLarge(_name, maxLines: 2),
                    if (_subtitle != null) ...<Widget>[
                      const SizedBox(height: 2),
                      AppText.caption(_subtitle!, color: muted, maxLines: 2),
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
          const SizedBox(height: 14),

          Wrap(spacing: 6, runSpacing: 6, children: _badges()),
          const SizedBox(height: 18),

          const AppText.titleMedium('The licence'),
          const SizedBox(height: 8),
          if (licence.licenceNo != null)
            AppDetailRow(
              icon: Icons.badge_outlined,
              value: licence.licenceNo!,
            ),
          if (licence.verificationCode != null)
            AppDetailRow(
              // What a shopkeeper shows and an officer checks.
              icon: Icons.qr_code_2_rounded,
              value: licence.verificationCode!,
            ),
          if (term != null)
            AppDetailRow(
              icon: Icons.event_available_outlined,
              value: term,
              maxLines: 2,
            ),
          if (licence.issuedOn != null)
            AppDetailRow(
              icon: Icons.event_note_outlined,
              value: 'Issued ${Formatters.date(licence.issuedOn!.toLocal())}',
            ),

          const SizedBox(height: 18),
          const AppText.titleMedium('The holder'),
          const SizedBox(height: 8),
          AppDetailRow(
            icon: Icons.person_outline_rounded,
            value: licence.holderName ?? 'Not recorded',
            maxLines: 2,
          ),
          if (licence.fatherName != null)
            AppDetailRow(
              icon: Icons.people_outline_rounded,
              value: "Father's name: ${licence.fatherName!}",
              maxLines: 2,
            ),
          if (licence.cnic != null)
            AppDetailRow(
              // A licence is keyed on this, not on a property or an allotment.
              icon: Icons.credit_card_outlined,
              value: licence.cnic!,
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
          if (licence.trade != null)
            AppDetailRow(
              icon: Icons.storefront_outlined,
              value: licence.trade!,
              maxLines: 2,
            ),
          if (licence.shopAddress != null)
            AppDetailRow(
              icon: Icons.place_outlined,
              value: licence.shopAddress!,
              maxLines: 3,
              trailing: _directions(context),
            ),
          if (_where != null)
            AppDetailRow(
              icon: Icons.map_outlined,
              value: _where!,
              maxLines: 2,
              // On the shop where there is one, on the bazaar otherwise — the
              // action belongs on the most exact place named.
              trailing: licence.shopAddress == null
                  ? _directions(context)
                  : null,
            ),

          const SizedBox(height: 22),
          AppButton(
            label: 'Done',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  String get _name =>
      licence.businessName ?? licence.holderName ?? 'Unnamed shop';

  /// The holder and the trade, dropped where the name above is already one of
  /// them.
  String? get _subtitle {
    final List<String> parts = <String>[
      if (licence.businessName != null && licence.holderName != null)
        licence.holderName!,
      ?licence.trade,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  String? get _where {
    final List<String> parts = <String>[?licence.areaName, ?licence.zoneName];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// The dates as the register holds them. Never a date subtraction of our own
  /// — how long is left is the server's [TradeLicence.daysRemaining], on a
  /// badge above.
  String? get _term {
    final DateTime? from = licence.validFrom;
    final DateTime? to = licence.validTo;
    if (from == null && to == null) return null;
    if (from == null) return 'Valid to ${Formatters.date(to!.toLocal())}';
    if (to == null) return 'Valid from ${Formatters.date(from.toLocal())}';
    return 'Valid ${Formatters.date(from.toLocal())} to '
        '${Formatters.date(to.toLocal())}';
  }

  List<Widget> _badges() => <Widget>[
    AppStatusBadge(
      // `isValid` is the server's answer to "may this shop trade today", and
      // the only thing that decides what this says.
      label: licence.isValid ? 'Live' : 'Lapsed',
      tone: licence.isValid ? AppTone.success : AppTone.danger,
      icon: licence.isValid
          ? Icons.verified_outlined
          : Icons.event_busy_outlined,
    ),
    if (_days != null)
      AppStatusBadge(
        label: _days!,
        tone: _daysTone,
        icon: Icons.schedule_rounded,
      ),
  ];

  /// The server's own count of days left, which runs negative on a licence
  /// that has lapsed.
  String? get _days {
    final int? days = licence.daysRemaining;
    if (days == null) return null;
    if (days > 1) return '$days days left';
    if (days == 1) return '1 day left';
    if (days == 0) return 'Last day';
    final int over = -days;
    return '$over ${over == 1 ? 'day' : 'days'} over';
  }

  AppTone get _daysTone {
    if (!licence.isValid) return AppTone.danger;
    final int? days = licence.daysRemaining;
    return (days != null && days <= 30) ? AppTone.warning : AppTone.success;
  }

  /// Null where the licence carries neither a pin nor an address — most rows
  /// on this register were never surveyed.
  Widget? _directions(BuildContext context) {
    final Uri? target = MapLauncher.targetFor(
      point: licence.mapPin,
      address: licence.shopAddress,
    );
    if (target == null) return null;

    return AppButton(
      label: 'Directions',
      icon: Icons.directions_outlined,
      variant: AppButtonVariant.outline,
      fullWidth: false,
      height: 34,
      onPressed: () =>
          maps.open(point: licence.mapPin, address: licence.shopAddress),
    );
  }
}
