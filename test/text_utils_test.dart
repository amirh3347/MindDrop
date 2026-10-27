import 'package:flutter_test/flutter_test.dart';
import 'package:minddrop/core/text_utils.dart';

void main() {
  test('localizeDigits only converts for Persian', () {
    expect(localizeDigits('12:30', 'fa'), '۱۲:۳۰');
    expect(localizeDigits('12:30', 'en'), '12:30');
  });

  test('normalizeForSearch unifies Arabic and Persian variants', () {
    expect(normalizeForSearch('علي'), normalizeForSearch('علی'));
    expect(normalizeForSearch('كتاب'), normalizeForSearch('کتاب'));
    expect(normalizeForSearch('می‌روم'), 'میروم');
    expect(normalizeForSearch('۱۲۳'), '123');
    expect(normalizeForSearch('Hello'), 'hello');
  });

  test('searchTerms splits and normalizes', () {
    expect(searchTerms('  Buy   MILK '), ['buy', 'milk']);
    expect(searchTerms(''), isEmpty);
  });
}
