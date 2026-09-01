import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mcq_app/controllers/api/offline_queue_controller.dart';
import 'package:mcq_app/core/network/api_envelope.dart';
import 'package:mcq_app/core/network/api_exception.dart';
import 'package:mcq_app/core/services/connectivity_service.dart';
import 'package:mcq_app/data/api/repositories/queued_write_repository.dart';
import 'package:mcq_app/models/offline/queued_write.dart';

/// A queue that records what it was asked to send, and answers however the
/// test needs it to.
class _FakeQueue implements QueuedWriteRepository {
  _FakeQueue({this.responder});

  final Future<ApiEnvelope> Function(QueuedWrite write)? responder;

  List<QueuedWrite> stored = [];

  /// Every UUID this fake was asked to send, in order — the record that
  /// proves a retry reuses the key instead of minting a new one.
  final List<String> sentUuids = [];

  @override
  List<QueuedWrite> load() => stored;

  @override
  Future<void> save(List<QueuedWrite> queue) async {
    stored = List<QueuedWrite>.from(queue);
  }

  @override
  Future<ApiEnvelope> send(QueuedWrite write) async {
    sentUuids.add(write.clientActionUuid);
    if (responder != null) return responder!(write);
    return const ApiEnvelope(data: {}, statusCode: 201);
  }
}

class _OfflineConnectivity extends ConnectivityService {
  @override
  Future<bool> get isOnline async => false;

  @override
  Stream<bool> get onChanged => const Stream<bool>.empty();
}

QueuedWrite _seal({String uuid = 'uuid-seal-1'}) => QueuedWrite(
      clientActionUuid: uuid,
      kind: QueuedWriteKind.seal,
      path: '/enforcement/cases/7/seal',
      body: {
        'reason': 'Arrears of 5 months',
        'client_action_uuid': uuid,
        'recorded_offline': true,
      },
      recordedAt: DateTime(2026, 8, 25, 10, 30),
      shopLabel: 'P-1',
      allotteeLabel: 'Abdul Rehman',
      caseId: 7,
    );

ApiException _network() => ApiException(
      kind: ApiFailureKind.network,
      message: 'no signal',
    );

ApiException _conflict() => ApiException(
      kind: ApiFailureKind.conflict,
      statusCode: 409,
      message: 'This shop is already sealed.',
      fromServer: true,
    );

void main() {
  tearDown(Get.reset);

  OfflineQueueController controllerFor(_FakeQueue queue) {
    final controller = OfflineQueueController(
      repository: queue,
      connectivity: _OfflineConnectivity(),
    );
    Get.put<OfflineQueueController>(controller);
    controller.onInit();
    return controller;
  }

  test('a queued write is persisted and sent with its own UUID', () async {
    final queue = _FakeQueue();
    final controller = controllerFor(queue);

    await controller.enqueue(_seal());
    expect(queue.stored.single.clientActionUuid, 'uuid-seal-1');
    expect(queue.sentUuids, isEmpty,
        reason: 'the caller has just failed to reach the server');

    await controller.drain();

    expect(queue.sentUuids, ['uuid-seal-1']);
    expect(controller.items, isEmpty, reason: 'the server has it now');
  });

  test('a timeout keeps the record, and the retry reuses the same UUID',
      () async {
    var attempt = 0;
    final queue = _FakeQueue(
      responder: (write) async {
        attempt++;
        // First attempt times out; the second succeeds. A double-seal here
        // would be a shop closed twice for one offence.
        if (attempt == 1) throw _network();
        return const ApiEnvelope(data: {}, statusCode: 200);
      },
    );
    final controller = controllerFor(queue);

    await controller.enqueue(_seal());
    expect(controller.items.single.status, QueuedWriteStatus.pending);

    // The signal dies on the first attempt.
    await controller.drain();
    expect(controller.items.single.status, QueuedWriteStatus.pending);

    // It comes back, and the same record goes out under the same key.
    await controller.drain();

    expect(queue.sentUuids, ['uuid-seal-1', 'uuid-seal-1']);
    expect(controller.items, isEmpty);
  });

  test('a 200 replay is treated as done, not as something to send again',
      () async {
    final queue = _FakeQueue(
      responder: (write) async => const ApiEnvelope(data: {}, statusCode: 200),
    );
    final controller = controllerFor(queue);

    await controller.enqueue(_seal());
    await controller.drain();
    await controller.drain();

    expect(queue.sentUuids.length, 1);
    expect(controller.items, isEmpty);
  });

  test('a 409 is never discarded — it waits with the server\'s sentence',
      () async {
    final queue = _FakeQueue(responder: (write) async => throw _conflict());
    final controller = controllerFor(queue);

    await controller.enqueue(_seal());
    await controller.drain();

    final stuck = controller.items.single;
    expect(stuck.status, QueuedWriteStatus.needsAttention);
    expect(stuck.serverMessage, 'This shop is already sealed.');
    expect(stuck.serverStatusCode, 409);
    expect(controller.attentionCount, 1);

    // And it is not retried behind the officer's back.
    await controller.drain();
    expect(queue.sentUuids.length, 1);
  });

  test('a stuck record can be sent again once the officer says so', () async {
    var attempt = 0;
    final queue = _FakeQueue(
      responder: (write) async {
        attempt++;
        if (attempt == 1) throw _conflict();
        return const ApiEnvelope(data: {}, statusCode: 201);
      },
    );
    final controller = controllerFor(queue);

    await controller.enqueue(_seal());
    await controller.drain();
    expect(controller.items.single.isBlocked, isTrue);

    await controller.retry('uuid-seal-1');

    expect(queue.sentUuids, ['uuid-seal-1', 'uuid-seal-1']);
    expect(controller.items, isEmpty);
  });

  test('discarding takes an explicit call and nothing else', () async {
    final queue = _FakeQueue(responder: (write) async => throw _conflict());
    final controller = controllerFor(queue);

    await controller.enqueue(_seal());
    await controller.drain();
    expect(controller.items.length, 1);

    await controller.discard('uuid-seal-1');
    expect(controller.items, isEmpty);
    expect(queue.stored, isEmpty);
  });

  test('draining stops at the first lost signal and keeps the rest', () async {
    final queue = _FakeQueue(responder: (write) async => throw _network());
    final controller = controllerFor(queue);

    await controller.enqueue(_seal(uuid: 'a'));
    await controller.enqueue(_seal(uuid: 'b'));
    await controller.drain();

    // One attempt, not two: with no signal there is no point working
    // through the rest, and 'b' keeps its place in the queue.
    expect(queue.sentUuids, ['a']);
    expect(controller.items.length, 2);
    expect(
      controller.items.every((item) => item.status == QueuedWriteStatus.pending),
      isTrue,
    );
  });

  test('the queue survives being reloaded from storage', () async {
    final queue = _FakeQueue(responder: (write) async => throw _network());
    final first = controllerFor(queue);
    await first.enqueue(_seal());
    Get.reset();

    final second = OfflineQueueController(
      repository: queue,
      connectivity: _OfflineConnectivity(),
    );
    second.onInit();

    expect(second.items.single.clientActionUuid, 'uuid-seal-1');
    expect(second.items.single.body['recorded_offline'], isTrue);
  });
}
