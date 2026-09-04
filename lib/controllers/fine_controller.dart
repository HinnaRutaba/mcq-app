import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/capture/photo_capture.dart';
import '../core/network/api_exception.dart';
import '../data/repositories/evidence_repository.dart';
import '../data/repositories/fine_repository.dart';
import '../data/repositories/person_repository.dart';
import '../data/repositories/reporting_repository.dart';
import '../models/api_refs.dart';
import '../models/enforcement_definitions.dart';
import '../models/field_beat.dart';
import '../models/fine.dart';
import '../models/fine_request.dart';
import '../models/person_lookup.dart';
import '../models/property_profile.dart';
import '../models/unit_card.dart';
import 'dashboard_controller.dart';
import 'definitions_controller.dart';
import 'person_lookup_controller.dart';

/// What came of pressing "Impose a fine".
enum ImposeOutcome {
  /// Posted. [FineController.imposed] holds the fine, its challan and its
  /// payment link.
  success,

  /// The form itself was not valid; the fields already say why.
  invalidForm,

  /// The server refused it. See [FineController.errorMessage] and the field
  /// validators.
  failed,
}

/// Imposing a fine: the form, the evidence attached to it, and the one call
/// that posts the lot.
///
/// Three rules this controller exists to hold in one place:
///
/// * **The request is built once.** [_pending] keeps the [FineRequest] that was
///   sent, so a retry after a dead signal re-sends the same `client_action_uuid`
///   and the server recognises it as the same fine arriving twice rather than a
///   second one. Editing any field throws it away, because that is a different
///   fine.
/// * **Evidence is uploaded before the write.** The photograph and the
///   signature go up through [EvidenceRepository] and only their returned paths
///   travel on the fine — so the image goes over a area's uplink once, and the
///   fine behind it can be retried as many times as it takes.
/// * **The amount is a string from end to end.** It is typed as a string, held
///   as a string and sent as a string. Nothing here parses it into a number.
class FineController extends GetxController {
  FineController({
    this.unit,
    this.propertyId,
    FineRepository? fineRepository,
    EvidenceRepository? evidenceRepository,
    ReportingRepository? reportingRepository,
    PersonRepository? personRepository,
    DefinitionsController? definitionsController,
    DashboardController? dashboardController,
    PhotoCapture? photoCapture,
  }) : _fines = fineRepository ?? Get.find<FineRepository>(),
       _reportingOverride = reportingRepository,
       _personOverride = personRepository,
       _evidence = evidenceRepository ?? Get.find<EvidenceRepository>(),
       _definitions =
           definitionsController ?? Get.find<DefinitionsController>(),
       _dashboardOverride = dashboardController,
       _photos = photoCapture ?? PhotoCapture();

  /// The unit being fined, when the officer arrived from its profile. Null when
  /// they came from the "new fine" button with no shop in mind, in which case
  /// they pick one first.
  final UnitCard? unit;

  /// The unit's id, for the case where only the id was carried on the route.
  final int? propertyId;

  final FineRepository _fines;
  final EvidenceRepository _evidence;
  final ReportingRepository? _reportingOverride;

  /// Only for the profile behind a route that carried an id and nothing else.
  /// Resolved on first use, because a fine on a shop the officer picked here
  /// already has everything it needs.
  late final ReportingRepository _reporting =
      _reportingOverride ?? Get.find<ReportingRepository>();

  final PersonRepository? _personOverride;

  /// The CNIC search behind the payer block, and the field it owns. Built on
  /// first use, because a fine on a shop is usually written without one.
  late final PersonLookupController personLookup = PersonLookupController(
    personRepository: _personOverride,
  );

  /// The offences a fine may be raised for, with the amount and provision the
  /// register suggests for each. Rows MCQ can edit, so they are read here and
  /// never carried as a copy.
  final DefinitionsController _definitions;

  final DashboardController? _dashboardOverride;

  /// The officer's beat, which is where the areas come from —
  /// `enforcement/field/beat`, held by the controller the home screen already
  /// built. Resolved on first use, so a fine against a shop, which takes its
  /// area off the unit, never asks for it.
  late final DashboardController _dashboard =
      _dashboardOverride ?? Get.find<DashboardController>();

  final PhotoCapture _photos;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // --- Which shop, or which area --------------------------------------

  /// The area the officer picked. On a unit fine it is usually left null and
  /// the unit's own area is used — see [targetAreaId].
  final RxnInt areaId = RxnInt();

  /// The search over the areas on the register, and the id typed by hand
  /// when the register lists none at all. `area_id` is required on every fine,
  /// so there has to be a way to name one even then.
  final TextEditingController areaSearchController = TextEditingController();
  final RxString areaQuery = ''.obs;
  final TextEditingController areaIdController = TextEditingController();

  /// The unit's own record, fetched when the route carried an id and no card.
  /// It is what the shop's details and the allottee's are drawn from.
  final Rxn<PropertyProfile> profile = Rxn<PropertyProfile>();
  final RxBool isLoadingProfile = false.obs;
  final RxnString profileError = RxnString();

  // --- The offence ------------------------------------------------------
  final Rxn<FineTypeDefinition> fineType = Rxn<FineTypeDefinition>();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController provisionController = TextEditingController();

  // --- Who pays ---------------------------------------------------------
  final TextEditingController offenderNameController = TextEditingController();
  final TextEditingController offenderFatherController =
      TextEditingController();
  final TextEditingController offenderMobileController =
      TextEditingController();

  /// The CNIC, held by the search that owns the field.
  TextEditingController get offenderCnicController =>
      personLookup.cnicController;

  // Optional, and where nobody is on the register they are the only way back
  // to the person: there is no unit to find them at.

  // --- The evidence -----------------------------------------------------
  final RxnString photoLocalPath = RxnString();
  final RxnString photoUploadedPath = RxnString();
  final RxBool isUploadingPhoto = false.obs;

  // --- Submission -------------------------------------------------------
  final RxBool isSubmitting = false.obs;
  final RxnString errorMessage = RxnString();
  final Rxn<Fine> imposed = Rxn<Fine>();

  /// The request that was sent, kept for a retry so the idempotency key
  /// survives it. Cleared whenever the officer edits the fine.
  FineRequest? _pending;

  /// The last amount and provision put in the fields by [chooseFineType], so a
  /// figure the officer typed themselves is never quietly replaced.
  String? _suggestedAmount;
  String? _suggestedProvision;

  /// The same for the payer block, filled in from the allottee.
  String? _suggestedName;
  String? _suggestedFather;
  String? _suggestedMobile;
  String? _suggestedCnic;

  String? _amountServerError;
  String? _provisionServerError;
  String? _fineTypeServerError;
  String? _offenderNameServerError;
  String? _offenderFatherServerError;
  String? _offenderMobileServerError;
  String? _offenderCnicServerError;
  String? _areaServerError;

  @override
  void onInit() {
    super.onInit();
    if (unit != null) {
      _prefillPayer();
    } else if (propertyId != null) {
      // The route carried an id and nothing else, so the shop's details and
      // the person to bill have to be fetched before either can be shown.
      loadProfile();
    }
    // A form opened after a sign-in on a dead signal has no offences to offer;
    // this is what fetches them.
    _definitions.ensureLoaded();
    // The areas come off the beat. Touching the controller builds it when
    // the officer went straight here without the home screen, and its load is
    // what the sole-area case waits on.
    _pickSoleArea();
    if (isAreaFine && areas.isEmpty && !_dashboard.isLoading.value) {
      _dashboard.load().then((_) => _pickSoleArea());
    }
  }

  @override
  void onClose() {
    amountController.dispose();
    provisionController.dispose();
    offenderNameController.dispose();
    offenderFatherController.dispose();
    offenderMobileController.dispose();
    areaSearchController.dispose();
    areaIdController.dispose();
    personLookup.onClose();
    super.onClose();
  }

  /// The unit the fine will be posted against, whichever way the officer got
  /// here.
  int? get targetPropertyId => unit?.propertyId ?? propertyId;

  /// Whether this fine is against a area rather than a unit — decided by how
  /// the officer got here, not by a switch on the form. Arriving from a shop's
  /// screen fines that shop; arriving from the fine button fines a person in a
  /// area.
  bool get isAreaFine => targetPropertyId == null;

  /// Whether the fine has to name a person. Always on an area fine — there is
  /// no tenancy to bill. Otherwise the server's own answer, read and never
  /// worked out from whether the unit looks vacant.
  bool get needsOffenderDetails =>
      isAreaFine || (unit?.needsOffenderDetails ?? false);

  /// The picker's entries. Ids, with [areaLabel] naming them, so the dropdown
  /// holds the value the request carries.
  List<int> get areaOptions => <int>[
    for (final FieldArea area in areas)
      if (area.id != null) area.id!,
  ];

  String areaLabel(int id) {
    for (final FieldArea area in areas) {
      if (area.id == id) return area.areaName;
    }
    return 'Area $id';
  }

  /// The offences on the register, in its own order and with its own wording.
  /// Read inside an `Obx` builder — these follow the definitions controller.
  List<FineTypeDefinition> get fineTypes => _definitions.fineTypes;

  bool get isLoadingOffences => _definitions.isLoading.value;

  String? get offencesError => _definitions.errorMessage.value;

  /// The retry behind an offence picker that came up empty.
  Future<void> reloadOffences() => _definitions.reload();

  /// The areas the officer is posted to, off the beat the home screen
  /// fetched. `FieldArea.id` is what travels as `area_id`.
  List<FieldArea> get areas =>
      _dashboard.beat.value?.scope.areas ?? const <FieldArea>[];

  bool get isLoadingAreas => _dashboard.isLoading.value;

  String? get areasError => _dashboard.errorMessage.value;

  /// The retry behind a area picker that came up empty. It re-fetches the
  /// beat, which is the officer's own postings.
  Future<void> reloadAreas() => _dashboard.load();

  /// The shop this fine is against, whichever way the officer got here — the
  /// card they arrived with, the one they searched for, or the profile fetched
  /// behind a route that carried only an id.
  ProfileProperty? get property => profile.value?.property;

  /// Who the register says holds it. Null on a vacant unit, and on a unit card
  /// that named nobody.
  String? get allotteeName =>
      unit?.allotteeName ?? profile.value?.allottee?.fullName;

  /// Whether there is anything to draw a shop card from yet.
  bool get hasUnitDetails => unit != null || property != null;

  // --- The shop card, from whichever of the two records is in hand --------

  String get unitTitle {
    final UnitCard? card = unit;
    final String? shopNo = card?.shopNo ?? property?.shopNo;
    final String? market = card?.marketName ?? property?.marketName;
    final parts = <String>[?shopNo, ?market];
    if (parts.isNotEmpty) return parts.join(' · ');
    return card?.propertyCode ??
        property?.propertyCode ??
        'The unit you opened';
  }

  String? get unitCode => unit?.propertyCode ?? property?.propertyCode;

  String? get unitArea => unit?.areaName ?? property?.areaName;

  /// Ready to print, and only the profile carries it.
  String? get unitAddress => property?.streetAddress;

  /// Rent arrears on the unit, as a string. A fine is a separate debt from
  /// this — it is here so the officer sees what else is owed, never added to
  /// the fine.
  String? get unitOutstanding =>
      unit?.outstanding ?? profile.value?.position.totalOutstanding;

  bool get unitIsSealed =>
      unit?.isSealed ?? profile.value?.enforcement.isSealed ?? false;

  bool get unitIsVacant =>
      unit?.isVacant ?? (property?.occupancyStatus == 'vacant');

  String? get allotteeMobile =>
      unit?.mobileNo ?? profile.value?.allottee?.mobileNo;

  String? get allotteeCnic => unit?.cnic ?? profile.value?.allottee?.cnic;

  /// The area the fine will name — required on every fine.
  ///
  /// A unit carries its own, so the form does not ask; anything the officer
  /// picked wins, which is what lets them name one when the unit's record has
  /// no area on it.
  int? get targetAreaId {
    final int? chosen = areaId.value;
    if (chosen != null) return chosen;
    if (isAreaFine) return null;
    final int? fromUnit = unit?.areaId ?? property?.areaId;
    if (fromUnit != null) return fromUnit;
    // A server that labels the area without naming its id: match the label
    // against the register rather than send nothing.
    final String? name = unit?.areaName ?? property?.areaName;
    if (name == null) return null;
    for (final FieldArea area in areas) {
      if (area.areaName == name) return area.id;
    }
    return null;
  }

  /// The chosen area's name, for the header. Null until one is chosen.
  String? get areaName {
    final int? id = targetAreaId;
    return id == null ? null : areaLabel(id);
  }

  /// What the register suggests this offence is worth, so the amount field can
  /// say where its figure came from.
  String? get suggestedAmount => fineType.value?.suggestedAmount;

  /// Whether every required field is filled. Drives the submit button, so the
  /// officer can see the form is not ready before they reach the bottom of it.
  bool get isComplete =>
      targetAreaId != null &&
      (isAreaFine || targetPropertyId != null) &&
      fineType.value != null &&
      amountController.text.trim().isNotEmpty &&
      provisionController.text.trim().isNotEmpty &&
      (!needsOffenderDetails ||
          (offenderNameController.text.trim().isNotEmpty &&
              offenderFatherController.text.trim().isNotEmpty &&
              offenderMobileController.text.trim().isNotEmpty &&
              offenderCnicController.text.trim().isNotEmpty));

  /// Whether every field the server insists on passes its own validator.
  ///
  /// Separate from [isComplete], which only asks whether the fields have
  /// something in them: this one is the full set of rules, and it is what
  /// decides whether a fine is sent.
  bool get isValid =>
      validateArea(targetAreaId) == null &&
      (isAreaFine || targetPropertyId != null) &&
      validateFineType(fineType.value) == null &&
      validateAmount(amountController.text) == null &&
      validateProvision(provisionController.text) == null &&
      validateOffenderName(offenderNameController.text) == null &&
      validateOffenderFather(offenderFatherController.text) == null &&
      validateOffenderMobile(offenderMobileController.text) == null &&
      validateOffenderCnic(offenderCnicController.text) == null;

  /// What is still missing, in the order the form asks for it. Shown beside the
  /// disabled button — a button that will not press and will not say why is the
  /// thing officers give up on.
  /// The person the fine names, or null when the block is not complete enough
  /// to send. Name, father's name and mobile go together or not at all.
  FineOffender? get payer {
    final FineOffender offender = _offender();
    return offender.isComplete ? offender : null;
  }

  List<String> get missing => <String>[
    if (targetAreaId == null) 'the area',
    if (!isAreaFine && targetPropertyId == null) 'the shop',
    if (fineType.value == null) 'the offence',
    if (amountController.text.trim().isEmpty) 'the amount',
    if (provisionController.text.trim().isEmpty) 'the provision of law',
    if (needsOffenderDetails && offenderNameController.text.trim().isEmpty)
      "the offender's name",
    if (needsOffenderDetails && offenderFatherController.text.trim().isEmpty)
      "their father's name",
    if (needsOffenderDetails && offenderMobileController.text.trim().isEmpty)
      'their mobile number',
    if (needsOffenderDetails && offenderCnicController.text.trim().isEmpty)
      'their CNIC',
  ];

  /// Bumped by [markEdited]. The completeness of the form is worked out from
  /// `TextEditingController.text`, which is not observable, so the submit bar
  /// watches this instead and re-reads them.
  final RxInt revision = 0.obs;

  /// Any edit makes this a different fine, so the request built for the last
  /// attempt — and the uuid on it — is no longer the right one to resend.
  void markEdited() {
    _pending = null;
    revision.value++;
  }

  // --- Which shop, or which area --------------------------------------

  /// One area on the register is not a choice worth asking about.
  void _pickSoleArea() {
    if (!isAreaFine || areaId.value != null) return;
    if (areaOptions.length == 1) areaId.value = areaOptions.first;
  }

  /// The areas matching [term], by name or by code. An empty term offers the
  /// whole beat, which is what a freshly opened suggestion box shows.
  List<FieldArea> areaMatchesFor(String term) {
    final String needle = term.trim().toLowerCase();
    final Iterable<FieldArea> named = areas.where(
      (FieldArea area) => area.id != null,
    );
    if (needle.isEmpty) return named.toList();
    return named
        .where(
          (FieldArea area) =>
              area.areaName.toLowerCase().contains(needle) ||
              (area.areaCode?.toLowerCase().contains(needle) ?? false),
        )
        .toList();
  }

  /// The matches for what is in the search box now.
  List<FieldArea> get areaMatches => areaMatchesFor(areaQuery.value);

  void searchArea(String term) => areaQuery.value = term;

  void setArea(int? id) {
    if (id == null || id == areaId.value) return;
    areaId.value = id;
    areaSearchController.clear();
    areaQuery.value = '';
    markEdited();
  }

  void clearArea() {
    areaId.value = null;
    markEdited();
  }

  /// The id typed by hand, for a handset whose register listed no areas at
  /// all. The fine cannot be sent without one.
  void setAreaFromText(String value) {
    areaId.value = int.tryParse(value.trim());
    markEdited();
  }

  /// The chosen area, when it is one the register named.
  FieldArea? get chosenArea {
    final int? id = targetAreaId;
    if (id == null) return null;
    for (final FieldArea area in areas) {
      if (area.id == id) return area;
    }
    return null;
  }

  /// The unit behind a route that carried only its id: its details for the
  /// card, its area for `area_id`, and its allottee for the payer block.
  /// Safe to call again — this is the retry behind a failed load.
  Future<void> loadProfile() async {
    final int? id = propertyId;
    if (id == null) return;
    isLoadingProfile.value = true;
    profileError.value = null;
    try {
      profile.value = await _reporting.propertyProfile(id);
      _prefillPayer();
    } on ApiException catch (error) {
      profileError.value = error.message;
    } finally {
      isLoadingProfile.value = false;
    }
  }

  /// Fills the payer block in from whoever the register says holds the unit.
  /// Nothing the officer typed is replaced — the person in front of them may
  /// not be the person on the register, and their correction stands.
  void _prefillPayer() {
    // An area fine has no register behind it, so there is nobody to fill it in
    // from and the block stays empty.
    final UnitCard? card = unit;
    final AllotteeRef? allottee = profile.value?.allottee;

    final String? name = card?.allotteeName ?? allottee?.fullName;
    final String? mobile = card?.mobileNo ?? allottee?.mobileNo;
    final String? cnic = card?.cnic ?? allottee?.cnic;

    _prefill(offenderNameController, name, _suggestedName);
    _prefill(offenderFatherController, allottee?.fatherName, _suggestedFather);
    _prefill(offenderMobileController, mobile, _suggestedMobile);
    _prefill(offenderCnicController, cnic, _suggestedCnic);

    _suggestedName = name;
    _suggestedFather = allottee?.fatherName;
    _suggestedMobile = mobile;
    _suggestedCnic = cnic;
    markEdited();
  }

  // --- The offence ------------------------------------------------------

  /// The offence, and with it the amount and the section of law the register
  /// suggests for it.
  ///
  /// Both are only prefilled while the officer has not typed over them: a
  /// figure they entered themselves is never quietly replaced, and `other`
  /// carries no provision at all, which is why the form still asks for one.
  void chooseFineType(FineTypeDefinition? chosen) {
    fineType.value = chosen;
    if (chosen != null) {
      _prefill(amountController, chosen.suggestedAmount, _suggestedAmount);
      _prefill(
        provisionController,
        chosen.defaultProvision,
        _suggestedProvision,
      );
      _suggestedAmount = chosen.suggestedAmount;
      _suggestedProvision = chosen.defaultProvision;
    }
    markEdited();
  }

  static void _prefill(
    TextEditingController field,
    String? suggestion,
    String? previous,
  ) {
    final String current = field.text.trim();
    // Anything the officer put there themselves stays.
    if (current.isNotEmpty && current != previous) return;
    field.text = suggestion ?? '';
  }

  // --- Who pays ---------------------------------------------------------

  /// Fills the payer block in from a CNIC the officer looked up and took.
  ///
  /// Straight over whatever was there: they tapped a card with a name on it,
  /// and the block has to say what they were shown.
  void takePerson(PersonSuggestion suggestion, PersonLookup found) {
    offenderNameController.text = suggestion.name;
    offenderFatherController.text = suggestion.fatherName ?? '';
    offenderMobileController.text = suggestion.mobileNo ?? '';
    // What was taken is what the register suggested, so a later prefill from a
    // shop does not mistake it for the officer's own typing.
    _suggestedName = suggestion.name;
    _suggestedFather = suggestion.fatherName;
    _suggestedMobile = suggestion.mobileNo;
    markEdited();
  }

  // --- The evidence -----------------------------------------------------

  /// Takes the photograph and puts it up straight away, so the officer learns
  /// the upload failed while they are still standing there rather than at the
  /// moment they press submit.
  Future<PhotoOutcome> attachPhoto({bool fromGallery = false}) async {
    final result = fromGallery
        ? await _photos.fromGallery()
        : await _photos.fromCamera();
    if (result.outcome != PhotoOutcome.taken) return result.outcome;

    photoLocalPath.value = result.path;
    photoUploadedPath.value = null;
    markEdited();
    await _uploadPhoto();
    return PhotoOutcome.taken;
  }

  Future<void> _uploadPhoto() async {
    final path = photoLocalPath.value;
    if (path == null) return;
    isUploadingPhoto.value = true;
    try {
      final upload = await _evidence.upload(
        filePath: path,
        kind: EvidenceRepository.kindPhoto,
      );
      photoUploadedPath.value = upload.path;
    } on ApiException catch (error) {
      // The picture stays on the handset and the button offers a retry. The
      // fine is not blocked by it — a photograph that will not go up is not a
      // reason to let a shopkeeper walk away unfined.
      errorMessage.value = error.message;
    } finally {
      isUploadingPhoto.value = false;
    }
  }

  Future<void> retryPhotoUpload() => _uploadPhoto();

  void removePhoto() {
    photoLocalPath.value = null;
    photoUploadedPath.value = null;
    markEdited();
  }

  // --- Validators -------------------------------------------------------

  String? validateAmount(String? value) {
    if (_amountServerError != null) return _amountServerError;
    final amount = value?.trim() ?? '';
    if (amount.isEmpty) return 'A fine amount is required';
    // Shape only. The figure itself is never parsed into a number here — it is
    // sent as typed and the server decides what it is worth.
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(amount)) {
      return 'Enter an amount like 4500 or 4500.00';
    }
    if (RegExp(r'^0+(\.0{1,2})?$').hasMatch(amount)) {
      return 'The amount must be at least 1';
    }
    return null;
  }

  String? validateProvision(String? value) {
    if (_provisionServerError != null) return _provisionServerError;
    final provision = value?.trim() ?? '';
    if (provision.isEmpty) {
      // Not a formality: this is the sentence a magistrate reads out if the
      // fine is challenged.
      return 'Name the section of law. A fine without one cannot be enforced.';
    }
    if (provision.length > FineRequest.legalProvisionMaxLength) {
      return 'Keep it under ${FineRequest.legalProvisionMaxLength} characters';
    }
    return null;
  }

  String? validateArea(int? value) {
    if (_areaServerError != null) return _areaServerError;
    // `area_id` is required whatever the fine is against; a unit answers it
    // without asking, and this is what catches the unit whose record cannot.
    if (targetAreaId == null) return 'Name the area the fine was issued in';
    return null;
  }

  String? validateFineType(FineTypeDefinition? value) {
    if (_fineTypeServerError != null) return _fineTypeServerError;
    if (value == null) return 'Choose what the offence was';
    // `fine_type_id` is the whole of what the server is told about the
    // offence, so a row that arrived without one cannot be sent.
    if (value.id == null) return 'This offence cannot be used — reload the app';
    return null;
  }

  String? validateOffenderName(String? value) {
    if (_offenderNameServerError != null) return _offenderNameServerError;
    if (!needsOffenderDetails) return null;
    if ((value?.trim() ?? '').isEmpty) return "The offender's name is required";
    return null;
  }

  String? validateOffenderFather(String? value) {
    if (_offenderFatherServerError != null) return _offenderFatherServerError;
    if (!needsOffenderDetails) return null;
    if ((value?.trim() ?? '').isEmpty) return "Their father's name is required";
    return null;
  }

  String? validateOffenderMobile(String? value) {
    if (_offenderMobileServerError != null) return _offenderMobileServerError;
    if (!needsOffenderDetails) return null;
    if ((value?.trim() ?? '').isEmpty) return 'A mobile number is required';
    return null;
  }

  /// Asked for wherever the officer has to name the person themselves. The
  /// server does not insist on it — it is how the fine is traced back to
  /// somebody with no unit and no tenancy on record.
  String? validateOffenderCnic(String? value) {
    if (_offenderCnicServerError != null) return _offenderCnicServerError;
    if (!needsOffenderDetails) return null;
    if ((value?.trim() ?? '').isEmpty) return 'A CNIC is required';
    return null;
  }

  // --- Submission -------------------------------------------------------

  Future<ImposeOutcome> impose() async {
    _clearServerErrors();
    errorMessage.value = null;

    final propertyId = targetPropertyId;
    if (!isAreaFine && propertyId == null) {
      errorMessage.value = 'Choose the shop this fine is against.';
      return ImposeOutcome.invalidForm;
    }
    if (isAreaFine && areaId.value == null) {
      errorMessage.value = 'Choose the area this fine was issued in.';
      return ImposeOutcome.invalidForm;
    }
    // The Form is asked to paint the messages; whether the fine may be sent is
    // decided here. The rules belong to the controller, not to whether a
    // widget happens to be mounted.
    formKey.currentState?.validate();
    if (!isValid) return ImposeOutcome.invalidForm;

    // Built once and kept. A second press after a timeout re-sends this same
    // object, uuid and all, and the server treats it as the same fine.
    final request = _pending ??= _buildRequest();

    isSubmitting.value = true;
    try {
      // Two endpoints behind one form: an area fine has no unit to be posted
      // against, and the area is the only scoping it carries.
      imposed.value = isAreaFine
          ? await _fines.imposeInArea(request: request)
          : await _fines.impose(propertyId: propertyId!, request: request);
      _pending = null;
      return ImposeOutcome.success;
    } on ApiException catch (error) {
      _applyFailure(error);
      formKey.currentState?.validate();
      return ImposeOutcome.failed;
    } finally {
      isSubmitting.value = false;
    }
  }

  FineRequest _buildRequest() =>
      isAreaFine ? _buildAreaRequest() : _buildUnitRequest();

  FineRequest _buildUnitRequest() => FineRequest(
    // Off the unit, so a fine against a shop still says which area it stands
    // in without asking the officer for it.
    areaId: targetAreaId,
    fineTypeId: fineType.value!.id!,
    fineAmount: amountController.text.trim(),
    legalProvision: provisionController.text.trim(),
    offender: payer,
    // The uploaded path, never the handset's own — the server has no idea what
    // `/data/user/0/…` means.
    photoPath: photoUploadedPath.value,
  );

  /// `POST enforcement/fines`: the area is the only scoping, and the offender
  /// is required because there is nobody on the register to bill.
  FineRequest _buildAreaRequest() => FineRequest.inArea(
    areaId: areaId.value!,
    offender: _offender(),
    fineTypeId: fineType.value!.id!,
    fineAmount: amountController.text.trim(),
    legalProvision: provisionController.text.trim(),
    photoPath: photoUploadedPath.value,
  );

  FineOffender _offender() => FineOffender(
    name: offenderNameController.text.trim(),
    fatherName: offenderFatherController.text.trim(),
    mobileNo: offenderMobileController.text.trim(),
    cnic: _trimmedOrNull(offenderCnicController.text),
  );

  static String? _trimmedOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _applyFailure(ApiException error) {
    errorMessage.value = error.message;
    if (!error.isValidation) return;

    _areaServerError = error.errorFor('area_id');
    _fineTypeServerError = error.errorFor('fine_type');
    _amountServerError = error.errorFor('fine_amount');
    _provisionServerError = error.errorFor('legal_provision');
    _offenderNameServerError = error.errorFor('offender_name');
    _offenderFatherServerError = error.errorFor('offender_father_name');
    _offenderMobileServerError = error.errorFor('offender_mobile_no');
    _offenderCnicServerError = error.errorFor('offender_cnic');
  }

  void _clearServerErrors() {
    _areaServerError = null;
    _fineTypeServerError = null;
    _amountServerError = null;
    _provisionServerError = null;
    _offenderNameServerError = null;
    _offenderFatherServerError = null;
    _offenderMobileServerError = null;
    _offenderCnicServerError = null;
  }
}
