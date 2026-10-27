import 'dart:convert';

import '../models/task.dart';

/// Version of the JSON layout written by [encodeBackup].
/// Bump only for incompatible changes; readers accept anything up to this.
const int kBackupFormat = 1;
const String kBackupApp = 'MindDrop';

class BackupData {
  const BackupData({required this.tasks, this.exportedAt, this.format = kBackupFormat});

  final List<Task> tasks;
  final DateTime? exportedAt;
  final int format;
}

enum BackupError { notJson, notMindDrop, newerVersion }

class BackupException implements Exception {
  const BackupException(this.error);

  final BackupError error;

  @override
  String toString() => 'BackupException(${error.name})';
}

String encodeBackup(List<Task> tasks, {DateTime? now}) {
  return const JsonEncoder.withIndent('  ').convert({
    'app': kBackupApp,
    'format': kBackupFormat,
    'exportedAt': (now ?? DateTime.now()).toIso8601String(),
    'count': tasks.length,
    'tasks': [for (final t in tasks) t.toJson()],
  });
}

/// Parses a backup file. Throws [BackupException] if it isn't one.
BackupData decodeBackup(String raw) {
  final Object? json;
  try {
    json = jsonDecode(raw.trim());
  } on FormatException {
    throw const BackupException(BackupError.notJson);
  }

  List<Object?>? rawTasks;
  DateTime? exportedAt;
  var format = kBackupFormat;

  if (json is Map) {
    final app = json['app'];
    if (app != null && app != kBackupApp) {
      throw const BackupException(BackupError.notMindDrop);
    }
    final f = json['format'];
    if (f is int) format = f;
    if (format > kBackupFormat) {
      throw const BackupException(BackupError.newerVersion);
    }
    final exported = json['exportedAt'];
    if (exported is String) exportedAt = DateTime.tryParse(exported);
    final t = json['tasks'];
    if (t is List) rawTasks = t;
  } else if (json is List) {
    rawTasks = json; // a bare list of tasks is accepted too
  }

  if (rawTasks == null) throw const BackupException(BackupError.notMindDrop);

  final tasks = <Task>[];
  final seen = <String>{};
  for (final item in rawTasks) {
    if (item is! Map) continue;
    final task = Task.fromJson(Map<String, dynamic>.from(item));
    if (task.title.isEmpty || !seen.add(task.id)) continue;
    tasks.add(task);
  }
  return BackupData(tasks: tasks, exportedAt: exportedAt, format: format);
}

class MergeResult {
  const MergeResult(this.tasks, {required this.added, required this.updated});

  final List<Task> tasks;
  final int added;
  final int updated;
}

/// Merges [incoming] into [existing]: new ids are added, and for ids present in
/// both the most recently updated version wins.
MergeResult mergeTasks(List<Task> existing, List<Task> incoming) {
  final byId = {for (final t in existing) t.id: t};
  var added = 0;
  var updated = 0;
  for (final t in incoming) {
    final current = byId[t.id];
    if (current == null) {
      byId[t.id] = t;
      added++;
    } else if (t.updatedAt.isAfter(current.updatedAt)) {
      byId[t.id] = t;
      updated++;
    }
  }
  return MergeResult(byId.values.toList(), added: added, updated: updated);
}

/// `minddrop-backup-2026-10-27-1430.json`
String backupFileName(DateTime now) {
  String two(int v) => v.toString().padLeft(2, '0');
  return 'minddrop-backup-${now.year}-${two(now.month)}-${two(now.day)}'
      '-${two(now.hour)}${two(now.minute)}.json';
}
