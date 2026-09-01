import 'package:get/get.dart';

import '../../data/api/repositories/field_repository.dart';
import '../../models/field/map_unit.dart';
import '../api/async_state.dart';

/// The map.
///
/// Every unit in the officer's areas that has a coordinate, coloured by
/// what it is doing — owing, sealed, current, vacant. The ones with no
/// coordinate are **counted and said out loud** rather than quietly left
/// off: a bazaar that looks empty on a map is not the same as a bazaar
/// with nothing in it.
class FieldMapController extends GetxController with AsyncState {
  FieldMapController({required FieldRepository field}) : _field = field;

  factory FieldMapController.resolve() => FieldMapController(field: Get.find());

  final FieldRepository _field;

  final Rx<MapUnits> units = MapUnits.empty.obs;
  final RxBool defaultersOnly = true.obs;
  final Rx<MapUnit?> selected = Rx<MapUnit?>(null);

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  void toggleDefaultersOnly(bool value) {
    defaultersOnly.value = value;
    reload();
  }

  void select(MapUnit? unit) => selected.value = unit;

  Future<void> reload({bool refreshing = false}) => load(
        () async {
          units.value =
              await _field.mapUnits(defaultersOnly: defaultersOnly.value);
          markFetched(DateTime.now(), fromCache: false);
        },
        refreshing: refreshing,
      );

  bool get hasPins => units.value.units.isNotEmpty;
  int get missingLocations => units.value.withoutLocation;
}
