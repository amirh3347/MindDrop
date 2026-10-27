import 'package:flutter_test/flutter_test.dart';
import 'package:minddrop/data/backup.dart';
import 'package:minddrop/models/task.dart';

Task _task(String id, String title, {DateTime? updated}) {
  final t = DateTime(2026, 1, 1);
  return Task(id: id, title: title, createdAt: t, updatedAt: updated ?? t);
}

void main() {
  test('encode → decode round-trips every field', () {
    final task = Task(
      id: 'a1',
      title: 'سلام دنیا',
      note: 'line 1\nline 2',
      priority: TaskPriority.high,
      tags: const ['work', 'کار'],
      subtasks: const [Subtask(id: 's1', title: 'step', done: true)],
      done: true,
      pinned: true,
      createdAt: DateTime(2026, 1, 1, 10),
      updatedAt: DateTime(2026, 1, 2, 11),
      completedAt: DateTime(2026, 1, 2, 11),
      dueAt: DateTime(2026, 1, 3, 9, 30),
      hasDueTime: true,
      remindAt: DateTime(2026, 1, 3, 9, 30),
    );
    final decoded = decodeBackup(encodeBackup([task])).tasks.single;
    expect(decoded.toJson(), task.toJson());
  });

  test('rejects garbage and foreign files', () {
    expect(() => decodeBackup('not json'),
        throwsA(isA<BackupException>().having((e) => e.error, 'error', BackupError.notJson)));
    expect(() => decodeBackup('{"app":"Other","tasks":[]}'),
        throwsA(isA<BackupException>().having((e) => e.error, 'error', BackupError.notMindDrop)));
    expect(() => decodeBackup('{"hello":1}'),
        throwsA(isA<BackupException>().having((e) => e.error, 'error', BackupError.notMindDrop)));
    expect(() => decodeBackup('{"app":"MindDrop","format":99,"tasks":[]}'),
        throwsA(isA<BackupException>().having((e) => e.error, 'error', BackupError.newerVersion)));
  });

  test('is lenient with missing fields and skips invalid tasks', () {
    final data = decodeBackup('''
      {"app":"MindDrop","format":1,"tasks":[
        {"id":"x","title":"Only a title"},
        {"id":"y","title":"   "},
        {"id":"x","title":"duplicate id"},
        "nonsense"
      ]}
    ''');
    expect(data.tasks, hasLength(1));
    expect(data.tasks.single.title, 'Only a title');
    expect(data.tasks.single.priority, TaskPriority.none);
  });

  test('merge adds new tasks and keeps the newest version', () {
    final existing = [
      _task('a', 'old A', updated: DateTime(2026, 1, 1)),
      _task('b', 'B', updated: DateTime(2026, 3, 1)),
    ];
    final incoming = [
      _task('a', 'new A', updated: DateTime(2026, 2, 1)),
      _task('b', 'stale B', updated: DateTime(2026, 2, 1)),
      _task('c', 'C'),
    ];
    final result = mergeTasks(existing, incoming);
    final byId = {for (final t in result.tasks) t.id: t.title};
    expect(byId, {'a': 'new A', 'b': 'B', 'c': 'C'});
    expect(result.added, 1);
    expect(result.updated, 1);
  });

  test('backup file name is sortable', () {
    expect(backupFileName(DateTime(2026, 3, 4, 5, 6)), 'minddrop-backup-2026-03-04-0506.json');
  });
}
