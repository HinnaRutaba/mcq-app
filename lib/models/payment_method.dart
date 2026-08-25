import 'package:flutter/material.dart';

/// Ways a tenant can settle a chalaan.
///
/// [bank], [easypaisa] and [jazzcash] are simulated online flows for now —
/// there is no real gateway wired in yet. [manual] records a bank transfer
/// the tenant made outside the app, pending the magistrate's verification.
enum PaymentMethod {
  bank,
  easypaisa,
  jazzcash,
  manual,
  cash;

  String get label => switch (this) {
        PaymentMethod.bank => 'Bank (Online)',
        PaymentMethod.easypaisa => 'Easypaisa',
        PaymentMethod.jazzcash => 'JazzCash',
        PaymentMethod.manual => 'Pay Manually via Bank Transfer',
        PaymentMethod.cash => 'Cash (Collected in person)',
      };

  IconData get icon => switch (this) {
        PaymentMethod.bank => Icons.account_balance_rounded,
        PaymentMethod.easypaisa => Icons.smartphone_rounded,
        PaymentMethod.jazzcash => Icons.phone_android_rounded,
        PaymentMethod.manual => Icons.receipt_long_rounded,
        PaymentMethod.cash => Icons.payments_rounded,
      };

  /// Whether this method is handled entirely within the app (simulated),
  /// vs. [manual] which requires the magistrate to verify a reference.
  bool get isInstant => this != PaymentMethod.manual;
}
