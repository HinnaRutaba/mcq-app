import '../../core/utils/json_reader.dart';
import '../common/money.dart';

/// A promise to pay that still stands, or has been broken.
///
/// This is the whole reason the defaulters list was worth rebuilding. MCQ
/// asked for it in their own words: *"so next time when magistrate comes
/// there he will see on cards that which shopkeeper has committed to submit
/// rent on which date and how many days are remaining"*.
///
/// Without it, an officer re-walking a bazaar cannot tell a shopkeeper he
/// spoke to last week from one nobody has ever visited.
class Commitment {
  const Commitment({
    required this.promisedPaymentDate,
    required this.daysRemaining,
    required this.broken,
  });

  final DateTime? promisedPaymentDate;

  /// Negative once the date has passed.
  final int daysRemaining;

  /// The server's judgement, not the app's. Do not recompute it from the
  /// date — a promise part-kept is settled server-side.
  final bool broken;

  factory Commitment.fromJson(Map<String, dynamic> json) => Commitment(
        promisedPaymentDate: json.date('promised_payment_date'),
        daysRemaining: json.intOr('days_remaining'),
        broken: json.boolean('broken'),
      );

  /// How long ago it lapsed. Only meaningful when [broken].
  int get daysSinceBroken => daysRemaining < 0 ? -daysRemaining : 0;

  /// Lapses today — worth a pulse on the card.
  bool get lapsesToday => !broken && daysRemaining == 0;
}

/// A coordinate pair, or nothing at all.
///
/// Both or neither: half a coordinate looks like proof of a location and
/// locates nothing. A unit without one simply does not appear on the map,
/// and the map says how many were left off rather than silently omitting
/// them.
class MapPoint {
  const MapPoint({required this.latitude, required this.longitude});

  /// Kept as the server's strings until the moment they are handed to the
  /// map, which is the only consumer that needs numbers.
  final String latitude;
  final String longitude;

  static MapPoint? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final lat = json.str('latitude');
    final lng = json.str('longitude');
    if (lat == null || lng == null || lat.isEmpty || lng.isEmpty) return null;
    if (double.tryParse(lat) == null || double.tryParse(lng) == null) {
      return null;
    }
    return MapPoint(latitude: lat, longitude: lng);
  }

  double get lat => double.parse(latitude);
  double get lng => double.parse(longitude);
}

/// **One card shape, for both lists.**
///
/// `field/defaulters` and `field/units` return the same object — the unit
/// endpoint simply leaves the tenancy fields null where there is no live
/// agreement. That is deliberate on the server's part and it means the app
/// builds *one* card widget rather than two that drift apart, and the
/// round's `stops` reuse it a third time.
///
/// Three fields carry facts the app must not flatten:
///
/// * [outstanding] is **null** on a vacant unit — nobody owes anything
///   because nobody holds it. That is a different statement from a tenant
///   who is up to date, and only one of them is good news. It renders as
///   "Vacant", never as `0.00`.
/// * [daysOverdue] is **null** when nothing is past due yet. Null and zero
///   are different facts and the officer acts differently on each.
/// * [neverPaid] separates somebody who pays late from somebody who has
///   never paid at all. The first needs a phone call and the second needs a
///   visit; the card has to say which.
class FieldCard {
  const FieldCard({
    required this.propertyId,
    required this.propertyCode,
    required this.shopNo,
    required this.areaName,
    required this.isSealed,
    required this.neverPaid,
    required this.isVacant,
    required this.monthsBehind,
    this.allotmentId,
    this.allotmentNo,
    this.areaId,
    this.marketName,
    this.allotteeId,
    this.allotteeName,
    this.mobileNo,
    this.cnic,
    this.outstanding,
    this.daysOverdue,
    this.lastPaymentDate,
    this.commitment,
    this.nextVisitDate,
    this.openCaseId,
    this.sealNo,
    this.map,
    this.occupancyStatus,
    this.canFineHolder = true,
    this.needsOffenderDetails = false,
  });

  // --- The unit ---------------------------------------------------------
  final int propertyId;
  final String propertyCode;
  final String shopNo;
  final int? areaId;
  final String areaName;
  final String? marketName;

  // --- The agreement, where there is one --------------------------------
  final int? allotmentId;
  final String? allotmentNo;
  final int? allotteeId;
  final String? allotteeName;
  final String? mobileNo;
  final String? cnic;

  // --- The money --------------------------------------------------------

  /// Null on a vacant unit. Never rendered as a zero.
  final Money? outstanding;

  final int monthsBehind;

  /// Null when nothing is past due yet.
  final int? daysOverdue;

  final bool neverPaid;
  final DateTime? lastPaymentDate;

  // --- The state --------------------------------------------------------
  final Commitment? commitment;
  final DateTime? nextVisitDate;
  final int? openCaseId;
  final String? sealNo;
  final bool isSealed;
  final MapPoint? map;

  // --- Vacancy, from `field/units` --------------------------------------
  final bool isVacant;
  final String? occupancyStatus;

  /// False when there is no live agreement to bill. A vacant unit cannot be
  /// fined through its tenancy and the server returns 422 — so that action
  /// is hidden, not disabled.
  final bool canFineHolder;

  /// The server telling the fine form to change shape and collect
  /// `offender_name` and `offender_mobile_no`. **Trust this flag rather
  /// than working it out client-side** — a database constraint refuses a
  /// fine that names nobody.
  final bool needsOffenderDetails;

  factory FieldCard.fromJson(Map<String, dynamic> json) {
    final vacant = json.boolean('is_vacant');
    return FieldCard(
      propertyId: json.intOr('property_id'),
      propertyCode: json.strOr('property_code'),
      shopNo: json.strOr('shop_no'),
      areaId: json.integer('area_id'),
      areaName: json.strOr('area_name'),
      marketName: json.str('market_name'),
      allotmentId: json.integer('allotment_id'),
      allotmentNo: json.str('allotment_no'),
      allotteeId: json.integer('allottee_id'),
      allotteeName: json.str('allottee_name'),
      mobileNo: json.str('mobile_no'),
      cnic: json.str('cnic'),
      // moneyOrNull, not money: absent must stay absent all the way to the
      // widget, which draws "Vacant" rather than a figure.
      outstanding: json.moneyOrNull('outstanding'),
      monthsBehind: json.intOr('months_behind'),
      daysOverdue: json.integer('days_overdue'),
      neverPaid: json.boolean('never_paid'),
      lastPaymentDate: json.date('last_payment_date'),
      commitment: json.child('commitment') == null
          ? null
          : Commitment.fromJson(json.child('commitment')!),
      nextVisitDate: json.date('next_visit_date'),
      openCaseId: json.integer('open_case_id'),
      sealNo: json.str('seal_no'),
      isSealed: json.boolean('is_sealed'),
      map: MapPoint.fromJson(json.child('map')),
      isVacant: vacant,
      occupancyStatus: json.str('occupancy_status'),
      canFineHolder: json.boolean('can_fine_holder', fallback: !vacant),
      needsOffenderDetails:
          json.boolean('needs_offender_details', fallback: vacant),
    );
  }

  static List<FieldCard> listFrom(List<dynamic> raw) => raw
      .whereType<Map<String, dynamic>>()
      .map(FieldCard.fromJson)
      .toList(growable: false);

  // --- What the card asks itself ---------------------------------------

  /// `MCQ-CR-001001 · Shop P-1`.
  String get unitLabel =>
      shopNo.isEmpty ? propertyCode : '$propertyCode · $shopNo';

  /// `Liaquat Market, Circular Road`.
  String get placeLabel => (marketName ?? '').isEmpty
      ? areaName
      : '$marketName, $areaName';

  bool get isCallable => (mobileNo ?? '').trim().isNotEmpty;

  bool get hasOpenCase => openCaseId != null;

  /// A promise that has lapsed. The strongest signal on the list, and the
  /// thing that justifies the next step: somebody has already been given a
  /// chance and has not taken it.
  bool get promiseBroken => commitment?.broken ?? false;

  /// A promise that still stands.
  bool get promiseStanding => commitment != null && !commitment!.broken;

  /// Ordering only — never displayed. See [Money.compareMagnitude].
  int compareOutstanding(FieldCard other) {
    final mine = outstanding;
    final theirs = other.outstanding;
    if (mine == null && theirs == null) return 0;
    if (mine == null) return 1;
    if (theirs == null) return -1;
    return theirs.compareMagnitude(mine);
  }
}
