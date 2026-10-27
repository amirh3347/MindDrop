import 'package:flutter_test/flutter_test.dart';
import 'package:minddrop/data/task_query.dart';
import 'package:minddrop/models/task.dart';

final now = DateTime(2026, 10, 27, 12);

Task _t(
  String title, {
  DateTime? due,
  bool done = false,
  bool pinned = false,
  TaskPriority priority = TaskPriority.none,
  List<String> tags = const [],
  DateTime? completedAt,
  String note = '',
}) {
  final created = DateTime(2026, 10, 1);
  return Task(
    id: title,
    title: title,
    note: note,
    createdAt: created,
    updatedAt: created,
  ).copyWith(
    dueAt: due,
    done: done,
    pinned: pinned,
    priority: priority,
    tags: tags,
    completedAt: completedAt ?? (done ? now : null),
  );
}

void main() {
  final tasks = [
    _t('pinned', pinned: true),
    _t('late', due: DateTime(2026, 10, 25)),
    _t('today low', due: DateTime(2026, 10, 27), priority: TaskPriority.low),
    _t('today high', due: DateTime(2026, 10, 27), priority: TaskPriority.high),
    _t('next week', due: DateTime(2026, 11, 3), tags: ['work']),
    _t('tomorrow', due: DateTime(2026, 10, 28)),
    _t('someday', tags: ['work', 'ideas'], note: 'Read about Flutter'),
    _t('finished', done: true, completedAt: DateTime(2026, 10, 27, 9)),
    _t('finished earlier', done: true, completedAt: DateTime(2026, 10, 26, 9)),
  ];

  List<String> titles(TaskSection s) => s.tasks.map((t) => t.title).toList();

  test('inbox groups open tasks into sections', () {
    final sections = buildSections(tasks, TaskView.inbox, now);
    expect(sections.map((s) => s.kind), [
      SectionKind.pinned,
      SectionKind.overdue,
      SectionKind.today,
      SectionKind.upcoming,
      SectionKind.someday,
    ]);
    expect(titles(sections[2]), ['today high', 'today low']);
    expect(titles(sections[3]), ['tomorrow', 'next week']);
  });

  test('inbox can include completed tasks', () {
    final sections = buildSections(tasks, TaskView.inbox, now, showCompleted: true);
    expect(sections.last.kind, SectionKind.completed);
    expect(titles(sections.last), ['finished', 'finished earlier']);
  });

  test('today shows overdue, due today and done today', () {
    final sections = buildSections(tasks, TaskView.today, now);
    expect(sections.map((s) => s.kind),
        [SectionKind.overdue, SectionKind.today, SectionKind.completed]);
    expect(titles(sections.last), ['finished']);
  });

  test('upcoming groups by day', () {
    final sections = buildSections(tasks, TaskView.upcoming, now);
    expect(sections.map((s) => s.date), [DateTime(2026, 10, 28), DateTime(2026, 11, 3)]);
  });

  test('done groups by completion day, newest first', () {
    final sections = buildSections(tasks, TaskView.done, now);
    expect(sections.map((s) => s.date), [DateTime(2026, 10, 27), DateTime(2026, 10, 26)]);
  });

  test('tag filter', () {
    final sections = buildSections(tasks, TaskView.inbox, now, tag: 'work');
    final all = sections.expand((s) => s.tasks).map((t) => t.title).toSet();
    expect(all, {'next week', 'someday'});
  });

  test('due today count includes overdue', () {
    expect(dueTodayCount(tasks, now), 3);
  });

  test('tags ordered by usage', () {
    expect(tagsByUsage(tasks), ['work', 'ideas']);
  });

  group('search', () {
    test('matches title, note and tags', () {
      expect(searchTasks(tasks, const SearchQuery(text: 'flutter')).single.title, 'someday');
      expect(searchTasks(tasks, const SearchQuery(text: '#ideas')).single.title, 'someday');
      expect(searchTasks(tasks, const SearchQuery(text: 'TODAY')).length, 2);
    });

    test('filters by status, priority and tag', () {
      expect(searchTasks(tasks, const SearchQuery(status: StatusFilter.done)).length, 2);
      expect(
        searchTasks(tasks, const SearchQuery(priorities: {TaskPriority.high})).single.title,
        'today high',
      );
      expect(searchTasks(tasks, const SearchQuery(tags: {'work', 'ideas'})).single.title, 'someday');
    });
  });

  test('stats', () {
    final stats = computeStats(tasks, now);
    expect(stats.total, tasks.length);
    expect(stats.done, 2);
    expect(stats.overdue, 1);
    expect(stats.streak, 2);
    expect(stats.last7Days, [0, 0, 0, 0, 0, 1, 1]);
    expect(stats.topTags.first.key, 'work');
  });
}
