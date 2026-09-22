import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../models/map_pins.dart';

/// The officer's bazaars from above: one marker per unit the register could
/// place, as `reporting/map` sends them.
///
/// The camera is driven by [selected] rather than by a controller handed in
/// from outside — a search sets the pin it found, and the map flies to it.
class UnitMap extends StatefulWidget {
  const UnitMap({
    super.key,
    required this.pins,
    required this.selected,
    required this.onTapPin,
    required this.onTapMap,
  });

  final List<MapPin> pins;

  /// The pin the card is open on, and what the camera holds.
  final MapPin? selected;

  final ValueChanged<MapPin> onTapPin;

  /// A press on the map itself, which closes the card.
  final VoidCallback onTapMap;

  /// Where the camera sits before anything has been placed: the old city,
  /// which is where every bazaar on the register is.
  static const LatLng quetta = LatLng(30.1956, 67.0164);

  /// Far enough out to hold a bazaar, and close enough to stand in front of
  /// one shop.
  static const double cityZoom = 14;
  static const double shopZoom = 18;

  /// Room left around the pins when the whole beat is fitted on screen — the
  /// search box is over the top of it and the card comes up from the bottom.
  static const double boundsPadding = 64;

  @override
  State<UnitMap> createState() => _UnitMapState();
}

class _UnitMapState extends State<UnitMap> {
  GoogleMapController? _map;

  @override
  void didUpdateWidget(UnitMap old) {
    super.didUpdateWidget(old);

    final MapPin? selected = widget.selected;
    if (selected != null && !identical(selected, old.selected)) {
      _flyTo(selected);
      return;
    }
    // The pins landing after the map did: show the beat rather than the city.
    if (selected == null && widget.pins.length != old.pins.length) _fitPins();
  }

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  void _created(GoogleMapController map) {
    _map = map;
    final MapPin? selected = widget.selected;
    if (selected != null) {
      _flyTo(selected);
      return;
    }
    _fitPins();
  }

  void _flyTo(MapPin pin) {
    final LatLng? at = _latLng(pin);
    if (at == null) return;
    _map?.animateCamera(CameraUpdate.newLatLngZoom(at, UnitMap.shopZoom));
  }

  /// The whole beat on screen at once. One pin has no bounds to speak of, so
  /// it is flown to instead.
  void _fitPins() {
    final List<LatLng> points = <LatLng>[
      for (final MapPin pin in widget.pins)
        if (_latLng(pin) case final LatLng at) at,
    ];
    if (points.isEmpty || _map == null) return;

    if (points.length == 1) {
      _map!.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, UnitMap.cityZoom + 2),
      );
      return;
    }

    double south = points.first.latitude;
    double north = points.first.latitude;
    double west = points.first.longitude;
    double east = points.first.longitude;
    for (final LatLng at in points) {
      south = at.latitude < south ? at.latitude : south;
      north = at.latitude > north ? at.latitude : north;
      west = at.longitude < west ? at.longitude : west;
      east = at.longitude > east ? at.longitude : east;
    }

    _map!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(south, west),
          northeast: LatLng(north, east),
        ),
        UnitMap.boundsPadding,
      ),
    );
  }

  static LatLng? _latLng(MapPin pin) {
    final double? lat = pin.latitudeValue;
    final double? lng = pin.longitudeValue;
    return lat == null || lng == null ? null : LatLng(lat, lng);
  }

  Set<Marker> get _markers {
    final MapPin? selected = widget.selected;
    final Set<Marker> markers = <Marker>{};

    for (int i = 0; i < widget.pins.length; i++) {
      final MapPin pin = widget.pins[i];
      final LatLng? at = _latLng(pin);
      if (at == null) continue;

      markers.add(
        Marker(
          markerId: MarkerId('${pin.propertyId ?? pin.propertyCode ?? i}'),
          position: at,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _hue(pin, chosen: identical(pin, selected)),
          ),
          // The card at the foot of the screen is the information; without
          // this the platform's own bubble opens over it as well.
          consumeTapEvents: true,
          onTap: () => widget.onTapPin(pin),
        ),
      );
    }

    // A shop found by the search that the pin list never carried — placed from
    // its own fix, or the camera would fly to nothing.
    if (selected != null &&
        !markers.any((Marker marker) => marker.position == _latLng(selected))) {
      final LatLng? at = _latLng(selected);
      if (at != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('searched'),
            position: at,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            consumeTapEvents: true,
            onTap: () => widget.onTapPin(selected),
          ),
        );
      }
    }

    return markers;
  }

  /// Sealed shut, behind on the rent, or neither — the same three readings the
  /// tiles carry, in the only palette a stock marker has.
  static double _hue(MapPin pin, {required bool chosen}) {
    if (chosen) return BitmapDescriptor.hueAzure;
    if (pin.sealed) return BitmapDescriptor.hueRed;
    if (pin.unpaidMonths > 0 || pin.severity == 'owing') {
      return BitmapDescriptor.hueOrange;
    }
    return BitmapDescriptor.hueGreen;
  }

  @override
  Widget build(BuildContext context) {
    final MapPin? selected = widget.selected;
    final LatLng start =
        (selected == null ? null : _latLng(selected)) ??
        (widget.pins.isEmpty ? null : _latLng(widget.pins.first)) ??
        UnitMap.quetta;

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: start,
        zoom: selected == null ? UnitMap.cityZoom : UnitMap.shopZoom,
      ),
      markers: _markers,
      onMapCreated: _created,
      onTap: (LatLng _) => widget.onTapMap(),
      // The map sits in a scroll view, and without this a drag across it
      // scrolls the page instead of panning the bazaar.
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
      },
      // The app's own chrome is over the top of this; the platform's would sit
      // under the search box and the card.
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      // Off on purpose: the blue dot costs a location prompt, and this screen
      // is opened to find a shop, not to be found.
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
    );
  }
}
