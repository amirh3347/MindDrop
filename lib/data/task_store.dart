import 'package:flutter/foundation.dart';

import '../models/task.dart';
import 'backup.dart';
import 'task_query.dart';
import 'task_repository.dart';

/// Schedules reminder notifications. Implemented by NotificationService;
/// absent in tests.
abstract class ReminderScheduler {
  Future<void> schedule(Task task);
  Future<void> cancel(Task task);
  Future<void> rescheduleAll(List<Task> tasks);
}

/// Single source of truth for tasks. Every mutation updates memory, notifies
/// listeners immediately and persists in the background.
class TaskStore extends ChangeNotifier {
  TaskStore(this._repo, {this.reminders});

  final TaskRepository _repo;
  final ReminderScheduler? reminders;

  List<Task> _tasks = [];
  bool _loaded = false;

  List<Task> get tasks => List.unmodifiable(_tasks);
  bool get loaded => _loaded;

  Future<void> load() async {
    _tasks = await _repo.load();
    _loaded = true;
    notifyListeners();
  }

  Task? byId(String id) {
    for (final t in _tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<String> get allTags => tagsByUsage(_tasks);

  void _changed() {
    notifyListeners();
    _repo.save(_tasks);
  }

  void add(Task task) {
    _tasks.add(task);
    _changed();
    reminders?.schedule(task);
  }

  /// Replaces the task with the same id and bumps its `updatedAt`.
  void update(Task task) {
    final i = _tasks.indexWhere((t) => t.id == task.id);
    if (i < 0) return;
    final updated = task.copyWith(updatedAt: DateTime.now());
    _tasks[i] = updated;
    _changed();
    reminders?.schedule(updated);
  }

  void setDone(Task task, bool done) {
    update(task.copyWith(done: done, completedAt: done ? DateTime.now() : null));
  }

  void toggleDone(Task task) => setDone(task, !task.done);

  void togglePinned(Task task) => update(task.copyWith(pinned: !task.pinned));

  void toggleSubtask(Task task, String subtaskId) {
    update(task.copyWith(subtasks: [
      for (final s in task.subtasks) s.id == subtaskId ? s.copyWith(done: !s.done) : s,
    ]));
  }

  Task duplicate(Task task) {
    final copy = task.duplicate();
    add(copy);
    return copy;
  }

  /// Removes tasks and returns them, so the caller can offer "undo".
  List<Task> remove(Iterable<String> ids) {
    final set = ids.toSet();
    final removed = _tasks.where((t) => set.contains(t.id)).toList();
    if (removed.isEmpty) return removed;
    _tasks.removeWhere((t) => set.contains(t.id));
    _changed();
    for (final t in removed) {
      reminders?.cancel(t);
    }
    return removed;
  }

  List<Task> delete(Task task) => remove([task.id]);

  List<Task> clearCompleted() => remove(_tasks.where((t) => t.done).map((t) => t.id));

  List<Task> deleteAll() => remove(_tasks.map((t) => t.id));

  /// Puts back tasks returned by [remove].
  void restore(List<Task> tasks) {
    final existing = _tasks.map((t) => t.id).toSet();
    final back = tasks.where((t) => !existing.contains(t.id)).toList();
    if (back.isEmpty) return;
    _tasks.addAll(back);
    _changed();
    for (final t in back) {
      reminders?.schedule(t);
    }
  }

  /// Imports tasks from a backup. With [replace] everything currently stored
  /// is dropped first; otherwise the two sets are merged.
  MergeResult importTasks(List<Task> incoming, {required bool replace}) {
    final result = replace
        ? MergeResult([...incoming], added: incoming.length, updated: 0)
        : mergeTasks(_tasks, incoming);
    _tasks = result.tasks;
    _changed();
    reminders?.rescheduleAll(_tasks);
    return result;
  }

  /// Re-registers every future reminder (e.g. after start-up or a restore).
  Future<void> rescheduleReminders() async => reminders?.rescheduleAll(_tasks);
}
