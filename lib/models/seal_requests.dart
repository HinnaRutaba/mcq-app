import '../core/utils/json_parse.dart';
import 'field_write_request.dart';

/// Seals a unit through its enforcement case, when the seal does not accompany
/// a fine. To seal and fine in one transaction, use `FineRequest.seal` instead.
class CaseSealRequest extends FieldWriteRequest {
  CaseSealRequest({
    required this.sealReason,
    this.sealedOn,
    this.sealPhotoPath,
    this.fineId,
    super.actionDate,
    super.latitude,
    super.longitude,
    super.locationAccuracyM,
    super.recordedOffline,
    super.deviceRecordedAt,
    super.photoPath,
    super.signaturePath,
    super.witnessName,
    super.remarks,
    super.clientActionUuid,
  }) : assert(
         sealReason.length >= reasonMinLength,
         'seal_reason must be at least $reasonMinLength characters — it is the '
         'record of why a shop was shut.',
       );

  /// Why the shop is being sealed, e.g. "Arrears unpaid after final notice.".
  /// Between 10 and 300 characters.
  final String sealReason;

  /// The day the seal went on. Documented by example rather than in the
  /// parameter table, which lists `action_date` for the same purpose; both are
  /// sent when set.
  final DateTime? sealedOn;

  /// Path from the evidence upload — the photograph of the applied seal.
  final String? sealPhotoPath;

  /// The fine this seal is being applied for, when there is one already on
  /// record.
  ///
  /// Sealing *with* a fine is one request — `FineRequest.seal`. This is the
  /// other case: the fine was written earlier and the shop is being shut for
  /// not paying it. Naming it here is what ties the seal to the debt, and so
  /// what lets the unseal queue work out that the seal is clear to come off
  /// once the fine is settled.
  final int? fineId;

  static const int reasonMinLength = 10;
  static const int reasonMaxLength = 300;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(),
    'seal_reason': sealReason,
    'sealed_on': Json.dateOnly(sealedOn),
    'seal_photo_path': sealPhotoPath,
    'fine_id': fineId,
  };
}

/// Releases a seal once the fine behind it is settled.
///
/// The unseal queue (`ready=1`) only lists seals the server considers settled;
/// [overrideReason] is for lifting one that is not, and is deliberately held to
/// a longer minimum than [unsealReason] — it is the justification for opening a
/// shop that still owes money.
class SealReleaseRequest extends FieldWriteRequest {
  SealReleaseRequest({
    required this.unsealReason,
    this.overrideReason,
    this.unsealedOn,
    super.actionDate,
    super.latitude,
    super.longitude,
    super.locationAccuracyM,
    super.recordedOffline,
    super.deviceRecordedAt,
    super.photoPath,
    super.signaturePath,
    super.witnessName,
    super.remarks,
    super.clientActionUuid,
  }) : assert(
         unsealReason.length >= reasonMinLength,
         'unseal_reason must be at least $reasonMinLength characters.',
       ),
       assert(
         overrideReason == null ||
             overrideReason.length >= overrideReasonMinLength,
         'override_reason must be at least $overrideReasonMinLength characters.',
       );

  /// Why the seal is coming off, e.g. "Fine paid in full, receipt
  /// MCQ-RC-2627-00123.". Between 10 and 300 characters.
  final String unsealReason;

  /// Required by the server when releasing a seal the unseal queue has not
  /// cleared. Between 20 and 300 characters.
  final String? overrideReason;

  /// The day the seal came off. Documented by example alongside `action_date`.
  final DateTime? unsealedOn;

  static const int reasonMinLength = 10;
  static const int reasonMaxLength = 300;
  static const int overrideReasonMinLength = 20;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(),
    'unseal_reason': unsealReason,
    'override_reason': overrideReason,
    'unsealed_on': Json.dateOnly(unsealedOn),
  };
}
