import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../data/api/repositories/billing_repository.dart';
import '../../data/api/repositories/enforcement_repository.dart';
import '../../data/api/repositories/property_repository.dart';
import '../../data/api/repositories/reporting_repository.dart';
import '../../models/auth/permissions.dart';
import '../../models/billing/challan.dart';
import '../../models/enforcement/fine.dart';
import '../../models/property/property_summary.dart';
import 'async_state.dart';
import 'session_controller.dart';

/// One unit, in full: who holds it, what it owes, whether it is sealed, and
/// what has been imposed on it.
///
/// The profile endpoint is preferred over three round trips on a mobile
/// connection; the challans and fines beside it are separate because a fine
/// is a separate debt from the rent and the screen shows two obligations,
/// never one total.
class PropertyProfileController extends GetxController with AsyncState {
  PropertyProfileController({
    required this.propertyId,
    required ReportingRepository reporting,
    required PropertyApiRepository properties,
    required BillingRepository billing,
    required EnforcementRepository enforcement,
    required SessionController session,
  })  : _reporting = reporting,
        _properties = properties,
        _billing = billing,
        _enforcement = enforcement,
        _session = session;

  factory PropertyProfileController.resolve(int propertyId) =>
      PropertyProfileController(
        propertyId: propertyId,
        reporting: Get.find(),
        properties: Get.find(),
        billing: Get.find(),
        enforcement: Get.find(),
        session: Get.find(),
      );

  final int propertyId;
  final ReportingRepository _reporting;
  final PropertyApiRepository _properties;
  final BillingRepository _billing;
  final EnforcementRepository _enforcement;
  final SessionController _session;

  final Rx<PropertyProfile?> profile = Rx<PropertyProfile?>(null);
  final Rx<PropertySummary?> property = Rx<PropertySummary?>(null);
  final RxList<Challan> challans = <Challan>[].obs;
  final RxList<Fine> fines = <Fine>[].obs;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload({bool refreshing = false}) => load(
        () async {
          try {
            final loaded = await _reporting.propertyProfile(propertyId);
            profile.value = loaded;
            property.value = loaded.property;
          } on ApiException catch (error) {
            // The profile lives in the reporting module; if this officer
            // cannot open it, the property endpoint still can.
            if (!error.isForbidden && error.kind != ApiFailureKind.notFound) {
              rethrow;
            }
            property.value = await _properties.byId(propertyId);
          }
          markFetched(DateTime.now(), fromCache: false);

          final allotmentId = property.value?.allotment.id;
          if (_session.can(Permissions.challanView) &&
              allotmentId != null &&
              allotmentId != 0) {
            final page = await _billing.challans(allotmentId: allotmentId);
            challans.assignAll(page.items);
          }
          if (_session.can(Permissions.fineView)) {
            final page = await _enforcement.fines(propertyId: propertyId);
            fines.assignAll(page.value.items);
          }
        },
        refreshing: refreshing,
      );

  /// Rent and fine obligations, kept apart. Paying the fine does not settle
  /// the rent and paying the rent does not settle the fine.
  List<Challan> get rentChallans =>
      challans.where((challan) => !challan.isFine).toList();

  List<Challan> get fineChallans =>
      challans.where((challan) => challan.isFine).toList();

  bool get canImposeFine =>
      _session.can(Permissions.fineImpose) && property.value != null;

  bool get canRecordInspection => _session.can(Permissions.inspectionRecord);

  /// A live stay order stops enforcement on this property.
  bool get hasLiveStay => profile.value?.liveStayOrder ?? false;
}
