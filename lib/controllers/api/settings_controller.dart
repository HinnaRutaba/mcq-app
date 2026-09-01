import 'package:get/get.dart';

import '../../core/services/device_info_service.dart';
import '../../data/api/repositories/location_repository.dart';
import '../../models/auth/permissions.dart';
import '../../models/location/posting.dart';
import 'async_state.dart';
import 'session_controller.dart';

/// The officer's own details: their postings, the name this handset carries,
/// and the language.
class SettingsController extends GetxController with AsyncState {
  SettingsController({
    required LocationRepository locations,
    required SessionController session,
    required DeviceInfoService devices,
  })  : _locations = locations,
        _session = session,
        _devices = devices;

  factory SettingsController.resolve() => SettingsController(
        locations: Get.find(),
        session: Get.find(),
        devices: Get.find(),
      );

  final LocationRepository _locations;
  final SessionController _session;
  final DeviceInfoService _devices;

  final RxList<Posting> postings = <Posting>[].obs;
  final RxString deviceName = ''.obs;
  final Rx<DateTime?> tokenExpiry = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload({bool refreshing = false}) => load(
        () async {
          deviceName.value = await _devices.suggestedDeviceName();
          final officer = _session.user.value;
          if (officer != null && _session.can(Permissions.postingView)) {
            postings.assignAll(await _locations.postings(userId: officer.id));
          }
        },
        refreshing: refreshing,
      );
}
