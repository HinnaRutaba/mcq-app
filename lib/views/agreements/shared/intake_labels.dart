/// How a reviewer says the workflow's machine values.
class IntakeLabels {
  IntakeLabels._();

  /// A `status.value`.
  static String status(String value) => switch (value) {
    'pending_taxation' => 'With Taxation',
    'pending_cmo' => 'With the CMO',
    'pending_admin' => 'With the Administrator',
    'pending_dispatch' => 'Awaiting dispatch',
    'pending_execution_handoff' => 'Awaiting hand-off',
    'approved' => 'Approved',
    'activated' => 'Activated',
    'returned' => 'Returned to Estate',
    'rejected' => 'Rejected',
    'cancelled' => 'Cancelled',
    _ => humanise(value),
  };

  /// A `with_branch` or a return `destination`.
  static String branch(String value) => switch (value) {
    'estate' => 'Estate',
    'taxation' => 'Taxation',
    'cmo' => 'the CMO',
    'administrator' => 'the Administrator',
    _ => humanise(value),
  };

  /// An act, as its button says it.
  static String act(String value) => switch (value) {
    'endorse' => 'Endorse',
    'approve' => 'Approve',
    'reject' => 'Reject',
    'return' => 'Return or query',
    'respond' => 'Answer query',
    'dispatch' => 'Dispatch',
    'forward' => 'Forward',
    _ => humanise(value),
  };

  /// An act, once done.
  static String actDone(String value) => switch (value) {
    'endorse' => 'Endorsed',
    'approve' => 'Approved',
    'reject' => 'Rejected',
    'return' => 'Sent back',
    'respond' => 'Query answered',
    'dispatch' => 'Dispatched',
    _ => humanise(value),
  };

  /// Why an act is closed — explained rather than worked around.
  static String refusal(String? reason) => switch (reason) {
    'not_at_stage' => 'The case is not at your stage.',
    'query_open' => 'A query is open at your stage. Answer it first.',
    'no_open_query' => 'There is no open query to answer.',
    'separation_of_duties' =>
      'You acted at another stage of this cycle; another officer must take '
          'this step.',
    'prior_step_not_valid' =>
      'Estate changed the case after it was endorsed. It has to come round '
          'again — return it to Estate.',
    'location_changed' =>
      'The shop’s location changed since review. Return it to Estate.',
    'signature_required' =>
      'You have no signature on file. Add one on the web: Profile → My '
          'signature.',
    _ => 'Not available on this case.',
  };

  /// `follow_ups_due` → `Follow ups due`, for a value newer than this build.
  static String humanise(String key) {
    if (key.isEmpty) return '—';
    final String words = key.replaceAll(RegExp(r'[_.]'), ' ').trim();
    return words[0].toUpperCase() + words.substring(1);
  }
}
