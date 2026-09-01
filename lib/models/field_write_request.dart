import '../core/utils/client_action_uuid.dart';
import '../core/utils/json_parse.dart';

/// What every field write carries, whatever it records.
///
/// Recording a visit, imposing a fine, applying a seal and releasing one all
/// accept the same envelope of evidence: when it happened, where the officer
/// stood, the photograph and signature backing it, who witnessed it, and the
/// idempotency key that makes a resend on a weak signal safe.
///
/// [clientActionUuid] is generated once, here, when the request object is
/// built. **Retry by re-sending the same instance.** Building a fresh request
/// for a retry mints a new uuid, and the server will read that as a second
/// fine rather than the same one arriving twice.
abstract class FieldWriteRequest {
  FieldWriteRequest({
    this.actionDate,
    this.latitude,
    this.longitude,
    this.locationAccuracyM,
    this.recordedOffline,
    this.deviceRecordedAt,
    this.photoPath,
    this.signaturePath,
    this.witnessName,
    this.remarks,
    String? clientActionUuid,
  }) : clientActionUuid = clientActionUuid ?? ClientActionUuid.generate();

  /// The day the thing happened. Cannot be in the future; defaults to today
  /// server-side when omitted.
  final DateTime? actionDate;

  /// Where the officer was standing. Both or neither.
  final double? latitude;
  final double? longitude;

  /// Accuracy of that fix in metres, as the OS reported it.
  final double? locationAccuracyM;

  /// True when this was written with no signal and is being sent later.
  final bool? recordedOffline;

  /// When the officer actually recorded it, as against when it reached the
  /// server. Send this whenever [recordedOffline] is true.
  final DateTime? deviceRecordedAt;

  /// Server-side paths from `POST /enforcement/evidence`. Upload the image
  /// first, then send its path here — that way the photograph goes up once and
  /// the write can be retried without re-sending it.
  final String? photoPath;
  final String? signaturePath;

  final String? witnessName;
  final String? remarks;

  /// The idempotency key. Generated on the handset, reused on every retry.
  final String clientActionUuid;

  /// The wire body. Nulls are dropped by the API service, so a field the
  /// officer left blank is simply not sent.
  Map<String, dynamic> toJson();

  /// The shared half of [toJson], for subclasses to spread into their own.
  Map<String, dynamic> baseJson() => <String, dynamic>{
    'action_date': Json.dateOnly(actionDate),
    'client_action_uuid': clientActionUuid,
    'device_recorded_at': Json.timestamp(deviceRecordedAt),
    'latitude': latitude,
    'longitude': longitude,
    'location_accuracy_m': locationAccuracyM,
    'recorded_offline': recordedOffline,
    'photo_path': photoPath,
    'signature_path': signaturePath,
    'witness_name': witnessName,
    'remarks': remarks,
  };
}
