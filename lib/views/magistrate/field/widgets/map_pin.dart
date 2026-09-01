import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../models/field/map_unit.dart';

/// A pin on the map, coloured by what the unit is doing — **and shaped by
/// it too.** Colour alone would leave a colour-blind officer with a field
/// of identical dots.
class MapPin extends StatelessWidget {
  const MapPin({
    super.key,
    required this.state,
    this.compact = false,
    this.selected = false,
  });

  final MapUnitState state;
  final bool compact;
  final bool selected;

  /// OpenStreetMap's standard tiles. No key to lose, no billing account to
  /// forget to renew — and they cache, which matters on bazaar data.
  static const String tileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const String userAgent = 'pk.gov.mcq.magistrate';

  static AppTone toneOf(MapUnitState state) {
    switch (state) {
      case MapUnitState.owing:
        return AppTone.danger;
      case MapUnitState.sealed:
        return AppTone.warning;
      case MapUnitState.current:
        return AppTone.success;
      case MapUnitState.vacant:
        return AppTone.info;
    }
  }

  static IconData iconOf(MapUnitState state) {
    switch (state) {
      case MapUnitState.owing:
        return Icons.priority_high_rounded;
      case MapUnitState.sealed:
        return Icons.lock_rounded;
      case MapUnitState.current:
        return Icons.check_rounded;
      case MapUnitState.vacant:
        return Icons.storefront_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colour = toneOf(state).on(context);
    final size = compact ? 16.0 : (selected ? 34.0 : 28.0);

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colour,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.surface,
            width: compact ? 1.5 : 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colour.withValues(alpha: 0.45),
              blurRadius: selected ? 14 : 6,
            ),
          ],
        ),
        child: compact
            ? null
            : Icon(
                iconOf(state),
                size: selected ? 18 : 15,
                color: Colors.white,
              ),
      ),
    );
  }
}
