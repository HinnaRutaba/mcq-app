import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/dialer.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/field_seal.dart';
import '../../../../widgets/widgets.dart';

/// One seal on the register: who holds the shop, which shop, and whether it
/// may be opened again.
class SealTile extends StatelessWidget {
  const SealTile({
    super.key,
    required this.seal,
    this.readyToRelease = false,
    this.onTap,
    this.dialer = const Dialer(),
  });

  final FieldSeal seal;

  /// Whether the seal is clear to come off — the server's judgement, read by
  /// `SealsController.isReady` and never recomputed from the amounts here.
  final bool readyToRelease;

  final VoidCallback? onTap;

  final Dialer dialer;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final String? note = _note();
    final String? outstanding = Formatters.money(seal.outstanding);
    final String? mobileNo = seal.mobileNo;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: AppText.titleMedium(
                  seal.allotteeName ?? 'No holder on record',
                  maxLines: 1,
                ),
              ),
              if (outstanding != null) ...<Widget>[
                const SizedBox(width: 12),
                AppText.titleMedium(outstanding, maxLines: 1),
              ],
            ],
          ),
          const SizedBox(height: 3),
          AppText.body(_unit, maxLines: 1),
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
                _CallButton(mobileNo: mobileNo, dialer: dialer),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String get _unit {
    final String unit =
        seal.shopNo ?? seal.propertyCode ?? seal.allotmentNo ?? 'Unit';
    final String? place = seal.marketName ?? seal.areaName;
    return place == null ? unit : '$unit · $place';
  }

  /// The seal itself: its number, and the day it went on or came off.
  String? _note() {
    final DateTime? on = seal.isSealed ? seal.sealedOn : seal.releasedOn;
    final String verb = seal.isSealed ? 'sealed' : 'released';
    final List<String> parts = <String>[
      if (seal.sealNo != null) 'Seal ${seal.sealNo}',
      if (on != null) '$verb ${Formatters.date(on.toLocal())}',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  List<Widget> _badges() {
    final String label =
        seal.status?.label ?? (seal.isSealed ? 'Sealed' : 'Released');
    final AppTone tone =
        _toneOf(seal.status?.tone) ??
        (seal.isSealed ? AppTone.danger : AppTone.success);

    return <Widget>[
      AppStatusBadge(label: label, tone: tone),
      // Only worth saying while the shop is still shut: on a seal already off,
      // "ready to release" is an answer to a question nobody is asking.
      if (readyToRelease && seal.isSealed)
        const AppStatusBadge(
          label: 'Ready to release',
          tone: AppTone.success,
          icon: Icons.lock_open_outlined,
        ),
      if (seal.caseNo != null) AppStatusBadge(label: 'Case ${seal.caseNo}'),
    ];
  }
}

/// The server's own word for how hard a status reads. Null where it sends
/// none, or a word this app does not know — the caller decides what that
/// means rather than defaulting to grey here.
AppTone? _toneOf(String? tone) => switch (tone) {
  'danger' => AppTone.danger,
  'warning' => AppTone.warning,
  'success' => AppTone.success,
  'info' => AppTone.info,
  'primary' => AppTone.primary,
  'neutral' => AppTone.neutral,
  _ => null,
};

class _CallButton extends StatelessWidget {
  const _CallButton({required this.mobileNo, required this.dialer});

  final String mobileNo;
  final Dialer dialer;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Call',
      icon: Icons.phone_outlined,
      variant: AppButtonVariant.outline,
      fullWidth: false,
      height: 34,
      onPressed: () => dialer.call(mobileNo),
    );
  }
}
