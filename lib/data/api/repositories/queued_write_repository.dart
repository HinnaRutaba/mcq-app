import 'dart:io';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/storage/key_value_store.dart';
import '../../../models/enforcement/field_evidence.dart';
import '../../../models/offline/queued_write.dart';
import 'enforcement_repository.dart';

/// Persistence and replay for field writes captured with no signal.
///
/// Only the four idempotent writes are queued — record an action, seal,
/// release, impose a fine. Each checks `client_action_uuid` before doing
/// anything and replays the record it already made, so sending the same
/// item again cannot double-seal a shop or fine a shopkeeper twice.
///
/// An inspection is deliberately **not** queued: it is a one-step
/// multipart write with no idempotency key, so a blind retry could record
/// it twice. Inspections need signal.
///
/// The queue controller depends on this abstract type, so the sync
/// behaviour — what a 409 does, what a timeout does — is testable without
/// a server.
abstract class QueuedWriteRepository {
  /// Everything still waiting, in the order it was captured.
  List<QueuedWrite> load();

  Future<void> save(List<QueuedWrite> queue);

  /// Sends one queued write, uploading any photograph still held locally
  /// first and writing the returned path back onto the item.
  Future<ApiEnvelope> send(QueuedWrite write);
}

class ApiQueuedWriteRepository implements QueuedWriteRepository {
  ApiQueuedWriteRepository({
    required ApiClient client,
    required EnforcementRepository enforcement,
    required KeyValueStore store,
  })  : _client = client,
        _enforcement = enforcement,
        _store = store;

  final ApiClient _client;
  final EnforcementRepository _enforcement;
  final KeyValueStore _store;

  @override
  List<QueuedWrite> load() {
    final raw = _store.getJsonList(KeyValueStore.queueKey) ?? const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(QueuedWrite.fromJson)
        .toList();
  }

  @override
  Future<void> save(List<QueuedWrite> queue) =>
      _store.setJson(KeyValueStore.queueKey, queue.map((w) => w.toJson()).toList());

  /// Sends one queued write.
  ///
  /// The photograph goes first and yields a path, which is written back
  /// onto the item before the action is posted — so a failed action never
  /// re-shoots or re-uploads the evidence, it just carries the same path
  /// next time.
  @override
  Future<ApiEnvelope> send(QueuedWrite write) async {
    if (write.hasPendingPhoto) {
      final upload = await _enforcement.uploadEvidence(
        file: File(write.localPhotoPath!),
        kind: EvidenceUpload.kindPhoto,
      );
      write.body['photo_path'] = upload.path;
      await _persistOne(write);
    }
    if (write.hasPendingSignature) {
      final upload = await _enforcement.uploadEvidence(
        file: File(write.localSignaturePath!),
        kind: EvidenceUpload.kindSignature,
      );
      write.body['signature_path'] = upload.path;
      await _persistOne(write);
    }
    return _client.post(write.path, body: write.body);
  }

  /// Writes the current state of one item back into the stored queue, so a
  /// path obtained mid-sync survives the app being killed.
  Future<void> _persistOne(QueuedWrite write) async {
    final queue = load();
    final index = queue.indexWhere(
      (item) => item.clientActionUuid == write.clientActionUuid,
    );
    if (index == -1) return;
    queue[index] = write;
    await save(queue);
  }
}
