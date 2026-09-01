import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../data/api/repositories/billing_repository.dart';
import '../../data/api/repositories/enforcement_repository.dart';
import '../../data/api/repositories/field_repository.dart';
import '../../data/api/repositories/property_repository.dart';
import '../../data/api/repositories/reporting_repository.dart';
import '../../models/auth/permissions.dart';
import '../../models/billing/challan.dart';
import '../../models/enforcement/enforcement_case.dart';
import '../../models/enforcement/field_evidence.dart';
import '../../models/enforcement/fine.dart';
import '../../models/field/field_card.dart';
import '../../models/property/property_summary.dart';
import '../api/async_state.dart';
import '../api/session_controller.dart';

/// The shopkeeper profile.
///
/// The card the officer tapped is already in his hand, so the screen is
/// built out of that **first** and enriched afterwards. That ordering is
/// the whole design: the name, the unit and the amount are on screen before
/// a single request goes out, so a shared-element transition has something
/// to land on and a dead signal still shows a usable page.
///
/// Everything after that is additive and each part is allowed to fail on
/// its own. A magistrate who cannot open the reporting profile because of a
/// permission he does not hold must still get the timeline.
class ShopProfileController extends GetxController with AsyncState {
  ShopProfileController({
    required this.propertyId,
    required FieldRepository field,
    required ReportingRepository reporting,
    required PropertyApiRepository properties,
    required BillingRepository billing,
    required EnforcementRepository enforcement,
    required SessionController session,
    FieldCard? seed,
  })  : _field = field,
        _reporting = reporting,
        _properties = properties,
        _billing = billing,
        _enforcement = enforcement,
        _session = session {
    card.value = seed;
  }

  factory ShopProfileController.resolve(int propertyId, {FieldCard? seed}) =>
      ShopProfileController(
        propertyId: propertyId,
        seed: seed,
        field: Get.find(),
        reporting: Get.find(),
        properties: Get.find(),
        billing: Get.find(),
        enforcement: Get.find(),
        session: Get.find(),
      );

  final int propertyId;
  final FieldRepository _field;
  final ReportingRepository _reporting;
  final PropertyApiRepository _properties;
  final BillingRepository _billing;
  final EnforcementRepository _enforcement;
  final SessionController _session;

  /// The card the officer tapped, when he came from a list. Null on a cold
  /// deep link, and then fetched.
  final Rx<FieldCard?> card = Rx<FieldCard?>(null);

  final Rx<PropertyProfile?> profile = Rx<PropertyProfile?>(null);
  final Rx<PropertySummary?> property = Rx<PropertySummary?>(null);
  final RxList<EnforcementCase> cases = <EnforcementCase>[].obs;
  final RxList<CaseAction> timeline = <CaseAction>[].obs;
  final RxList<Fine> fines = <Fine>[].obs;
  final RxList<Challan> challans = <Challan>[].obs;

  final RxBool isLoadingTimeline = false.obs;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload({bool refreshing = false}) async {
    await load(
      () async {
        // The card first: it is the cheapest and it is what the transition
        // landed on.
        if (card.value == null) await _loadCard();
        await _loadProperty();
        markFetched(DateTime.now(), fromCache: false);
      },
      refreshing: refreshing,
    );
    await _loadCases();
    await _loadTimeline();
    await _loadObligations();
  }

  /// A cold deep link — a notification, a restored session. `field/units`
  /// answers with the same card shape the lists use, so the screen is built
  /// out of exactly the same object either way.
  Future<void> _loadCard() async {
    try {
      final units = await _field.units(search: '$propertyId', limit: 5);
      for (final unit in units) {
        if (unit.propertyId == propertyId) {
          card.value = unit;
          return;
        }
      }
    } on ApiException {
      // Not fatal — the property lookup below fills the same gaps.
    }
  }

  Future<void> _loadProperty() async {
    try {
      final loaded = await _reporting.propertyProfile(propertyId);
      profile.value = loaded;
      property.value = loaded.property;
    } on ApiException catch (error) {
      // The profile lives in the reporting module. An officer who cannot
      // open it still gets the property endpoint.
      if (error.isForbidden || error.kind == ApiFailureKind.notFound) {
        property.value = await _properties.byId(propertyId);
        return;
      }
      if (card.value == null) rethrow;
      // There is already a card on screen; a failed enrichment is not a
      // reason to replace a usable page with an error.
    }
  }

  Future<void> _loadCases() async {
    if (!_session.can(Permissions.caseView)) return;
    try {
      final page = await _enforcement.cases(propertyId: propertyId);
      cases.assignAll(page.value.items);
    } on ApiException {
      // Leave the list as it is.
    }
  }

  Future<void> _loadTimeline() async {
    final id = openCaseId;
    if (id == null || !_session.can(Permissions.actionView)) return;
    isLoadingTimeline.value = true;
    try {
      final page = await _enforcement.caseActions(id);
      timeline.assignAll(page.items);
    } on ApiException {
      // Same again: a missing timeline is not a broken profile.
    } finally {
      isLoadingTimeline.value = false;
    }
  }

  Future<void> _loadObligations() async {
    final allotmentId = card.value?.allotmentId ?? property.value?.allotment.id;
    try {
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
    } on ApiException {
      // Nothing to do; the panels simply do not appear.
    }
  }

  // --- What the screen asks ---------------------------------------------

  /// The open case, whichever source knows about it.
  int? get openCaseId {
    final fromCard = card.value?.openCaseId;
    if (fromCard != null) return fromCard;
    for (final item in cases) {
      if (item.isLive || item.closedOn == null) return item.id;
    }
    return cases.isEmpty ? null : cases.first.id;
  }

  EnforcementCase? get openCase {
    for (final item in cases) {
      if (item.id == openCaseId) return item;
    }
    return null;
  }

  int? get sealId => openCase?.sealId;

  bool get isSealed =>
      card.value?.isSealed ?? property.value?.isSealed ?? false;

  /// A live stay order stops the seal, the fine and the assignment. The
  /// server refuses them anyway; the point of knowing here is that the
  /// officer does not walk to the shop in the first place.
  bool get hasLiveStay => profile.value?.liveStayOrder ?? false;

  /// Rent and fine obligations, kept apart on purpose. **Never summed.**
  /// One allottee can hold a live rent link and a live fine link at the
  /// same time; paying the fine does not settle the rent and paying the
  /// rent does not settle the fine. It is the single most common argument
  /// at the counter.
  List<Challan> get rentChallans =>
      challans.where((challan) => !challan.isFine).toList();

  List<Challan> get fineChallans =>
      challans.where((challan) => challan.isFine).toList();

  /// How many times this shopkeeper has promised to pay.
  ///
  /// The data is already on the timeline, and two promises with a balance
  /// that has not moved is exactly the history that justifies a seal — so
  /// the profile says so rather than making the officer count.
  int get promisesMade => timeline
      .where((action) =>
          action.actionType.value == FieldWriteEnums.paymentPromised)
      .length;

  bool get shouldSuggestEscalation =>
      promisesMade >= 2 && (card.value?.promiseBroken ?? false);
}
