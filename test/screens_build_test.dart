import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mcq_app/controllers/api/locale_controller.dart';
import 'package:mcq_app/controllers/api/offline_queue_controller.dart';
import 'package:mcq_app/controllers/api/seal_form_controller.dart';
import 'package:mcq_app/controllers/api/session_controller.dart';
import 'package:mcq_app/core/network/api_client.dart';
import 'package:mcq_app/core/network/api_envelope.dart';
import 'package:mcq_app/core/services/connectivity_service.dart';
import 'package:mcq_app/core/services/device_info_service.dart';
import 'package:mcq_app/core/services/location_service.dart';
import 'package:mcq_app/core/services/photo_service.dart';
import 'package:mcq_app/core/storage/key_value_store.dart';
import 'package:mcq_app/core/storage/read_cache.dart';
import 'package:mcq_app/core/storage/secure_token_store.dart';
import 'package:mcq_app/data/api/repositories/auth_repository.dart';
import 'package:mcq_app/data/api/repositories/enforcement_repository.dart';
import 'package:mcq_app/data/api/repositories/queued_write_repository.dart';
import 'package:mcq_app/models/offline/queued_write.dart';
import 'package:mcq_app/views/auth/change_password_screen.dart';
import 'package:mcq_app/views/magistrate/api/case_write_args.dart';
import 'package:mcq_app/views/magistrate/api/seal_form_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// These are regression tests for one specific and easy mistake: wrapping an
/// input in `Obx` when the only observable it touches is inside a callback
/// (`validator:`, `onChanged:`). The builder then reads nothing at build
/// time and GetX throws "the improper use of a GetX has been detected" —
/// which reaches the officer as a red screen where a form should be.
///
/// A screen that renders without an exception is the whole assertion.
class _NoFix extends LocationService {
  @override
  Future<GpsFix?> currentFix({Duration timeout = const Duration(seconds: 12)}) async =>
      null;
}

class _OfflineConnectivity extends ConnectivityService {
  @override
  Future<bool> get isOnline async => false;

  @override
  Stream<bool> get onChanged => const Stream<bool>.empty();
}

class _EmptyQueue implements QueuedWriteRepository {
  @override
  List<QueuedWrite> load() => [];

  @override
  Future<void> save(List<QueuedWrite> queue) async {}

  @override
  Future<ApiEnvelope> send(QueuedWrite write) async =>
      const ApiEnvelope(data: {}, statusCode: 201);
}

Future<void> _registerCoreDependencies() async {
  SharedPreferences.setMockInitialValues({});
  final store = await KeyValueStore.open();
  final tokens = SecureTokenStore();
  final client = ApiClient(tokenStore: tokens);
  final cache = ReadCache(store);

  Get.put<KeyValueStore>(store);
  Get.put<SecureTokenStore>(tokens);
  Get.put<ApiClient>(client);
  Get.put<ReadCache>(cache);
  Get.put<PhotoService>(PhotoService());
  Get.put<LocationService>(_NoFix());
  Get.put<DeviceInfoService>(DeviceInfoService(store));
  Get.put<EnforcementRepository>(
    EnforcementRepository(client: client, cache: cache),
  );
  Get.put<QueuedWriteRepository>(_EmptyQueue());
  Get.put<OfflineQueueController>(
    OfflineQueueController(
      repository: Get.find<QueuedWriteRepository>(),
      connectivity: _OfflineConnectivity(),
    ),
  );
  final locale = Get.put<LocaleController>(LocaleController(store));
  Get.put<SessionController>(
    SessionController(
      auth: AuthRepository(client: client, tokens: tokens),
      client: client,
      locale: locale,
      devices: Get.find<DeviceInfoService>(),
      cache: cache,
    ),
  );
}

void main() {
  setUp(_registerCoreDependencies);
  tearDown(Get.reset);

  testWidgets('the forced password-change screen renders', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ChangePasswordScreen()),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(TextFormField), findsNWidgets(3));
  });

  testWidgets('the seal form renders and refuses to submit without a photograph',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SealFormScreen(
          mode: SealMode.seal,
          caseId: 7,
          args: CaseWriteArgs(
            shopLabel: 'P-1',
            allotteeName: 'Abdul Rehman',
            caseId: 7,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // The confirmation text names the shop and the allottee before anything
    // is sent, and the button is dead until the shutter is photographed.
    expect(find.textContaining('P-1'), findsWidgets);
    expect(find.textContaining('Abdul Rehman'), findsWidgets);

    final controller = Get.find<SealFormController>(tag: 'seal-seal-7');
    expect(controller.isValid, isFalse);
    controller.reason.value = 'Arrears of five months';
    expect(controller.isValid, isFalse, reason: 'still no photograph');
  });
}
