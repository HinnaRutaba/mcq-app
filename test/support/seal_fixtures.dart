import 'package:mcq_app/data/repositories/field_seal_repository.dart';
import 'package:mcq_app/models/models.dart';

/// `GET /api/v1/enforcement/field/seals`, in both its readings.
///
/// Built from raw payloads rather than from the constructor: the published
/// spec captured this list only while it was empty, so `FieldSeal` reads its
/// keys leniently, and a fixture that skipped the JSON would prove nothing
/// about the part most likely to be wrong.

Map<String, dynamic> _seal({
  required int id,
  required String sealNo,
  required String shopNo,
  required String allotteeName,
  String? outstanding,
  String? caseNo,
  Map<String, dynamic>? status,
  bool sealed = true,
  bool? readyToRelease,
  String sealedOn = '2026-08-14',
  String? releasedOn,
}) => <String, dynamic>{
  'id': id,
  'seal_no': sealNo,
  'seal_status': ?status,
  'sealed_on': sealedOn,
  'seal_reason': 'Arrears unpaid after final notice.',
  // Absent, not false, where the caller passes none: that is how a row on the
  // full list can be clear to come off without saying so.
  'ready_to_release': ?readyToRelease,
  'is_sealed': sealed,
  'released_on': releasedOn,
  'unseal_reason': releasedOn == null ? null : 'Fine paid in full.',
  'property_id': 700 + id,
  'property_code': 'PR-LQ-${(700 + id)}',
  'shop_no': shopNo,
  'area_id': 2,
  'area_name': 'Prince Road',
  'market_name': 'Liaquat Bazaar',
  'allotment_id': 400 + id,
  'allotment_no': 'ALT-${400 + id}',
  'allottee_id': 300 + id,
  'allottee_name': allotteeName,
  'mobile_no': '030012345${id.toString().padLeft(2, '0')}',
  'outstanding': outstanding,
  'enforcement_case_id': caseNo == null ? null : 900 + id,
  'case_no': caseNo,
  'sealed_by': <String, dynamic>{'id': 5, 'name': 'Shahid Rutaba'},
};

/// A shop still owing, so the seal stays on.
final FieldSeal sealStillOwing = FieldSeal.fromJson(
  _seal(
    id: 1,
    sealNo: 'MCQ-SL-2627-00001',
    shopNo: 'S-12',
    allotteeName: 'Abdul Samad',
    outstanding: '84500.00',
    caseNo: 'ENF-2627-00031',
    status: <String, dynamic>{
      'value': 'sealed',
      'label': 'Sealed',
      'tone': 'danger',
    },
  ),
);

/// Settled, and the row says so itself.
final FieldSeal sealSettled = FieldSeal.fromJson(
  _seal(
    id: 2,
    sealNo: 'MCQ-SL-2627-00002',
    shopNo: 'S-19',
    allotteeName: 'Noor Muhammad',
    outstanding: '0.00',
    caseNo: 'ENF-2627-00034',
    readyToRelease: true,
    status: <String, dynamic>{
      'value': 'sealed',
      'label': 'Sealed',
      'tone': 'danger',
    },
  ),
);

/// Settled, and the row does *not* say so: no `ready_to_release` key on it and
/// no status either, but `ready=1` returns it. Membership of that queue is the
/// only thing that can tell the officer this seal may come off.
final FieldSeal sealSettledQuietly = FieldSeal.fromJson(
  _seal(
    id: 3,
    sealNo: 'MCQ-SL-2627-00003',
    shopNo: 'K-4',
    allotteeName: 'Bashir Ahmed',
    outstanding: '0.00',
  ),
);

/// Already off. Its status carries no tone, which is the other thing a lenient
/// payload does.
final FieldSeal sealReleased = FieldSeal.fromJson(
  _seal(
    id: 4,
    sealNo: 'MCQ-SL-2627-00004',
    shopNo: 'S-31',
    allotteeName: 'Ghulam Farooq',
    caseNo: 'ENF-2627-00021',
    sealed: false,
    releasedOn: '2026-09-02',
    status: <String, dynamic>{'value': 'unsealed', 'label': 'Reopened'},
  ),
);

/// The whole register, newest seal first, as the server orders it.
final List<FieldSeal> sealsFixture = <FieldSeal>[
  sealStillOwing,
  sealSettled,
  sealSettledQuietly,
  sealReleased,
];

/// What `ready=1` answers: the two that are settled, and neither of the others.
final List<FieldSeal> readySealsFixture = <FieldSeal>[
  sealSettled,
  sealSettledQuietly,
];

/// The seal register, for a preview or a screen test.
///
/// Answers the two readings separately, the way the endpoint does, and keeps
/// what it was asked so a test can prove the queue was fetched rather than
/// worked out on the handset.
class FakeFieldSealRepository implements FieldSealRepository {
  FakeFieldSealRepository({
    List<FieldSeal>? seals,
    List<FieldSeal>? ready,
    this.failure,
  }) : all = seals ?? sealsFixture,
       readyRows = ready ?? readySealsFixture;

  /// Mutable so a test can let the signal come back and retry.
  Object? failure;

  final List<FieldSeal> all;
  final List<FieldSeal> readyRows;

  /// One entry per call, holding the `readyOnly` it was made with.
  final List<bool> asked = <bool>[];

  int get calls => asked.length;

  @override
  Future<List<FieldSeal>> seals({bool readyOnly = false}) async {
    asked.add(readyOnly);
    if (failure != null) throw failure!;
    return readyOnly ? readyRows : all;
  }

  @override
  Future<FieldSeal> release(int sealId, SealReleaseRequest request) async {
    throw UnimplementedError(
      'The register reads; a seal comes off from the shop it is on.',
    );
  }
}
