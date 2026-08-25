import '../../models/chalaan.dart';
import '../../models/payment_method.dart';
import '../mock/mock_seed.dart';

/// Read/write access to chalaans & fines.
///
/// This is the swap point for a real backend: implement this interface
/// against an HTTP API and register it in place of [MockChalaanRepository]
/// (see `lib/app/app.dart` / wherever repositories get registered) — no
/// controller or view code needs to change.
abstract class ChalaanRepository {
  List<Chalaan> getAll();
  List<Chalaan> getByTenant(String tenantId);
  Chalaan getById(String id);

  /// Simulates an instant online payment (Bank/Easypaisa/JazzCash).
  Future<Chalaan> payOnline(String chalaanId, PaymentMethod method);

  /// Records a manual bank transfer the tenant made outside the app; goes
  /// to [ChalaanStatus.pendingVerification] until a magistrate confirms it.
  Future<Chalaan> submitManualPayment(String chalaanId, String referenceNumber);

  /// A magistrate collecting payment in person (cash) — settles instantly,
  /// no verification step needed since the magistrate is the verifier.
  Future<Chalaan> markCollected(String chalaanId);

  /// Issues a new chalaan or fine against a property.
  Future<Chalaan> create({
    required ChalaanType type,
    required String propertyId,
    required double amount,
    required DateTime dueDate,
    String? description,
  });
}

class MockChalaanRepository implements ChalaanRepository {
  final List<Chalaan> _chalaans = MockSeed.buildChalaans();

  @override
  List<Chalaan> getAll() => List.unmodifiable(_chalaans);

  @override
  List<Chalaan> getByTenant(String tenantId) =>
      _chalaans.where((c) => c.tenantId == tenantId).toList();

  @override
  Chalaan getById(String id) => _chalaans.firstWhere((c) => c.id == id);

  @override
  Future<Chalaan> payOnline(String chalaanId, PaymentMethod method) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    final chalaan = getById(chalaanId)
      ..status = ChalaanStatus.paid
      ..paidDate = DateTime.now()
      ..method = method;
    return chalaan;
  }

  @override
  Future<Chalaan> submitManualPayment(
    String chalaanId,
    String referenceNumber,
  ) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final chalaan = getById(chalaanId)
      ..status = ChalaanStatus.pendingVerification
      ..paidDate = DateTime.now()
      ..method = PaymentMethod.manual
      ..referenceNumber = referenceNumber;
    return chalaan;
  }

  @override
  Future<Chalaan> markCollected(String chalaanId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final chalaan = getById(chalaanId)
      ..status = ChalaanStatus.paid
      ..paidDate = DateTime.now()
      ..method = PaymentMethod.cash;
    return chalaan;
  }

  @override
  Future<Chalaan> create({
    required ChalaanType type,
    required String propertyId,
    required double amount,
    required DateTime dueDate,
    String? description,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final property = MockSeed.propertyById(propertyId);
    final chalaan = Chalaan(
      id: '${type == ChalaanType.fine ? 'FIN' : 'CHL'}-${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      status: ChalaanStatus.upcoming,
      tenantId: property.tenantId,
      tenantName: property.tenantName,
      propertyId: property.id,
      propertyName: property.name,
      propertyAddress: property.address,
      amount: amount,
      issueDate: DateTime.now(),
      dueDate: dueDate,
      description: description,
    );
    _chalaans.insert(0, chalaan);
    return chalaan;
  }
}
