import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../config/routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../controllers/field/field_map_controller.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/get_helpers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/field/map_unit.dart';
import '../../../widgets/widgets.dart';
import 'widgets/map_pin.dart';

/// The map — every unit in the officer's areas that has a coordinate.
///
/// Coloured **and shaped** by state, because a field of identical dots in
/// four colours is useless to a colour-blind officer and nearly useless to
/// anyone in Quetta sunlight.
///
/// Pins bunch together at low zoom into a count bubble, so a market of
/// thirty shops reads as "30 here" rather than as one unreadable blob. And
/// the units with **no** coordinate are counted in a footnote rather than
/// silently omitted: a bazaar that looks empty on the map is not the same
/// as a bazaar with nothing in it.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _map = MapController();
  double _zoom = 14;

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(FieldMapController.resolve);

    return Scaffold(
      appBar: AppBar(
        title: AppText.titleLarge(t('map.title')),
        actions: [
          IconButton(
            tooltip: t('map.nearMe'),
            icon: const Icon(Icons.my_location_rounded),
            onPressed: _goToMe,
          ),
        ],
      ),
      body: Obx(() {
        final units = controller.units.value;

        if (controller.isLoading.value && units.units.isEmpty) {
          // The shape of the map while its pins load, not a spinner over
          // a blank rectangle.
          return const Padding(
            padding: EdgeInsets.all(18),
            child: AppShimmer(child: AppSkeleton.block(height: 320)),
          );
        }
        if (controller.hasFailed && units.units.isEmpty) {
          return AppEmptyState(
            illustration: AppIllustrationKind.disconnected,
            title: t('map.couldNotLoad'),
            message: controller.failure.value!.message,
            actionLabel: t('common.retry'),
            onAction: controller.reload,
          );
        }
        if (units.units.isEmpty) {
          return AppEmptyState(
            illustration: AppIllustrationKind.noPosting,
            title: t('map.noPins'),
            message: units.withoutLocation > 0
                ? t('map.missing', args: {'n': '${units.withoutLocation}'})
                : t('map.noPinsHelp'),
          );
        }

        return Stack(
          children: [
            FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCameraFit: CameraFit.coordinates(
                  coordinates: [
                    for (final unit in units.units)
                      LatLng(unit.point.lat, unit.point.lng),
                  ],
                  padding: const EdgeInsets.all(56),
                ),
                onPositionChanged: (camera, _) {
                  if ((camera.zoom - _zoom).abs() > 0.4) {
                    setState(() => _zoom = camera.zoom);
                  }
                },
                onTap: (_, _) => controller.select(null),
              ),
              children: [
                TileLayer(
                  urlTemplate: MapPin.tileUrl,
                  userAgentPackageName: MapPin.userAgent,
                ),
                MarkerLayer(
                  markers: _markers(controller, units.units),
                ),
              ],
            ),
            PositionedDirectional(
              top: 12,
              start: 12,
              end: 12,
              child: _Legend(controller: controller, units: units),
            ),
            Obx(() {
              final selected = controller.selected.value;
              if (selected == null) return const SizedBox.shrink();
              return PositionedDirectional(
                bottom: 16,
                start: 16,
                end: 16,
                child: _PinCard(
                  unit: selected,
                  onOpen: () => context.push(
                    AppRoutes.propertyProfilePath(selected.propertyId),
                  ),
                  onClose: () => controller.select(null),
                ),
              );
            }),
          ],
        );
      }),
    );
  }

  Future<void> _goToMe() async {
    final fix = await Get.find<LocationService>().currentFix();
    if (fix == null || !mounted) return;
    _map.move(LatLng(fix.latitude, fix.longitude), 16);
  }

  /// Pins, bunched by a grid whose cell size follows the zoom.
  ///
  /// Deliberately grid clustering rather than a clustering package: a
  /// magistrate's beat is tens to low hundreds of units, the arithmetic is
  /// twenty lines, and it is one fewer dependency to keep alive on a
  /// handset build MCQ has to maintain.
  List<Marker> _markers(FieldMapController controller, List<MapUnit> units) {
    final clusters = _cluster(units, _zoom);
    return [
      for (final cluster in clusters)
        if (cluster.units.length == 1)
          Marker(
            point: LatLng(
              cluster.units.first.point.lat,
              cluster.units.first.point.lng,
            ),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                AppHaptics.select();
                controller.select(cluster.units.first);
              },
              child: Obx(
                () => MapPin(
                  state: cluster.units.first.state,
                  selected: controller.selected.value?.propertyId ==
                      cluster.units.first.propertyId,
                ),
              ),
            ),
          )
        else
          Marker(
            point: LatLng(cluster.lat, cluster.lng),
            width: 46,
            height: 46,
            child: GestureDetector(
              onTap: () => _map.move(LatLng(cluster.lat, cluster.lng), _zoom + 2),
              child: _ClusterBubble(cluster: cluster),
            ),
          ),
    ];
  }

  static List<_Cluster> _cluster(List<MapUnit> units, double zoom) {
    // Roughly 90m of grid at zoom 17, doubling each level down.
    final cell = 0.0008 * math.pow(2, math.max(0, 17 - zoom));
    final buckets = <String, List<MapUnit>>{};
    for (final unit in units) {
      final key =
          '${(unit.point.lat / cell).floor()}:${(unit.point.lng / cell).floor()}';
      buckets.putIfAbsent(key, () => []).add(unit);
    }
    return [
      for (final bucket in buckets.values)
        _Cluster(
          units: bucket,
          lat: bucket.map((u) => u.point.lat).reduce((a, b) => a + b) /
              bucket.length,
          lng: bucket.map((u) => u.point.lng).reduce((a, b) => a + b) /
              bucket.length,
        ),
    ];
  }
}

class _Cluster {
  const _Cluster({required this.units, required this.lat, required this.lng});

  final List<MapUnit> units;
  final double lat;
  final double lng;

  /// A cluster takes the tone of the worst thing in it. A market with one
  /// sealed shop in it should not read as settled.
  MapUnitState get worst {
    if (units.any((u) => u.state == MapUnitState.owing)) {
      return MapUnitState.owing;
    }
    if (units.any((u) => u.state == MapUnitState.sealed)) {
      return MapUnitState.sealed;
    }
    if (units.any((u) => u.state == MapUnitState.vacant)) {
      return MapUnitState.vacant;
    }
    return MapUnitState.current;
  }
}

class _ClusterBubble extends StatelessWidget {
  const _ClusterBubble({required this.cluster});

  final _Cluster cluster;

  @override
  Widget build(BuildContext context) {
    final colour = MapPin.toneOf(cluster.worst).on(context);
    return Center(
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colour,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.surface,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(color: colour.withValues(alpha: 0.4), blurRadius: 10),
          ],
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: AppText.titleSmall(
            '${cluster.units.length}',
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// What the colours mean, and how many units the map could not place.
class _Legend extends StatelessWidget {
  const _Legend({required this.controller, required this.units});

  final FieldMapController controller;
  final MapUnits units;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              for (final state in MapUnitState.values)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      MapPin.iconOf(state),
                      size: 14,
                      color: MapPin.toneOf(state).on(context),
                    ),
                    const SizedBox(width: 5),
                    AppText.caption(t('map.state.${state.name}')),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppText.bodySmall(
                  units.withoutLocation > 0
                      // Said out loud. Never silently omitted.
                      ? t('map.missing',
                          args: {'n': '${units.withoutLocation}'})
                      : t('map.subtitle',
                          args: {'n': '${units.units.length}'}),
                  color: units.withoutLocation > 0
                      ? AppTone.warning.on(context)
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Obx(
                () => Switch.adaptive(
                  value: controller.defaultersOnly.value,
                  onChanged: controller.toggleDefaultersOnly,
                ),
              ),
              AppText.caption(t('map.owingOnly')),
            ],
          ),
        ],
      ),
    );
  }
}

/// The compact card a pin opens: who, how much, and one way in.
class _PinCard extends StatelessWidget {
  const _PinCard({
    required this.unit,
    required this.onOpen,
    required this.onClose,
  });

  final MapUnit unit;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      tone: MapPin.toneOf(unit.state),
      rail: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserText.headline(
                      unit.allotteeName,
                      fallback: t('card.noTenant'),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    AppText.bodySmall(
                      unit.unitLabel,
                      maxLines: 1,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (unit.outstanding != null)
                MoneyText(
                  unit.outstanding!,
                  variant: AppTextVariant.titleLarge,
                  color: AppTone.danger.on(context),
                )
              else
                AppText.titleMedium(
                  t('card.vacant'),
                  color: AppTone.info.on(context),
                ),
              const Spacer(),
              AppButton(
                label: t('map.openProfile'),
                variant: AppButtonVariant.outline,
                fullWidth: false,
                height: 44,
                onPressed: onOpen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
