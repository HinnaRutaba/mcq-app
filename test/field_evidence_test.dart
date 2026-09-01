import 'package:flutter_test/flutter_test.dart';
import 'package:mcq_app/models/enforcement/field_evidence.dart';

void main() {
  FieldEvidence evidence({
    double? latitude,
    double? longitude,
    double? accuracy,
    String? photoPath,
    bool offline = false,
  }) =>
      FieldEvidence(
        clientActionUuid: '9f1c8f2a-0000-4000-8000-000000000001',
        actionDate: DateTime(2026, 8, 25),
        deviceRecordedAt: DateTime.utc(2026, 8, 27, 6, 30),
        latitude: latitude,
        longitude: longitude,
        locationAccuracyM: accuracy,
        photoPath: photoPath,
        recordedOffline: offline,
      );

  test('always carries the idempotency key', () {
    expect(
      evidence().toJson()['client_action_uuid'],
      '9f1c8f2a-0000-4000-8000-000000000001',
    );
  });

  test('sends the date it happened, not the date it synced', () {
    expect(evidence().toJson()['action_date'], '2026-08-25');
  });

  test('coordinates are both or neither', () {
    final half = evidence(latitude: 30.1913, accuracy: 8.4).toJson();
    expect(half.containsKey('latitude'), isFalse);
    expect(half.containsKey('longitude'), isFalse);
    // Accuracy without a fix would be a pin that locates nothing.
    expect(half.containsKey('location_accuracy_m'), isFalse);

    final full =
        evidence(latitude: 30.1913, longitude: 67.0099, accuracy: 8.4).toJson();
    expect(full['latitude'], 30.1913);
    expect(full['longitude'], 67.0099);
    expect(full['location_accuracy_m'], 8.4);
  });

  test('an empty witness or remark is left out rather than sent blank', () {
    final json = FieldEvidence(
      clientActionUuid: 'u',
      actionDate: DateTime(2026, 8, 25),
      deviceRecordedAt: DateTime.utc(2026, 8, 25),
      witnessName: '   ',
      remarks: '',
    ).toJson();
    expect(json.containsKey('witness_name'), isFalse);
    expect(json.containsKey('remarks'), isFalse);
  });

  test('a record captured with no signal says so', () {
    expect(evidence(offline: true).toJson()['recorded_offline'], isTrue);
    expect(evidence().toJson()['recorded_offline'], isFalse);
  });

  test('the photograph travels as a path, never as bytes', () {
    final json = evidence(photoPath: 'photos/01m0wdk5sm.png').toJson();
    expect(json['photo_path'], 'photos/01m0wdk5sm.png');
    expect(json.containsKey('file'), isFalse);
  });

  test('survives a round trip through the offline queue unchanged', () {
    final original = evidence(
      latitude: 30.1913,
      longitude: 67.0099,
      accuracy: 8.4,
      photoPath: 'photos/x.png',
      offline: true,
    );
    final restored = FieldEvidence.fromJson(original.toJson());
    expect(restored.clientActionUuid, original.clientActionUuid);
    expect(restored.toJson()['action_date'], '2026-08-25');
    expect(restored.photoPath, 'photos/x.png');
    expect(restored.recordedOffline, isTrue);
  });
}
