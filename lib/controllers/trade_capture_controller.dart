import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/network/api_exception.dart';
import '../data/repositories/trade_repository.dart';
import '../models/field_beat.dart';
import '../models/trade_application.dart';
import '../models/trade_application_request.dart';
import '../models/trade_beat.dart';
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

class TradeCaptureController extends GetxController {
  TradeCaptureController({
    this.searched,
    this.initialAreaId,
    TradeRepository? tradeRepository,
  }) : _trade = tradeRepository ?? Get.find<TradeRepository>();

  final String? searched;

  /// The bazaar the officer was filtering by, when they were.
  final int? initialAreaId;

  final TradeRepository _trade;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // --- The bazaar -------------------------------------------------------

  /// The licensing beat, which is where the bazaars come from. The tariff
  /// cannot supply them — it prices one bazaar and has to be told which.
  final Rxn<TradeBeat> beat = Rxn<TradeBeat>();
  final RxBool isLoadingAreas = RxBool(false);
  final RxnString areasError = RxnString();

  final RxnInt areaId = RxnInt();

  /// The search over the officer's bazaars. Held here so a rebuild does not
  /// lose what is being typed.
  final TextEditingController areaSearchController = TextEditingController();
  final RxString areaQuery = RxString('');

  // --- The tariff -------------------------------------------------------
  final Rxn<TradeTariff> tariff = Rxn<TradeTariff>();
  final RxBool isLoadingTariff = RxBool(false);
  final RxnString tariffError = RxnString();

  final Rxn<TradeCategory> category = Rxn<TradeCategory>();

  /// The yearly fee, prefilled from the tariff when a trade is chosen and the
  /// officer's to correct. A string from end to end.
  final TextEditingController feeController = TextEditingController();

  /// How long the licence runs. Fixed at a year: it is the only term MCQ
  /// issues in the field for now, so the form states it rather than asking.
  /// The server still reads `years`, and still prices the licence itself.
  static const int years = 1;

  // --- The shopkeeper ---------------------------------------------------
  final TextEditingController applicantController = TextEditingController();
  final TextEditingController fatherController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController cnicController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  // --- The shop ---------------------------------------------------------
  final TextEditingController businessController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

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
    loadAreas();
    // The bazaar they were filtering by is already an answer to step one, so
    // its prices are fetched without waiting for the beat behind the picker.
    if (areaId.value != null) loadTariff();
  }

  @override
  void onClose() {
    areaSearchController.dispose();
    feeController.dispose();
    applicantController.dispose();
    fatherController.dispose();
    mobileController.dispose();
    cnicController.dispose();
    emailController.dispose();
    businessController.dispose();
    addressController.dispose();
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

  // --- The bazaar -------------------------------------------------------

  /// The bazaars this officer may quote for, off `trade/field/beat`. The
  /// tariff's own list is the fallback, for the bazaar arrived with: it comes
  /// back with the prices, which is sooner than the beat lands.
  Future<void> loadAreas() async {
    isLoadingAreas.value = true;
    areasError.value = null;
    try {
      beat.value = await _trade.beat();
      _pickSoleArea();
    } on ApiException catch (error) {
      areasError.value = error.message;
    } finally {
      isLoadingAreas.value = false;
    }
  }

  List<FieldArea> get areas {
    final List<FieldArea> onTheBeat =
        beat.value?.scope.areas ?? const <FieldArea>[];
    if (onTheBeat.isNotEmpty) return onTheBeat;
    return tariff.value?.areas ?? const <FieldArea>[];
  }

  List<int> get areaOptions => <int>[
    for (final FieldArea area in areas)
      if (area.id != null) area.id!,
  ];

  /// One bazaar on the beat is not a choice worth asking about.
  void _pickSoleArea() {
    if (areaId.value != null) return;
    if (areaOptions.length == 1) setArea(areaOptions.first);
  }

  /// The bazaars matching [term], by name or by code. An empty term offers the
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

  void searchArea(String term) => areaQuery.value = term;

  /// The chosen bazaar, named. Falls back to the one the tariff answered for,
  /// so a bazaar arrived with is shown before the beat has landed.
  FieldArea? get chosenArea {
    final int? id = areaId.value;
    if (id == null) return null;
    for (final FieldArea area in areas) {
      if (area.id == id) return area;
    }
    final FieldArea? priced = tariff.value?.area;
    return priced?.id == id ? priced : null;
  }

  /// Naming a bazaar is what makes a quote possible, so its prices are fetched
  /// on the spot.
  Future<void> setArea(int? id) async {
    if (id == null || id == areaId.value) return;
    areaId.value = id;
    areaSearchController.clear();
    areaQuery.value = '';
    markEdited();
    await loadTariff();
  }

  /// Cancelling it. The prices go with it — they belonged to that bazaar.
  void clearArea() {
    areaId.value = null;
    tariff.value = null;
    tariffError.value = null;
    category.value = null;
    feeController.clear();
    markEdited();
  }

  // --- The tariff -------------------------------------------------------

  Future<void> loadTariff() async {
    final int? id = areaId.value;
    // The endpoint prices a bazaar. Without one there is nothing to ask it.
    if (id == null) return;
    isLoadingTariff.value = true;
    tariffError.value = null;
    try {
      final TradeTariff priced = await _trade.tariff(areaId: id);
      tariff.value = priced;
      // A trade priced in the last zone may be unpriced in this one, and a
      // stale choice would quote a fee this zone does not charge.
      final TradeCategory? chosen = category.value;
      if (chosen?.id != null) {
        final TradeCategory? here = priced.category(chosen!.id!);
        category.value = (here != null && here.canQuote) ? here : null;
        // This zone's price for the same trade, or none — the last zone's
        // figure is not a quote here.
        feeController.text = category.value?.annualFee ?? '';
      }
    } on ApiException catch (error) {
      tariffError.value = error.message;
      // Whatever is on screen was priced for the bazaar this replaced, so it
      // cannot be quoted at this one — a wrong figure read out to a shopkeeper
      // is worse than none.
      tariff.value = null;
      category.value = null;
      feeController.clear();
    } finally {
      isLoadingTariff.value = false;
    }
  }

  /// The zone the prices actually hang off, for a line that says so.
  String? get zoneName => tariff.value?.zone?.zoneName;

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

  /// What the tariff quotes for the chosen trade, exactly as the server sent
  /// it. The suggestion behind [feeController], never multiplied by [years].
  String? get annualFee => category.value?.annualFee;

  /// The figure that will be sent, as typed. Never parsed, never rounded.
  String get fee => feeController.text.trim();

  /// The heading the chosen trade sits under in the tariff. The group is on
  /// the group, not on the category, so it is looked up rather than read off.
  String? get categoryGroup {
    final int? id = category.value?.id;
    if (id == null) return null;
    for (final TradeCategoryGroup group
        in tariff.value?.groups ?? const <TradeCategoryGroup>[]) {
      if (group.categories.any((TradeCategory row) => row.id == id)) {
        return group.label;
      }
    }
    return null;
  }

  void chooseCategory(TradeCategory chosen) {
    if (!chosen.canQuote) return;
    category.value = chosen;
    // The tariff's own figure, put in the field. An officer who has to type
    // the fee MCQ already quoted is an officer who mistypes it.
    feeController.text = chosen.annualFee ?? '';
    markEdited();
  }

  /// Any edit clears the "did that land?" state: the officer is writing a
  /// different capture now, not resending the last one.
  void markEdited() {
    mayHaveLanded.value = false;
    revision.value++;
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
    // The endpoint would take a capture without one; MCQ will not. A licence
    // is keyed on a CNIC, so a shop captured without it cannot be issued.
    if (cnic.isEmpty) return "The shopkeeper's CNIC is required";
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

  String? validateFee(String? value) {
    final String? fromServer = _serverErrors['fee_amount'];
    if (fromServer != null) return fromServer;
    final String amount = value?.trim() ?? '';
    if (amount.isEmpty) return 'The licence fee is required';
    // Shape only. The figure is sent as typed and the server decides what the
    // licence is worth.
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(amount)) {
      return 'Enter a fee like 6000 or 6000.00';
    }
    if (RegExp(r'^0+(\.0{1,2})?$').hasMatch(amount)) {
      return 'The fee must be at least 1';
    }
    return null;
  }

  String? get categoryError => _serverErrors['trade_category_id'];

  String? get areaError => _serverErrors['area_id'];

  // --- Whether it may be sent -------------------------------------------

  /// What is still missing, in the order the form asks for it. Shown beside
  /// the disabled button — a button that will not press and will not say why
  /// is the thing officers give up on.
  List<String> get missing => <String>[
    if (areaId.value == null) 'the bazaar',
    if (category.value == null) 'the trade',
    if (feeController.text.trim().isEmpty) 'the licence fee',
    if (cnicController.text.trim().isEmpty) "the shopkeeper's CNIC",
    if (applicantController.text.trim().isEmpty) 'their name',
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
      validateFee(feeController.text) == null &&
      validateApplicant(applicantController.text) == null &&
      validateFather(fatherController.text) == null &&
      validateMobile(mobileController.text) == null &&
      validateCnic(cnicController.text) == null &&
      validateEmail(emailController.text) == null &&
      validateBusiness(businessController.text) == null &&
      validateAddress(addressController.text) == null;

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
    return TradeApplicationRequest(
      tradeCategoryId: category.value!.id!,
      areaId: areaId.value!,
      years: years,
      applicantName: applicantController.text.trim(),
      fatherName: fatherController.text.trim(),
      mobileNo: mobileController.text.trim(),
      businessName: businessController.text.trim(),
      shopAddress: addressController.text.trim(),
      feeAmount: fee,
      cnic: cnicController.text.trim(),
      email: _orNull(emailController.text),
    );
  }

  void _applyFieldErrors(ApiException error) {
    for (final String field in const <String>[
      'trade_category_id',
      'area_id',
      'fee_amount',
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
