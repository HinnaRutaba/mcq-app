import 'package:flutter_test/flutter_test.dart';
import 'package:mcq_app/models/common/can_flags.dart';

/// Buttons are enabled from the server's flags, never from `status`. These
/// tests pin the two properties that matter: an absent flag means *not
/// permitted*, and a flag the documents name differently in two places
/// still resolves.
void main() {
  test('a flag the server did not send is not permitted', () {
    const flags = CanFlags({});
    expect(flags.canSeal, isFalse);
    expect(flags.canRelease, isFalse);
    expect(flags.canClose, isFalse);
    expect(flags['can_anything_at_all'], isFalse);
    expect(flags.knows('can_seal'), isFalse);
  });

  test('reads the flags off a case payload and ignores everything else', () {
    final flags = CanFlags.fromJson({
      'id': 1,
      'case_no': 'MCQ-EC-0001',
      'status': {'value': 'open', 'label': 'Open'},
      'is_live': true,
      'is_sealed': false,
      'visit_overdue': true,
      'can_seal': true,
      'can_close': false,
      'closing_remarks': null,
    });

    expect(flags.canSeal, isTrue);
    expect(flags.canClose, isFalse);
    expect(flags.isLive, isTrue);
    expect(flags.isSealed, isFalse);
    expect(flags.visitOverdue, isTrue);
    expect(flags.knows('can_close'), isTrue);
    expect(flags.all.containsKey('case_no'), isFalse);
    expect(flags.all.containsKey('status'), isFalse);
  });

  test('status alone never enables an action', () {
    // The exact bug this guards: an open case with a court stay on it
    // comes back with can_seal false, and the app must not offer to seal.
    final stayed = CanFlags.fromJson({
      'status': {'value': 'open'},
      'is_live': true,
      'can_seal': false,
    });
    expect(stayed.isLive, isTrue);
    expect(stayed.canSeal, isFalse);
  });

  test('release resolves whether the server calls it release or unseal', () {
    expect(CanFlags.fromJson({'can_release': true}).canRelease, isTrue);
    expect(CanFlags.fromJson({'can_unseal': true}).canRelease, isTrue);
    expect(CanFlags.fromJson({'can_unseal': false}).canRelease, isFalse);
  });

  test('approval flags are read, not inferred from a fine amount', () {
    final fine = CanFlags.fromJson({
      'requires_approval': true,
      'awaiting_approval': true,
      'can_approve': false,
    });
    expect(fine.requiresApproval, isTrue);
    expect(fine.awaitingApproval, isTrue);
    expect(fine.canApprove, isFalse);
  });
}
