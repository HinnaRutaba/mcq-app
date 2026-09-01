/// How a chalaan was settled.
///
/// [cash] is the only method the app itself records — a magistrate
/// collecting in person. The rest describe payments that arrived through
/// an outside channel (a bank counter, a wallet transfer) and are kept so
/// historical records still read correctly.
enum PaymentMethod {
  bank,
  easypaisa,
  jazzcash,
  manual,
  cash;

  String get label => switch (this) {
        PaymentMethod.bank => 'Bank Transfer',
        PaymentMethod.easypaisa => 'Easypaisa',
        PaymentMethod.jazzcash => 'JazzCash',
        PaymentMethod.manual => 'Manual Bank Transfer',
        PaymentMethod.cash => 'Cash (Collected in person)',
      };
}
