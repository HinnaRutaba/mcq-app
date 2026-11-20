import '../core/utils/json_parse.dart';

/// A workspace the app can draw. The server names them in `mobile.workspaces`.
enum MobileWorkspace {
  /// The magistrate's enforcement round.
  field('field', 'Field enforcement'),

  /// The CMO's and Administrator's agreement reviews.
  agreements('agreements', 'Agreement reviews');

  const MobileWorkspace(this.key, this.label);

  final String key;
  final String label;

  static MobileWorkspace? byKey(String key) {
    for (final MobileWorkspace workspace in values) {
      if (workspace.key == key) return workspace;
    }
    return null;
  }
}

/// The `mobile` block on sign-in and on every session read: what this officer
/// may see on the phone. Recomputed by the server each call, so a role changed
/// after sign-in shows on the next session read.
///
/// Drawing from it is a courtesy — every endpoint authorises again.
class MobileAccess {
  const MobileAccess({
    this.workspaces = const <MobileWorkspace>[],
    this.capabilities = const <String>[],
    this.passwordChangeRequired = false,
    this.fromServer = true,
  });

  final List<MobileWorkspace> workspaces;

  /// Dotted keys, e.g. `agreements.decide`. See [AgreementCapability].
  final List<String> capabilities;

  final bool passwordChangeRequired;

  /// False when the payload carried no `mobile` block — a server from before
  /// the shared app. Treated as the magistrate's field workspace, which is all
  /// that server knew.
  final bool fromServer;

  /// What an older server's session means: the field workspace and nothing
  /// else, exactly as the app behaved before.
  static const MobileAccess legacy = MobileAccess(
    workspaces: <MobileWorkspace>[MobileWorkspace.field],
    fromServer: false,
  );

  factory MobileAccess.fromJson(Object? source) {
    if (source is! Map) return legacy;
    final Map<String, dynamic> json = Json.map(source);
    return MobileAccess(
      // An unknown workspace is a newer server's; it is skipped, not guessed.
      workspaces: Json.stringList(
        json['workspaces'],
      ).map(MobileWorkspace.byKey).whereType<MobileWorkspace>().toList(),
      capabilities: Json.stringList(json['capabilities']),
      passwordChangeRequired: Json.booleanOr(json['password_change_required']),
    );
  }

  bool has(MobileWorkspace workspace) => workspaces.contains(workspace);

  bool can(String capability) => capabilities.contains(capability);

  bool get hasMany => workspaces.length > 1;

  bool get isEmpty => workspaces.isEmpty;

  /// The one workspace to open straight into, or null when there is a choice
  /// to make (or nothing to open).
  MobileWorkspace? get only => workspaces.length == 1 ? workspaces.first : null;
}

/// The agreement workspace's capability keys, as `mobile.capabilities` sends
/// them.
class AgreementCapability {
  AgreementCapability._();

  static const String endorse = 'agreements.endorse';
  static const String dispatch = 'agreements.dispatch';
  static const String decide = 'agreements.decide';
  static const String view = 'agreements.view';
  static const String applicantDocuments = 'agreements.applicant_documents';
  static const String executionEvidence = 'agreements.execution_evidence';
  static const String executionVideo = 'agreements.execution_video';
  static const String terminations = 'agreements.terminations';
}
