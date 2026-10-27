import 'package:flutter_test/flutter_test.dart';
import 'package:minddrop/core/calendar.dart';

void main() {
  group('Jalali conversion', () {
    test('Nowruz 1404 is 21 March 2025', () {
      expect(gregorianToJalali(2025, 3, 21), [1404, 1, 1]);
      expect(jalaliToGregorian(1404, 1, 1), [2025, 3, 21]);
    });

    test('known dates', () {
      expect(gregorianToJalali(2026, 10, 27), [1405, 8, 5]);
      expect(gregorianToJalali(2024, 3, 20), [1403, 1, 1]);
      expect(gregorianToJalali(1979, 2, 11), [1357, 11, 22]);
    });

    test('round-trips every day for several years', () {
      var day = DateTime.utc(2020, 1, 1);
      final end = DateTime.utc(2032, 1, 1);
      while (day.isBefore(end)) {
        final j = gregorianToJalali(day.year, day.month, day.day);
        expect(jalaliToGregorian(j[0], j[1], j[2]), [day.year, day.month, day.day]);
        day = day.add(const Duration(days: 1));
      }
    });

    test('month lengths', () {
      expect(jalaliMonthLength(1404, 1), 31);
      expect(jalaliMonthLength(1404, 7), 30);
      expect(jalaliMonthLength(1403, 12), 30); // 1403 is a leap year
      expect(jalaliMonthLength(1404, 12), 29);
    });
  });

  group('AppCalendar', () {
    test('formats Persian dates with Persian digits', () {
      const cal = AppCalendar(jalali: true, lang: 'fa');
      final d = DateTime(2026, 10, 27);
      expect(cal.shortDate(d, now: d), '۵ آبان');
      expect(cal.fullDate(d), 'سه‌شنبه ۵ آبان ۱۴۰۵');
      expect(cal.time(DateTime(2026, 1, 1, 9, 5)), '۰۹:۰۵');
    });

    test('formats English Gregorian dates', () {
      const cal = AppCalendar(jalali: false, lang: 'en');
      final d = DateTime(2026, 10, 27);
      expect(cal.shortDate(d, now: d), 'Oct 27');
      expect(cal.shortDate(d, now: DateTime(2025, 1, 1)), 'Oct 27, 2026');
      expect(cal.fullDate(d), 'Tuesday, October 27, 2026');
    });

    test('month navigation wraps years', () {
      const cal = AppCalendar(jalali: true, lang: 'fa');
      expect(cal.shiftMonth(1404, 12, 1), (1405, 1));
      expect(cal.shiftMonth(1405, 1, -1), (1404, 12));
      expect(cal.dateFor(1405, 8, 5), DateTime(2026, 10, 27));
      expect(cal.daysInMonth(1405, 8), 30);
    });

    test('week starts on Saturday for Persian, Monday for English', () {
      expect(const AppCalendar(jalali: true, lang: 'fa').firstWeekday, DateTime.saturday);
      expect(const AppCalendar(jalali: false, lang: 'en').firstWeekday, DateTime.monday);
    });
  });
}
