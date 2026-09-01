/// What kind of field write is queued — used for the label the officer
/// reads and for deciding which screen to refresh once it lands.
enum QueuedWriteKind {
  action,
  seal,
  release,
  fine,
  inspection;

  String get labelKey => switch (this) {
        QueuedWriteKind.action => 'queue.itemAction',
        QueuedWriteKind.seal => 'queue.itemSeal',
        QueuedWriteKind.release => 'queue.itemRelease',
        QueuedWriteKind.fine => 'queue.itemFine',
        QueuedWriteKind.inspection => 'inspection.title',
      };

  static QueuedWriteKind fromName(String? name) => QueuedWriteKind.values
      .firstWhere((kind) => kind.name == name, orElse: () => QueuedWriteKind.action);
}

enum QueuedWriteStatus {
  /// Waiting for signal. The normal state.
  pending,

  /// In flight right now.
  sending,

  /// The server refused it — a 409 because the state of the case moved
  /// while the handset was offline, or a 422/403. **Never discarded
  /// silently**: a queue that drops a visit an officer made is worse than
  /// one that never existed.
  needsAttention,

  /// Accepted by the server (201) or replayed by it (200).
  sent;

  static QueuedWriteStatus fromName(String? name) => QueuedWriteStatus.values
      .firstWhere((s) => s.name == name, orElse: () => QueuedWriteStatus.pending);
}

/// One field write captured on the handset, waiting to reach the server.
///
/// The queue stores the request itself — endpoint, body, and any image
/// still to upload — so replay needs no knowledge of which screen created
/// it. The body already carries `client_action_uuid`, which is what makes
/// the replay safe: all four field writes check it before doing anything
/// and return the record they already made.
class QueuedWrite {
  QueuedWrite({
    required this.clientActionUuid,
    required this.kind,
    required this.path,
    required this.body,
    required this.recordedAt,
    required this.shopLabel,
    required this.allotteeLabel,
    this.localPhotoPath,
    this.localSignaturePath,
    this.status = QueuedWriteStatus.pending,
    this.attempts = 0,
    this.serverMessage,
    this.serverStatusCode,
    this.caseId,
    this.propertyId,
    this.sealId,
  });

  /// The idempotency key. Also this item's identity in the queue — the
  /// same UUID goes on every retry, for the lifetime of the record.
  final String clientActionUuid;

  final QueuedWriteKind kind;

  /// The endpoint this write posts to, e.g. `/enforcement/cases/7/actions`.
  final String path;

  /// The JSON body, already complete apart from `photo_path` /
  /// `signature_path`, which are filled in after the image uploads.
  Map<String, dynamic> body;

  /// Images captured on the handset. The photograph uploads first and
  /// yields a path; the action then carries that path, so a failed action
  /// never loses the evidence and a retry does not re-send two megabytes.
  String? localPhotoPath;
  String? localSignaturePath;

  final DateTime recordedAt;

  /// Named on the queue row and on the discard confirmation, because the
  /// officer needs to know *which* shop a stuck record belongs to.
  final String shopLabel;
  final String allotteeLabel;

  QueuedWriteStatus status;
  int attempts;

  /// The server's own sentence when it refused. Shown verbatim.
  String? serverMessage;
  int? serverStatusCode;

  final int? caseId;
  final int? propertyId;
  final int? sealId;

  bool get isBlocked => status == QueuedWriteStatus.needsAttention;
  bool get hasPendingPhoto => (localPhotoPath ?? '').isNotEmpty &&
      (body['photo_path'] == null || '${body['photo_path']}'.isEmpty);
  bool get hasPendingSignature => (localSignaturePath ?? '').isNotEmpty &&
      (body['signature_path'] == null || '${body['signature_path']}'.isEmpty);

  Map<String, dynamic> toJson() => {
        'client_action_uuid': clientActionUuid,
        'kind': kind.name,
        'path': path,
        'body': body,
        'recorded_at': recordedAt.toIso8601String(),
        'shop_label': shopLabel,
        'allottee_label': allotteeLabel,
        'local_photo_path': localPhotoPath,
        'local_signature_path': localSignaturePath,
        'status': status.name,
        'attempts': attempts,
        'server_message': serverMessage,
        'server_status_code': serverStatusCode,
        'case_id': caseId,
        'property_id': propertyId,
        'seal_id': sealId,
      };

  factory QueuedWrite.fromJson(Map<String, dynamic> json) => QueuedWrite(
        clientActionUuid: '${json['client_action_uuid']}',
        kind: QueuedWriteKind.fromName(json['kind'] as String?),
        path: '${json['path']}',
        body: (json['body'] as Map?)?.cast<String, dynamic>() ?? {},
        recordedAt:
            DateTime.tryParse('${json['recorded_at']}') ?? DateTime.now(),
        shopLabel: '${json['shop_label'] ?? ''}',
        allotteeLabel: '${json['allottee_label'] ?? ''}',
        localPhotoPath: json['local_photo_path'] as String?,
        localSignaturePath: json['local_signature_path'] as String?,
        status: QueuedWriteStatus.fromName(json['status'] as String?),
        attempts: json['attempts'] is int ? json['attempts'] as int : 0,
        serverMessage: json['server_message'] as String?,
        serverStatusCode: json['server_status_code'] as int?,
        caseId: json['case_id'] as int?,
        propertyId: json['property_id'] as int?,
        sealId: json['seal_id'] as int?,
      );
}
