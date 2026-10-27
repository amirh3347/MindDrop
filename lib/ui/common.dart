import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/calendar.dart';
import '../core/l10n.dart';
import '../data/settings_store.dart';
import '../models/task.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

/// Shows a floating snackbar, replacing any visible one.
/// Snackbars with an action are closed after [duration] explicitly, so they
/// never linger on screen.
void showSnack(
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = messengerKey.currentState;
  if (messenger == null) return;
  messenger.clearSnackBars();
  final controller = messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      action: actionLabel == null
          ? null
          : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
    ),
  );
  if (actionLabel != null) {
    var closed = false;
    controller.closed.then((_) => closed = true);
    Timer(duration, () {
      if (!closed) controller.close();
    });
  }
}

void haptic(BuildContext context, {bool strong = false}) {
  if (!context.read<SettingsStore>().haptics) return;
  strong ? HapticFeedback.mediumImpact() : HapticFeedback.selectionClick();
}

/// The user's calendar. Pass `listen: false` outside of `build`.
AppCalendar calendarOf(BuildContext context, {bool listen = true}) {
  final settings = Provider.of<SettingsStore>(context, listen: listen);
  return AppCalendar(
    jalali: settings.calendar == CalendarSystem.jalali,
    lang: settings.language,
  );
}

/// "Today", "Tomorrow · 14:30", "5 Aban" …
String relativeDate(DateTime date, L10n l, AppCalendar cal, {bool withTime = false}) {
  final today = dateOnly(DateTime.now());
  final day = dateOnly(date);
  final String label;
  if (day == today) {
    label = l.t('today');
  } else if (day == addDays(today, 1)) {
    label = l.t('tomorrow');
  } else if (day == addDays(today, -1)) {
    label = l.t('yesterday');
  } else {
    label = cal.shortDate(date);
  }
  return withTime ? '$label · ${cal.time(date)}' : label;
}

String priorityLabel(TaskPriority p, L10n l) => switch (p) {
      TaskPriority.none => l.t('prioNone'),
      TaskPriority.low => l.t('prioLow'),
      TaskPriority.medium => l.t('prioMedium'),
      TaskPriority.high => l.t('prioHigh'),
    };

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final l = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: message == null ? null : Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.t('cancel')),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Time picker that always uses 24h format (common in Iran and unambiguous).
Future<TimeOfDay?> pickTime(BuildContext context, TimeOfDay initial) {
  return showTimePicker(
    context: context,
    initialTime: initial,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
  );
}

/// Highlights occurrences of [terms] inside [text].
List<TextSpan> highlightSpans(String text, List<String> terms, TextStyle highlight) {
  if (terms.isEmpty) return [TextSpan(text: text)];
  final lower = text.toLowerCase();
  final marks = List<bool>.filled(text.length, false);
  for (final term in terms) {
    if (term.isEmpty) continue;
    var start = lower.indexOf(term);
    while (start >= 0) {
      for (var i = start; i < start + term.length && i < marks.length; i++) {
        marks[i] = true;
      }
      start = lower.indexOf(term, start + term.length);
    }
  }
  final spans = <TextSpan>[];
  var i = 0;
  while (i < text.length) {
    final marked = marks[i];
    var j = i;
    while (j < text.length && marks[j] == marked) {
      j++;
    }
    final part = text.substring(i, j);
    spans.add(marked ? TextSpan(text: part, style: highlight) : TextSpan(text: part));
    i = j;
  }
  return spans;
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.count, this.color, this.trailing});

  final String text;
  final int? count;
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 18, 6, 8),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                context.l10n.n(count!),
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: c),
              ),
            ),
          ],
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
