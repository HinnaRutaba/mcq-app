import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../models/billing/payment.dart';
import '../../../models/common/money.dart';
import '../../../models/common/pagination_meta.dart';
import '../../../core/utils/json_reader.dart';

/// The `/payment` module. A magistrate may *see* payments and never record
/// one — there is no `payment.record` in their permission set.
class PaymentRepository {
  PaymentRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<Paginated<Payment>> payments({
    int? allotmentId,
    int page = 1,
    int perPage = ApiConstants.defaultPerPage,
  }) async {
    final envelope = await _client.get(
      ApiConstants.payments,
      query: {
        ApiConstants.qAllotmentId: allotmentId,
        ApiConstants.qPage: page,
        ApiConstants.qPerPage: perPage,
      },
    );
    return Paginated(
      items:
          envelope.list.whereType<Map<String, dynamic>>().map(Payment.fromJson).toList(),
      meta: PaginationMeta.fromJson(envelope.meta),
    );
  }

  /// The public payment page behind an SMS link. Unauthenticated — the
  /// token *is* the credential, because asking a hawker to register an
  /// account to pay a fine is how a payment route ends up unused.
  ///
  /// The app does not render this page; this exists so an officer can
  /// confirm a link is live when a shopkeeper says it is not.
  Future<PublicPaymentPage> publicPayment(String token) async {
    final envelope = await _client.get(ApiConstants.publicPayment(token));
    final json = envelope.map;
    return PublicPaymentPage(
      payerName: json.strOr('payer_name'),
      consumerNo: json.str('consumer_no'),
      challanNo: json.str('challan_no'),
      payableNow: json.child('amounts')?.money('payable_now') ??
          json.money('payable_now'),
    );
  }
}

/// What the public page shows the person being asked to pay.
class PublicPaymentPage {
  const PublicPaymentPage({
    required this.payerName,
    required this.payableNow,
    this.consumerNo,
    this.challanNo,
  });

  final String payerName;
  final Money payableNow;
  final String? consumerNo;
  final String? challanNo;
}
