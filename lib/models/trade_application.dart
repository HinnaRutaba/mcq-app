import '../core/utils/json_parse.dart';

/// A field capture waiting to be paid: an unlicensed shop this officer wrote
/// up, whose challan is still open.
///
/// Scoped to the officer, not to the bazaar — somebody else's captures are not
/// theirs to chase.
///
/// The published spec captured this list only while it was empty, so the keys
/// are read leniently and the untouched payload is kept in [raw]. If a field
/// you need is missing here, read it from [raw] and then add it properly
/// rather than guessing at a getter.
class TradeApplication {
  const TradeApplication({
    this.id,
    this.applicationNo,
    this.applicantName,
    this.fatherName,
    this.mobileNo,
    this.cnic,
    this.businessName,
    this.shopAddress,
    this.trade,
    this.areaName,
    this.status,
    this.years,
    this.feeAmount,
    this.challanNo,
    this.consumerNo,
    this.hasLiveLink = false,
    this.appliedOn,
    this.raw = const <String, dynamic>{},
  });

  final int? id;
  final String? applicationNo;

  final String? applicantName;
  final String? fatherName;
  final String? mobileNo;
  final String? cnic;

  final String? businessName;
  final String? shopAddress;

  /// The trade applied for, e.g. "Naan Shop / Tandoor".
  final String? trade;

  final String? areaName;

  /// e.g. `pending`.
  final String? status;

  /// The licence term applied for, in years.
  final int? years;

  /// The quoted fee, as a string. Quoted by the server from (trade x zone) —
  /// never computed in the app.
  final String? feeAmount;

  final String? challanNo;

  /// What the shopkeeper quotes at a payment counter.
  final String? consumerNo;

  /// Whether the payment link the shopkeeper was texted still works.
  final bool hasLiveLink;

  final DateTime? appliedOn;

  final Map<String, dynamic> raw;

  factory TradeApplication.fromJson(Map<String, dynamic> json) =>
      TradeApplication(
        id: Json.integer(json['id']),
        applicationNo: Json.string(
          Json.pick(json, <String>['application_no', 'reference_no']),
        ),
        applicantName: Json.string(
          Json.pick(json, <String>['applicant_name', 'holder_name', 'name']),
        ),
        fatherName: Json.string(json['father_name']),
        mobileNo: Json.string(json['mobile_no']),
        cnic: Json.string(json['cnic']),
        businessName: Json.string(json['business_name']),
        shopAddress: Json.string(json['shop_address']),
        trade: Json.string(
          Json.pick(json, <String>['trade', 'category_name', 'trade_category']),
        ),
        areaName: Json.string(json['area_name']),
        status: Json.string(json['status']),
        years: Json.integer(json['years']),
        feeAmount: Json.money(
          Json.pick(json, <String>['fee_amount', 'total_fee', 'amount']),
        ),
        challanNo: Json.string(json['challan_no']),
        consumerNo: Json.string(
          Json.pick(json, <String>['consumer_no', 'consumer_number']),
        ),
        hasLiveLink: Json.booleanOr(json['has_live_link']),
        appliedOn: Json.dateTime(
          Json.pick(json, <String>['applied_on', 'created_at']),
        ),
        raw: json,
      );
}
