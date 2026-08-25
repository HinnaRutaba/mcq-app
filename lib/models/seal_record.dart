/// Lifecycle of a shop seal.
///
/// [readyToUnseal] is derived — a [sealed] record automatically becomes
/// [readyToUnseal] once its linked fine ([Chalaan]) is paid, and stays that
/// way until the magistrate removes the seal (-> [removed]).
enum SealStatus { sealed, readyToUnseal, removed }

extension SealStatusLabel on SealStatus {
  String get label => switch (this) {
        SealStatus.sealed => 'Sealed',
        SealStatus.readyToUnseal => 'Ready to Unseal',
        SealStatus.removed => 'Removed',
      };
}

/// A record of a property being sealed for a violation, and (eventually)
/// unsealed once the related fine is settled.
class SealRecord {
  SealRecord({
    required this.id,
    required this.propertyId,
    required this.propertyName,
    required this.tenantName,
    required this.reason,
    required this.sealedDate,
    required this.relatedChalaanId,
    this.status = SealStatus.sealed,
    this.removedDate,
  });

  final String id;
  final String propertyId;
  final String propertyName;
  final String tenantName;
  final String reason;
  final DateTime sealedDate;

  /// The fine ([Chalaan]) whose payment lifts this seal.
  final String relatedChalaanId;

  SealStatus status;
  DateTime? removedDate;
}
