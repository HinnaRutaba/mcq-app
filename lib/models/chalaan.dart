import 'payment_method.dart';

/// A regular chalaan (rent/dues invoice) vs a [fine] issued by a magistrate
/// for a violation.
enum ChalaanType { chalaan, fine }

extension ChalaanTypeLabel on ChalaanType {
  String get label => this == ChalaanType.fine ? 'Fine' : 'Chalaan';
}

enum ChalaanStatus { upcoming, overdue, pendingVerification, paid }

extension ChalaanStatusLabel on ChalaanStatus {
  String get label => switch (this) {
        ChalaanStatus.upcoming => 'Upcoming',
        ChalaanStatus.overdue => 'Overdue',
        ChalaanStatus.pendingVerification => 'Pending Verification',
        ChalaanStatus.paid => 'Paid',
      };
}

/// A single chalaan or fine tied to a tenant + property.
///
/// This is a plain in-memory model backing the mock repositories in
/// `lib/data/repositories` — the shape is expected to change once the real
/// data model lands, but views/controllers only ever touch this class, so
/// swapping the backing repository won't ripple through the UI.
class Chalaan {
  Chalaan({
    required this.id,
    required this.type,
    required this.status,
    required this.tenantId,
    required this.tenantName,
    required this.propertyId,
    required this.propertyName,
    required this.propertyAddress,
    required this.amount,
    required this.issueDate,
    required this.dueDate,
    this.description,
    this.paidDate,
    this.method,
    this.referenceNumber,
  });

  final String id;
  final ChalaanType type;
  ChalaanStatus status;
  final String tenantId;
  final String tenantName;
  final String propertyId;
  final String propertyName;
  final String propertyAddress;
  final double amount;
  final DateTime issueDate;
  final DateTime dueDate;
  final String? description;
  DateTime? paidDate;
  PaymentMethod? method;
  String? referenceNumber;

  bool get isSettled => status == ChalaanStatus.paid;
  bool get isFine => type == ChalaanType.fine;
}
