import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/calendar.dart';
import '../../core/l10n.dart';
import '../../core/quick_parse.dart';
import '../../core/theme.dart';
import '../../data/settings_store.dart';
import '../../data/task_store.dart';
import '../../models/task.dart';
import '../common.dart';
import '../widgets/date_picker_sheet.dart';
import 'task_editor_screen.dart';

/// Opens the quick-capture sheet. [text] and [note] prefill it, e.g. with
/// content shared from another app.
Future<void> showQuickAdd(BuildContext context, {String text = '', String note = ''}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => QuickAddSheet(initialText: text, initialNote: note),
  );
}

class QuickAddSheet extends StatefulWidget {
  const QuickAddSheet({super.key, this.initialText = '', this.initialNote = ''});

  final String initialText;
  final String initialNote;

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);
  final FocusNode _focus = FocusNode();

  late String _note = widget.initialNote;
  DateTime? _manualDue;
  bool _dateCleared = false;
  TaskPriority? _manualPriority;
  TimeOfDay? _time;
  int _saved = 0;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Mirrors SettingsStore.smartParse; refreshed on every build.
  bool _smart = true;

  QuickParseResult get _parsed {
    final text = _controller.text;
    if (!_smart) {
      return QuickParseResult(title: text.trim());
    }
    return quickParse(text, parseDates: !_dateCleared);
  }

  DateTime? get _due => _manualDue ?? (_dateCleared ? null : _parsed.due);

  TaskPriority get _priority => _manualPriority ?? _parsed.priority ?? TaskPriority.none;

  Task _buildTask() {
    final parsed = _parsed;
    final due = _due;
    final time = _time;
    DateTime? dueAt;
    DateTime? remindAt;
    if (due != null) {
      dueAt = time == null
          ? dateOnly(due)
          : DateTime(due.year, due.month, due.day, time.hour, time.minute);
      if (time != null) remindAt = dueAt;
    }
    return Task.create(
      title: parsed.title,
      note: _note.trim(),
      priority: _priority,
      tags: parsed.tags,
      dueAt: dueAt,
      hasDueTime: time != null && due != null,
      remindAt: remindAt,
    );
  }

  void _submit({bool keepOpen = false}) {
    if (_controller.text.trim().isEmpty) return;
    context.read<TaskStore>().add(_buildTask());
    haptic(context, strong: true);
    if (!keepOpen) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _controller.clear();
      _note = '';
      _manualDue = null;
      _dateCleared = false;
      _manualPriority = null;
      _time = null;
      _saved++;
    });
    _focus.requestFocus();
  }

  void _openEditor() {
    final draft = _controller.text.trim().isEmpty ? null : _buildTask();
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => TaskEditorScreen(draft: draft)),
    );
  }

  Future<void> _pickDate() async {
    final pick = await pickDate(context, initial: _due);
    if (pick == null || !mounted) return;
    setState(() {
      _manualDue = pick.date;
      _dateCleared = pick.date == null;
      if (pick.date == null) _time = null;
    });
  }

  Future<void> _pickReminder() async {
    final settings = context.read<SettingsStore>();
    final time = await pickTime(
      context,
      _time ?? TimeOfDay(hour: settings.reminderHour, minute: 0),
    );
    if (time == null || !mounted) return;
    setState(() {
      _time = time;
      if (_due == null) {
        final now = DateTime.now();
        final todayAt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        _manualDue = todayAt.isAfter(now) ? dateOnly(now) : addDays(dateOnly(now), 1);
        _dateCleared = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _smart = context.watch<SettingsStore>().smartParse;
    final l = context.l10n;
    final cal = calendarOf(context);
    final scheme = Theme.of(context).colorScheme;
    final parsed = _parsed;
    final due = _due;
    final priority = _priority;
    final empty = _controller.text.trim().isEmpty;

    final chips = <Widget>[
      if (due != null)
        InputChip(
          avatar: Icon(Icons.event_rounded, size: 18, color: scheme.primary),
          label: Text(relativeDate(due, l, cal)),
          onPressed: _pickDate,
          onDeleted: () => setState(() {
            _manualDue = null;
            _dateCleared = true;
            _time = null;
          }),
        ),
      if (_time != null && due != null)
        InputChip(
          avatar: Icon(Icons.notifications_active_outlined, size: 18, color: scheme.tertiary),
          label: Text(cal.time(DateTime(2000, 1, 1, _time!.hour, _time!.minute))),
          onPressed: _pickReminder,
          onDeleted: () => setState(() => _time = null),
        ),
      if (priority != TaskPriority.none)
        InputChip(
          avatar: Icon(Icons.flag_rounded, size: 18, color: priorityColor(priority, scheme)),
          label: Text(priorityLabel(priority, l)),
          onDeleted: () => setState(() => _manualPriority = TaskPriority.none),
        ),
      for (final tag in parsed.tags)
        Chip(
          label: Text('#$tag'),
          labelStyle: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
        ),
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: true,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _submit(),
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: l.t('quickHint'),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              ),
            ),
            if (_note.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 4, 8),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notes_rounded, size: 18, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() => _note = ''),
                    ),
                  ],
                ),
              ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              alignment: AlignmentDirectional.topStart,
              child: chips.isEmpty
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(spacing: 6, runSpacing: 6, children: chips),
                    ),
            ),
            if (empty && _saved == 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text(
                  l.t('quickTips'),
                  style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
                ),
              ),
            Row(
              children: [
                IconButton(
                  tooltip: l.t('dueDate'),
                  onPressed: _pickDate,
                  icon: Icon(
                    Icons.event_rounded,
                    color: due != null ? scheme.primary : null,
                  ),
                ),
                PopupMenuButton<TaskPriority>(
                  tooltip: l.t('priority'),
                  initialValue: priority,
                  onSelected: (p) => setState(() => _manualPriority = p),
                  icon: Icon(
                    Icons.flag_rounded,
                    color: priority == TaskPriority.none ? null : priorityColor(priority, scheme),
                  ),
                  itemBuilder: (context) => [
                    for (final p in TaskPriority.values.reversed)
                      PopupMenuItem(
                        value: p,
                        child: Row(
                          children: [
                            Icon(Icons.flag_rounded, color: priorityColor(p, scheme), size: 20),
                            const SizedBox(width: 10),
                            Text(priorityLabel(p, l)),
                          ],
                        ),
                      ),
                  ],
                ),
                IconButton(
                  tooltip: l.t('setReminder'),
                  onPressed: _pickReminder,
                  icon: Icon(
                    Icons.notifications_none_rounded,
                    color: _time != null ? scheme.tertiary : null,
                  ),
                ),
                IconButton(
                  tooltip: l.t('openEditor'),
                  onPressed: _openEditor,
                  icon: const Icon(Icons.open_in_full_rounded),
                ),
                const Spacer(),
                if (_saved > 0)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 4),
                    child: Text(
                      l.f('savedCount', {'count': _saved}),
                      style: const TextStyle(fontSize: 12, color: kSuccess, fontWeight: FontWeight.w600),
                    ),
                  ),
                IconButton(
                  tooltip: l.t('saveAndNew'),
                  onPressed: empty ? null : () => _submit(keepOpen: true),
                  icon: const Icon(Icons.playlist_add_rounded),
                ),
                const SizedBox(width: 4),
                IconButton.filled(
                  tooltip: l.t('save'),
                  onPressed: empty ? null : _submit,
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
