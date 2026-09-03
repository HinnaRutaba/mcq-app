import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/dialer.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/trade_licence.dart';
import '../../../../widgets/widgets.dart';

/// One trade licence on the round list.
///
/// The shop's own name leads, because that is what is painted above the door
/// the officer is standing at; the holder and the trade come under it. The
/// figure on the right is days, not money — nothing in this register is a debt.
class LicenceTile extends StatelessWidget {
  const LicenceTile({
    super.key,
    required this.licence,
    this.dialer = const Dialer(),
  });

  final TradeLicence licence;

  final Dialer dialer;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final String? note = _note();
    final String? mobileNo = licence.mobileNo;
    final AppTone tone = _tone;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: AppText.titleMedium(_name, maxLines: 1)),
              if (_term != null) ...<Widget>[
                const SizedBox(width: 12),
                AppText.caption(
                  _term!,
                  color: tone.on(context),
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          AppText.body(_holder, maxLines: 1),
          if (note != null) ...<Widget>[
            const SizedBox(height: 4),
            AppText.caption(note, color: muted, maxLines: 1),
          ],
          const SizedBox(height: 10),
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
      licence.businessName ?? licence.holderName ?? 'Unnamed shop';

  /// The person and the trade — dropped from the line when the business name
  /// above is already the holder's.
  String get _holder {
    final List<String> parts = <String>[
      if (licence.businessName != null && licence.holderName != null)
        licence.holderName!,
      ?licence.trade,
    ];
    return parts.isEmpty ? 'Trade not recorded' : parts.join(' · ');
  }

  String? _note() {
    final List<String> parts = <String>[
      ?licence.licenceNo,
      ?licence.areaName,
      if (licence.validTo != null)
        'to ${Formatters.date(licence.validTo!.toLocal())}',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// The server's own count of days left, which runs negative on a licence
  /// that has lapsed — never a date subtraction of our own.
  String? get _term {
    final int? days = licence.daysRemaining;
    if (days == null) return licence.isValid ? null : 'Lapsed';
    if (days > 1) return '$days days left';
    if (days == 1) return '1 day left';
    if (days == 0) return 'Last day';
    final int over = -days;
    return '$over ${over == 1 ? 'day' : 'days'} over';
  }

  /// `isValid` is the server's answer to "may this shop trade today" and the
  /// only thing that decides the colour. A licence inside its last month is
  /// warned about, not condemned.
  AppTone get _tone {
    if (!licence.isValid) return AppTone.danger;
    final int? days = licence.daysRemaining;
    return (days != null && days <= 30) ? AppTone.warning : AppTone.success;
  }

  List<Widget> _badges() => <Widget>[
    AppStatusBadge(
      label: licence.isValid ? 'Live' : 'Lapsed',
      tone: licence.isValid ? AppTone.success : AppTone.danger,
      icon: licence.isValid
          ? Icons.verified_outlined
          : Icons.event_busy_outlined,
    ),
    if (licence.verificationCode != null)
      AppStatusBadge(
        // What a shopkeeper shows and an officer checks.
        label: licence.verificationCode!,
        icon: Icons.qr_code_2_rounded,
      ),
  ];
}
