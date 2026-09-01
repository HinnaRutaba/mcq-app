import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/theme_controller.dart';
import '../core/network/api_service.dart';
import '../core/permissions/permission_service.dart';
import '../core/storage/secure_storage_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/challan_repository.dart';
import '../data/repositories/dashboard_repository.dart';
import '../data/repositories/defaulters_repository.dart';
import '../data/repositories/enforcement_case_repository.dart';
import '../data/repositories/evidence_repository.dart';
import '../data/repositories/field_seal_repository.dart';
import '../data/repositories/fine_repository.dart';
import '../data/repositories/reporting_repository.dart';
import '../data/repositories/units_repository.dart';

/// Registers app-wide singletons before [runApp].
///
/// Repositories are registered against their abstract type, so a controller
/// asking for [AuthRepository] never learns whether it is talking to the API or
/// to a stand-in.
///
/// Order matters: [SecureStorageService] holds the bearer token, [ApiService]
/// reads it on every call, and every repository is built on top of that.
void setupDependencies() {
  final storage = SecureStorageService();
  Get.put<SecureStorageService>(storage, permanent: true);

  // A 401 has already cleared the keychain by the time `onUnauthorized` fires;
  // wire it to the router when the app starts routing on session state, so a
  // dead token lands the officer on the sign-in screen instead of an empty one.
  final api = ApiService(storage: storage);
  Get.put<ApiService>(api, permanent: true);

  Get.put<PermissionService>(const PermissionService(), permanent: true);

  // MCQ Magistrate API, in the order an officer meets the screens.
  Get.put<AuthRepository>(
    ApiAuthRepository(api: api, storage: storage),
    permanent: true,
  );
  Get.put<DashboardRepository>(
    ApiDashboardRepository(api: api),
    permanent: true,
  );
  Get.put<DefaultersRepository>(
    ApiDefaultersRepository(api: api),
    permanent: true,
  );
  Get.put<UnitsRepository>(ApiUnitsRepository(api: api), permanent: true);
  Get.put<ReportingRepository>(
    ApiReportingRepository(api: api),
    permanent: true,
  );
  Get.put<EnforcementCaseRepository>(
    ApiEnforcementCaseRepository(api: api),
    permanent: true,
  );
  Get.put<FineRepository>(ApiFineRepository(api: api), permanent: true);
  Get.put<FieldSealRepository>(
    ApiFieldSealRepository(api: api),
    permanent: true,
  );
  Get.put<ChallanRepository>(ApiChallanRepository(api: api), permanent: true);
  Get.put<EvidenceRepository>(ApiEvidenceRepository(api: api), permanent: true);

  // The session owner. Permanent because three places read it: the splash
  // screen restoring a stored token, the sign-in form, and the profile
  // screen's sign-out.
  Get.put(AuthController(), permanent: true);
  Get.put(ThemeController(), permanent: true);

  // Lazily, unlike the rest: this one fetches in `onInit`, and building it
  // here would put two authenticated calls on the wire before anyone has
  // signed in. It is created when the home screen first asks for it, and
  // `fenix` rebuilds it if the branch is ever disposed.
  Get.lazyPut<DashboardController>(DashboardController.new, fenix: true);
}
