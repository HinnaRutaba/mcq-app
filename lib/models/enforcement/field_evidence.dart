import 'package:intl/intl.dart';

/// The evidence block every field write carries.
///
/// `enforcement_actions` has carried these columns since the schema was
/// written and `RecordsFieldEvidence` validates every one of them on all
/// four field writes — a plain action, a seal, an unseal and a fine.
class FieldEvidence {
  const FieldEvidence({
    required this.clientActionUuid,
    required this.actionDate,
    required this.deviceRecordedAt,
    this.photoPath,
    this.signaturePath,
    this.latitude,
    this.longitude,
    this.locationAccuracyM,
    this.witnessName,
    this.remarks,
    this.recordedOffline = false,
  });

  /// The idempotency key, generated on the handset. All four field writes
  /// check it before doing anything and replay the existing record if they
  /// have seen it, so retrying on a flaky connection cannot double-seal a
  /// shop or fine a shopkeeper twice. Send the **same** one on every retry.
  final String clientActionUuid;

  /// When it *happened*. The server accepts a past date and refuses a
  /// future one, so a visit synced on Thursday still reports as Tuesday's.
  final DateTime actionDate;

  /// The handset clock. Refused if more than 5 minutes ahead of the server.
  final DateTime deviceRecordedAt;

  /// The path returned by `POST /enforcement/evidence`, not the image.
  final String? photoPath;
  final String? signaturePath;

  /// Both or neither — half a coordinate looks like proof of presence and
  /// locates nothing, and the server refuses it.
  final double? latitude;
  final double? longitude;

  /// Metres, 0 to 9999.99. Sent with the coordinates so a reader knows
  /// whether the pin means anything.
  final double? locationAccuracyM;

  final String? witnessName;
  final String? remarks;
  final bool recordedOffline;

  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');

  /// `yyyy-MM-dd`, the only date format the API accepts on a write. Public
  /// so the writes that carry an *extra* date — a promised payment, a
  /// revisit, the day a fine was imposed — format it the same way.
  static String apiDate(DateTime date) => _apiDate.format(date);

  bool get hasCoordinates => latitude != null && longitude != null;

  Map<String, dynamic> toJson() => {
        'client_action_uuid': clientActionUuid,
        'action_date': _apiDate.format(actionDate),
        'device_recorded_at': deviceRecordedAt.toUtc().toIso8601String(),
        'recorded_offline': recordedOffline,
        if (photoPath != null) 'photo_path': photoPath,
        if (signaturePath != null) 'signature_path': signaturePath,
        // Both or neither, enforced here so no caller can send half a fix.
        if (hasCoordinates) 'latitude': latitude,
        if (hasCoordinates) 'longitude': longitude,
        if (hasCoordinates && locationAccuracyM != null)
          'location_accuracy_m': locationAccuracyM,
        if ((witnessName ?? '').trim().isNotEmpty)
          'witness_name': witnessName!.trim(),
        if ((remarks ?? '').trim().isNotEmpty) 'remarks': remarks!.trim(),
      };

  factory FieldEvidence.fromJson(Map<String, dynamic> json) => FieldEvidence(
        clientActionUuid: '${json['client_action_uuid']}',
        actionDate: DateTime.tryParse('${json['action_date']}') ?? DateTime.now(),
        deviceRecordedAt:
            DateTime.tryParse('${json['device_recorded_at']}') ?? DateTime.now(),
        photoPath: json['photo_path'] as String?,
        signaturePath: json['signature_path'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        locationAccuracyM: (json['location_accuracy_m'] as num?)?.toDouble(),
        witnessName: json['witness_name'] as String?,
        remarks: json['remarks'] as String?,
        recordedOffline: json['recorded_offline'] == true,
      );

  FieldEvidence copyWith({
    String? photoPath,
    String? signaturePath,
    bool? recordedOffline,
  }) =>
      FieldEvidence(
        clientActionUuid: clientActionUuid,
        actionDate: actionDate,
        deviceRecordedAt: deviceRecordedAt,
        photoPath: photoPath ?? this.photoPath,
        signaturePath: signaturePath ?? this.signaturePath,
        latitude: latitude,
        longitude: longitude,
        locationAccuracyM: locationAccuracyM,
        witnessName: witnessName,
        remarks: remarks,
        recordedOffline: recordedOffline ?? this.recordedOffline,
      );
}

/// What `POST /enforcement/evidence` gives back: a path to send with the
/// action, never the image itself.
class EvidenceUpload {
  const EvidenceUpload({required this.path, required this.kind});

  final String path;
  final String kind;

  factory EvidenceUpload.fromJson(Map<String, dynamic> json) => EvidenceUpload(
        path: '${json['path']}',
        kind: '${json['kind'] ?? 'photo'}',
      );

  static const String kindPhoto = 'photo';
  static const String kindSignature = 'signature';
}

/// Enum values the API validates field writes against.
///
/// `fine_type` is fixed by the contract. The action types below are the
/// ones the documents name; the rest of that enum is **not documented and
/// must be confirmed against the live API** before release — a wrong value
/// is a 422 on a dropdown the app offered. See QUESTIONS.md.
class FieldWriteEnums {
  FieldWriteEnums._();

  static const List<String> fineTypes = [
    'non_payment',
    'seal_violation',
    'unauthorised_use',
    'encroachment',
    'other',
  ];

  // --- Action types, as the build brief names them ----------------------
  //
  // The brief's action-sheet table is the first document to write these
  // down, so they replace the guesses the app previously offered. There is
  // still no options endpoint returning `{value,label}`, which means the
  // labels below live in `lib/l10n/` and are a second source of truth —
  // see QUESTIONS.md §2.

  /// A call paid at the shop, with nothing else recorded.
  static const String siteVisit = 'site_visit';

  /// Said out loud, at the counter.
  static const String verbalWarning = 'verbal_warning';

  /// The last one before a fine or a seal.
  static const String finalWarning = 'final_warning';

  /// Carries `promised_payment_date`. **This is the write the app exists
  /// for** — it is what puts a shopkeeper's own words back in front of the
  /// officer the next time he walks that bazaar.
  static const String paymentPromised = 'payment_promised';

  /// Carries `next_visit_date`.
  static const String reminderVisitSet = 'reminder_visit_set';

  /// A written notice handed over.
  static const String noticeServed = 'notice_served';

  static const String other = 'other';

  static const List<String> actionTypes = [
    siteVisit,
    verbalWarning,
    finalWarning,
    paymentPromised,
    reminderVisitSet,
    noticeServed,
    other,
  ];

  /// The two that are meaningless without their date. The form refuses to
  /// submit one of these without it rather than letting the server 422 an
  /// officer standing in a bazaar.
  static bool needsPromiseDate(String actionType) =>
      actionType == paymentPromised;

  static bool needsVisitDate(String actionType) =>
      actionType == reminderVisitSet;
}
