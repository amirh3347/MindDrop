import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/task.dart';
import 'backup.dart';

/// Where tasks are persisted.
abstract class TaskRepository {
  Future<List<Task>> load();
  Future<void> save(List<Task> tasks);
}

/// Stores all tasks in a single JSON file (same format as backups).
///
/// Writes go to a temp file that is then renamed over the real one, so a crash
/// mid-write can never leave a half-written database behind. The previous
/// version is kept as `tasks.json.bak` and used if the main file is unreadable.
class FileTaskRepository implements TaskRepository {
  FileTaskRepository(this.directory);

  final Directory directory;
  Future<void> _queue = Future.value();

  File get _main => File('${directory.path}/tasks.json');
  File get _backup => File('${directory.path}/tasks.json.bak');
  File get _temp => File('${directory.path}/tasks.json.tmp');

  @override
  Future<List<Task>> load() async {
    for (final file in [_main, _backup]) {
      if (!await file.exists()) continue;
      try {
        return decodeBackup(await file.readAsString()).tasks;
      } catch (e) {
        debugPrint('Could not read ${file.path}: $e');
        // Keep the unreadable file around for manual recovery.
        try {
          final stamp = DateTime.now().millisecondsSinceEpoch;
          await file.copy('${file.path}.corrupt-$stamp');
        } on FileSystemException {
          // Best effort only.
        }
      }
    }
    return [];
  }

  @override
  Future<void> save(List<Task> tasks) {
    final json = encodeBackup(tasks);
    // Serialise writes so they never interleave.
    _queue = _queue.then((_) => _write(json)).catchError((Object e) {
      debugPrint('Saving tasks failed: $e');
    });
    return _queue;
  }

  Future<void> _write(String json) async {
    await directory.create(recursive: true);
    if (await _main.exists()) await _main.copy(_backup.path);
    await _temp.writeAsString(json, flush: true);
    await _temp.rename(_main.path);
  }
}

/// In-memory repository for tests.
class MemoryTaskRepository implements TaskRepository {
  MemoryTaskRepository([List<Task>? initial]) : tasks = [...?initial];

  List<Task> tasks;
  int saves = 0;

  @override
  Future<List<Task>> load() async => [...tasks];

  @override
  Future<void> save(List<Task> tasks) async {
    this.tasks = [...tasks];
    saves++;
  }
}
