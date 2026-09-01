import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/field/map_unit.dart';
import '../../../../widgets/widgets.dart';
import 'map_pin.dart';

/// A small map on the home screen, showing the officer's beat.
///
/// It is a preview, not a working map: the pins are drawn, panning is
/// disabled, and the whole card is one tap into the real one. A map that
/// steals a scroll gesture on a home screen is a map that makes the home
/// screen unusable.
class MapPreviewCard extends StatelessWidget {
  const MapPreviewCard({
    super.key,
    required this.units,
    required this.onTap,
  });

  final MapUnits units;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pins = units.units.take(60).toList();

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 168,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (pins.isEmpty)
                  Container(
                    color: AppTone.info.surface(context),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.map_outlined,
                      size: 34,
                      color: AppTone.info.on(context),
                    ),
                  )
                else
                  IgnorePointer(
                    child: FlutterMap(
                      options: MapOptions(
                        initialCameraFit: CameraFit.coordinates(
                          coordinates: [
                            for (final unit in pins)
                              LatLng(unit.point.lat, unit.point.lng),
                          ],
                          padding: const EdgeInsets.all(36),
                        ),
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: MapPin.tileUrl,
                          userAgentPackageName: MapPin.userAgent,
                        ),
                        MarkerLayer(
                          markers: [
                            for (final unit in pins)
                              Marker(
                                point:
                                    LatLng(unit.point.lat, unit.point.lng),
                                width: 20,
                                height: 20,
                                child: MapPin(state: unit.state, compact: true),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                PositionedDirectional(
                  bottom: 10,
                  start: 12,
                  child: Container(
                    padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 12, 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.map_rounded,
                          size: 15,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        AppText.caption(t('map.openFull')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleMedium(t('map.title')),
                const SizedBox(height: 2),
                AppText.bodySmall(
                  t('map.subtitle', args: {'n': '${units.units.length}'}),
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                // Units with no coordinate do not appear, and that is said
                // out loud rather than silently swallowed.
                if (units.withoutLocation > 0) ...[
                  const SizedBox(height: 4),
                  AppText.bodySmall(
                    t('map.missing', args: {'n': '${units.withoutLocation}'}),
                    color: AppTone.warning.on(context),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
