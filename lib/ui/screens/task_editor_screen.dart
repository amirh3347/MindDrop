import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/calendar.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/settings_store.dart';
import '../../data/task_store.dart';
import '../../models/task.dart';
import '../common.dart';
import '../widgets/date_picker_sheet.dart';

/// Full editor for a task. Changes are saved automatically when leaving.
///
/// Pass [task] to edit an existing one, or [draft] (optional) to start a new
/// task prefilled with some values.
class TaskEditorScreen extends StatefulWidget {
  const TaskEditorScreen({super.key, this.task, this.draft});

  final Task? task;
  final Task? draft;

  @override
  State<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends State<TaskEditorScreen> {
  late final Task? _original = widget.task;
  late final Task _source = widget.task ?? widget.draft ?? Task.create(title: '');

  late final TextEditingController _title = TextEditingController(text: _source.title);
  late final TextEditingController _note = TextEditingController(text: _source.note);
  final TextEditingController _subtaskInput = TextEditingController();

  late TaskPriority _priority = _source.priority;
  late List<String> _tags = [..._source.tags];
  late List<Subtask> _subtasks = [..._source.subtasks];
  late bool _pinned = _source.pinned;
  late bool _done = _source.done;
  late DateTime? _date = _source.dueAt == null ? null : dateOnly(_source.dueAt!);
  late TimeOfDay? _time =
      _source.hasDueTime && _source.dueAt != null ? TimeOfDay.fromDateTime(_source.dueAt!) : null;
  late bool _remind = _source.remindAt != null;
  late TimeOfDay? _remindTime =
      _source.remindAt == null ? null : TimeOfDay.fromDateTime(_source.remindAt!);

  bool _deleted = false;

  bool get _isNew => _original == null;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _subtaskInput.dispose();
    super.dispose();
  }

  DateTime? _dueAt() {
    final d = _date;
    if (d == null) return null;
    final t = _time;
    return t == null ? d : DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  DateTime? _remindAt(int defaultHour) {
    final d = _date;
    if (!_remind || d == null) return null;
    final t = _time ?? _remindTime ?? TimeOfDay(hour: defaultHour, minute: 0);
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  void _save() {
    if (_deleted) return;
    final title = _title.text.trim();
    if (title.isEmpty) return; // empty new task: discard; existing: keep as is
    final store = context.read<TaskStore>();
    final reminderHour = context.read<SettingsStore>().reminderHour;

    final pendingSubtask = _subtaskInput.text.trim();
    final subtasks = [
      ..._subtasks,
      if (pendingSubtask.isNotEmpty) Subtask.create(pendingSubtask),
    ];

    final original = _original;
    if (original == null) {
      store.add(Task.create(
        title: title,
        note: _note.text.trim(),
        priority: _priority,
        tags: _tags,
        subtasks: subtasks,
        pinned: _pinned,
        dueAt: _dueAt(),
        hasDueTime: _time != null && _date != null,
        remindAt: _remindAt(reminderHour),
      ));
      return;
    }

    // Read the latest version: the task may have changed elsewhere meanwhile.
    final latest = store.byId(original.id) ?? original;
    final doneChanged = _done != original.done;
    final updated = latest.copyWith(
      title: title,
      note: _note.text.trim(),
      priority: _priority,
      tags: _tags,
      subtasks: subtasks,
      pinned: _pinned,
      done: doneChanged ? _done : latest.done,
      completedAt: doneChanged ? (_done ? DateTime.now() : null) : latest.completedAt,
      dueAt: _dueAt(),
      hasDueTime: _time != null && _date != null,
      remindAt: _remindAt(reminderHour),
    );
    if (jsonEncode(updated.toJson()) != jsonEncode(latest.toJson())) {
      store.update(updated);
    }
  }

  Future<void> _pickDate() async {
    final pick = await pickDate(context, initial: _date);
    if (pick == null || !mounted) return;
    setState(() {
      _date = pick.date == null ? null : dateOnly(pick.date!);
      if (_date == null) {
        _time = null;
        _remind = false;
      }
    });
  }

  Future<void> _pickTime() async {
    final reminderHour = context.read<SettingsStore>().reminderHour;
    final time = await pickTime(context, _time ?? TimeOfDay(hour: reminderHour, minute: 0));
    if (time == null || !mounted) return;
    setState(() {
      _time = time;
      _date ??= dateOnly(DateTime.now());
    });
  }

  Future<void> _addTag() async {
    final l = context.l10n;
    final existing = context.read<TaskStore>().allTags.where((t) => !_tags.contains(t)).toList();
    final controller = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (context) {
        String clean(String raw) =>
            raw.trim().replaceFirst(RegExp(r'^#+'), '').replaceAll(RegExp(r'\s+'), '_');
        return AlertDialog(
          title: Text(l.t('addTag')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(hintText: l.t('tagHint'), prefixText: '# '),
                onSubmitted: (v) => Navigator.pop(context, clean(v)),
              ),
              if (existing.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in existing.take(12))
                      ActionChip(
                        label: Text('#$t'),
                        onPressed: () => Navigator.pop(context, t),
                      ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l.t('cancel'))),
            FilledButton(
              onPressed: () => Navigator.pop(context, clean(controller.text)),
              child: Text(l.t('add')),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (tag == null || tag.isEmpty || _tags.contains(tag) || !mounted) return;
    setState(() => _tags = [..._tags, tag]);
  }

  void _addSubtask() {
    final text = _subtaskInput.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subtasks = [..._subtasks, Subtask.create(text)];
      _subtaskInput.clear();
    });
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final original = _original;
    if (original == null) {
      _deleted = true;
      Navigator.pop(context);
      return;
    }
    final ok = await confirmDialog(
      context,
      title: l.t('deleteConfirmTitle'),
      message: original.title,
      confirmLabel: l.t('delete'),
      destructive: true,
    );
    if (!ok || !mounted) return;
    _deleted = true;
    final store = context.read<TaskStore>();
    final removed = store.delete(original);
    Navigator.pop(context);
    showSnack(l.t('taskDeleted'), actionLabel: l.t('undo'), onAction: () => store.restore(removed));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cal = calendarOf(context);
    final scheme = Theme.of(context).colorScheme;
    final reminderHour = context.watch<SettingsStore>().reminderHour;
    final remindAt = _remindAt(reminderHour);
    final original = _original;
    final completedAt = original?.completedAt;

    return PopScope<Object?>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _save();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isNew ? l.t('newTask') : l.t('editTask')),
          actions: [
            IconButton(
              tooltip: _pinned ? l.t('unpin') : l.t('pin'),
              onPressed: () => setState(() => _pinned = !_pinned),
              icon: Icon(
                _pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                color: _pinned ? scheme.primary : null,
              ),
            ),
            IconButton(
              tooltip: l.t('delete'),
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
            IconButton(
              tooltip: l.t('save'),
              onPressed: () {
                if (_title.text.trim().isEmpty && !_isNew) {
                  showSnack(l.t('titleRequired'));
                  return;
                }
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check_rounded),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            TextField(
              controller: _title,
              autofocus: _isNew && _title.text.isEmpty,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.4),
              decoration: InputDecoration(
                hintText: l.t('titleHint'),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              maxLines: null,
              minLines: 3,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 15, height: 1.6),
              decoration: InputDecoration(hintText: l.t('noteHint')),
            ),
            _Section(
              title: l.t('priority'),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<TaskPriority>(
                  showSelectedIcon: false,
                  segments: [
                    for (final p in TaskPriority.values)
                      ButtonSegment(
                        value: p,
                        label: Text(priorityLabel(p, l)),
                        icon: Icon(Icons.circle, size: 10, color: priorityColor(p, scheme)),
                      ),
                  ],
                  selected: {_priority},
                  onSelectionChanged: (s) => setState(() => _priority = s.first),
                ),
              ),
            ),
            _Section(
              title: l.t('schedule'),
              child: Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.event_rounded, color: _date != null ? scheme.primary : null),
                      title: Text(l.t('dueDate')),
                      subtitle: Text(_date == null ? l.t('noDate') : cal.fullDate(_date!)),
                      onTap: _pickDate,
                      trailing: _date == null
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => setState(() {
                                _date = null;
                                _time = null;
                                _remind = false;
                              }),
                            ),
                    ),
                    ListTile(
                      leading: Icon(Icons.schedule_rounded, color: _time != null ? scheme.primary : null),
                      title: Text(l.t('dueTime')),
                      subtitle: Text(
                        _time == null
                            ? l.t('noTime')
                            : cal.time(DateTime(2000, 1, 1, _time!.hour, _time!.minute)),
                      ),
                      onTap: _pickTime,
                      trailing: _time == null
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => setState(() => _time = null),
                            ),
                    ),
                    SwitchListTile(
                      secondary: Icon(
                        Icons.notifications_active_outlined,
                        color: _remind && _date != null ? scheme.tertiary : null,
                      ),
                      title: Text(l.t('reminder')),
                      subtitle: Text(
                        _date == null
                            ? l.t('reminderNeedsDate')
                            : remindAt == null
                                ? l.f('reminderAt', {
                                    'time': cal.time(DateTime(
                                      2000,
                                      1,
                                      1,
                                      (_time ?? _remindTime)?.hour ?? reminderHour,
                                      (_time ?? _remindTime)?.minute ?? 0,
                                    )),
                                  })
                                : cal.dateTime(remindAt),
                      ),
                      value: _remind && _date != null,
                      onChanged: _date == null ? null : (v) => setState(() => _remind = v),
                    ),
                  ],
                ),
              ),
            ),
            _Section(
              title: l.t('tags'),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in _tags)
                    InputChip(
                      label: Text('#$tag'),
                      labelStyle: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
                      onDeleted: () => setState(() => _tags = [..._tags]..remove(tag)),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add_rounded, size: 18),
                    label: Text(l.t('addTag')),
                    onPressed: _addTag,
                  ),
                ],
              ),
            ),
            _Section(
              title: l.t('subtasks'),
              trailing: _subtasks.isEmpty
                  ? null
                  : Text(
                      '${l.n(_subtasks.where((s) => s.done).length)}/${l.n(_subtasks.length)}',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                    ),
              child: Card(
                child: Column(
                  children: [
                    for (final s in _subtasks)
                      ListTile(
                        key: ValueKey(s.id),
                        contentPadding: const EdgeInsetsDirectional.only(start: 4, end: 4),
                        leading: Checkbox(
                          value: s.done,
                          shape: const CircleBorder(),
                          onChanged: (v) => setState(() {
                            _subtasks = [
                              for (final x in _subtasks) x.id == s.id ? x.copyWith(done: v ?? false) : x,
                            ];
                          }),
                        ),
                        title: Text(
                          s.title,
                          style: TextStyle(
                            decoration: s.done ? TextDecoration.lineThrough : null,
                            color: s.done ? scheme.onSurfaceVariant : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => setState(() {
                            _subtasks = _subtasks.where((x) => x.id != s.id).toList();
                          }),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 4, 4),
                      child: Row(
                        children: [
                          Icon(Icons.add_rounded, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _subtaskInput,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _addSubtask(),
                              decoration: InputDecoration(
                                hintText: l.t('addSubtask'),
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _addSubtask,
                            icon: Icon(Icons.keyboard_return_rounded, color: scheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: _done ? null : kSuccess.withValues(alpha: 0.18),
                foregroundColor: _done ? null : kSuccess,
              ),
              onPressed: () {
                haptic(context, strong: !_done);
                setState(() => _done = !_done);
              },
              icon: Icon(_done ? Icons.undo_rounded : Icons.check_circle_rounded),
              label: Text(
                _done ? l.t('markUndone') : l.t('markDone'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (original != null) ...[
              const SizedBox(height: 20),
              Text(
                [
                  l.f('createdAt', {'date': cal.dateTime(original.createdAt)}),
                  if (completedAt != null && _done)
                    l.f('completedOn', {'date': cal.dateTime(completedAt)}),
                ].join('\n'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, height: 1.7, color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 10),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}
