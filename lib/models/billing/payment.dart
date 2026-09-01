import '../../core/utils/json_reader.dart';
import '../common/api_enum.dart';
import '../common/money.dart';

/// A payment the corporation received. Read-only for a magistrate: they do
/// not take money and hold no `payment.record` permission.
class Payment {
  const Payment({
    required this.id,
    required this.amount,
    this.receiptNo,
    this.paidOn,
    this.method = ApiEnum.unknown,
    this.challanNo,
  });

  final int id;
  final Money amount;
  final String? receiptNo;
  final DateTime? paidOn;
  final ApiEnum method;
  final String? challanNo;

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json.intOr('id'),
        amount: json.moneyOrNull('amount') ?? json.money('amount_paid'),
        receiptNo: json.str('receipt_no'),
        paidOn: json.date('paid_on') ?? json.date('received_on'),
        method: json.apiEnum('method'),
        challanNo: json.str('challan_no') ??
            json.child('challan')?.str('challan_no'),
      );
}
