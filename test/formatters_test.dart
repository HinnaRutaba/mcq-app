import 'package:flutter_test/flutter_test.dart';
import 'package:mcq_app/core/utils/formatters.dart';

void main() {
  test('span keeps the two largest units', () {
    expect(Formatters.span(const Duration(seconds: 33)), '33s');
    expect(Formatters.span(const Duration(minutes: 5)), '5m');
    expect(Formatters.span(const Duration(hours: 1, minutes: 20)), '1h 20m');
    expect(
      Formatters.span(const Duration(days: 422, hours: 22, minutes: 40)),
      '422d 22h',
    );
    expect(Formatters.span(Duration.zero), '0s');
  });
}
