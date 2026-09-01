import 'package:get/get.dart';

import '../controllers/api/locale_controller.dart';
import '../controllers/api/offline_queue_controller.dart';
import '../controllers/api/session_controller.dart';
import '../controllers/seal_controller.dart';
import '../controllers/theme_controller.dart';
import '../core/network/api_client.dart';
import '../core/services/connectivity_service.dart';
import '../core/services/device_info_service.dart';
import '../core/services/location_service.dart';
import '../core/services/photo_service.dart';
import '../core/services/visit_reminder_service.dart';
import '../core/storage/key_value_store.dart';
import '../core/storage/read_cache.dart';
import '../core/storage/secure_token_store.dart';
import '../data/api/repositories/allotment_repository.dart';
import '../data/api/repositories/auth_repository.dart';
import '../data/api/repositories/billing_repository.dart';
import '../data/api/repositories/enforcement_repository.dart';
import '../data/api/repositories/field_repository.dart';
import '../data/api/repositories/legal_repository.dart';
import '../data/api/repositories/location_repository.dart';
import '../data/api/repositories/notification_repository.dart';
import '../data/api/repositories/payment_repository.dart';
import '../data/api/repositories/property_repository.dart';
import '../data/api/repositories/queued_write_repository.dart';
import '../data/api/repositories/reporting_repository.dart';
import '../data/repositories/chalaan_repository.dart';
import '../data/repositories/property_repository.dart' as demo;
import '../data/repositories/seal_repository.dart';

/// Registers app-wide singletons before `runApp`.
///
/// Order matters: storage, then the HTTP client, then one repository per API
/// module, then the three controllers that outlive any screen — the session,
/// the language, and the offline write queue.
///
/// Screen controllers are not registered here. They are created by their own
/// screen through `X.resolve()` (see `lib/controllers/api/`), which resolves
/// the repositories from this container.
Future<void> setupDependencies() async {
  // --- Storage ---------------------------------------------------------
  final keyValues = await KeyValueStore.open();
  Get.put<KeyValueStore>(keyValues, permanent: true);
  Get.put<SecureTokenStore>(SecureTokenStore(), permanent: true);
  Get.put<ReadCache>(ReadCache(keyValues), permanent: true);

  // --- HTTP ------------------------------------------------------------
  // One client, one interceptor: 401 signs out, 403 shows the server's
  // sentence, 409 and 422 are left for the screen.
  final client = ApiClient(tokenStore: Get.find<SecureTokenStore>());
  Get.put<ApiClient>(client, permanent: true);

  // --- Services --------------------------------------------------------
  Get.put<DeviceInfoService>(DeviceInfoService(keyValues), permanent: true);
  Get.put<PhotoService>(PhotoService(), permanent: true);
  Get.put<LocationService>(LocationService(), permanent: true);
  Get.put<ConnectivityService>(ConnectivityService(), permanent: true);
  Get.put<VisitReminderService>(VisitReminderService(), permanent: true);

  // --- One repository per API module ------------------------------------
  Get.put<AuthRepository>(
    AuthRepository(client: client, tokens: Get.find<SecureTokenStore>()),
    permanent: true,
  );
  Get.put<ReportingRepository>(
    ReportingRepository(client: client, cache: Get.find<ReadCache>()),
    permanent: true,
  );
  final enforcement = EnforcementRepository(
    client: client,
    cache: Get.find<ReadCache>(),
  );
  Get.put<EnforcementRepository>(enforcement, permanent: true);
  // The `/enforcement/field` module — the seven endpoints built for this
  // handset, each of which answers a whole screen in one request.
  Get.put<FieldRepository>(
    FieldRepository(client: client, cache: Get.find<ReadCache>()),
    permanent: true,
  );
  Get.put<PropertyApiRepository>(
    PropertyApiRepository(client: client),
    permanent: true,
  );
  Get.put<AllotmentRepository>(
    AllotmentRepository(client: client),
    permanent: true,
  );
  Get.put<BillingRepository>(BillingRepository(client: client), permanent: true);
  Get.put<PaymentRepository>(PaymentRepository(client: client), permanent: true);
  Get.put<LegalRepository>(LegalRepository(client: client), permanent: true);
  Get.put<LocationRepository>(
    LocationRepository(client: client),
    permanent: true,
  );
  Get.put<NotificationRepository>(
    NotificationRepository(client: client),
    permanent: true,
  );
  Get.put<QueuedWriteRepository>(
    ApiQueuedWriteRepository(
      client: client,
      enforcement: enforcement,
      store: keyValues,
    ),
    permanent: true,
  );

  // --- Controllers that outlive every screen ---------------------------
  Get.put<ThemeController>(ThemeController(keyValues), permanent: true);
  final locale = Get.put<LocaleController>(
    LocaleController(keyValues),
    permanent: true,
  );
  Get.put<SessionController>(
    SessionController(
      auth: Get.find<AuthRepository>(),
      client: client,
      locale: locale,
      devices: Get.find<DeviceInfoService>(),
      cache: Get.find<ReadCache>(),
    ),
    permanent: true,
  );
  // The queue drains itself when the signal returns, so it is registered
  // whether or not the queue screen is open.
  Get.put<OfflineQueueController>(
    OfflineQueueController(
      repository: Get.find<QueuedWriteRepository>(),
      connectivity: Get.find<ConnectivityService>(),
    ),
    permanent: true,
  );

  _registerDemoRepositories();
}

/// The mock repositories behind the prototype screens that predate the API
/// layer. They are not part of the officer app and nothing in it reads
/// them; they stay registered only so those screens still compile.
void _registerDemoRepositories() {
  Get.put<ChalaanRepository>(MockChalaanRepository(), permanent: true);
  Get.put<demo.PropertyRepository>(
    demo.MockPropertyRepository(),
    permanent: true,
  );
  Get.put<SealRepository>(MockSealRepository(), permanent: true);
  Get.put<SealController>(SealController(), permanent: true);
}
