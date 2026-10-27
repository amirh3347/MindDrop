import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../data/task_store.dart';
import '../models/task.dart';
import 'common.dart';
import 'screens/task_editor_screen.dart';

/// Toggles completion with haptics and an undo snackbar.
void toggleTaskDone(BuildContext context, Task task) {
  final store = context.read<TaskStore>();
  final l = context.l10n;
  haptic(context, strong: !task.done);
  store.toggleDone(task);
  if (!task.done) {
    showSnack(
      l.t('taskCompleted'),
      actionLabel: l.t('undo'),
      onAction: () {
        final current = store.byId(task.id);
        if (current != null) store.setDone(current, false);
      },
    );
  }
}

/// Deletes with an undo snackbar.
void deleteTaskWithUndo(BuildContext context, Task task) {
  final store = context.read<TaskStore>();
  final l = context.l10n;
  haptic(context);
  final removed = store.delete(task);
  showSnack(
    l.t('taskDeleted'),
    actionLabel: l.t('undo'),
    onAction: () => store.restore(removed),
  );
}

Future<void> openTaskEditor(BuildContext context, {Task? task, Task? draft}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => TaskEditorScreen(task: task, draft: draft),
    ),
  );
}

/// Long-press menu for a task.
Future<void> showTaskMenu(BuildContext context, Task task) async {
  final l = context.l10n;
  final store = context.read<TaskStore>();
  haptic(context);
  final action = await showModalBottomSheet<String>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      Widget item(String id, IconData icon, String label, {Color? color}) => ListTile(
            leading: Icon(icon, color: color),
            title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            onTap: () => Navigator.pop(context, id),
          );
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              item(
                'done',
                task.done ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
                task.done ? l.t('markUndone') : l.t('markDone'),
              ),
              item(
                'pin',
                task.pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                task.pinned ? l.t('unpin') : l.t('pin'),
              ),
              item('duplicate', Icons.copy_rounded, l.t('duplicate')),
              item('delete', Icons.delete_outline_rounded, l.t('delete'), color: scheme.error),
            ],
          ),
        ),
      );
    },
  );
  if (!context.mounted || action == null) return;
  switch (action) {
    case 'done':
      toggleTaskDone(context, task);
    case 'pin':
      store.togglePinned(task);
    case 'duplicate':
      store.duplicate(task);
      showSnack(l.t('duplicated'));
    case 'delete':
      deleteTaskWithUndo(context, task);
  }
}
