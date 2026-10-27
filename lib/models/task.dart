import 'dart:math';

/// How urgent a task is. Stored by [name] in JSON, so never rename values.
enum TaskPriority {
  none,
  low,
  medium,
  high;

  static TaskPriority parse(Object? raw) {
    for (final p in values) {
      if (p.name == raw) return p;
    }
    return TaskPriority.none;
  }
}

final Random _random = Random();

/// A short, collision-resistant id that sorts roughly by creation time.
String newId() {
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final noise = _random.nextInt(1 << 32).toRadixString(36).padLeft(7, '0');
  return '$time$noise';
}

DateTime? _parseDate(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toLocal();
}

class Subtask {
  const Subtask({required this.id, required this.title, this.done = false});

  factory Subtask.create(String title) => Subtask(id: newId(), title: title);

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
        id: (json['id'] as String?) ?? newId(),
        title: (json['title'] as String?) ?? '',
        done: json['done'] == true,
      );

  final String id;
  final String title;
  final bool done;

  Subtask copyWith({String? title, bool? done}) =>
      Subtask(id: id, title: title ?? this.title, done: done ?? this.done);

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};
}

class Task {
  const Task({
    required this.id,
    required this.title,
    this.note = '',
    this.priority = TaskPriority.none,
    this.tags = const [],
    this.subtasks = const [],
    this.done = false,
    this.pinned = false,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.dueAt,
    this.hasDueTime = false,
    this.remindAt,
  });

  factory Task.create({
    required String title,
    String note = '',
    TaskPriority priority = TaskPriority.none,
    List<String> tags = const [],
    List<Subtask> subtasks = const [],
    bool pinned = false,
    DateTime? dueAt,
    bool hasDueTime = false,
    DateTime? remindAt,
  }) {
    final now = DateTime.now();
    return Task(
      id: newId(),
      title: title,
      note: note,
      priority: priority,
      tags: tags,
      subtasks: subtasks,
      pinned: pinned,
      createdAt: now,
      updatedAt: now,
      dueAt: dueAt,
      hasDueTime: hasDueTime,
      remindAt: remindAt,
    );
  }

  /// Lenient parser: unknown fields are ignored and missing ones get defaults,
  /// so backups from older or newer app versions still import.
  factory Task.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final created = _parseDate(json['createdAt']) ?? now;
    return Task(
      id: (json['id'] as String?) ?? newId(),
      title: ((json['title'] as String?) ?? '').trim(),
      note: (json['note'] as String?) ?? '',
      priority: TaskPriority.parse(json['priority']),
      tags: [
        for (final t in (json['tags'] as List?) ?? const [])
          if (t is String && t.trim().isNotEmpty) t.trim(),
      ],
      subtasks: [
        for (final s in (json['subtasks'] as List?) ?? const [])
          if (s is Map) Subtask.fromJson(Map<String, dynamic>.from(s)),
      ],
      done: json['done'] == true,
      pinned: json['pinned'] == true,
      createdAt: created,
      updatedAt: _parseDate(json['updatedAt']) ?? created,
      completedAt: _parseDate(json['completedAt']),
      dueAt: _parseDate(json['dueAt']),
      hasDueTime: json['hasDueTime'] == true,
      remindAt: _parseDate(json['remindAt']),
    );
  }

  static const Object _unset = Object();

  final String id;
  final String title;
  final String note;
  final TaskPriority priority;
  final List<String> tags;
  final List<Subtask> subtasks;
  final bool done;
  final bool pinned;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  /// Due date. When [hasDueTime] is false only the date part is meaningful.
  final DateTime? dueAt;
  final bool hasDueTime;

  /// When to fire a reminder notification, if any.
  final DateTime? remindAt;

  int get subtasksDone => subtasks.where((s) => s.done).length;

  /// Stable 31-bit id for the notification plugin (FNV-1a of [id]).
  int get notificationId {
    var hash = 0x811c9dc5;
    for (final unit in id.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }

  Task copyWith({
    String? title,
    String? note,
    TaskPriority? priority,
    List<String>? tags,
    List<Subtask>? subtasks,
    bool? done,
    bool? pinned,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? completedAt = _unset,
    Object? dueAt = _unset,
    bool? hasDueTime,
    Object? remindAt = _unset,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      subtasks: subtasks ?? this.subtasks,
      done: done ?? this.done,
      pinned: pinned ?? this.pinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: identical(completedAt, _unset)
          ? this.completedAt
          : completedAt as DateTime?,
      dueAt: identical(dueAt, _unset) ? this.dueAt : dueAt as DateTime?,
      hasDueTime: hasDueTime ?? this.hasDueTime,
      remindAt:
          identical(remindAt, _unset) ? this.remindAt : remindAt as DateTime?,
    );
  }

  /// A copy with a fresh id, as if it had just been created.
  Task duplicate() {
    final now = DateTime.now();
    return Task(
      id: newId(),
      title: title,
      note: note,
      priority: priority,
      tags: tags,
      subtasks: [for (final s in subtasks) Subtask.create(s.title)],
      pinned: pinned,
      createdAt: now,
      updatedAt: now,
      dueAt: dueAt,
      hasDueTime: hasDueTime,
      remindAt: remindAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (note.isNotEmpty) 'note': note,
        'priority': priority.name,
        if (tags.isNotEmpty) 'tags': tags,
        if (subtasks.isNotEmpty)
          'subtasks': [for (final s in subtasks) s.toJson()],
        'done': done,
        'pinned': pinned,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        if (dueAt != null) 'dueAt': dueAt!.toIso8601String(),
        if (hasDueTime) 'hasDueTime': true,
        if (remindAt != null) 'remindAt': remindAt!.toIso8601String(),
      };
}
