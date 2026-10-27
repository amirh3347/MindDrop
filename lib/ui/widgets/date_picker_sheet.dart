import 'package:flutter/material.dart';

import '../../core/calendar.dart';
import '../../core/l10n.dart';
import '../common.dart';

/// Result of [pickDate]. A null [date] means the user cleared the date.
class DatePick {
  const DatePick(this.date);

  final DateTime? date;
}

/// Next start of the week (Saturday for Jalali/Persian, Monday otherwise).
DateTime nextWeekStart(AppCalendar cal, DateTime from) {
  final today = dateOnly(from);
  var delta = (cal.firstWeekday - today.weekday) % 7;
  if (delta == 0) delta = 7;
  return addDays(today, delta);
}

/// Bottom sheet with quick picks and a month calendar that follows the
/// user's calendar system (Jalali or Gregorian). Returns null when dismissed.
Future<DatePick?> pickDate(BuildContext context, {DateTime? initial}) {
  final cal = calendarOf(context, listen: false);
  return showModalBottomSheet<DatePick>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _DatePickerSheet(calendar: cal, initial: initial),
  );
}

class _DatePickerSheet extends StatefulWidget {
  const _DatePickerSheet({required this.calendar, this.initial});

  final AppCalendar calendar;
  final DateTime? initial;

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  late int _year;
  late int _month;

  AppCalendar get cal => widget.calendar;

  @override
  void initState() {
    super.initState();
    final (year, month) = cal.yearMonthOf(widget.initial ?? DateTime.now());
    _year = year;
    _month = month;
  }

  void _shift(int delta) {
    final (year, month) = cal.shiftMonth(_year, _month, delta);
    setState(() {
      _year = year;
      _month = month;
    });
  }

  void _select(DateTime? date) => Navigator.pop(context, DatePick(date));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final today = dateOnly(DateTime.now());
    final selected = widget.initial == null ? null : dateOnly(widget.initial!);

    final first = cal.dateFor(_year, _month, 1);
    final offset = (first.weekday - cal.firstWeekday) % 7;
    final days = cal.daysInMonth(_year, _month);
    final weekdays = [for (var i = 0; i < 7; i++) (cal.firstWeekday - 1 + i) % 7 + 1];

    Widget quick(String label, DateTime? date, IconData icon) => ActionChip(
          avatar: Icon(icon, size: 18),
          label: Text(label),
          onPressed: () => _select(date),
        );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                quick(l.t('dueToday'), today, Icons.today_rounded),
                quick(l.t('dueTomorrow'), addDays(today, 1), Icons.wb_sunny_outlined),
                quick(l.t('dueNextWeek'), nextWeekStart(cal, today), Icons.date_range_rounded),
                if (widget.initial != null) quick(l.t('noDate'), null, Icons.event_busy_rounded),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  onPressed: () => _shift(-1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    cal.monthTitle(_year, _month),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => _shift(1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final wd in weekdays)
                  Expanded(
                    child: Center(
                      child: Text(
                        cal.weekdayShort(wd),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
              itemCount: offset + days,
              itemBuilder: (context, index) {
                if (index < offset) return const SizedBox.shrink();
                final day = index - offset + 1;
                final date = cal.dateFor(_year, _month, day);
                final isSelected = selected != null && isSameDay(date, selected);
                final isToday = isSameDay(date, today);
                final isPast = date.isBefore(today);
                return Padding(
                  padding: const EdgeInsets.all(3),
                  child: Material(
                    color: isSelected ? scheme.primary : Colors.transparent,
                    shape: CircleBorder(
                      side: isToday && !isSelected
                          ? BorderSide(color: scheme.primary, width: 1.5)
                          : BorderSide.none,
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _select(date),
                      child: Center(
                        child: Text(
                          cal.digits(day),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? scheme.onPrimary
                                : isPast
                                    ? scheme.onSurfaceVariant.withValues(alpha: 0.55)
                                    : scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
