import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/network/api_exception.dart';
import '../data/repositories/enforcement_case_repository.dart';
import '../data/repositories/person_repository.dart';
import '../data/repositories/reporting_repository.dart';
import '../models/api_refs.dart';
import '../models/case_type_option.dart';
import '../models/enforcement_case.dart';
import '../models/field_case_request.dart';
import '../models/fine_request.dart';
import '../models/person_lookup.dart';
import '../models/property_profile.dart';
import '../models/unit_card.dart';
import 'definitions_controller.dart';
import 'person_lookup_controller.dart';

/// What came of pressing "Open the case".
enum OpenCaseOutcome {
  /// Opened. [CaseController.opened] holds the file the server created.
  success,

  /// The form itself was not valid; the fields already say why.
  invalidForm,

  /// The server refused it. See [CaseController.errorMessage] and the field
  /// validators.
  failed,
}

/// Opening a case on a shop: `POST enforcement/field/cases`.
///
/// A **conduct** case, always — it names the unit and what is happening at it.
/// A recovery case is opened against a tenancy off the ledger, which is the
/// taxation branch's call and not a form an officer fills in at a shopfront.
class CaseController extends GetxController {
  CaseController({
    this.unit,
    this.propertyId,
    EnforcementCaseRepository? caseRepository,
    ReportingRepository? reportingRepository,
    PersonRepository? personRepository,
    DefinitionsController? definitionsController,
  }) : _cases = caseRepository ?? Get.find<EnforcementCaseRepository>(),
       _reportingOverride = reportingRepository,
       _personOverride = personRepository,
       _definitions =
           definitionsController ?? Get.find<DefinitionsController>();

  /// The shop, when the officer came from its profile with the card in hand.
  final UnitCard? unit;

  /// Its id, when only that was carried on the route.
  final int? propertyId;

  final EnforcementCaseRepository _cases;

  final ReportingRepository? _reportingOverride;

  /// Only for the profile behind a route that carried an id and nothing else.
  late final ReportingRepository _reporting =
      _reportingOverride ?? Get.find<ReportingRepository>();

  final PersonRepository? _personOverride;

  /// The CNIC search behind the person block, and the field it owns.
  late final PersonLookupController personLookup = PersonLookupController(
    personRepository: _personOverride,
  );

  /// Where the priorities come from. Rows MCQ can edit, so they are read here
  /// and never carried as a copy.
  final DefinitionsController _definitions;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // --- The shop ---------------------------------------------------------

  /// The unit's own record, fetched when the route carried an id and no card.
  final Rxn<PropertyProfile> profile = Rxn<PropertyProfile>();
  final RxBool isLoadingProfile = false.obs;
  final RxnString profileError = RxnString();

  // --- What the case is about -------------------------------------------
  final RxList<CaseTypeOption> caseTypes = RxList<CaseTypeOption>();
  final RxBool isLoadingCaseTypes = false.obs;
  final RxnString caseTypesError = RxnString();
  final Rxn<CaseTypeOption> caseType = Rxn<CaseTypeOption>();

  /// Why the case is being opened, in the officer's own words. It is the
  /// substance of the file a clerk reads later, so the form insists on it.
  final TextEditingController reasonController = TextEditingController();

  // --- Who it is against --------------------------------------------------

  /// Name, father's name and mobile go together — the server refuses a case
  /// naming one without the others, because a file nobody is named on cannot
  /// have a notice served on it.
  final TextEditingController offenderNameController = TextEditingController();
  final TextEditingController offenderFatherController =
      TextEditingController();
  final TextEditingController offenderMobileController =
      TextEditingController();

  /// The CNIC, held by the search that owns the field.
  TextEditingController get offenderCnicController =>
      personLookup.cnicController;

  /// The last values put in the block by [_prefillOffender], so anything the
  /// officer typed themselves is never quietly replaced.
  String? _suggestedName;
  String? _suggestedFather;
  String? _suggestedMobile;
  String? _suggestedCnic;

  // --- How urgent -------------------------------------------------------

  /// Optional: left unset, the server opens the case at its own priority.
  final Rxn<LabelledValue> priority = Rxn<LabelledValue>();

  // --- Submission -------------------------------------------------------
  final RxBool isSubmitting = false.obs;
  final RxnString errorMessage = RxnString();
  final Rxn<EnforcementCase> opened = Rxn<EnforcementCase>();

  String? _caseTypeServerError;
  String? _reasonServerError;
  String? _priorityServerError;
  String? _offenderNameServerError;
  String? _offenderFatherServerError;
  String? _offenderMobileServerError;
  String? _offenderCnicServerError;

  /// Bumped by [markEdited]. The form's completeness is worked out from
  /// `TextEditingController.text`, which is not observable, so the submit bar
  /// watches this instead and re-reads it.
  final RxInt revision = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadCaseTypes();
    if (unit != null) {
      _prefillOffender();
    }
    if (unit == null && propertyId != null) {
      // The route carried an id and nothing else, so the shop's details have
      // to be fetched before the card can be shown.
      loadProfile();
    }
    // A form opened after a sign-in on a dead signal has no priorities to
    // offer; this is what fetches them.
    _definitions.ensureLoaded().then((_) => _pickDefaultPriority());
    _pickDefaultPriority();
  }

  @override
  void onClose() {
    reasonController.dispose();
    offenderNameController.dispose();
    offenderFatherController.dispose();
    offenderMobileController.dispose();
    personLookup.onClose();
    super.onClose();
  }

  /// The unit the case will be opened on, whichever way the officer got here.
  int? get targetPropertyId => unit?.propertyId ?? propertyId;

  /// The shop this case is about, once the profile has landed.
  ProfileProperty? get property => profile.value?.property;

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

  /// Rent arrears on the unit, as a string. Shown because a case opened over
  /// conduct is still worked alongside the money — never added to anything.
  String? get unitOutstanding =>
      unit?.outstanding ?? profile.value?.position.totalOutstanding;

  bool get unitIsSealed =>
      unit?.isSealed ?? profile.value?.enforcement.isSealed ?? false;

  bool get unitIsVacant =>
      unit?.isVacant ?? (property?.occupancyStatus == 'vacant');

  /// Who the register says holds it. Null on a vacant unit, and on a unit card
  /// that named nobody.
  String? get allotteeName =>
      unit?.allotteeName ?? profile.value?.allottee?.fullName;

  /// The case already open on this shop, where the record names one. A second
  /// file on the same conduct is what the officer is warned about.
  String? get openCaseLabel {
    final String? caseNo = profile.value?.enforcement.openCaseNo;
    if (caseNo != null) return caseNo;
    final int? id = unit?.openCaseId;
    return id == null ? null : '#$id';
  }

  bool get hasOpenCase => openCaseLabel != null;

  /// Whether the register named somebody to fill the person block in from —
  /// the note under it says so, because a prefilled field an officer did not
  /// type is one they have to be told to check.
  bool get hasRegisteredPerson =>
      (unit?.allotteeName ?? profile.value?.allottee?.fullName) != null;

  /// The priorities on the register, in its own order and with its own
  /// wording. Read inside an `Obx` builder — these follow the definitions
  /// controller.
  List<LabelledValue> get priorities => _definitions.casePriorities;

  bool get isLoadingPriorities => _definitions.isLoading.value;

  // --- Loading ----------------------------------------------------------

  /// Safe to call again — this is the retry behind an empty picker.
  Future<void> loadCaseTypes() async {
    isLoadingCaseTypes.value = true;
    caseTypesError.value = null;
    try {
      final List<CaseTypeOption> rows = await _cases.caseTypes();
      if (isClosed) return;
      caseTypes.assignAll(rows);
      // One kind of case is not a choice worth asking about.
      if (rows.length == 1) chooseCaseType(rows.first);
    } on ApiException catch (error) {
      if (isClosed) return;
      caseTypesError.value = error.message;
    } finally {
      if (!isClosed) isLoadingCaseTypes.value = false;
    }
  }

  /// The unit behind a route that carried only its id. Safe to call again —
  /// this is the retry behind a failed load.
  Future<void> loadProfile() async {
    final int? id = propertyId;
    if (id == null) return;
    isLoadingProfile.value = true;
    profileError.value = null;
    try {
      final PropertyProfile fetched = await _reporting.propertyProfile(id);
      if (isClosed) return;
      profile.value = fetched;
      _prefillOffender();
    } on ApiException catch (error) {
      if (isClosed) return;
      profileError.value = error.message;
    } finally {
      if (!isClosed) isLoadingProfile.value = false;
    }
  }

  /// `normal` where the register offers it: the priority an officer would pick
  /// nine times out of ten, and never a guess over their own choice.
  void _pickDefaultPriority() {
    if (isClosed || priority.value != null) return;
    for (final LabelledValue row in priorities) {
      if (row.value == 'normal') {
        priority.value = row;
        return;
      }
    }
  }

  // --- Who it is against --------------------------------------------------

  /// Fills the block in from whoever the register says holds the unit — on a
  /// held shop that is the person the case is against, and retyping four
  /// fields off the card above is how a wrong digit gets onto a notice.
  ///
  /// Nothing the officer typed is replaced: the person in front of them may
  /// not be the person on the register, and their correction stands.
  void _prefillOffender() {
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

  /// Fills the block in from a CNIC the officer looked up and took. Straight
  /// over whatever was there: they tapped a card with a name on it.
  void takePerson(PersonSuggestion suggestion, PersonLookup found) {
    offenderNameController.text = suggestion.name;
    offenderFatherController.text = suggestion.fatherName ?? '';
    offenderMobileController.text = suggestion.mobileNo ?? '';
    _suggestedName = suggestion.name;
    _suggestedFather = suggestion.fatherName;
    _suggestedMobile = suggestion.mobileNo;
    markEdited();
  }

  // --- Editing ----------------------------------------------------------

  void markEdited() => revision.value++;

  void chooseCaseType(CaseTypeOption? chosen) {
    caseType.value = chosen;
    markEdited();
  }

  void choosePriority(LabelledValue? chosen) {
    priority.value = chosen;
    markEdited();
  }

  // --- Validators -------------------------------------------------------

  String? validateCaseType(CaseTypeOption? value) {
    if (_caseTypeServerError != null) return _caseTypeServerError;
    if (value == null) return 'Choose what the case is about';
    return null;
  }

  String? validateReason(String? value) {
    if (_reasonServerError != null) return _reasonServerError;
    if ((value?.trim() ?? '').isEmpty) {
      return 'Say why the case is being opened';
    }
    return null;
  }

  /// Only ever the server's own refusal: the priority is optional, so there is
  /// no rule of ours for it to break.
  String? validatePriority(LabelledValue? value) => _priorityServerError;

  String? validateOffenderName(String? value) {
    if (_offenderNameServerError != null) return _offenderNameServerError;
    if ((value?.trim() ?? '').isEmpty) {
      return 'Name the person this case is against';
    }
    return null;
  }

  String? validateOffenderFather(String? value) {
    if (_offenderFatherServerError != null) return _offenderFatherServerError;
    if ((value?.trim() ?? '').isEmpty) return "Their father's name is required";
    return null;
  }

  String? validateOffenderMobile(String? value) {
    if (_offenderMobileServerError != null) return _offenderMobileServerError;
    if ((value?.trim() ?? '').isEmpty) {
      return 'A mobile number to reach them on is required';
    }
    return null;
  }

  /// Optional, and only ever the server's own refusal: the three fields above
  /// are what a notice is served on, and a CNIC is how the person is found
  /// again where the register holds one.
  String? validateOffenderCnic(String? value) => _offenderCnicServerError;

  /// Whether every required field has something in it. Drives the submit
  /// button, so the officer can see the form is not ready before they reach
  /// the bottom of it.
  bool get isComplete =>
      targetPropertyId != null &&
      caseType.value != null &&
      reasonController.text.trim().isNotEmpty &&
      _offender().isComplete;

  /// Whether every field the server insists on passes its own validator.
  bool get isValid =>
      targetPropertyId != null &&
      validateCaseType(caseType.value) == null &&
      validateReason(reasonController.text) == null &&
      validatePriority(priority.value) == null &&
      validateOffenderName(offenderNameController.text) == null &&
      validateOffenderFather(offenderFatherController.text) == null &&
      validateOffenderMobile(offenderMobileController.text) == null &&
      validateOffenderCnic(offenderCnicController.text) == null;

  /// What is still missing, in the order the form asks for it. Shown beside
  /// the disabled button — a button that will not press and will not say why
  /// is the thing officers give up on.
  List<String> get missing => <String>[
    if (targetPropertyId == null) 'the shop',
    if (caseType.value == null) 'what the case is about',
    if (reasonController.text.trim().isEmpty) 'why it is being opened',
    if (offenderNameController.text.trim().isEmpty)
      "the name of the person it is against",
    if (offenderFatherController.text.trim().isEmpty) "their father's name",
    if (offenderMobileController.text.trim().isEmpty) 'their mobile number',
  ];

  // --- Submission -------------------------------------------------------

  Future<OpenCaseOutcome> open() async {
    _clearServerErrors();
    errorMessage.value = null;

    final int? id = targetPropertyId;
    if (id == null) {
      errorMessage.value = 'Choose the shop this case is about.';
      return OpenCaseOutcome.invalidForm;
    }
    // The Form is asked to paint the messages; whether the case may be opened
    // is decided here — the rules belong to the controller, not to whether a
    // widget happens to be mounted.
    formKey.currentState?.validate();
    if (!isValid) return OpenCaseOutcome.invalidForm;

    isSubmitting.value = true;
    try {
      opened.value = await _cases.openCase(
        FieldCaseRequest.conduct(
          propertyId: id,
          caseType: caseType.value!.code,
          caseReason: reasonController.text.trim(),
          offender: _offender(),
          priority: priority.value?.value,
        ),
      );
      return OpenCaseOutcome.success;
    } on ApiException catch (error) {
      _applyFailure(error);
      formKey.currentState?.validate();
      return OpenCaseOutcome.failed;
    } finally {
      isSubmitting.value = false;
    }
  }

  FineOffender _offender() => FineOffender(
    name: offenderNameController.text.trim(),
    fatherName: offenderFatherController.text.trim(),
    mobileNo: offenderMobileController.text.trim(),
    cnic: _trimmedOrNull(offenderCnicController.text),
  );

  static String? _trimmedOrNull(String value) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _applyFailure(ApiException error) {
    errorMessage.value = error.message;
    if (!error.isValidation) return;

    // No `property_id` here on purpose: the unit came off the record the
    // officer arrived with, so a refusal about it is nothing they can fix on
    // this form and it stays on the banner.
    _caseTypeServerError = error.errorFor('case_type');
    _reasonServerError = error.errorFor('case_reason');
    _priorityServerError = error.errorFor('priority');
    _offenderNameServerError = error.errorFor('offender_name');
    _offenderFatherServerError = error.errorFor('offender_father_name');
    _offenderMobileServerError = error.errorFor('offender_mobile_no');
    _offenderCnicServerError = error.errorFor('offender_cnic');
  }

  void _clearServerErrors() {
    _caseTypeServerError = null;
    _reasonServerError = null;
    _priorityServerError = null;
    _offenderNameServerError = null;
    _offenderFatherServerError = null;
    _offenderMobileServerError = null;
    _offenderCnicServerError = null;
  }
}
