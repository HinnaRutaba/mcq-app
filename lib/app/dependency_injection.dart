import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/defaulters_controller.dart';
import '../controllers/definitions_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/trade_licences_controller.dart';
import '../core/network/api_service.dart';
import '../core/permissions/permission_service.dart';
import '../core/storage/secure_storage_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/challan_repository.dart';
import '../data/repositories/dashboard_repository.dart';
import '../data/repositories/defaulters_repository.dart';
import '../data/repositories/definitions_repository.dart';
import '../data/repositories/enforcement_case_repository.dart';
import '../data/repositories/evidence_repository.dart';
import '../data/repositories/field_seal_repository.dart';
import '../data/repositories/fine_repository.dart';
import '../data/repositories/person_repository.dart';
import '../data/repositories/reporting_repository.dart';
import '../data/repositories/trade_repository.dart';
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
  // Master data first, because it is what every enforcement drop-down is drawn
  // from. It caches, so registering it here costs nothing until something asks.
  Get.put<DefinitionsRepository>(
    ApiDefinitionsRepository(api: api),
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
  Get.put<PersonRepository>(ApiPersonRepository(api: api), permanent: true);
  Get.put<FieldSealRepository>(
    ApiFieldSealRepository(api: api),
    permanent: true,
  );
  Get.put<ChallanRepository>(ApiChallanRepository(api: api), permanent: true);
  Get.put<EvidenceRepository>(ApiEvidenceRepository(api: api), permanent: true);

  // A different register from everything above: the shops MCQ licenses but is
  // not landlord to. Same bazaar, second job.
  Get.put<TradeRepository>(ApiTradeRepository(api: api), permanent: true);

  // The session owner. Permanent because three places read it: the splash
  // screen restoring a stored token, the sign-in form, and the profile
  // screen's sign-out.
  Get.put(AuthController(), permanent: true);
  Get.put(ThemeController(), permanent: true);

  // After the session owner, and permanent alongside it: the enforcement
  // module's drop-downs are read from here for the whole app lifecycle, and
  // this watches `AuthController.officer` to know when it may fetch them. It
  // puts nothing on the wire until an officer is signed in — see
  // [DefinitionsController] — so registering it eagerly is safe where the
  // fetching controllers below are not.
  Get.put(DefinitionsController(), permanent: true);

  // Lazily, unlike the rest: these fetch in `onInit`, and building them here
  // would put authenticated calls on the wire before anyone has signed in.
  // Each is created when its tab first asks for it, and `fenix` rebuilds it
  // if the branch is ever disposed.
  Get.lazyPut<DashboardController>(DashboardController.new, fenix: true);
  Get.lazyPut<DefaultersController>(DefaultersController.new, fenix: true);
  Get.lazyPut<TradeLicencesController>(
    TradeLicencesController.new,
    fenix: true,
  );
}
