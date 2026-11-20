import 'dart:typed_data';

import 'package:get/get.dart';

import '../core/network/api_exception.dart';
import '../core/network/api_service.dart';
import '../core/utils/formatters.dart';
import '../core/utils/json_parse.dart';
import '../data/repositories/agreement_repository.dart';
import '../models/agreement_case.dart';
import '../models/intake_attachments.dart';
import '../models/intake_legacy.dart';
import '../models/mobile_access.dart';
import 'auth_controller.dart';

/// The faces of one case. A reviewer reads them one at a time.
enum AgreementCaseTab {
  // One word each: four chips share a phone's width.
  overview('Overview'),
  money('Money'),
  workflow('History'),
  preview('Preview');

  const AgreementCaseTab(this.label);

  final String label;
}

/// One case end to end: `GET allotment/intakes/{id}`, and its documents.
class AgreementCaseController extends GetxController {
  AgreementCaseController({
    required this.caseId,
    AgreementCase? row,
    AgreementRepository? agreementRepository,
    AuthController? authController,
  }) : file = Rxn<AgreementCase>(row),
       _agreements = agreementRepository ?? Get.find<AgreementRepository>(),
       _auth = authController ?? Get.find<AuthController>();

  final String caseId;
  final AgreementRepository _agreements;
  final AuthController _auth;

  /// The row tapped, then the detail once it lands. A row has no act options,
  /// so [isDetailLoaded] — not this — says whether acts can be drawn.
  final Rxn<AgreementCase> file;

  final Rx<AgreementCaseTab> tab = Rx<AgreementCaseTab>(
    AgreementCaseTab.overview,
  );

  final RxBool isLoading = RxBool(false);
  final RxBool isDetailLoaded = RxBool(false);
  final RxnString errorMessage = RxnString();

  /// 404: no such case, or not for this reader.
  final RxBool notAvailable = RxBool(false);

  /// 403: not this officer's to read — the view goes back to the list.
  final RxBool forbidden = RxBool(false);

  /// The url of the document being fetched, for its row's spinner.
  final RxnString openingUrl = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  bool get hasData => file.value != null;

  MobileAccess? get access => _auth.access.value;

  /// The signing video is the Administrator's; the CMO sees it listed only.
  bool get canPlayVideo =>
      access?.can(AgreementCapability.executionVideo) ?? false;

  bool get canSeeExecution =>
      access?.can(AgreementCapability.executionEvidence) ?? true;

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      file.value = await _agreements.caseDetail(caseId);
      isDetailLoaded.value = true;
      notAvailable.value = false;
      _refreshPdf(force: true);
    } on ApiException catch (error) {
      if (error.failure == ApiFailure.notFound) {
        notAvailable.value = true;
      } else if (error.failure == ApiFailure.forbidden) {
        forbidden.value = true;
      }
      errorMessage.value = explainIntakeFailure(error);
    } finally {
      isLoading.value = false;
    }
  }

  /// The case an act came back with — it is the whole updated case.
  void adopt(AgreementCase updated) {
    file.value = updated;
    isDetailLoaded.value = true;
    _refreshPdf();
  }

  void showTab(AgreementCaseTab value) {
    tab.value = value;
    if (value == AgreementCaseTab.preview) loadAgreementPdf();
  }

  /// The stamp paper PDF's bytes, fetched when Preview is first opened.
  final Rxn<Uint8List> agreementPdf = Rxn<Uint8List>();
  final RxBool isPdfLoading = RxBool(false);
  final RxnString pdfError = RxnString();

  /// The address [agreementPdf] came from; a new one means a new file.
  String? _pdfUrl;

  Future<void> loadAgreementPdf({bool force = false}) async {
    final String? url = file.value?.agreementPdf?.viewUrl;
    if (url == null || !(file.value!.agreementPdf!.canView)) return;
    if (isPdfLoading.value) return;
    if (!force && url == _pdfUrl && agreementPdf.value != null) return;
    isPdfLoading.value = true;
    pdfError.value = null;
    try {
      final ApiDownload download = await _agreements.document(url);
      agreementPdf.value = download.bytes;
      _pdfUrl = url;
    } on ApiException catch (error) {
      pdfError.value =
          error.failure == ApiFailure.notFound ||
              error.failure == ApiFailure.forbidden
          ? 'The agreement PDF is not available to you.'
          : error.message;
    } finally {
      isPdfLoading.value = false;
    }
  }

  /// After the case changes: drop a PDF the server no longer points at, and
  /// fetch the new one if Preview is the tab on screen. A pull-to-refresh
  /// [force]s it — a draft is re-rendered under the same address.
  void _refreshPdf({bool force = false}) {
    final String? url = file.value?.agreementPdf?.viewUrl;
    if (url != _pdfUrl) {
      agreementPdf.value = null;
      pdfError.value = null;
      _pdfUrl = null;
    }
    if (tab.value == AgreementCaseTab.preview) {
      loadAgreementPdf(force: force);
    }
  }

  /// The Attachments drawer on the screen's right edge.
  final RxBool attachmentsOpen = RxBool(false);

  void showAttachments(bool open) => attachmentsOpen.value = open;

  /// Whether the legacy card lists the fields that match, not just the count.
  final RxBool legacyMatchesOpen = RxBool(false);

  void showLegacyMatches(bool open) => legacyMatchesOpen.value = open;

  static final RegExp _witness = RegExp(
    r'wit(?:ness)?[\s_-]*(\d+)[\s_-]*',
    caseSensitive: false,
  );
  static final RegExp _applicant = RegExp(
    r'^(applicant|allottee)[\s_-]*',
    caseSensitive: false,
  );
  static final RegExp _supporting = RegExp(
    r'certificate|deed|noc|affidavit|licen[cs]e',
    caseSensitive: false,
  );

  /// The case's files by whose they are: the applicant, each witness, the
  /// supporting papers, then the agreement itself. Read off `media[].slot`.
  List<IntakeAttachmentGroup> attachmentGroups(AgreementCase file) {
    final List<IntakeDocument> applicant = <IntakeDocument>[];
    final List<IntakeDocument> supporting = <IntakeDocument>[];
    final Map<int, List<IntakeDocument>> witnesses =
        <int, List<IntakeDocument>>{
          for (final IntakeWitness w in file.witnesses)
            if (w.position != null) w.position!: <IntakeDocument>[],
        };

    for (final IntakeDocument doc in file.media) {
      final String key = doc.slot ?? doc.evidenceCode ?? '';
      final RegExpMatch? witness = _witness.firstMatch(key);
      if (witness != null) {
        final int at = int.parse(witness[1]!);
        (witnesses[at] ??= <IntakeDocument>[]).add(
          _relabel(doc, key.replaceFirst(_witness, '')),
        );
      } else if (_supporting.hasMatch(key)) {
        supporting.add(doc);
      } else {
        applicant.add(_relabel(doc, key.replaceFirst(_applicant, '')));
      }
    }

    final IntakeExecution? execution = file.execution;
    final IntakeAgreementPdf? stampPaper = file.agreementPdf;
    final List<IntakeDocument> agreement = <IntakeDocument>[
      if (stampPaper != null && stampPaper.canView)
        IntakeDocument(
          label: stampPaper.isDraft ? 'Stamp paper (draft)' : 'Stamp paper',
          isPdf: true,
          mime: 'application/pdf',
          url: stampPaper.viewUrl,
        ),
      ?file.numberedPdf,
      if (canSeeExecution) ...?execution?.signedScan,
      ...?execution?.video,
    ];
    final int earlier = canSeeExecution ? (execution?.scanVersions ?? 0) : 0;
    final String note = <String>[
      if (earlier > 0)
        '$earlier earlier signed ${earlier == 1 ? 'version' : 'versions'} '
            'on file.',
      if (execution?.video.isNotEmpty ?? false)
        execution!.videoRestricted || !canPlayVideo
            ? 'Only the Administrator may play the signing video.'
            : 'Videos are not played on the phone yet.',
    ].join(' ');

    final List<int> positions = witnesses.keys.toList()..sort();
    return <IntakeAttachmentGroup>[
      IntakeAttachmentGroup(
        owner: IntakeAttachmentOwner.applicant,
        title: 'Applicant',
        subtitle: file.applicant?.name,
        docs: applicant,
      ),
      for (final int at in positions)
        IntakeAttachmentGroup(
          owner: IntakeAttachmentOwner.witness,
          title: 'Witness $at',
          subtitle: file.witnesses
              .firstWhereOrNull((IntakeWitness w) => w.position == at)
              ?.name,
          docs: witnesses[at]!,
        ),
      if (supporting.isNotEmpty)
        IntakeAttachmentGroup(
          owner: IntakeAttachmentOwner.supporting,
          title: 'Supporting papers',
          docs: supporting,
        ),
      IntakeAttachmentGroup(
        owner: IntakeAttachmentOwner.agreement,
        title: 'Agreement',
        subtitle: 'Stamp paper, numbered copy, signed original',
        note: note.isEmpty ? null : note,
        docs: agreement,
      ),
    ];
  }

  /// The applicant and opening figures beside the shop's legacy register row.
  /// Empty when the shop has no row.
  static List<LegacyCheck> legacyChecks(AgreementCase file) {
    final IntakeLegacyEntry? entry = file.legacy?.entry;
    if (entry == null) return const <LegacyCheck>[];
    final IntakeApplicant? applicant = file.applicant;
    final Map<String, String> amounts = file.amounts;
    return <LegacyCheck?>[
      _check('Name', applicant?.name, entry.allotteeName, _letters),
      _check('Father', applicant?.fatherName, entry.fatherName, _letters),
      _check('CNIC', applicant?.cnic, entry.cnic, _digits, show: _cnic),
      _check('Mobile', applicant?.mobile, entry.mobileNo, _phone),
      _check(
        'Monthly rent',
        amounts['verified_monthly_rent'] ?? amounts['monthly_rent'],
        entry.monthlyRent,
        _amount,
        show: Formatters.moneyExact,
      ),
      _check(
        'Opening arrears',
        amounts['opening_arrears'],
        entry.openingArrears,
        _amount,
        show: Formatters.moneyExact,
      ),
      _check(
        'Arrears up to',
        amounts['opening_arrears_as_of'] ?? amounts['arrears_up_to'],
        entry.arrearsUpTo,
        _day,
        show: _date,
      ),
    ].whereType<LegacyCheck>().toList();
  }

  static LegacyCheck? _check(
    String label,
    String? onCase,
    String? inRegister,
    String Function(String) key, {
    String? Function(String?)? show,
  }) {
    if (onCase == null && inRegister == null) return null;
    final String? Function(String?) display = show ?? (String? v) => v;
    return LegacyCheck(
      label: label,
      caseValue: display(onCase),
      legacyValue: display(inRegister),
      match: onCase == null || inRegister == null
          ? LegacyMatch.unchecked
          : key(onCase) == key(inRegister)
          ? LegacyMatch.same
          : LegacyMatch.differs,
    );
  }

  // Spelling only: "Hayat ullah" and "Hayatullah" are one name.
  static String _letters(String v) =>
      v.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u0600-\u06ff]'), '');

  static String _digits(String v) => v.replaceAll(RegExp(r'\D'), '');

  /// +92 300… and 0300… are one number.
  static String _phone(String v) {
    final String d = _digits(v);
    return d.startsWith('92') && d.length == 12 ? '0${d.substring(2)}' : d;
  }

  /// "10248.70" and "10,248.7" are one amount — compared as text, not parsed.
  static String _amount(String v) {
    String t = v.replaceAll(RegExp(r'[^\d.\-]'), '');
    if (t.contains('.')) t = t.replaceFirst(RegExp(r'\.?0+$'), '');
    return t.replaceFirstMapped(RegExp(r'^(-?)0+(?=\d)'), (Match m) => m[1]!);
  }

  static String _day(String v) {
    final DateTime? at = DateTime.tryParse(v.trim());
    return at == null ? v.trim() : Json.dateOnly(at)!;
  }

  static String? _date(String? v) {
    final DateTime? at = v == null ? null : DateTime.tryParse(v.trim());
    return at == null ? v : Formatters.date(at);
  }

  /// 13 digits read as 54400-1889638-7, as on the card.
  static String? _cnic(String? v) {
    if (v == null) return null;
    final String d = _digits(v);
    return d.length == 13
        ? '${d.substring(0, 5)}-${d.substring(5, 12)}-${d.substring(12)}'
        : v;
  }

  /// "witness_1_cnic_front" files under Witness 1 as "CNIC front".
  static IntakeDocument _relabel(IntakeDocument doc, String rest) =>
      doc.label != null || rest.isEmpty
      ? doc
      : doc.withLabel(IntakeDocument.humanise(rest));

  /// A document's bytes, or the sentence saying why not. Kept apart from
  /// [errorMessage], which is about the case itself.
  Future<({ApiDownload? download, String? error})> openDocument(
    IntakeDocument document,
  ) async {
    final String? url = document.url;
    if (url == null || openingUrl.value != null) {
      return (download: null, error: null);
    }
    openingUrl.value = url;
    try {
      return (download: await _agreements.document(url), error: null);
    } on ApiException catch (error) {
      final bool closed =
          error.failure == ApiFailure.notFound ||
          error.failure == ApiFailure.forbidden;
      return (
        download: null,
        error: closed
            ? 'This document is not available to you.'
            : error.message,
      );
    } finally {
      openingUrl.value = null;
    }
  }
}

/// The reviewer's sentence for a refusal, by the codes the server publishes.
String explainIntakeFailure(ApiException error) {
  switch (error.code) {
    case 'intake.changed_since_viewed':
      return 'Someone acted on this case first. It has been reloaded — '
          'check what changed and decide again.';
    case 'intake.wrong_stage':
    case 'intake.no_query':
      return 'This case has moved on since you opened it. It has been '
          'reloaded.';
    case 'intake.endorsement_not_valid':
      return 'Estate changed this case after it was endorsed, so the '
          'endorsement no longer counts. Return it to Estate.';
    case 'intake.location_changed':
    case 'intake.location_unverified':
      return 'The shop’s market, area or zone changed since it was reviewed. '
          'Return the case to Estate.';
    case 'intake.no_signature':
      return 'You have no signature on file. Add one on the web: Profile → '
          'My signature.';
    case 'intake.return_destination':
      return 'It cannot be sent there from this stage.';
    case 'intake.client_uuid_reused':
      return 'That request was already used for a different act. Please try '
          'again.';
    case 'intake.acted_at_earlier_stage':
      return 'You acted on this case at an earlier stage, so another officer '
          'has to take this step.';
    case 'intake.own_case':
      return 'This case is your own, so another officer has to take this step.';
    case 'password_change_required':
      return 'Your password must be changed before you can carry on.';
    case 'database_error':
      final String? ref = error.reference;
      return ref == null
          ? error.message
          : 'The server could not complete this. Quote reference $ref to MCQ IT.';
  }
  return switch (error.failure) {
    ApiFailure.forbidden => 'This is not yours to act on.',
    ApiFailure.notFound => 'This case is not available.',
    _ when error.statusCode == 429 =>
      'Too many requests. Wait a minute and try again.',
    _ => error.message,
  };
}
