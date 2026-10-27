import 'package:flutter_test/flutter_test.dart';
import 'package:minddrop/core/l10n.dart';

void main() {
  test('Persian and English define the same keys', () {
    final missingInFa = L10n.englishKeys.difference(L10n.persianKeys);
    final missingInEn = L10n.persianKeys.difference(L10n.englishKeys);
    expect(missingInFa, isEmpty, reason: 'missing Persian translations');
    expect(missingInEn, isEmpty, reason: 'missing English strings');
  });

  test('placeholders are filled with localized digits', () {
    expect(const L10n('en').f('summaryToday', {'count': 3}), '3 due today');
    expect(const L10n('fa').f('summaryToday', {'count': 3}), '۳ کار برای امروز');
  });

  test('unknown keys fall back to the key itself', () {
    expect(const L10n('fa').t('doesNotExist'), 'doesNotExist');
  });
}
