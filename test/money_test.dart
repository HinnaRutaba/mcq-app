import 'package:flutter_test/flutter_test.dart';
import 'package:mcq_app/models/common/money.dart';

/// Money is a `String` and is never parsed. These tests exist to keep it
/// that way: every expectation below is about the digits the server sent
/// surviving unchanged through display.
void main() {
  group('Money.format', () {
    test('groups the integer part and appends the fraction verbatim', () {
      expect(const Money('2198409.10').format(), '2,198,409.10');
      expect(const Money('263100.00').format(), '263,100.00');
      expect(const Money('16674600.00').format(), '16,674,600.00');
      expect(const Money('5600.00').format(), '5,600.00');
      expect(const Money('0.00').format(), '0.00');
    });

    test('does not round, pad or normalise the fraction', () {
      // A double would turn each of these into something else.
      expect(const Money('0.1').format(), '0.1');
      expect(const Money('1234.5').format(), '1,234.5');
      expect(const Money('0.005').format(), '0.005');
      expect(const Money('99999999999.99').format(), '99,999,999,999.99');
    });

    test('keeps a whole number readable when there is no fraction', () {
      expect(const Money('4500').format(), '4,500.00');
    });

    test('handles a negative amount without losing the sign', () {
      expect(const Money('-2500.50').format(), '-2,500.50');
    });

    test('leaves the raw string untouched', () {
      const amount = Money('2198409.10');
      amount.format();
      expect(amount.raw, '2198409.10');
      expect(amount.toJson(), '2198409.10');
    });
  });

  group('Money.withSymbol', () {
    test('prefixes rupees and keeps Western digits', () {
      expect(const Money('4500.00').withSymbol(), 'Rs 4,500.00');
    });
  });

  group('Money.isZero', () {
    test('recognises the shapes the API sends for nothing owed', () {
      expect(const Money('0.00').isZero, isTrue);
      expect(const Money('0').isZero, isTrue);
      expect(const Money('0.0000').isZero, isTrue);
      expect(const Money('-0.00').isZero, isTrue);
      expect(const Money('0.01').isZero, isFalse);
    });
  });

  group('Money.fromJson', () {
    test('takes the server string as it is', () {
      expect(Money.fromJson('267600.00').raw, '267600.00');
    });

    test('treats a missing amount as zero rather than throwing', () {
      expect(Money.fromJson(null).raw, '0.00');
    });
  });

  test('Money has no arithmetic', () {
    // There is deliberately no `+` on the type. If this test ever needs
    // changing, the change belongs on the server: every total, subtotal,
    // share and percentage the app shows is computed there.
    const a = Money('1.00');
    const b = Money('2.00');
    expect(a == b, isFalse);
    expect(a == const Money('1.00'), isTrue);
  });

  group('comparison is ordering, never an amount', () {
    test('a smaller balance compares smaller', () {
      expect(const Money('260100.00').isLessThan(const Money('263100.00')),
          isTrue);
      expect(const Money('263100.00').isLessThan(const Money('260100.00')),
          isFalse);
    });

    test('equal amounts compare equal', () {
      expect(
        const Money('263100.00').compareMagnitude(const Money('263100.00')),
        0,
      );
    });
  });
}
