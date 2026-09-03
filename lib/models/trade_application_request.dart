/// Captures an unlicensed shop on the spot.
///
/// The only write in the licensing module, and it does four things in one
/// transaction: quotes the fee from (trade x zone), raises the challan, issues
/// a payment link and texts the shopkeeper. So the app never computes a fee —
/// pick a [TradeCategory] whose `canQuote` is true and let the server price it.
///
/// Unlike the enforcement writes this carries no `client_action_uuid`: the
/// endpoint does not accept one, so a resend on a weak signal is not made safe
/// by the server. Confirm against `trade/field/pending` before sending a second
/// time.
///
/// The validation rules below are the server's own, transcribed from the
/// endpoint's parameter table so a form uses them rather than reinventing
/// them. Note that [namePattern] is ASCII-only: an Urdu name is refused by the
/// server, and the form has to say so rather than let the officer find out
/// after typing.
class TradeApplicationRequest {
  const TradeApplicationRequest({
    required this.tradeCategoryId,
    required this.areaId,
    required this.years,
    required this.applicantName,
    required this.fatherName,
    required this.mobileNo,
    required this.businessName,
    required this.shopAddress,
    this.cnic,
    this.email,
    this.marketId,
    this.propertyId,
    this.latitude,
    this.longitude,
    this.remarks,
  });

  /// From the tariff — `TradeCategory.id`. Never a code.
  final int tradeCategoryId;

  /// The bazaar. The officer's own postings are the only ones the server will
  /// accept.
  final int areaId;

  /// The licence term. Bound by `TradeTariff.terms`.
  final int years;

  final String applicantName;
  final String fatherName;

  /// `03XXXXXXXXX`. This is where the payment link is texted, so a wrong digit
  /// is a challan nobody ever sees.
  final String mobileNo;

  final String businessName;
  final String shopAddress;

  /// 13 digits, no dashes.
  final String? cnic;

  final String? email;

  /// The market within the bazaar, when the shop sits in one.
  final int? marketId;

  /// Set only when the shop happens to occupy an MCQ unit. Most captures are
  /// businesses MCQ is not landlord to, and leave this null.
  final int? propertyId;

  /// Where the officer was standing.
  final double? latitude;
  final double? longitude;

  final String? remarks;

  // --- The server's own rules -------------------------------------------

  /// `applicant_name` and `father_name`. ASCII letters, spaces, full stops,
  /// apostrophes and hyphens, and it must start with a letter.
  static final RegExp namePattern = RegExp(r"^[A-Za-z][A-Za-z .'\-]*$");

  /// `business_name`. As [namePattern] plus digits, commas, slashes,
  /// ampersands, brackets and `#`.
  static final RegExp businessNamePattern = RegExp(
    r"^[A-Za-z0-9][A-Za-z0-9 .,'\-\/&()#]*$",
  );

  /// `cnic` — exactly 13 digits, unlike the dashed form a fine accepts.
  static final RegExp cnicPattern = RegExp(r'^\d{13}$');

  /// `mobile_no`.
  static final RegExp mobilePattern = RegExp(r'^03\d{9}$');

  static const int nameMaxLength = 150;
  static const int businessNameMaxLength = 200;
  static const int shopAddressMaxLength = 300;
  static const int emailMaxLength = 150;
  static const int remarksMaxLength = 500;
  static const int cnicLength = 13;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'trade_category_id': tradeCategoryId,
    'area_id': areaId,
    'years': years,
    'applicant_name': applicantName,
    'father_name': fatherName,
    'mobile_no': mobileNo,
    'business_name': businessName,
    'shop_address': shopAddress,
    'cnic': cnic,
    'email': email,
    'market_id': marketId,
    'property_id': propertyId,
    'latitude': latitude,
    'longitude': longitude,
    'remarks': remarks,
  };
}
