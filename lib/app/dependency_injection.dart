import 'package:get/get.dart';

import '../controllers/seal_controller.dart';
import '../controllers/theme_controller.dart';
import '../data/repositories/chalaan_repository.dart';
import '../data/repositories/property_repository.dart';
import '../data/repositories/seal_repository.dart';

/// Registers app-wide singletons before [runApp].
///
/// Repositories are registered against their abstract type — swap
/// `MockChalaanRepository()` etc. for a real implementation here and no
/// controller or view needs to change. [SealController] is registered here
/// (rather than per-screen like the other controllers) because its "ready
/// to unseal" state is shared by the Magistrate shell's badge, the Home
/// banner, and the Sealed screen alike.
void setupDependencies() {
  Get.put<ChalaanRepository>(MockChalaanRepository(), permanent: true);
  Get.put<PropertyRepository>(MockPropertyRepository(), permanent: true);
  Get.put<SealRepository>(MockSealRepository(), permanent: true);
  Get.put(SealController(), permanent: true);
  Get.put(ThemeController(), permanent: true);
}
