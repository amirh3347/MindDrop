import '../models/task.dart';
import 'calendar.dart';

/// Result of parsing a quick-capture line such as
/// `Buy milk tomorrow #home !!` → title "Buy milk", due tomorrow,
/// tag "home", medium priority.
class QuickParseResult {
  const QuickParseResult({
    required this.title,
    this.tags = const [],
    this.priority,
    this.due,
  });

  final String title;
  final List<String> tags;
  final TaskPriority? priority;

  /// Date only (midnight), or null.
  final DateTime? due;

  bool get hasExtras => tags.isNotEmpty || priority != null || due != null;
}

final RegExp _tagPattern =
    RegExp(r'^#([\p{L}\p{M}\p{N}_\-\u200C]+)$', unicode: true);
final RegExp _priorityPattern = RegExp(r'^[!！]{1,3}$');
const _trailingPunctuation = '.,;:!?،؛؟';

const _todayWords = {'today', 'امروز'};
const _tomorrowWords = {'tomorrow', 'فردا'};
const _dayAfterWords = {'پسفردا', 'پس‌فردا'};

QuickParseResult quickParse(
  String input, {
  DateTime? now,
  bool parseDates = true,
}) {
  final today = dateOnly(now ?? DateTime.now());
  final words = input.trim().split(RegExp(r'\s+'));
  final kept = <String>[];
  final tags = <String>[];
  TaskPriority? priority;
  DateTime? due;

  for (final word in words) {
    if (word.isEmpty) continue;

    var bare = word;
    while (bare.length > 1 &&
        _trailingPunctuation.contains(bare[bare.length - 1]) &&
        !_priorityPattern.hasMatch(bare)) {
      bare = bare.substring(0, bare.length - 1);
    }

    final tag = _tagPattern.firstMatch(bare);
    if (tag != null) {
      final name = tag.group(1)!;
      if (!tags.contains(name)) tags.add(name);
      continue;
    }

    if (_priorityPattern.hasMatch(word)) {
      priority = switch (word.length) {
        1 => TaskPriority.low,
        2 => TaskPriority.medium,
        _ => TaskPriority.high,
      };
      continue;
    }

    if (parseDates && due == null) {
      final lower = bare.toLowerCase();
      if (_todayWords.contains(lower)) {
        due = today;
        continue;
      }
      if (_tomorrowWords.contains(lower)) {
        due = addDays(today, 1);
        continue;
      }
      if (_dayAfterWords.contains(lower)) {
        due = addDays(today, 2);
        continue;
      }
    }

    kept.add(word);
  }

  final title = kept.join(' ').trim();
  return QuickParseResult(
    // Never produce an empty title: fall back to what the user typed.
    title: title.isEmpty ? input.trim() : title,
    tags: tags,
    priority: priority,
    due: due,
  );
}
