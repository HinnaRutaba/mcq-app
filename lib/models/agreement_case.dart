import '../core/utils/json_parse.dart';
import 'api_refs.dart';
import 'intake_legacy.dart';

/// A counter agreement case (an "intake"): the shop, the applicant, the money
/// the server computed, and the review chain it is moving through.
///
/// One class serves the list row and the detail — a row simply arrives
/// without [actOptions] and the applicant's register record. Ids are strings
/// here and are sent back exactly as received.
class AgreementCase {
  const AgreementCase({
    required this.id,
    this.intakeNo,
    this.caseType,
    this.status,
    this.approvalRoute,
    this.contentRevision,
    this.lockVersion,
    this.withBranch,
    this.nextAction,
    this.shop = const IntakeShop(),
    this.applicant,
    this.legacy,
    this.witnesses = const <IntakeWitness>[],
    this.amounts = const <String, String>{},
    this.actions = const <IntakeAction>[],
    this.lastReturn,
    this.query,
    this.actOptions = const <IntakeActOption>[],
    this.media = const <IntakeDocument>[],
    this.numberedPdf,
    this.execution,
    this.agreementPdf,
    this.submittedAt,
  });

  final String id;
  final String? intakeNo;
  final LabelledValue? caseType;

  /// `status.value` is one of [IntakeStatus].
  final LabelledValue? status;
  final String? approvalRoute;
  final int? contentRevision;

  /// Sent back on every act. A stale one is `409 intake.changed_since_viewed`.
  final int? lockVersion;

  /// `estate`, `taxation`, `cmo`, `administrator`.
  final String? withBranch;
  final String? nextAction;

  final IntakeShop shop;
  final IntakeApplicant? applicant;

  /// The shop's legacy register row, to check the case against.
  final IntakeLegacy? legacy;
  final List<IntakeWitness> witnesses;

  /// `amounts.*` flattened to dotted keys, values exactly as sent. Never
  /// parsed or totalled here — every figure is the server's.
  final Map<String, String> amounts;

  /// The workflow, in the order the server sent it.
  final List<IntakeAction> actions;
  final IntakeNote? lastReturn;

  /// An open query at the reader's stage — `stage.query`.
  final IntakeNote? query;

  /// What this reader may do. Empty on a list row.
  final List<IntakeActOption> actOptions;
  final List<IntakeDocument> media;

  /// Null until Estate saves one.
  final IntakeDocument? numberedPdf;
  final IntakeExecution? execution;

  /// The agreement on stamp paper as the server renders it — `agreement_pdf`.
  final IntakeAgreementPdf? agreementPdf;
  final DateTime? submittedAt;

  factory AgreementCase.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> stage = Json.map(json['stage']);
    final String id = Json.stringOr(json['id']);
    return AgreementCase(
      id: id,
      intakeNo: Json.string(Json.pick(json, <String>['intake_no', 'case_no'])),
      caseType: LabelledValue.maybe(json['case_type']),
      status: LabelledValue.maybe(json['status']),
      approvalRoute: intakeText(json['approval_route']),
      contentRevision: Json.integer(json['content_revision']),
      lockVersion: Json.integer(json['lock_version']),
      withBranch: intakeText(json['with_branch']),
      nextAction: intakeText(json['next_action']),
      shop: IntakeShop.fromJson(Json.map(json['shop'])),
      applicant: json['applicant'] is Map
          ? IntakeApplicant.fromJson(Json.map(json['applicant']))
          : null,
      legacy: IntakeLegacy.maybe(
        json['legacy'] ?? Json.map(json['shop'])['legacy'],
      ),
      witnesses: Json.list(
        json['witnesses'],
      ).map(IntakeWitness.fromJson).toList(),
      amounts: flattenScalars(Json.map(json['amounts'])),
      actions: Json.list(json['actions']).map(IntakeAction.fromJson).toList(),
      lastReturn: IntakeNote.maybe(json['last_return']),
      query: IntakeNote.maybe(stage['query']),
      actOptions: Json.list(
        Json.pick(stage, <String>['act_options']) ?? json['act_options'],
      ).map(IntakeActOption.fromJson).toList(),
      media: Json.list(json['media']).map(IntakeDocument.fromJson).toList(),
      numberedPdf: _numbered(json['numbered_pdf'], id),
      execution: json['execution'] is Map
          ? IntakeExecution.fromJson(Json.map(json['execution']))
          : null,
      agreementPdf: IntakeAgreementPdf.maybe(json['agreement_pdf']),
      submittedAt: Json.dateTime(
        Json.pick(json, <String>['submitted_at', 'last_submitted_at']),
      ),
    );
  }

  String get title => applicant?.name ?? intakeNo ?? 'Case $id';

  String? get statusValue => status?.value;

  /// Read only: nothing left for a reviewer on the phone.
  bool get isClosed => IntakeStatus.readOnly.contains(statusValue);

  /// The acts the server expects to accept, in the order it listed them.
  List<IntakeActOption> get allowedActs =>
      actOptions.where((IntakeActOption o) => o.allowed).toList();

  static IntakeDocument? _numbered(Object? source, String id) {
    if (source == null || source == false) return null;
    if (source is Map) return IntakeDocument.fromJson(Json.map(source));
    // A bare flag: the document lives at its fixed address.
    return IntakeDocument(
      label: 'Numbered copy',
      isPdf: true,
      url: '/api/v1/allotment/intakes/$id/numbered-pdf',
    );
  }
}

/// The `status.value`s the workflow publishes.
class IntakeStatus {
  IntakeStatus._();

  static const String pendingTaxation = 'pending_taxation';
  static const String pendingCmo = 'pending_cmo';
  static const String pendingAdmin = 'pending_admin';
  static const String pendingDispatch = 'pending_dispatch';
  static const String pendingExecutionHandoff = 'pending_execution_handoff';
  static const String approved = 'approved';
  static const String activated = 'activated';
  static const String returned = 'returned';
  static const String rejected = 'rejected';
  static const String cancelled = 'cancelled';

  static const Set<String> readOnly = <String>{
    approved,
    activated,
    returned,
    rejected,
    cancelled,
  };
}

class IntakeShop {
  const IntakeShop({
    this.shopNo,
    this.market,
    this.area,
    this.zone,
    this.address,
    this.verified,
    this.problem,
    this.reviewedLocation,
    this.locationChangedSinceReview = false,
  });

  final String? shopNo;
  final String? market;
  final String? area;
  final String? zone;
  final String? address;
  final bool? verified;
  final String? problem;

  /// Market/area/zone/shop at last submission, joined for reading.
  final String? reviewedLocation;
  final bool locationChangedSinceReview;

  factory IntakeShop.fromJson(Map<String, dynamic> json) => IntakeShop(
    shopNo: Json.string(Json.pick(json, <String>['shop_no', 'number'])),
    market: intakeText(json['market']),
    area: intakeText(json['area']),
    zone: intakeText(json['zone']),
    address: Json.string(json['address']),
    verified: Json.boolean(json['verified']),
    problem: intakeText(json['problem']),
    reviewedLocation: _location(json['reviewed_location']),
    locationChangedSinceReview: Json.booleanOr(
      json['location_changed_since_review'],
    ),
  );

  /// The shop and where it is, e.g. "S-14 · Liaquat Bazaar · Zone A".
  String? get line {
    final List<String> parts = <String>[
      if (shopNo != null) 'Shop $shopNo',
      ?market,
      if (area != null && area != market) area!,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// "Shop S-14 · Liaquat Bazaar, Quetta" — the street address if sent.
  String? get addressLine {
    final String where =
        address ??
        <String>[?market, if (area != null && area != market) area!].join(', ');
    final List<String> parts = <String>[
      if (shopNo != null) 'Shop $shopNo',
      if (where.isNotEmpty) where,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// Every part sent: shop, market, area, zone, then the street address less
  /// any part already named, e.g. "Shop S-14 · Liaquat Bazaar · Quetta".
  String? get fullAddress {
    final List<String> parts = <String>[
      if (shopNo != null) 'Shop $shopNo',
      ?market,
      if (area != null && area != market) area!,
      ?zone,
    ];
    final Set<String> named = parts.map((String p) => p.toLowerCase()).toSet();
    for (final String piece in (address ?? '').split(',')) {
      final String part = piece.trim();
      if (part.isNotEmpty && named.add(part.toLowerCase())) parts.add(part);
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  static String? _location(Object? source) {
    if (source is! Map) return intakeText(source);
    final Map<String, dynamic> json = Json.map(source);
    final List<String> parts = <String>[
      for (final String key in <String>[
        'shop',
        'shop_no',
        'market',
        'area',
        'zone',
      ])
        ?intakeText(json[key]),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

class IntakeApplicant {
  const IntakeApplicant({
    this.name,
    this.fatherName,
    this.cnic,
    this.mobile,
    this.address,
    this.business,
    this.ntn,
    this.recordMatches,
    this.recordLabel,
  });

  final String? name;
  final String? fatherName;
  final String? cnic;
  final String? mobile;
  final String? address;
  final String? business;
  final String? ntn;

  /// Whether the applicant matches the register record they will become.
  /// Null on a list row, which carries no record.
  final bool? recordMatches;
  final String? recordLabel;

  factory IntakeApplicant.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? record = Json.mapOrNull(json['record']);
    return IntakeApplicant(
      name: Json.string(Json.pick(json, <String>['name', 'full_name'])),
      fatherName: Json.string(
        Json.pick(json, <String>['father_name', 'father']),
      ),
      cnic: Json.string(Json.pick(json, <String>['cnic', 'cnic_no'])),
      mobile: Json.string(Json.pick(json, <String>['mobile', 'mobile_no'])),
      address: Json.string(json['address']),
      business: intakeText(
        Json.pick(json, <String>['business', 'business_name']),
      ),
      ntn: Json.string(Json.pick(json, <String>['ntn', 'ntn_no'])),
      recordMatches: record == null
          ? null
          : Json.boolean(Json.pick(record, <String>['matches', 'match'])),
      recordLabel: record == null
          ? null
          : intakeText(
              Json.pick(record, <String>[
                'label',
                'allottee_code',
                'code',
                'status',
              ]),
            ),
    );
  }
}

class IntakeWitness {
  const IntakeWitness({
    this.position,
    this.name,
    this.fatherName,
    this.cnic,
    this.mobile,
  });

  final int? position;
  final String? name;
  final String? fatherName;
  final String? cnic;
  final String? mobile;

  factory IntakeWitness.fromJson(Map<String, dynamic> json) => IntakeWitness(
    position: Json.integer(json['position']),
    name: Json.string(Json.pick(json, <String>['name', 'full_name'])),
    fatherName: Json.string(Json.pick(json, <String>['father_name', 'father'])),
    cnic: Json.string(Json.pick(json, <String>['cnic', 'cnic_no'])),
    mobile: Json.string(Json.pick(json, <String>['mobile', 'mobile_no'])),
  );
}

/// One step on the case's workflow.
class IntakeAction {
  const IntakeAction({
    this.id,
    this.action,
    this.actor,
    this.actorRole,
    this.branch,
    this.fromStatus,
    this.toStatus,
    this.destination,
    this.remarks,
    this.at,
    this.caseRevision,
    this.changeCount = 0,
    this.attachments = const <IntakeDocument>[],
    this.inReplyTo,
  });

  final String? id;
  final LabelledValue? action;
  final String? actor;
  final String? actorRole;
  final String? branch;
  final String? fromStatus;
  final String? toStatus;
  final String? destination;
  final String? remarks;
  final DateTime? at;
  final int? caseRevision;

  /// How many fields a resubmission changed.
  final int changeCount;
  final List<IntakeDocument> attachments;
  final String? inReplyTo;

  factory IntakeAction.fromJson(Map<String, dynamic> json) {
    final Object? changes = json['changes'];
    return IntakeAction(
      id: Json.string(json['id']),
      action: LabelledValue.maybe(json['action']),
      actor: intakeText(json['actor']),
      actorRole: intakeText(json['actor_role']),
      branch: intakeText(json['branch']),
      fromStatus: intakeText(json['from_status']),
      toStatus: intakeText(json['to_status']),
      destination: intakeText(json['destination']),
      remarks: Json.string(json['remarks']),
      at: Json.dateTime(json['at']),
      caseRevision: Json.integer(json['case_revision']),
      changeCount: changes is List
          ? changes.length
          : changes is Map
          ? changes.length
          : 0,
      attachments: Json.list(
        json['attachments'],
      ).map(IntakeDocument.fromJson).toList(),
      inReplyTo: intakeText(json['in_reply_to']),
    );
  }
}

/// A return or a query: who, when, and what they wrote.
class IntakeNote {
  const IntakeNote({this.by, this.fromStage, this.remarks, this.at});

  final String? by;
  final String? fromStage;
  final String? remarks;
  final DateTime? at;

  static IntakeNote? maybe(Object? source) {
    if (source is! Map) return null;
    final Map<String, dynamic> json = Json.map(source);
    return IntakeNote(
      by: intakeText(
        Json.pick(json, <String>['by', 'asked_by', 'actor', 'returned_by']),
      ),
      fromStage: intakeText(
        Json.pick(json, <String>['from_stage', 'stage', 'branch']),
      ),
      remarks: Json.string(
        Json.pick(json, <String>['remarks', 'question', 'text', 'message']),
      ),
      at: Json.dateTime(
        Json.pick(json, <String>['at', 'asked_at', 'created_at']),
      ),
    );
  }
}

/// One entry of `stage.act_options`: an act, and whether the server expects
/// to accept it from this reader right now.
class IntakeActOption {
  const IntakeActOption({
    required this.act,
    this.allowed = false,
    this.reason,
    this.method = 'POST',
    this.path,
    this.signed = false,
    this.remarksRequired = false,
    this.destinations = const <String>[],
  });

  /// `endorse`, `approve`, `reject`, `return`, `respond`, `dispatch`.
  final String act;
  final bool allowed;

  /// Null when allowed. One of [IntakeRefusalReason].
  final String? reason;
  final String method;
  final String? path;

  /// Endorse and approve carry the officer's signature on file.
  final bool signed;
  final bool remarksRequired;

  /// For `return`: where this reader may send it (`estate`, `taxation`, `cmo`).
  final List<String> destinations;

  factory IntakeActOption.fromJson(Map<String, dynamic> json) =>
      IntakeActOption(
        act: Json.stringOr(json['act']),
        allowed: Json.booleanOr(json['allowed']),
        reason: Json.string(json['reason']),
        method: Json.stringOr(json['method'], 'POST'),
        path: Json.string(json['path']),
        signed: Json.booleanOr(json['signed']),
        remarksRequired: Json.booleanOr(json['remarks_required']),
        destinations: Json.stringList(json['destinations']),
      );
}

/// The `reason`s an act option can be closed for.
class IntakeRefusalReason {
  IntakeRefusalReason._();

  static const String notAtStage = 'not_at_stage';
  static const String queryOpen = 'query_open';
  static const String noOpenQuery = 'no_open_query';
  static const String separationOfDuties = 'separation_of_duties';
  static const String priorStepNotValid = 'prior_step_not_valid';
  static const String locationChanged = 'location_changed';
  static const String signatureRequired = 'signature_required';
  static const String notAvailable = 'not_available';
}

/// A file on the case — a capture, an act's attachment, a numbered PDF, a
/// signed-scan part. [url] streams through the API with the bearer token.
class IntakeDocument {
  const IntakeDocument({
    this.id,
    this.slot,
    this.evidenceCode,
    this.mime,
    this.isPdf = false,
    this.filename,
    this.label,
    this.url,
  });

  final String? id;
  final String? slot;
  final String? evidenceCode;
  final String? mime;
  final bool isPdf;
  final String? filename;
  final String? label;

  /// Null when the reader may not open it (a restricted signing video).
  final String? url;

  factory IntakeDocument.fromJson(Map<String, dynamic> json) {
    final String? mime = Json.string(
      Json.pick(json, <String>['mime', 'mime_type']),
    );
    return IntakeDocument(
      id: Json.string(json['id']),
      slot: intakeText(json['slot']),
      evidenceCode: Json.string(json['evidence_code']),
      mime: mime,
      isPdf: Json.boolean(json['is_pdf']) ?? (mime?.contains('pdf') ?? false),
      filename: Json.string(Json.pick(json, <String>['filename', 'name'])),
      label: intakeText(Json.pick(json, <String>['label', 'title'])),
      url: Json.string(json['url']),
    );
  }

  bool get isImage => mime?.startsWith('image/') ?? false;
  bool get isVideo => mime?.startsWith('video/') ?? false;
  bool get canOpen => url != null;

  String get name =>
      label ?? humanise(slot) ?? filename ?? evidenceCode ?? 'Document';

  IntakeDocument withLabel(String? label) => IntakeDocument(
    id: id,
    slot: slot,
    evidenceCode: evidenceCode,
    mime: mime,
    isPdf: isPdf,
    filename: filename,
    label: label,
    url: url,
  );

  /// `cnic_front` → "CNIC front".
  static String? humanise(String? key) {
    if (key == null || key.isEmpty) return null;
    final String words = key
        .replaceAll('_', ' ')
        .trim()
        .replaceAllMapped(
          RegExp(r'\b(cnic|ntn)\b'),
          (Match m) => m[0]!.toUpperCase(),
        );
    return words[0].toUpperCase() + words.substring(1);
  }
}

/// `agreement_pdf`: the agreement rendered on stamp paper by the server.
class IntakeAgreementPdf {
  const IntakeAgreementPdf({
    this.kind,
    this.available = false,
    this.pdfUrl,
    this.downloadUrl,
  });

  /// `draft` until the agreement is numbered.
  final String? kind;
  final bool available;

  /// Streamed inline for viewing.
  final String? pdfUrl;

  /// The same file served as an attachment. Not used on the phone — nothing
  /// is written to its storage.
  final String? downloadUrl;

  factory IntakeAgreementPdf.fromJson(Map<String, dynamic> json) =>
      IntakeAgreementPdf(
        kind: Json.string(json['kind']),
        available: Json.booleanOr(json['available']),
        pdfUrl: Json.string(json['pdf_url']),
        downloadUrl: Json.string(json['download_url']),
      );

  static IntakeAgreementPdf? maybe(Object? source) =>
      source is Map ? IntakeAgreementPdf.fromJson(Json.map(source)) : null;

  bool get isDraft => kind == 'draft';

  /// Something to open: the server says so and gave an address for it.
  bool get canView => available && (pdfUrl ?? downloadUrl) != null;

  String? get viewUrl => pdfUrl ?? downloadUrl;
}

/// The signed original and the signing video, under `execution`.
class IntakeExecution {
  const IntakeExecution({
    this.signedScan = const <IntakeDocument>[],
    this.scanVersions = 0,
    this.video = const <IntakeDocument>[],
    this.videoRestricted = false,
  });

  /// The current signed scan's parts.
  final List<IntakeDocument> signedScan;

  /// Earlier versions in `signed_scan.history`.
  final int scanVersions;
  final List<IntakeDocument> video;

  /// True when the reader may not play the video; its urls are null.
  final bool videoRestricted;

  factory IntakeExecution.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> scan = Json.map(json['signed_scan']);
    final Map<String, dynamic> video = Json.map(json['execution_video']);
    return IntakeExecution(
      signedScan: _parts(scan['current'], 'Signed original'),
      scanVersions: Json.list(scan['history']).length,
      video: _parts(video['current'], 'Signing video'),
      videoRestricted: Json.booleanOr(video['restricted']),
    );
  }

  bool get isEmpty => signedScan.isEmpty && video.isEmpty;

  /// A file is either a list of parts or a single document.
  static List<IntakeDocument> _parts(Object? source, String fallback) {
    if (source is! Map) return const <IntakeDocument>[];
    final Map<String, dynamic> json = Json.map(source);
    final List<Map<String, dynamic>> parts = Json.list(json['parts']);
    final List<IntakeDocument> docs = parts.isEmpty
        ? <IntakeDocument>[IntakeDocument.fromJson(json)]
        : parts.map(IntakeDocument.fromJson).toList();
    return <IntakeDocument>[
      for (int i = 0; i < docs.length; i++)
        IntakeDocument(
          id: docs[i].id,
          mime: docs[i].mime,
          isPdf: docs[i].isPdf,
          filename: docs[i].filename,
          url: docs[i].url,
          label:
              docs[i].label ??
              (docs.length == 1 ? fallback : '$fallback · part ${i + 1}'),
        ),
    ];
  }
}

/// A value the API sends either as a string or as an object with a name.
String? intakeText(Object? source) {
  if (source is Map) {
    final Map<String, dynamic> json = Json.map(source);
    return Json.string(
      Json.pick(json, <String>['label', 'name', 'full_name', 'value', 'code']),
    );
  }
  return Json.string(source);
}

/// `{"rent": "1.00", "offer": {"months": 6}}` → `{rent: 1.00, offer.months: 6}`.
Map<String, String> flattenScalars(
  Map<String, dynamic> source, [
  String prefix = '',
]) {
  final Map<String, String> result = <String, String>{};
  source.forEach((String key, Object? value) {
    final String name = prefix.isEmpty ? key : '$prefix.$key';
    if (value is Map) {
      result.addAll(flattenScalars(Json.map(value), name));
    } else if (value is List) {
      final List<Map<String, dynamic>> rows = Json.list(value);
      for (int i = 0; i < rows.length; i++) {
        result.addAll(flattenScalars(rows[i], '$name.${i + 1}'));
      }
    } else {
      final String? text = Json.string(value);
      if (text != null) result[name] = text;
    }
  });
  return result;
}
