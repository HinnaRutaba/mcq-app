import '../../models/seal_record.dart';
import '../mock/mock_seed.dart';

/// Read/write access to seal records. See [ChalaanRepository] for the swap
/// pattern used across this app's data layer.
abstract class SealRepository {
  List<SealRecord> getAll();
  SealRecord getById(String id);

  Future<SealRecord> sealProperty({
    required String propertyId,
    required String propertyName,
    required String tenantName,
    required String reason,
    required String relatedChalaanId,
  });

  Future<SealRecord> removeSeal(String sealId);
}

class MockSealRepository implements SealRepository {
  final List<SealRecord> _seals = MockSeed.buildSealRecords();

  @override
  List<SealRecord> getAll() => List.unmodifiable(_seals);

  @override
  SealRecord getById(String id) => _seals.firstWhere((s) => s.id == id);

  @override
  Future<SealRecord> sealProperty({
    required String propertyId,
    required String propertyName,
    required String tenantName,
    required String reason,
    required String relatedChalaanId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final seal = SealRecord(
      id: 'SEAL-${DateTime.now().millisecondsSinceEpoch}',
      propertyId: propertyId,
      propertyName: propertyName,
      tenantName: tenantName,
      reason: reason,
      sealedDate: DateTime.now(),
      relatedChalaanId: relatedChalaanId,
    );
    _seals.insert(0, seal);
    return seal;
  }

  @override
  Future<SealRecord> removeSeal(String sealId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final seal = getById(sealId)
      ..status = SealStatus.removed
      ..removedDate = DateTime.now();
    return seal;
  }
}
