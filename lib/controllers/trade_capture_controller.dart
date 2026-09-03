import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/capture/location_capture.dart';
import '../core/network/api_exception.dart';
import '../data/repositories/trade_repository.dart';
import '../models/field_beat.dart';
import '../models/trade_application.dart';
import '../models/trade_application_request.dart';
import '../models/trade_tariff.dart';

/// What came of pressing "Capture this shop".
enum CaptureOutcome {
  /// Written. [TradeCaptureController.captured] holds the application, its
  /// challan and its consumer number.
  success,

  /// The form itself was not valid; the fields already say why.
  invalidForm,

  /// The server refused it, and said so — nothing was written.
  failed,

  /// The call did not come back. Nothing here can say whether it landed, so
  /// the officer is sent to check their captures rather than offered a retry.
  unconfirmed,
}

/// Capturing an unlicensed shop: the tariff the fee is quoted from, and the one
/// call that writes it.
///
/// Two rules this controller exists to hold:
///
/// * **The app never prices a licence.** The fee comes off the tariff for
///   (trade x zone) and only a [TradeCategory] whose `canQuote` is true may be
///   picked. The annual fee is shown as the server sent it and is never
///   multiplied by the term — the server prices the licence when it raises the
///   challan.
/// * **A resend is not safe.** Unlike every enforcement write this endpoint
///   accepts no `client_action_uuid`, so a call that timed out may well have
///   landed. [mayHaveLanded] turns the retry into a trip to
///   `trade/field/pending` instead of a second shop on the register.
class TradeCaptureController extends GetxController {
  TradeCaptureController({
    this.searched,
    this.initialAreaId,
    TradeRepository? tradeRepository,
    LocationCapture? locationCapture,
  }) : _trade = tradeRepository ?? Get.find<TradeRepository>(),
       _locations = locationCapture ?? const LocationCapture();

  /// What the officer looked up before finding nothing — a CNIC or a mobile
  /// number. Prefilled into whichever field it is, because retyping the number
  /// that just came back "not on the register" is how a wrong digit gets in.
  final String? searched;

  /// The bazaar the officer was filtering by, when they were.
  final int? initialAreaId;

  final TradeRepository _trade;
  final LocationCapture _locations;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // --- The tariff -------------------------------------------------------
  final Rxn<TradeTariff> tariff = Rxn<TradeTariff>();
  final RxBool isLoadingTariff = RxBool(false);
  final RxnString tariffError = RxnString();

  final RxnInt areaId = RxnInt();
  final Rxn<TradeCategory> category = Rxn<TradeCategory>();
  final RxInt years = RxInt(1);

  // --- The shopkeeper ---------------------------------------------------
  final TextEditingController applicantController = TextEditingController();
  final TextEditingController fatherController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController cnicController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  // --- The shop ---------------------------------------------------------
  final TextEditingController businessController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  final Rxn<LocationFix> locationFix = Rxn<LocationFix>();
  final RxBool isFixingLocation = RxBool(false);
  final Rx<LocationOutcome> locationOutcome = Rx<LocationOutcome>(
    LocationOutcome.unavailable,
  );

  // --- The write --------------------------------------------------------
  final RxBool isSubmitting = RxBool(false);
  final RxnString errorMessage = RxnString();
  final Rxn<TradeApplication> captured = Rxn<TradeApplication>();

  /// A send that never came back. The endpoint is not idempotent, so the only
  /// honest next step is to read `trade/field/pending` and look.
  final RxBool mayHaveLanded = RxBool(false);

  /// Bumped by [markEdited]. Completeness is worked out from
  /// `TextEditingController.text`, which is not observable, so the submit bar
  /// watches this instead and re-reads them.
  final RxInt revision = RxInt(0);

  final Map<String, String> _serverErrors = <String, String>{};

  @override
  void onInit() {
    super.onInit();
    areaId.value = initialAreaId;
    _prefillSearched();
    loadTariff();
  }

  @override
  void onClose() {
    applicantController.dispose();
    fatherController.dispose();
    mobileController.dispose();
    cnicController.dispose();
    emailController.dispose();
    businessController.dispose();
    addressController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  /// Whatever was looked up, put where it belongs. A mobile and a CNIC are
  /// told apart by shape, which is the same way the server tells them apart.
  void _prefillSearched() {
    final String term = searched?.trim() ?? '';
    if (term.isEmpty) return;
    if (TradeApplicationRequest.mobilePattern.hasMatch(term)) {
      mobileController.text = term;
    } else if (TradeApplicationRequest.cnicPattern.hasMatch(term)) {
      cnicController.text = term;
    }
  }

  // --- The tariff -------------------------------------------------------

  /// Every trade with its price in one bazaar. Re-read when the bazaar
  /// changes: MCQ prices a trade per zone, and the bazaar inherits its zone's
  /// prices.
  Future<void> loadTariff() async {
    isLoadingTariff.value = true;
    tariffError.value = null;
    try {
      final TradeTariff priced = await _trade.tariff(areaId: areaId.value);
      tariff.value = priced;
      // The server answers for a bazaar even when none was asked for; adopt
      // it, so the request carries the area the prices belong to.
      areaId.value ??= priced.area?.id;
      // A trade priced in the last zone may be unpriced in this one, and a
      // stale choice would quote a fee this zone does not charge.
      final TradeCategory? chosen = category.value;
      if (chosen?.id != null) {
        final TradeCategory? here = priced.category(chosen!.id!);
        category.value = (here != null && here.canQuote) ? here : null;
      }
      if (!priced.terms.allows(years.value)) {
        years.value = priced.terms.minYears;
      }
    } on ApiException catch (error) {
      tariffError.value = error.message;
    } finally {
      isLoadingTariff.value = false;
    }
  }

  /// The bazaars this officer may quote for.
  List<FieldArea> get areas => tariff.value?.areas ?? const <FieldArea>[];

  List<int> get areaOptions => <int>[
    for (final FieldArea area in areas)
      if (area.id != null) area.id!,
  ];

  String areaLabel(int id) {
    for (final FieldArea area in areas) {
      if (area.id == id) return area.areaName;
    }
    return 'Bazaar $id';
  }

  /// The zone the prices actually hang off, for a line that says so.
  String? get zoneName => tariff.value?.zone?.zoneName;

  TradeTerms get terms => tariff.value?.terms ?? const TradeTerms();

  List<int> get termOptions => <int>[
    for (int year = terms.minYears; year <= terms.maxYears; year++) year,
  ];

  /// Only the trades this zone carries a price for. A trade with no price
  /// cannot raise a challan, so the picker must not offer it.
  List<TradeCategoryGroup> get quotableGroups => <TradeCategoryGroup>[
    for (final TradeCategoryGroup group
        in tariff.value?.groups ?? const <TradeCategoryGroup>[])
      if (group.categories.any((TradeCategory c) => c.canQuote))
        TradeCategoryGroup(
          group: group.group,
          categories: group.categories
              .where((TradeCategory c) => c.canQuote)
              .toList(),
        ),
  ];

  /// How many trades this zone has no price for. Above zero, the picker has to
  /// say so rather than look short.
  int get unpricedCount => tariff.value?.unpriced ?? 0;

  /// The yearly fee for the chosen trade, exactly as the server quoted it.
  /// Never multiplied by [years] — the server prices the licence.
  String? get annualFee => category.value?.annualFee;

  Future<void> setArea(int? id) async {
    if (id == null || id == areaId.value) return;
    areaId.value = id;
    markEdited();
    await loadTariff();
  }

  void chooseCategory(TradeCategory chosen) {
    if (!chosen.canQuote) return;
    category.value = chosen;
    markEdited();
  }

  void setYears(int? value) {
    if (value == null || !terms.allows(value)) return;
    years.value = value;
    markEdited();
  }

  /// Any edit clears the "did that land?" state: the officer is writing a
  /// different capture now, not resending the last one.
  void markEdited() {
    mayHaveLanded.value = false;
    revision.value++;
  }

  // --- Where the officer stood ------------------------------------------

  Future<LocationOutcome> attachLocation() async {
    isFixingLocation.value = true;
    try {
      final LocationResult result = await _locations.fix();
      locationOutcome.value = result.outcome;
      // Both coordinates or neither: a failed attempt clears the last fix
      // rather than leaving a stale one attached to a different shop.
      locationFix.value = result.fix;
      markEdited();
      return result.outcome;
    } finally {
      isFixingLocation.value = false;
    }
  }

  // --- Validators, transcribed from the endpoint's own rules ------------

  String? validateApplicant(String? value) =>
      _serverErrors['applicant_name'] ??
      _name(value, "The shopkeeper's name is required");

  String? validateFather(String? value) =>
      _serverErrors['father_name'] ??
      _name(value, "Their father's name is required");

  String? _name(String? value, String whenEmpty) {
    final String name = value?.trim() ?? '';
    if (name.isEmpty) return whenEmpty;
    if (name.length > TradeApplicationRequest.nameMaxLength) {
      return 'Keep it under ${TradeApplicationRequest.nameMaxLength} characters';
    }
    if (!TradeApplicationRequest.namePattern.hasMatch(name)) {
      // The server's rule is ASCII-only, so the form says so here rather than
      // letting the officer find out after typing the whole form in Urdu.
      return 'English letters only — the register will not take Urdu here';
    }
    return null;
  }

  String? validateMobile(String? value) {
    final String? fromServer = _serverErrors['mobile_no'];
    if (fromServer != null) return fromServer;
    final String mobile = value?.trim() ?? '';
    if (mobile.isEmpty) return 'A mobile number is required';
    if (!TradeApplicationRequest.mobilePattern.hasMatch(mobile)) {
      // This is where the payment link is texted, so a wrong digit is a
      // challan nobody ever sees.
      return 'Enter it as 03XXXXXXXXX';
    }
    return null;
  }

  String? validateCnic(String? value) {
    final String? fromServer = _serverErrors['cnic'];
    if (fromServer != null) return fromServer;
    final String cnic = value?.trim() ?? '';
    if (cnic.isEmpty) return null;
    if (!TradeApplicationRequest.cnicPattern.hasMatch(cnic)) {
      return '${TradeApplicationRequest.cnicLength} digits, no dashes';
    }
    return null;
  }

  String? validateEmail(String? value) {
    final String? fromServer = _serverErrors['email'];
    if (fromServer != null) return fromServer;
    final String email = value?.trim() ?? '';
    if (email.isEmpty) return null;
    if (email.length > TradeApplicationRequest.emailMaxLength) {
      return 'Keep it under ${TradeApplicationRequest.emailMaxLength} characters';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'That is not an email address';
    }
    return null;
  }

  String? validateBusiness(String? value) {
    final String? fromServer = _serverErrors['business_name'];
    if (fromServer != null) return fromServer;
    final String name = value?.trim() ?? '';
    if (name.isEmpty) return 'What the shop trades as is required';
    if (name.length > TradeApplicationRequest.businessNameMaxLength) {
      return 'Keep it under '
          '${TradeApplicationRequest.businessNameMaxLength} characters';
    }
    if (!TradeApplicationRequest.businessNamePattern.hasMatch(name)) {
      return 'English letters, digits and . , - / & ( ) # only';
    }
    return null;
  }

  String? validateAddress(String? value) {
    final String? fromServer = _serverErrors['shop_address'];
    if (fromServer != null) return fromServer;
    final String address = value?.trim() ?? '';
    if (address.isEmpty) return 'Where the shop stands is required';
    if (address.length > TradeApplicationRequest.shopAddressMaxLength) {
      return 'Keep it under '
          '${TradeApplicationRequest.shopAddressMaxLength} characters';
    }
    return null;
  }

  String? validateRemarks(String? value) {
    if ((value ?? '').length > TradeApplicationRequest.remarksMaxLength) {
      return 'Keep remarks under '
          '${TradeApplicationRequest.remarksMaxLength} characters';
    }
    return null;
  }

  String? get categoryError => _serverErrors['trade_category_id'];

  String? get areaError => _serverErrors['area_id'];

  String? get yearsError => _serverErrors['years'];

  // --- Whether it may be sent -------------------------------------------

  /// What is still missing, in the order the form asks for it. Shown beside
  /// the disabled button — a button that will not press and will not say why
  /// is the thing officers give up on.
  List<String> get missing => <String>[
    if (areaId.value == null) 'the bazaar',
    if (category.value == null) 'the trade',
    if (applicantController.text.trim().isEmpty) "the shopkeeper's name",
    if (fatherController.text.trim().isEmpty) "their father's name",
    if (mobileController.text.trim().isEmpty) 'a mobile number',
    if (businessController.text.trim().isEmpty) 'the business name',
    if (addressController.text.trim().isEmpty) 'the shop address',
  ];

  /// Whether every rule the server insists on passes. Separate from [missing],
  /// which only asks whether the fields have something in them.
  bool get isValid =>
      missing.isEmpty &&
      (category.value?.canQuote ?? false) &&
      terms.allows(years.value) &&
      validateApplicant(applicantController.text) == null &&
      validateFather(fatherController.text) == null &&
      validateMobile(mobileController.text) == null &&
      validateCnic(cnicController.text) == null &&
      validateEmail(emailController.text) == null &&
      validateBusiness(businessController.text) == null &&
      validateAddress(addressController.text) == null &&
      validateRemarks(remarksController.text) == null;

  // --- The write --------------------------------------------------------

  Future<CaptureOutcome> capture() async {
    _serverErrors.clear();
    errorMessage.value = null;
    mayHaveLanded.value = false;

    // The Form is asked to paint the messages; whether the capture may be sent
    // is decided here. The rules belong to the controller, not to whether a
    // widget happens to be mounted.
    formKey.currentState?.validate();
    if (!isValid) return CaptureOutcome.invalidForm;

    isSubmitting.value = true;
    try {
      captured.value = await _trade.submitApplication(_buildRequest());
      return CaptureOutcome.success;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      if (error.isValidation) {
        _applyFieldErrors(error);
        formKey.currentState?.validate();
        return CaptureOutcome.failed;
      }
      // No idempotency key on this endpoint, so a timeout or a dead radio is
      // genuinely unknown: the shop may already be on the register.
      if (error.isRetryable) {
        mayHaveLanded.value = true;
        return CaptureOutcome.unconfirmed;
      }
      return CaptureOutcome.failed;
    } finally {
      isSubmitting.value = false;
    }
  }

  TradeApplicationRequest _buildRequest() {
    final LocationFix? fix = locationFix.value;
    return TradeApplicationRequest(
      tradeCategoryId: category.value!.id!,
      areaId: areaId.value!,
      years: years.value,
      applicantName: applicantController.text.trim(),
      fatherName: fatherController.text.trim(),
      mobileNo: mobileController.text.trim(),
      businessName: businessController.text.trim(),
      shopAddress: addressController.text.trim(),
      cnic: _orNull(cnicController.text),
      email: _orNull(emailController.text),
      latitude: fix?.latitude,
      longitude: fix?.longitude,
      remarks: _orNull(remarksController.text),
    );
  }

  void _applyFieldErrors(ApiException error) {
    for (final String field in const <String>[
      'trade_category_id',
      'area_id',
      'years',
      'applicant_name',
      'father_name',
      'mobile_no',
      'cnic',
      'email',
      'business_name',
      'shop_address',
    ]) {
      final String? message = error.errorFor(field);
      if (message != null) _serverErrors[field] = message;
    }
  }

  static String? _orNull(String value) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
