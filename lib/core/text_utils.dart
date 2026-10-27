/// Text helpers shared by search, parsing and display.
library;

const _persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

/// Converts Latin digits to Persian ones when [lang] is `fa`.
String localizeDigits(String input, String lang) {
  if (lang != 'fa') return input;
  final b = StringBuffer();
  for (final unit in input.codeUnits) {
    if (unit >= 0x30 && unit <= 0x39) {
      b.write(_persianDigits[unit - 0x30]);
    } else {
      b.writeCharCode(unit);
    }
  }
  return b.toString();
}

/// Folds text so that searching is forgiving:
/// lowercase, Arabic/Persian letter variants unified (ي→ی, ك→ک, …),
/// Persian/Arabic digits → Latin, diacritics, tatweel and ZWNJ removed.
String normalizeForSearch(String input) {
  final b = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    switch (rune) {
      case 0x064A || 0x0649: // ي ى
        b.writeCharCode(0x06CC); // ی
      case 0x0643: // ك
        b.writeCharCode(0x06A9); // ک
      case 0x0629: // ة
        b.writeCharCode(0x0647); // ه
      case 0x0622 || 0x0623 || 0x0625: // آ أ إ
        b.writeCharCode(0x0627); // ا
      case 0x0624: // ؤ
        b.writeCharCode(0x0648); // و
      case 0x200C || 0x200D || 0x200E || 0x200F || 0x0640:
        break; // ZWNJ, ZWJ, direction marks, tatweel
      default:
        if (rune >= 0x06F0 && rune <= 0x06F9) {
          b.writeCharCode(0x30 + rune - 0x06F0);
        } else if (rune >= 0x0660 && rune <= 0x0669) {
          b.writeCharCode(0x30 + rune - 0x0660);
        } else if ((rune >= 0x064B && rune <= 0x065F) || rune == 0x0670) {
          // Arabic diacritics: skip.
        } else {
          b.writeCharCode(rune);
        }
    }
  }
  return b.toString();
}

/// Splits a search query into normalized, non-empty words.
List<String> searchTerms(String query) => normalizeForSearch(query)
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty)
    .toList();
