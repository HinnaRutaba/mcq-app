import 'dart:async';

import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/utils/app_feedback.dart';
import '../../data/api/repositories/queued_write_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/offline/queued_write.dart';

/// The offline write queue.
///
/// The contract, from the schema's own comment on `client_action_uuid`
/// ("Generated on the handset. Makes the offline sync idempotent when the
/// app retries on a weak signal"):
///
/// 1. The officer records a visit with no signal. It is stored locally with
///    a generated UUID, the real `device_recorded_at`, and
///    `recorded_offline: true`.
/// 2. Signal returns. The photograph uploads, then the action posts with
///    the **same UUID**.
/// 3. The POST times out? Send it again with the same UUID. The server
///    returns the record it already made.
///
/// What the server does not provide is conflict resolution: if the case's
/// state moved while the handset was offline — somebody else sealed it, the
/// dues were cleared at a counter — the write is refused with a 409. That
/// record is **never discarded**. It goes to "needs attention" with the
/// server's sentence attached, so the officer can see what happened and
/// decide. A queue that silently drops a visit an officer made is worse
/// than one that never existed.
class OfflineQueueController extends GetxController {
  OfflineQueueController({
    required QueuedWriteRepository repository,
    required ConnectivityService connectivity,
  })  : _repository = repository,
        _connectivity = connectivity;

  final QueuedWriteRepository _repository;
  final ConnectivityService _connectivity;

  final RxList<QueuedWrite> items = <QueuedWrite>[].obs;
  final RxBool isSyncing = false.obs;
  final RxBool isOnline = true.obs;

  /// Bumped every time a queued write reaches the server, so open screens
  /// know to reload rather than showing a case that has since moved.
  final RxInt landed = 0.obs;

  StreamSubscription<bool>? _connectivitySub;

  @override
  void onInit() {
    super.onInit();
    items.assignAll(_repository.load());
    _connectivitySub = _connectivity.onChanged.listen((online) {
      isOnline.value = online;
      if (online) drain();
    });
    _connectivity.isOnline.then((online) {
      isOnline.value = online;
      if (online && items.isNotEmpty) drain();
    });
  }

  @override
  void onClose() {
    _connectivitySub?.cancel();
    super.onClose();
  }

  int get pendingCount => items
      .where((item) => item.status != QueuedWriteStatus.needsAttention)
      .length;

  int get attentionCount => items.where((item) => item.isBlocked).length;

  int get badgeCount => items.length;

  List<QueuedWrite> get needsAttention =>
      items.where((item) => item.isBlocked).toList();

  /// Stores a write captured with no signal.
  ///
  /// It is deliberately not sent here: the caller has just failed to reach
  /// the server, so an immediate second attempt would only burn the
  /// officer's battery. It goes out when the signal returns (the
  /// connectivity listener above), when the app next launches, or when the
  /// officer taps "send now".
  Future<void> enqueue(QueuedWrite write) async {
    items.add(write);
    await _repository.save(items);
    AppFeedback.toast(t('action.queued'));
  }

  /// Sends everything waiting, oldest first.
  ///
  /// Stops at the first network failure: with no signal there is no point
  /// working through the rest, and every item keeps its UUID for the next
  /// attempt.
  Future<void> drain() async {
    if (isSyncing.value) return;
    isSyncing.value = true;
    try {
      for (final write in List<QueuedWrite>.from(items)) {
        if (write.isBlocked) continue;
        final keepGoing = await _send(write);
        if (!keepGoing) break;
      }
    } finally {
      isSyncing.value = false;
      await _repository.save(items);
      items.refresh();
    }
  }

  Future<bool> _send(QueuedWrite write) async {
    write.status = QueuedWriteStatus.sending;
    write.attempts += 1;
    items.refresh();
    try {
      await _repository.send(write);
      // 201 created or 200 replayed — either way the server has the
      // record, so mark it done rather than sending it again.
      write.status = QueuedWriteStatus.sent;
      items.removeWhere(
        (item) => item.clientActionUuid == write.clientActionUuid,
      );
      landed.value++;
      return true;
    } on ApiException catch (error) {
      if (error.isNetwork) {
        write.status = QueuedWriteStatus.pending;
        return false;
      }
      // A 409, 422 or 403 is the server's decision, not a transport
      // hiccup: stop retrying and put it in front of the officer.
      write.status = QueuedWriteStatus.needsAttention;
      write.serverMessage = error.message;
      write.serverStatusCode = error.statusCode;
      return true;
    }
  }

  /// The officer asking a stuck item to go again — after they have read the
  /// server's sentence and, say, refreshed the case.
  Future<void> retry(String clientActionUuid) async {
    final write = _byUuid(clientActionUuid);
    if (write == null) return;
    write.status = QueuedWriteStatus.pending;
    write.serverMessage = null;
    write.serverStatusCode = null;
    items.refresh();
    await _repository.save(items);
    await drain();
  }

  /// Only ever from an explicit confirmation that names the shop and the
  /// allottee. Nothing in this class discards a record on its own.
  Future<void> discard(String clientActionUuid) async {
    items.removeWhere((item) => item.clientActionUuid == clientActionUuid);
    await _repository.save(items);
  }

  QueuedWrite? _byUuid(String uuid) =>
      items.firstWhereOrNull((item) => item.clientActionUuid == uuid);
}
