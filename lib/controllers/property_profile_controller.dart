import 'package:get/get.dart';

import '../core/network/api_exception.dart';
import '../data/repositories/enforcement_case_repository.dart';
import '../data/repositories/reporting_repository.dart';
import '../models/api_refs.dart';
import '../models/api_response.dart';
import '../models/defaulter_card.dart';
import '../models/enforcement_action.dart';
import '../models/enforcement_case.dart';
import '../models/property_profile.dart';

/// The faces of a property profile. One screen holds four different questions
/// about a shop, and an officer standing in front of it is asking one at a
/// time — so they are tabs rather than a page to scroll through.
enum ProfileTab {
  /// The unit, who holds it, and where enforcement stands.
  overview('Overview'),

  /// The rent side: what makes up the debt, and the bills behind it. One word
  /// because four labels share a handset's width — a chip row that has to be
  /// scrolled can leave the tab an officer is on off the screen.
  owed('Owed'),

  /// The corporation's own files on the shop.
  cases('Cases'),

  /// The visit timeline of whichever case is being read.
  history('History');

  const ProfileTab(this.label);

  final String label;
}

/// One property's profile: the shop and its paperwork, where it stands on
/// money, the enforcement cases opened on it, and the visit timeline of
/// whichever case is being read.
///
/// Three calls behind one screen — `reporting/properties/{id}/profile`,
/// `enforcement/cases` and `enforcement/cases/{id}/actions`. The profile and
/// the case list go out together; the timeline follows, because the case it
/// belongs to is only known once one of the other two has answered.
class PropertyProfileController extends GetxController {
  PropertyProfileController({
    required this.propertyId,
    this.card,
    ReportingRepository? reportingRepository,
    EnforcementCaseRepository? caseRepository,
  }) : _reporting = reportingRepository ?? Get.find<ReportingRepository>(),
       _cases = caseRepository ?? Get.find<EnforcementCaseRepository>();

  final int propertyId;

  /// The row the officer tapped, when they arrived from a list. The header is
  /// drawn from it while the profile is still in flight — this screen is
  /// opened mid-round and an officer should not be looking at a blank page to
  /// find out which shop they tapped. Null on a cold link.
  final DefaulterCard? card;

  final ReportingRepository _reporting;
  final EnforcementCaseRepository _cases;

  static const int casePageSize = 50;

  /// How far into the case list to look. `enforcement/cases` publishes no
  /// property filter, so this property's files are found by reading pages and
  /// keeping the rows that name it — 200 cases deep, then it stops.
  static const int maxCasePages = 4;

  final Rxn<PropertyProfile> profile = Rxn<PropertyProfile>();

  /// The cases opened on this property, in the order the server listed them.
  final RxList<EnforcementCase> cases = RxList<EnforcementCase>();

  /// The timeline of [selectedCase], oldest first as the server sends it.
  final RxList<EnforcementAction> actions = RxList<EnforcementAction>();

  final RxnInt selectedCaseId = RxnInt();

  final Rx<ProfileTab> tab = Rx<ProfileTab>(ProfileTab.overview);

  final RxBool isLoading = RxBool(false);
  final RxBool isLoadingTimeline = RxBool(false);

  final RxnString errorMessage = RxnString();

  /// Kept apart from [errorMessage]: a timeline that would not load is a hole
  /// in one section, not a failed screen.
  final RxnString timelineError = RxnString();

  /// Bumped per timeline fetch, so switching case twice cannot leave the
  /// first answer on screen.
  int _timelineTicket = 0;

  bool get hasData => profile.value != null || cases.isNotEmpty;

  EnforcementCase? get selectedCase {
    final int? id = selectedCaseId.value;
    if (id == null) return null;
    for (final EnforcementCase file in cases) {
      if (file.id == id) return file;
    }
    return null;
  }

  // --- What the header says, before and after the profile lands ---------

  ProfileProperty? get property => profile.value?.property;

  /// The holder, or the fact that there is none. Falls back to the card, then
  /// to silence while the call is still out.
  String get holder {
    final PropertyProfile? loaded = profile.value;
    if (loaded != null) {
      return loaded.allottee?.fullName ??
          (loaded.isVacant ? 'Vacant unit' : 'No holder on record');
    }
    return card?.allotteeName ?? 'Unit';
  }

  /// The shop and the bazaar it stands in.
  String get propertyLine {
    final ProfileProperty? shop = property;
    final String unit =
        shop?.shopNo ??
        shop?.propertyCode ??
        card?.shopNo ??
        card?.propertyCode ??
        'Unit $propertyId';
    final String? place =
        shop?.marketName ??
        shop?.areaName ??
        card?.marketName ??
        card?.areaName;
    return place == null ? unit : '$unit · $place';
  }

  /// Rent arrears. The server's own total, never one added up here — and
  /// never a fine, which is a separate debt on a separate challan.
  String? get outstanding =>
      profile.value?.position.totalOutstanding ?? card?.outstanding;

  /// How far behind the rent is. A zero from the profile does not erase what
  /// the list already knew: the payload omits `unpaid_months` for some shops
  /// and that parses to 0, which is not the same as "not behind" — and `??`
  /// never falls through a zero.
  int? get unpaidMonths {
    final int? fromProfile = profile.value?.position.unpaidMonths;
    if (fromProfile != null && fromProfile > 0) return fromProfile;
    return card?.monthsBehind;
  }

  DateTime? get lastPaymentDate =>
      profile.value?.position.lastPaymentDate ?? card?.lastPaymentDate;

  /// When the officer is next due at the shop, and whether a promise to pay
  /// stands against that day. Only the row they tapped carries either — none
  /// of the profile's three endpoints returns a visit date — so on a cold
  /// link there is nothing to say and the header says nothing.
  DateTime? get nextVisitDate => card?.nextVisitDate;

  bool get hasCommitment => card?.hasCommitment ?? false;

  /// Nothing has ever been paid on the unit — a different problem from having
  /// fallen behind, and the one worth saying on the header.
  bool get neverPaid {
    final PropertyPosition? position = profile.value?.position;
    if (position != null) return !position.hasEverPaid;
    return card?.neverPaid ?? false;
  }

  /// The holder's number, for the call and message actions. Null on a vacant
  /// unit, and on one whose holder the register has no number for.
  String? get mobileNo => profile.value?.allottee?.mobileNo ?? card?.mobileNo;

  /// Where the shop stands, when the register holds a fix for it.
  GeoPoint? get mapPoint {
    final GeoPoint? fromProfile = property?.location;
    if (fromProfile != null && fromProfile.hasFix) return fromProfile;
    final GeoPoint? fromCard = card?.map;
    return fromCard != null && fromCard.hasFix ? fromCard : null;
  }

  /// What to search a map for when there is no fix: the printed address, else
  /// the shop and the bazaar it stands in, which is what a map can find.
  String? get mapQuery {
    final ProfileProperty? shop = property;
    final String? address = shop?.streetAddress?.trim();
    if (address != null && address.isNotEmpty) return address;
    final List<String> parts = <String>[
      ?(shop?.shopNo ?? card?.shopNo),
      ?(shop?.marketName ?? card?.marketName),
      ?(shop?.areaName ?? card?.areaName),
    ];
    return parts.isEmpty ? null : parts.join(', ');
  }

  bool get canOpenMap => mapPoint != null || mapQuery != null;

  @override
  void onInit() {
    super.onInit();
    selectedCaseId.value = card?.openCaseId;
    load();
  }

  /// Everything the screen shows. Safe to call again — this is the
  /// pull-to-refresh.
  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    await Future.wait(<Future<void>>[_loadProfile(), _loadCases()]);
    isLoading.value = false;
    await _loadTimeline();
  }

  void showTab(ProfileTab next) => tab.value = next;

  /// Reads another of this property's cases. Choosing a case is asking for its
  /// history, so the page goes there — an already-read case moves the tab
  /// without fetching the timeline again.
  Future<void> showCase(int caseId) async {
    final bool changed = caseId != selectedCaseId.value;
    selectedCaseId.value = caseId;
    tab.value = ProfileTab.history;
    if (changed) await _loadTimeline();
  }

  Future<void> _loadProfile() async {
    try {
      profile.value = await _reporting.propertyProfile(propertyId);
    } on ApiException catch (error) {
      _report(error);
    }
  }

  Future<void> _loadCases() async {
    try {
      final List<EnforcementCase> found = <EnforcementCase>[];
      for (int page = 1; page <= maxCasePages; page++) {
        final Paginated<EnforcementCase> result = await _cases.cases(
          page: page,
          perPage: casePageSize,
        );
        found.addAll(result.items.where(_isThisProperty));
        if (!result.hasMore) break;
      }
      cases.value = found;
      selectedCaseId.value = _preferred(found)?.id ?? selectedCaseId.value;
    } on ApiException catch (error) {
      _report(error);
    }
  }

  bool _isThisProperty(EnforcementCase file) => file.property?.id == propertyId;

  /// The case to open on: the one the card named, else the live one, else the
  /// first the server listed.
  EnforcementCase? _preferred(List<EnforcementCase> found) {
    final int? named = selectedCaseId.value;
    for (final EnforcementCase file in found) {
      if (file.id == named) return file;
    }
    for (final EnforcementCase file in found) {
      if (file.isLive) return file;
    }
    return found.isEmpty ? null : found.first;
  }

  Future<void> _loadTimeline() async {
    final int? caseId = selectedCaseId.value;
    if (caseId == null) {
      actions.clear();
      return;
    }
    final int ticket = ++_timelineTicket;
    isLoadingTimeline.value = true;
    timelineError.value = null;
    try {
      final List<EnforcementAction> timeline = await _cases.actions(caseId);
      if (ticket != _timelineTicket) return;
      actions.value = timeline;
    } on ApiException catch (error) {
      if (ticket != _timelineTicket) return;
      timelineError.value = error.message;
      actions.clear();
    } finally {
      if (ticket == _timelineTicket) isLoadingTimeline.value = false;
    }
  }

  void _report(ApiException error) {
    errorMessage.value ??= error.message;
  }
}
