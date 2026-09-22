import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/dialer.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/map_pins.dart';
import '../../../../models/unit_card.dart';
import '../../../../widgets/widgets.dart';

/// What the map says about the shop under a pin, at the foot of the screen.
///
/// A card over the map rather than a modal sheet: the officer is reading a
/// bazaar, and a panel that has to be dismissed before the next pin can be
/// pressed turns browsing into a sequence of dialogs.
///
/// [unit] is the search row for the same property when the list in hand holds
/// one — the pin payload names no holder and carries no mobile number, so the
/// card is thinner without it rather than wrong.
class PinCard extends StatelessWidget {
  const PinCard({
    super.key,
    required this.pin,
    this.unit,
    this.onOpen,
    this.onClose,
    this.dialer = const Dialer(),
  });

  final MapPin pin;
  final UnitCard? unit;

  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  final Dialer dialer;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color? muted = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.6,
    );
    final String? owed = _owed;
    final String? note = _note;
    final List<Widget> badges = _badges();
    final String? mobileNo = unit?.mobileNo;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: AppText.titleMedium(_title, maxLines: 1)),
              if (owed != null) ...<Widget>[
                const SizedBox(width: 12),
                AppText.titleMedium(owed, maxLines: 1),
              ],
              if (onClose != null) ...<Widget>[
                const SizedBox(width: 8),
                AppCircleIconButton(
                  icon: Icons.close_rounded,
                  size: 30,
                  background: theme.colorScheme.surfaceContainerHigh,
                  iconColor: muted,
                  onTap: onClose,
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          AppText.body(_unitLine, maxLines: 1),
          if (note != null) ...<Widget>[
            const SizedBox(height: 4),
            AppText.caption(note, color: muted, maxLines: 1),
          ],
          if (badges.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: badges),
          ],
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              if (mobileNo != null) ...<Widget>[
                AppButton(
                  label: 'Call',
                  icon: Icons.phone_outlined,
                  variant: AppButtonVariant.outline,
                  fullWidth: false,
                  height: 38,
                  onPressed: () => dialer.call(mobileNo),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: AppButton(
                  label: 'Open shop',
                  icon: Icons.storefront_outlined,
                  height: 38,
                  onPressed: onOpen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Who holds it where the search list knows, and what it is where nobody
  /// does — a pin on its own never names a person.
  String get _title {
    final String? holder = unit?.allotteeName;
    if (holder != null) return holder;
    if (_isVacant) return 'Vacant — nobody holds this unit';
    return _unitLine;
  }

  String get _unitLine {
    final String shop = pin.shopNo ?? pin.propertyCode ?? 'Unit';
    final String? place = pin.marketName ?? pin.areaName;
    return place == null ? shop : '$shop · $place';
  }

  String? get _note {
    final List<String> parts = <String>[
      if (pin.propertyCode != null) pin.propertyCode!,
      if (pin.categoryName != null) pin.categoryName!,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  bool get _isVacant =>
      unit?.isVacant ?? (pin.occupancyStatus?.toLowerCase() == 'vacant');

  /// Rent arrears, and nothing where there are none: "Rs 0" beside a shop
  /// reads as a debt.
  String? get _owed {
    final num? value = num.tryParse(pin.outstanding.trim());
    if (value != null && value <= 0) return null;
    return Formatters.money(pin.outstanding);
  }

  List<Widget> _badges() {
    final int months = pin.unpaidMonths;
    return <Widget>[
      if (_isVacant) const AppStatusBadge(label: 'Vacant', tone: AppTone.info),
      if (pin.sealed)
        const AppStatusBadge(label: 'Sealed', tone: AppTone.danger),
      if (months > 0)
        AppStatusBadge(
          label: '$months ${months == 1 ? 'month' : 'months'} behind',
          tone: AppTone.warning,
        ),
      if (pin.physicalStatus != null)
        AppStatusBadge(label: _sentence(pin.physicalStatus!)),
    ];
  }

  /// `closed` as the register sends it, said the way a label reads.
  static String _sentence(String value) {
    final String trimmed = value.replaceAll('_', ' ').trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }
}
