import '../core/calendar.dart';
import '../core/text_utils.dart';
import '../models/task.dart';

/// The four tabs of the home screen.
enum TaskView { inbox, today, upcoming, done }

enum SectionKind { pinned, overdue, today, upcoming, someday, completed, day }

class TaskSection {
  const TaskSection(this.kind, this.tasks, {this.date});

  final SectionKind kind;
  final List<Task> tasks;

  /// Set for [SectionKind.day] sections.
  final DateTime? date;
}

bool isOverdue(Task t, DateTime now) {
  final due = t.dueAt;
  if (t.done || due == null) return false;
  return t.hasDueTime ? due.isBefore(now) : dateOnly(due).isBefore(dateOnly(now));
}

bool isDueToday(Task t, DateTime now) {
  final due = t.dueAt;
  return due != null && isSameDay(due, now);
}

/// Most important first: priority, then earliest due, then newest.
int compareSmart(Task a, Task b) {
  final p = b.priority.index.compareTo(a.priority.index);
  if (p != 0) return p;
  final ad = a.dueAt, bd = b.dueAt;
  if (ad != null && bd != null) {
    final d = ad.compareTo(bd);
    if (d != 0) return d;
  } else if (ad != null) {
    return -1;
  } else if (bd != null) {
    return 1;
  }
  return b.createdAt.compareTo(a.createdAt);
}

int _compareDue(Task a, Task b) {
  final d = a.dueAt!.compareTo(b.dueAt!);
  return d != 0 ? d : compareSmart(a, b);
}

int _compareCompleted(Task a, Task b) =>
    (b.completedAt ?? b.updatedAt).compareTo(a.completedAt ?? a.updatedAt);

List<TaskSection> buildSections(
  List<Task> all,
  TaskView view,
  DateTime now, {
  bool showCompleted = false,
  String? tag,
}) {
  final tasks = tag == null ? all : all.where((t) => t.tags.contains(tag)).toList();
  final today = dateOnly(now);
  final active = tasks.where((t) => !t.done).toList();
  final sections = <TaskSection>[];
  void add(SectionKind kind, List<Task> list, Comparator<Task> cmp, {DateTime? date}) {
    if (list.isEmpty) return;
    list.sort(cmp);
    sections.add(TaskSection(kind, list, date: date));
  }

  switch (view) {
    case TaskView.inbox:
      final rest = active.where((t) => !t.pinned);
      add(SectionKind.pinned, active.where((t) => t.pinned).toList(), compareSmart);
      add(SectionKind.overdue, rest.where((t) => isOverdue(t, now)).toList(), _compareDue);
      add(
        SectionKind.today,
        rest.where((t) => isDueToday(t, now) && !isOverdue(t, now)).toList(),
        _compareDue,
      );
      add(
        SectionKind.upcoming,
        rest.where((t) => t.dueAt != null && dateOnly(t.dueAt!).isAfter(today)).toList(),
        _compareDue,
      );
      add(SectionKind.someday, rest.where((t) => t.dueAt == null).toList(), compareSmart);
      if (showCompleted) {
        final completed = tasks.where((t) => t.done).toList()..sort(_compareCompleted);
        add(SectionKind.completed, completed.take(200).toList(), _compareCompleted);
      }
    case TaskView.today:
      add(SectionKind.overdue, active.where((t) => isOverdue(t, now)).toList(), _compareDue);
      add(
        SectionKind.today,
        active.where((t) => isDueToday(t, now) && !isOverdue(t, now)).toList(),
        _compareDue,
      );
      add(
        SectionKind.completed,
        tasks.where((t) => t.done && t.completedAt != null && isSameDay(t.completedAt!, now)).toList(),
        _compareCompleted,
      );
    case TaskView.upcoming:
      final dueByDay = <DateTime, List<Task>>{};
      for (final t in active) {
        final due = t.dueAt;
        if (due == null || !dateOnly(due).isAfter(today)) continue;
        dueByDay.putIfAbsent(dateOnly(due), () => []).add(t);
      }
      final dueDays = dueByDay.keys.toList()..sort();
      for (final day in dueDays) {
        add(SectionKind.day, dueByDay[day]!, _compareDue, date: day);
      }
    case TaskView.done:
      final doneByDay = <DateTime, List<Task>>{};
      for (final t in tasks.where((t) => t.done)) {
        doneByDay.putIfAbsent(dateOnly(t.completedAt ?? t.updatedAt), () => []).add(t);
      }
      final doneDays = doneByDay.keys.toList()..sort((a, b) => b.compareTo(a));
      for (final day in doneDays) {
        add(SectionKind.day, doneByDay[day]!, _compareCompleted, date: day);
      }
  }
  return sections;
}

/// Number of open tasks that are due today or overdue.
int dueTodayCount(List<Task> tasks, DateTime now) => tasks
    .where((t) => !t.done && (isDueToday(t, now) || isOverdue(t, now)))
    .length;

/// Tags ordered by how often they are used.
List<String> tagsByUsage(List<Task> tasks) {
  final counts = <String, int>{};
  for (final t in tasks) {
    for (final tag in t.tags) {
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
  }
  final tags = counts.keys.toList()
    ..sort((a, b) {
      final c = counts[b]!.compareTo(counts[a]!);
      return c != 0 ? c : a.compareTo(b);
    });
  return tags;
}

// ---------------------------------------------------------------- search ----

enum StatusFilter { all, active, done }

class SearchQuery {
  const SearchQuery({
    this.text = '',
    this.status = StatusFilter.all,
    this.priorities = const {},
    this.tags = const {},
  });

  final String text;
  final StatusFilter status;
  final Set<TaskPriority> priorities;
  final Set<String> tags;

  bool get isEmpty =>
      text.trim().isEmpty && status == StatusFilter.all && priorities.isEmpty && tags.isEmpty;
}

String _haystack(Task t) => normalizeForSearch([
      t.title,
      t.note,
      ...t.tags.map((tag) => '#$tag'),
      ...t.subtasks.map((s) => s.title),
    ].join('\n'));

List<Task> searchTasks(List<Task> tasks, SearchQuery query) {
  final terms = searchTerms(query.text);
  final results = tasks.where((t) {
    if (query.status == StatusFilter.active && t.done) return false;
    if (query.status == StatusFilter.done && !t.done) return false;
    if (query.priorities.isNotEmpty && !query.priorities.contains(t.priority)) return false;
    if (query.tags.isNotEmpty && !query.tags.every(t.tags.contains)) return false;
    if (terms.isEmpty) return true;
    final hay = _haystack(t);
    return terms.every(hay.contains);
  }).toList();

  results.sort((a, b) {
    if (a.done != b.done) return a.done ? 1 : -1;
    return b.updatedAt.compareTo(a.updatedAt);
  });
  return results;
}

// ----------------------------------------------------------------- stats ----

class TaskStats {
  const TaskStats({
    required this.total,
    required this.active,
    required this.done,
    required this.overdue,
    required this.streak,
    required this.last7Days,
    required this.topTags,
  });

  final int total;
  final int active;
  final int done;
  final int overdue;

  /// Consecutive days (ending today, or yesterday) with at least one completion.
  final int streak;

  /// Completions per day, oldest first; the last entry is today.
  final List<int> last7Days;
  final List<MapEntry<String, int>> topTags;

  double get completionRate => total == 0 ? 0 : done / total;
}

TaskStats computeStats(List<Task> tasks, DateTime now) {
  final today = dateOnly(now);
  final completedDays = <DateTime>{};
  final last7 = List<int>.filled(7, 0);
  for (final t in tasks) {
    final c = t.completedAt;
    if (!t.done || c == null) continue;
    final day = dateOnly(c);
    completedDays.add(day);
    // Rounding tolerates the 23h/25h days around DST switches.
    final diff = (today.difference(day).inMinutes / 1440).round();
    if (diff >= 0 && diff < 7) last7[6 - diff]++;
  }

  var streak = 0;
  var cursor = completedDays.contains(today) ? today : addDays(today, -1);
  while (completedDays.contains(cursor)) {
    streak++;
    cursor = addDays(cursor, -1);
  }

  final tagCounts = <String, int>{};
  for (final t in tasks) {
    for (final tag in t.tags) {
      tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
    }
  }
  final topTags = tagCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final done = tasks.where((t) => t.done).length;
  return TaskStats(
    total: tasks.length,
    active: tasks.length - done,
    done: done,
    overdue: tasks.where((t) => isOverdue(t, now)).length,
    streak: streak,
    last7Days: last7,
    topTags: topTags.take(5).toList(),
  );
}
