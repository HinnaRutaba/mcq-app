import '../../core/utils/json_reader.dart';
import '../common/api_enum.dart';
import '../common/money.dart';

/// A challan: the monthly bill. Has a `challan_no`. Not an "invoice".
///
/// **Every challan says what kind it is — show it.** A 3,000 fine and a
/// 3,000 rent bill are indistinguishable by amount, and the officer is
/// often standing in front of the person being billed. Use
/// [challanType]'s label, which is already translated; never map its value
/// to strings of our own.
///
/// A fine is a separate debt, not part of the rent: a shop can hold a live
/// rent challan and a live fine challan at the same time, with different
/// due dates and different payment links. Never sum them into one "amount
/// due", and never treat one link as replacing the other.
class Challan {
  const Challan({
    required this.id,
    required this.challanNo,
    required this.challanType,
    required this.status,
    required this.total,
    this.payableNow,
    this.dueDate,
    this.issuedOn,
    this.payUrl,
    this.consumerNo,
    this.payerName,
    this.payerMobileNo,
    this.allotmentId,
    this.allotteeId,
  });

  final int id;
  final String challanNo;
  final ApiEnum challanType;
  final ApiEnum status;
  final Money total;
  final Money? payableNow;
  final DateTime? dueDate;
  final DateTime? issuedOn;

  /// The public payment link from the SMS. The person fined opens this on
  /// their own phone; the app only reports that it exists.
  final String? payUrl;

  final String? consumerNo;
  final String? payerName;
  final String? payerMobileNo;
  final int? allotmentId;
  final int? allotteeId;

  factory Challan.fromJson(Map<String, dynamic> json) => Challan(
        id: json.intOr('id'),
        challanNo: json.strOr('challan_no'),
        challanType: json.apiEnum('challan_type'),
        status: json.apiEnum('status'),
        total: json.moneyOrNull('total') ?? json.money('total_amount'),
        payableNow: json.moneyOrNull('payable_now') ??
            json.child('amounts')?.moneyOrNull('payable_now'),
        dueDate: json.date('due_date'),
        issuedOn: json.date('issued_on') ?? json.date('created_at'),
        payUrl: json.str('pay_url') ?? json.str('payment_url'),
        consumerNo: json.str('consumer_no'),
        payerName: json.str('payer_name'),
        payerMobileNo: json.str('payer_mobile_no'),
        allotmentId: json.integer('allotment_id'),
        allotteeId: json.integer('allottee_id'),
      );

  bool get isFine => challanType.value == 'fine';
  bool get hasPayLink => (payUrl ?? '').isNotEmpty;
}
