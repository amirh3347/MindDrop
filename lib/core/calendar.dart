import 'text_utils.dart';

/// A date in the Solar Hijri (Jalali / Persian) calendar.
class JalaliDate {
  const JalaliDate(this.year, this.month, this.day);

  factory JalaliDate.fromDateTime(DateTime date) {
    final r = gregorianToJalali(date.year, date.month, date.day);
    return JalaliDate(r[0], r[1], r[2]);
  }

  final int year;
  final int month;
  final int day;

  DateTime toDateTime() {
    final g = jalaliToGregorian(year, month, day);
    return DateTime(g[0], g[1], g[2]);
  }

  @override
  bool operator ==(Object other) =>
      other is JalaliDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => '$year/$month/$day';
}

/// Gregorian → Jalali. Returns `[year, month, day]`.
List<int> gregorianToJalali(int gy, int gm, int gd) {
  const gDaysBeforeMonth = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
  final gy2 = gm > 2 ? gy + 1 : gy;
  var days = 355666 +
      365 * gy +
      (gy2 + 3) ~/ 4 -
      (gy2 + 99) ~/ 100 +
      (gy2 + 399) ~/ 400 +
      gd +
      gDaysBeforeMonth[gm - 1];
  var jy = -1595 + 33 * (days ~/ 12053);
  days %= 12053;
  jy += 4 * (days ~/ 1461);
  days %= 1461;
  if (days > 365) {
    jy += (days - 1) ~/ 365;
    days = (days - 1) % 365;
  }
  final int jm;
  final int jd;
  if (days < 186) {
    jm = 1 + days ~/ 31;
    jd = 1 + days % 31;
  } else {
    jm = 7 + (days - 186) ~/ 30;
    jd = 1 + (days - 186) % 30;
  }
  return [jy, jm, jd];
}

/// Jalali → Gregorian. Returns `[year, month, day]`.
List<int> jalaliToGregorian(int jy, int jm, int jd) {
  jy += 1595;
  var days = -355668 +
      365 * jy +
      (jy ~/ 33) * 8 +
      ((jy % 33) + 3) ~/ 4 +
      jd +
      (jm < 7 ? (jm - 1) * 31 : (jm - 7) * 30 + 186);
  var gy = 400 * (days ~/ 146097);
  days %= 146097;
  if (days > 36524) {
    days--;
    gy += 100 * (days ~/ 36524);
    days %= 36524;
    if (days >= 365) days++;
  }
  gy += 4 * (days ~/ 1461);
  days %= 1461;
  if (days > 365) {
    gy += (days - 1) ~/ 365;
    days = (days - 1) % 365;
  }
  var gd = days + 1;
  final leap = (gy % 4 == 0 && gy % 100 != 0) || gy % 400 == 0;
  final monthLengths = [0, 31, leap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  var gm = 0;
  while (gm < 13 && gd > monthLengths[gm]) {
    gd -= monthLengths[gm];
    gm++;
  }
  return [gy, gm, gd];
}

int jalaliMonthLength(int year, int month) {
  if (month <= 6) return 31;
  if (month <= 11) return 30;
  final a = jalaliToGregorian(year, 12, 1);
  final b = jalaliToGregorian(year + 1, 1, 1);
  return DateTime.utc(b[0], b[1], b[2])
      .difference(DateTime.utc(a[0], a[1], a[2]))
      .inDays;
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Adds whole calendar days, safe across DST changes.
DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days, d.hour, d.minute);

/// Calendar-aware formatting for the two supported calendars and languages.
class AppCalendar {
  const AppCalendar({required this.jalali, required this.lang});

  final bool jalali;
  final String lang;

  bool get _fa => lang == 'fa';

  static const _jalaliMonths = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', //
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
  ];
  static const _jalaliMonthsLatin = [
    'Farvardin', 'Ordibehesht', 'Khordad', 'Tir', 'Mordad', 'Shahrivar', //
    'Mehr', 'Aban', 'Azar', 'Dey', 'Bahman', 'Esfand',
  ];
  static const _gregorianMonthsFa = [
    'ژانویه', 'فوریه', 'مارس', 'آوریل', 'مه', 'ژوئن', //
    'ژوئیه', 'اوت', 'سپتامبر', 'اکتبر', 'نوامبر', 'دسامبر',
  ];
  static const _gregorianMonthsEn = [
    'January', 'February', 'March', 'April', 'May', 'June', //
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  // Indexed by DateTime.weekday - 1 (Monday first).
  static const _weekdaysFa = [
    'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه', 'شنبه', 'یکشنبه',
  ];
  static const _weekdaysEn = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  static const _weekdaysShortFa = ['د', 'س', 'چ', 'پ', 'ج', 'ش', 'ی'];
  static const _weekdaysShortEn = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  /// First day of the week as a [DateTime.weekday] value.
  int get firstWeekday => _fa || jalali ? DateTime.saturday : DateTime.monday;

  String digits(Object value) => localizeDigits('$value', lang);

  String monthName(int month) {
    if (jalali) return (_fa ? _jalaliMonths : _jalaliMonthsLatin)[month - 1];
    return (_fa ? _gregorianMonthsFa : _gregorianMonthsEn)[month - 1];
  }

  String weekdayName(DateTime d) =>
      (_fa ? _weekdaysFa : _weekdaysEn)[d.weekday - 1];

  String weekdayShort(int weekday) =>
      (_fa ? _weekdaysShortFa : _weekdaysShortEn)[weekday - 1];

  // ---- Month arithmetic in the active calendar (used by the date picker) ----

  /// `(year, month)` of [d] in the active calendar.
  (int, int) yearMonthOf(DateTime d) {
    if (!jalali) return (d.year, d.month);
    final j = JalaliDate.fromDateTime(d);
    return (j.year, j.month);
  }

  int dayOf(DateTime d) => jalali ? JalaliDate.fromDateTime(d).day : d.day;

  int daysInMonth(int year, int month) =>
      jalali ? jalaliMonthLength(year, month) : DateTime(year, month + 1, 0).day;

  DateTime dateFor(int year, int month, int day) =>
      jalali ? JalaliDate(year, month, day).toDateTime() : DateTime(year, month, day);

  (int, int) shiftMonth(int year, int month, int delta) {
    final index = year * 12 + (month - 1) + delta;
    return (index ~/ 12, index % 12 + 1);
  }

  String monthTitle(int year, int month) =>
      '${monthName(month)} ${digits(year)}';

  // ---- Formatting ----

  /// "5 Aban" / "۵ آبان" / "Oct 27" — year added when not the current one.
  String shortDate(DateTime d, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final (y, m) = yearMonthOf(d);
    final (cy, _) = yearMonthOf(current);
    final day = dayOf(d);
    final yearPart = y == cy ? '' : ' ${digits(y)}';
    if (_fa) return '${digits(day)} ${monthName(m)}$yearPart';
    final name = monthName(m);
    final short = jalali ? name : name.substring(0, 3);
    return '$short ${digits(day)}${y == cy ? '' : ', ${digits(y)}'}';
  }

  /// "Tuesday 5 Aban 1405" / "سه‌شنبه ۵ آبان ۱۴۰۵" / "Tuesday, October 27, 2026"
  String fullDate(DateTime d) {
    final (y, m) = yearMonthOf(d);
    final day = dayOf(d);
    if (_fa) return '${weekdayName(d)} ${digits(day)} ${monthName(m)} ${digits(y)}';
    if (jalali) return '${weekdayName(d)}, ${digits(day)} ${monthName(m)} ${digits(y)}';
    return '${weekdayName(d)}, ${monthName(m)} ${digits(day)}, ${digits(y)}';
  }

  String time(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return digits('$h:$m');
  }

  String dateTime(DateTime d) => '${shortDate(d)} · ${time(d)}';
}
